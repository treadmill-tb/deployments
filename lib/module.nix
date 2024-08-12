{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.treadmill;
  db = import ./combined.nix { inherit lib; };

  # Global database lookup shortcuts:
  dbSite = db.supervisors."${cfg.site}";

  ensureUuidV4 = str:
    if (builtins.match "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$" str) == null then
      throw "String is not a valid UUID v4: ${str}"
    else
      str;

  # Short ID, taking the first 4 bytes / 8 characters of the UUID. This is used
  # within network interface names, as in total they cannot exceed 14
  # characters. This has a low chance of collisions for UUID v4s, which we
  # expect to be used here.
  shortId = builtins.substring 0 8;

  devFsPrefix = "tml-boards";

  genNbdNetbootSupervisorConfig = supervisorId: supervisorAttrs: let
    dbSupervisor = db.supervisors."${supervisorId}";
    dbSiteSupervisor = dbSite.supervisors."${supervisorId}";
    dbSwitch = dbSite.switches."${dbSiteSupervisor.nbd_netboot_host_switch}";

    vlanNetdevName = [ "tn-${shortId supervisorId}" ];
  in {
    # VLAN network device on the experiment link
    systemd.network.netdevs."10-${vlanNetdevName}" = {
      netdevConfig = {
        Name = "${vlanNetdevName}";
        Kind = "vlan";
      };
      vlanConfig.Id = 1000;
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
    systemd.network.network."20-${vlanNetdevName}" =
      if dbSupervisor.nbd_netboot_host.pxe_profile == "raspberrypi" then {
        matchConfig.Name = name;
        address = [ "${dbSiteSupervisor.nbd_netboot_host_ip4.supervisor_addr}/${dbSiteSupervisor.nbd_netboot_host_ip4.prefixlen}" ];
        linkConfig.RequiredForOnline = "no";
        networkConfig.DHCPServer = "yes";
        dhcpServerConfig = {
          EmitDNS = "yes";
          DNS = [ "10.64.0.1" ];
          EmitNTP = "yes";
          NTP = [ "129.6.15.28" ]; # time-a-g.nist.gov
          EmitRouter = "yes";
          BindToInterface = "yes";
          BootServerAddress = "${dbSiteSupervisor.nbd_netboot_host_ip4.supervisor_addr}";
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
            MACAddress = "${dbSupervisor.nbd_netboot_host.mac_addr}";
            Address = "${dbSiteSupervisor.nbd_netboot_host_ip4.addr}";
          };
        } ];
        routes = [{
          routeConfig = {
            Destination = "${dbSiteSupervisor.nbd_netboot_host_ip4.addr}/${dbSiteSupervisor.nbd_netboot_host_ip4.prefixlen}";
            Table = 1337;
          };
        }];
        routingPolicyRules = [{
          routingPolicyRuleConfig = {
            From = "${dbSiteSupervisor.nbd_netboot_host_ip4.addr}/${dbSiteSupervisor.nbd_netboot_host_ip4.prefixlen}";
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
        SYMLINK+="${tmlFsPrefix}/${supervisorId}/host-console", \
        MODE="0666"
    '';
  };

  genSupervisorConfig = supervisorId: supervisorAttrs: let
    dbSupervisor = db.supervisors."${supervisorId}";
  in
    # Call out to different generators depending on the type of supervisor:
    if dbSupervisor.type == "nbd_netboot" then
      genNbdNetbootSupervisorConfig supervisorId supervisorAttrs
    else
      throw "Unknown supervisor type ${dbSupervisor.type} for supervisor ${supervisorId}";
in

{
  imports = [];

  options = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    site = mkOption {
      type = types.string;
    };

    treadmill.supervisors = {
      type = types.attrsOf (submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
          };
        };
      });
    };
  };

  config = mkIf cfg.enable ({
    # Global system configuration
  } // (
    # Per-supervisor configuration, generated from the set of enabled
    # supervisors:
    mkMerge (
      builtins.mapAttrsToList
        genSupervisorConfig
        (
          lib.filterAttrs
            (_: supervisorAttrs: supervisorAttrs.enable)
            cfg.treadmill.supervisors
        )
    )
  ));
}
