{ site }:
{ config, lib, pkgs, ... }:

with lib;

let
  # Static parameters:
  tmlDevFsPrefix = "tml-boards";

  # Helper functions:
  ensureUuidV4 = str:
    if (builtins.match "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$" str) == null then
      throw "String is not a valid UUID v4: ${str}"
    else
      str;

  # Short ID, taking the first 4 bytes / 8 characters of the UUID. This is used
  # within network interface names, as in total they cannot exceed 14
  # characters. This has a low chance of collisions for UUID v4s, which we
  # expect to be used here.
  shortId = str: builtins.substring 0 8 (ensureUuidV4 str);

  # Treadmill configuration database:
  db = import ./combined.nix { inherit lib; };

  # Global database lookup shortcuts:
  dbSite = db.sites."${site}";

  # Supervisor build infrastructure:
  fenix = import (builtins.fetchGit {
    url = "https://github.com/nix-community/fenix.git";
    ref = "main";
    rev = "0900ff903f376cc822ca637fef58c1ca4f44fab5";
  }) { };

  tmlSource = builtins.fetchGit {
    url = "https://github.com/treadmill-tb/treadmill";
    ref = "main";
    rev = "553f7f3fd53a14609457947d3f42045002bd6499";
  };

  rustToolchain = fenix.fromToolchainFile {
    file = "${tmlSource}/rust-toolchain.toml";
    sha256 = "sha256-6eN/GKzjVSjEhGO9FhWObkRFaE1Jf+uqMSdQnb8lcB4=";
  };

  rustPlatform = pkgs.makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  tmlQemuSupervisor = rustPlatform.buildRustPackage rec {
    pname = "tml-qemu-supervisor";
    version = "0.0.1";

    src = "${tmlSource}";
    buildAndTestSubdir = "supervisor/qemu";

    cargoLock.lockFile = "${src}/Cargo.lock";
    cargoLock.outputHashes."inquire-0.7.5" = "sha256-iEdsjq4IYYl6QoJmDkPQS5bJJvPG3sehDygefAOhTrY=";
  };

  # Configuration generators:
  genNbdNetbootSupervisorConfig = supervisorId: nbdNetbootStatic: let
    dbSupervisor = db.supervisors."${supervisorId}";
    dbSiteSupervisor = dbSite.supervisors."${supervisorId}";
    dbSwitch = dbSite.switches."${dbSiteSupervisor.nbd_netboot_host_switch}";

    vlanNetdevName = "tn-${shortId supervisorId}";
    networkCIDR = "${dbSiteSupervisor.nbd_netboot_host_ip4.network}/${toString dbSiteSupervisor.nbd_netboot_host_ip4.prefixlen}";
    supervisorCIDR = "${dbSiteSupervisor.nbd_netboot_host_ip4.supervisor_addr}/${toString dbSiteSupervisor.nbd_netboot_host_ip4.prefixlen}";
    hostCIDR = "${dbSiteSupervisor.nbd_netboot_host_ip4.addr}/${toString dbSiteSupervisor.nbd_netboot_host_ip4.prefixlen}";
  in mkMerge [{
    # VLAN network device on the experiment link
    systemd.network.netdevs."10-${vlanNetdevName}" = {
      netdevConfig = {
        Name = "${vlanNetdevName}";
        Kind = "vlan";
      };
      vlanConfig.Id = dbSiteSupervisor.nbd_netboot_host_vlan;
    };

    # Add this VLAN to the trunk link.
    #
    # TODO: this is not nice. We expect that the importing system configurations
    # defines a systemd-networkd network definition named the same as the
    # underlying network interface. Is there a better way to merge
    # configurations like this?
    systemd.network.networks."${dbSwitch.trunk_supervisor_netdev}" = {
      networkConfig.VLAN = [ "${vlanNetdevName}" ];
    };

    # VLAN network configuration:
    systemd.network.networks."20-${vlanNetdevName}" =
      if dbSupervisor.nbd_netboot_host.pxe_profile == "raspberrypi" then {
        matchConfig.Name = vlanNetdevName;
        address = [ supervisorCIDR ];
        linkConfig.RequiredForOnline = "no";
        networkConfig.DHCPServer = "yes";
        dhcpServerConfig = {
          EmitDNS = "yes";
          #DNS = [ "10.64.0.1" ];
          DNS = [ "8.8.8.8" ];
          EmitNTP = "yes";
          NTP = [ "129.6.15.28" ]; # time-a-g.nist.gov
          EmitRouter = "yes";
          BindToInterface = "yes";
          BootServerAddress = dbSiteSupervisor.nbd_netboot_host_ip4.supervisor_addr;
          BootServerName = "Raspberry Pi Boot";
          BootFilename = "bootcode.bin";
          SendOption = [ "60:string:PXEClient" ];
          SendVendorOption = [
            "6:uint8:3"
            "10:uint32:5265477"
            "9:string:\\x00\\x00\\x11\\x52\\x61\\x73\\x70\\x62\\x65\\x72\\x72\\x79\\x20\\x50\\x69\\x20\\x42\\x6f\\x6f\\x74"
          ];
        };
        dhcpServerStaticLeases = [ {
          dhcpServerStaticLeaseConfig = {
            MACAddress = dbSupervisor.nbd_netboot_host.mac_addr;
            Address = dbSiteSupervisor.nbd_netboot_host_ip4.addr;
          };
        } ];
        routes = [{
          routeConfig = {
            Destination = networkCIDR;
            Table = 1337;
          };
        }];
        routingPolicyRules = [{
          routingPolicyRuleConfig = {
            From = networkCIDR;
            Table = 1337;
            Priority = 10000;
          };
        }];
      } else throw "Unsupported NBD Netboot PXE Profile: ${dbSupervisor.nbd_netboot_host.pxe_profile}";

    # Add the serial console adapter to the udev rules:
    services.udev.extraRules = ''
      # ----- Treadmill NBD Netboot Host ${supervisorId}
      SUBSYSTEM=="tty", \
        ${lib.concatStringsSep "\\\n  " dbSupervisor.nbd_netboot_console.udev_filters} \
        SYMLINK+="${tmlDevFsPrefix}/${supervisorId}/host-console", \
        MODE="0666"
    '';
  } (optionalAttrs nbdNetbootStatic (let
    state_dir = "/var/lib/treadmill/supervisor-state/nbd-netboot-static-${supervisorId}";
  in {
    systemd.services."tml-nbd-netboot-static-${shortId supervisorId}-boot-tftp" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartIfChanged = false;
      reloadIfChanged = false;

      serviceConfig = {
        Type = "simple";
        User = "tml";
        Group = "tml";
        ExecStartPre = pkgs.writeScript "tml-nbd-netboot-static-${shortId supervisorId}-boot-tftp-setup.sh" ''
          #!${pkgs.bash}/bin/bash
          set -e -x

          # Ensure the work directory
          ${pkgs.coreutils}/bin/mkdir -p "${state_dir}"

          # Remove any existing unpacked boot files
          ${pkgs.coreutils}/bin/rm -rf "${state_dir}/boot"

          # Unpack the boot file system
          ${pkgs.coreutils}/bin/mkdir -p "${state_dir}/boot"
          ${pkgs.gnutar}/bin/tar -xf "${dbSupervisor.nbd_netboot_static.boot_archive}" -C "${state_dir}/boot"
        '';
        ExecStart = "+${pkgs.atftp}/sbin/atftpd --daemon --no-fork --bind-address ${dbSiteSupervisor.nbd_netboot_host_ip4.supervisor_addr} ${state_dir}/boot";
      };
    };

    systemd.services."tml-nbd-netboot-static-${shortId supervisorId}-root-nbd" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartIfChanged = false;
      reloadIfChanged = false;

      serviceConfig = rec {
        Type = "simple";
        User = "tml";
        Group = "tml";
        ExecStart = pkgs.writeScript "tml-nbd-netboot-static-${shortId supervisorId}-root-nbd.sh" ''
          #!${pkgs.bash}/bin/bash
          set -e -x

          # Ensure the work directory exists
          mkdir -p "${state_dir}"

          # We want to create a new COW layer if the base image path changes,
          # thus we name it after its hash:
          BASE_IMAGE_PATH_HASH="$( \
            echo -n "${dbSupervisor.nbd_netboot_static.root_base_image}" \
            | ${pkgs.coreutils}/bin/sha256sum \
            | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
          COW_IMAGE_PATH="${state_dir}/$BASE_IMAGE_PATH_HASH.cow.qcow2"

          # Create a new thin COW layer if it doesn't exist yet:
          if [ ! -f "$COW_IMAGE_PATH" ]; then
            ${pkgs.qemu}/bin/qemu-img create \
              -b "${dbSupervisor.nbd_netboot_static.root_base_image}" -F qcow2 \
              -f qcow2 "$COW_IMAGE_PATH" "${dbSupervisor.nbd_netboot_static.root_dev_size}"
          fi

          # Exec the qemu-nbd image server
          exec ${pkgs.qemu}/bin/qemu-nbd \
            --aio=io_uring --discard=unmap --detect-zeroes=unmap \
            --format=qcow2 --export-name=root --persistent --shared=0 \
            --bind ${dbSiteSupervisor.nbd_netboot_host_ip4.supervisor_addr} \
            "$COW_IMAGE_PATH"
        '';
      };
    };
  }))];

  genQemuSupervisorConfig = supervisorId: let
    dbSupervisor = db.supervisors."${supervisorId}";
    dbSiteSupervisor = dbSite.supervisors."${supervisorId}";
    dbSwitch = dbSite.switches."${dbSiteSupervisor.qemu_host_switch}";

    networkCIDR = "${dbSiteSupervisor.qemu_host_ip4.network}/${toString dbSiteSupervisor.qemu_host_ip4.prefixlen}";
    supervisorCIDR = "${dbSiteSupervisor.qemu_host_ip4.supervisor_addr}/${toString dbSiteSupervisor.qemu_host_ip4.prefixlen}";
    hostCIDR = "${dbSiteSupervisor.qemu_host_ip4.addr}/${toString dbSiteSupervisor.qemu_host_ip4.prefixlen}";
    bridgeNetdevName = "tn-${shortId supervisorId}";

    qemuPkg = pkgs.qemu_kvm;

    qemuSupervisorConfig = {
      base = {
        supervisor_id = supervisorId;
        coord_connector = "ws_connector";
      };

      ws_connector = {
        switchboard_uri = "wss://swb.treadmill.ci";
        token_file = "/var/lib/treadmill/supervisor-ws-tokens/${supervisorId}";
      };

      image_store = {
        # Doesn't do anything yet. This endpoint will be used to request
        # images to be downloaded etc. later on:
        http_endpoint = "https://localhost:8080";

        # Local mountpoint of the read-only image store:
        fs_endpoint = "/var/lib/treadmill/store";
      };

      qemu = rec {
        qemu_binary = "${qemuPkg}/bin/qemu-kvm";
        qemu_img_binary = "${qemuPkg}/bin/qemu-img";

        state_dir = "/var/lib/treadmill/supervisor-state/qemu-${supervisorId}";

        qemu_args = [
          # Misc:
          "-name" "tml-{job_id}"
          "-nographic"
          # Base machine configuration:
          "-machine" "q35"
          "-m" "4G"
          "-drive" "if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd"
          "-drive" "if=pflash,format=raw,file={job_workdir}/OVMF_VARS.fd"
          # Storage:
          "-device" "virtio-scsi-pci,id=scsi0"
          "-drive" "file={main_disk_image},id=drive0,format=qcow2,if=none"
          "-device" "scsi-hd,drive=drive0,bus=scsi0.0"
          # Network:
          "-netdev" "bridge,id=net0,helper=/run/wrappers/bin/tml-${supervisorId}-qemu-bridge-helper,br=${bridgeNetdevName}"
          "-device" "virtio-net-pci,id=nic0,netdev=net0,mac=${dbSupervisor.qemu_host.mac_addr}"
          # Treamill-specific attributes:
          # (10.0.2.2 is the host address in QEMU SLIRP networking)
          "-fw_cfg" "name=opt/org.tockos.treadmill.tcp-ctrl-socket,string=${dbSiteSupervisor.qemu_host_ip4.supervisor_addr}:3859"
          # QEMU monitor for debugging:
          "-monitor" "unix:qemu-monitor-socket,server,nowait,path=${state_dir}/monitor_sock"
          # USB:
          "-device" "qemu-xhci"
        ] ++ (
          flatten (
            mapAttrsToList (deviceId: _: [
              "-device" "usb-host,hostbus={usb_passthrough_dev_${deviceId}_hostbus},hostaddr={usb_passthrough_dev_${deviceId}_hostaddr}"
            ]) dbSupervisor.qemu_host.usb_passthrough_devs
          )
        );

        tcp_control_socket_listen_addr = "${dbSiteSupervisor.qemu_host_ip4.supervisor_addr}:3859";

        # Each VM will have at most 32GB to work with. This should be
        # sufficient to support most images, even heavy-weight toolchains
        # (such as OpenTitan with Bazel and Vivado Lab tools)
        working_disk_max_bytes = 34359738368;

        start_script = "${pkgs.writeScript "tml-qemu-3b9003a2-33e5-4847-9417-52698df301ec-start.sh" ''
          #!${pkgs.bash}/bin/bash
          set -e -x

          cp "${pkgs.OVMF.fd}/FV/OVMF_VARS.fd" "$TML_JOB_WORKDIR/OVMF_VARS.fd"
          chmod u+w "$TML_JOB_WORKDIR/OVMF_VARS.fd"

          ${
            concatStringsSep "\n\n" (
              mapAttrsToList (deviceId: device: ''
                USB_HOSTBUS="$(${pkgs.systemd}/bin/udevadm info /dev/tml-boards/${supervisorId}/usb-${deviceId} -q property --property BUSNUM --value)"
                USB_HOSTADDR="$(${pkgs.systemd}/bin/udevadm info /dev/tml-boards/${supervisorId}/usb-${deviceId} -q property --property DEVNUM --value)"
                echo "USB passthrough device ${deviceId} attached to bus $USB_HOSTBUS:$USB_HOSTADDR" >&2
                echo "tml-set-variable:usb_passthrough_dev_${deviceId}_hostbus=$(echo "$USB_HOSTBUS" | ${pkgs.gnused}/bin/sed 's/^0*//')"
                echo "tml-set-variable:usb_passthrough_dev_${deviceId}_hostaddr=$(echo "$USB_HOSTADDR" | ${pkgs.gnused}/bin/sed 's/^0*//')"
              '') dbSupervisor.qemu_host.usb_passthrough_devs
            )
          }
        ''}";
      };
    };

  in {
    # Bridge network interface to which the VM attaches. We use a network
    # bridge to have a persistent network interface that is always configured
    # regardless of whether the QEMU process is running. This allows us to bind
    # services on the host IP even before the QEMU process is started, etc.
    systemd.network.netdevs."10-${bridgeNetdevName}".netdevConfig = {
      Name = "${bridgeNetdevName}";
      Kind = "bridge";
    };

    # Bridge network configuration:
    systemd.network.networks."20-${bridgeNetdevName}" = {
      matchConfig.Name = bridgeNetdevName;
      address = [ supervisorCIDR ];
      linkConfig.RequiredForOnline = "no";
      networkConfig.ConfigureWithoutCarrier = "yes";
      networkConfig.DHCPServer = "yes";
      dhcpServerConfig = {
        EmitDNS = "yes";
        DNS = [ "10.64.0.1" ];
        EmitNTP = "yes";
        NTP = [ "129.6.15.28" ]; # time-a-g.nist.gov
        EmitRouter = "yes";
        BindToInterface = "yes";
      };
      dhcpServerStaticLeases = [ {
        dhcpServerStaticLeaseConfig = {
          MACAddress = dbSupervisor.qemu_host.mac_addr;
          Address = dbSiteSupervisor.qemu_host_ip4.addr;
        };
      } ];
      routes = [{
        routeConfig = {
          Destination = networkCIDR;
          Table = 1337;
        };
      }];
      routingPolicyRules = [{
        routingPolicyRuleConfig = {
          From = networkCIDR;
          Table = 1337;
          Priority = 10000;
        };
      }];
    };

    systemd.services."tml-supervisor-qemu-${shortId supervisorId}-ssh-proxy" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "root";
        ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:${builtins.toString dbSiteSupervisor.qemu_host_ip4.ssh_forward_host_port},fork,reuseaddr TCP:${dbSiteSupervisor.qemu_host_ip4.addr}:22";
      };
    };

    systemd.services."tml-supervisor-qemu-${shortId supervisorId}" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartIfChanged = false;
      reloadIfChanged = true;

      serviceConfig = rec {
        Type = "simple";
        User = "tml";
        Group = "tml";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p ${qemuSupervisorConfig.qemu.state_dir}"
          "${pkgs.coreutils}/bin/chown ${User}:${Group} ${qemuSupervisorConfig.qemu.state_dir}"
        ];
        ExecStart = "${tmlQemuSupervisor}/bin/tml-qemu-supervisor -c ${
          (pkgs.formats.toml {}).generate "tml-supervisor-qemu-${supervisorId}.toml" qemuSupervisorConfig
        }";
      };
    };

    environment.etc."qemu/bridge.conf".text = ''
      allow ${bridgeNetdevName}
    '';

    security.wrappers."tml-${supervisorId}-qemu-bridge-helper" = {
      source = "${qemuPkg}/libexec/qemu-bridge-helper";
      owner = "root";
      group = "root";
      capabilities = "cap_net_admin=pe";
    };

    # Add the serial console adapter to the udev rules:
    services.udev.extraRules = ''
      # ----- Treadmill QEMU Host ${supervisorId} USB Devices
      ${
        concatStringsSep "\n" (
          mapAttrsToList (deviceId: device: ''
            SUBSYSTEM=="usb", \
              ${lib.concatStringsSep "\\\n  " device.udev_filters} \
              SYMLINK+="${tmlDevFsPrefix}/${supervisorId}/usb-${deviceId}", \
              MODE="0666"
          '') dbSupervisor.qemu_host.usb_passthrough_devs
        )
      }
    '';
  };

  genSupervisorConfig = supervisorId: let
    dbSupervisor = db.supervisors."${supervisorId}";
  in
    # Call out to different generators depending on the type of supervisor:
    if (dbSupervisor.type == "nbd_netboot" || dbSupervisor.type == "nbd_netboot_static") then
      genNbdNetbootSupervisorConfig supervisorId (dbSupervisor.type == "nbd_netboot_static")
    else if dbSupervisor.type == "qemu" then
      genQemuSupervisorConfig supervisorId
    else
      throw "Unknown supervisor type ${dbSupervisor.type} for supervisor ${supervisorId}";
in

mkMerge ([{
  # Global system configuration
  users.groups.tml = {
    gid = 700;
  };

  users.users.tml = {
    uid = 700;
    isSystemUser = true;
    group = "tml";
    extraGroups = [ "kvm" ];
    home = "/var/lib/treadmill";
  };

  environment.etc."qemu/bridge.conf" = {
    enable = true;
    user = "root";
    group = "root";
  };
}] ++ (
  # Per-supervisor configuration, generated from the set of enabled
  # supervisors:
  builtins.map
    genSupervisorConfig
    (builtins.attrNames dbSite.supervisors)
))
