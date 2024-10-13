{
  switches."pton-srv0-sw0" = let
    switchSSHCommand = pkgs: switchIP: command:
    "${pkgs.openssh}/bin/ssh ${pkgs.lib.concatStringsSep " " [
      "-F none"
      "-i /var/state/tml-switch-ssh-key"
      "-o StrictHostKeyChecking=no"
      "-o UserKnownHostsFile=/dev/null"
      "'tml-automation@${switchIP}'"
      "'configure; ${command}; commit'"
    ] }";
   in rec {
    trunk_supervisor_netdev = "enp3s0";

    management_ip = "172.17.193.254";

    start_script = switchPort: pkgs: pkgs.writeScript "switch-host-start.sh" ''
      #! ${pkgs.bash}/bin/bash
      echo "Enabling PoE interface ${switchPort}"
      (
        # Acquire an exclusive lock, we don't want two configure sessions to conflict
        ${pkgs.util-linux}/bin/flock -x 200
        echo "Acquired switch configuration lock"

        # Enable the PoE interface:
        ${switchSSHCommand pkgs management_ip "delete poe interface ${switchPort} disable"}
      ) 200>/var/lib/treadmill/tml-automation-switch-lock
      echo "Enabled PoE interface ${switchPort}"
    '';

    stop_script = switchPort: pkgs: pkgs.writeScript "switch-host-stop.sh" ''
      #! ${pkgs.bash}/bin/bash
      echo "Disabling PoE interface ${switchPort}"
      (
        # Acquire an exclusive lock, we don't want two configure sessions to conflict
        ${pkgs.util-linux}/bin/flock -x 200
        echo "Acquired switch configuration lock"

        # Disable the PoE interface:
        ${switchSSHCommand pkgs management_ip "set poe interface ${switchPort} disable"}
      ) 200>/var/lib/treadmill/tml-automation-switch-lock
      echo "Disabled PoE interface ${switchPort}"
    '';
  };

  supervisors = {
    "524aa422-3ea7-47be-99d3-b78430449589" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_switch_port = "ge-0/0/1";
      nbd_netboot_host_vlan = 1000;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.0";
        prefixlen = 30;
        supervisor_addr = "172.17.193.1";
        addr = "172.17.193.2";
        ssh_forward_host_port = 22002;
      };
    };

    "0679be07-6106-48aa-8057-b1d4f2e18a99" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_switch_port = "ge-0/0/2";
      nbd_netboot_host_vlan = 1001;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.4";
        prefixlen = 30;
        supervisor_addr = "172.17.193.5";
        addr = "172.17.193.6";
        ssh_forward_host_port = 22006;
      };
    };

    "8723bd6d-88d4-4605-94f1-331b8d54a202" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_switch_port = "ge-0/0/3";
      nbd_netboot_host_vlan = 1002;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.8";
        prefixlen = 30;
        supervisor_addr = "172.17.193.9";
        addr = "172.17.193.10";
        ssh_forward_host_port = 22010;
      };
    };

    "56f98833-da16-4ba0-9f38-2b02cfd01ddd" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_switch_port = "ge-0/0/4";
      nbd_netboot_host_vlan = 1003;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.12";
        prefixlen = 30;
        supervisor_addr = "172.17.193.13";
        addr = "172.17.193.14";
        ssh_forward_host_port = 22014;
      };
    };

    "64e5e94d-67e9-4276-9a0c-509a6789b372" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_switch_port = "ge-0/0/6";
      nbd_netboot_host_vlan = 1004;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.16";
        prefixlen = 30;
        supervisor_addr = "172.17.193.17";
        addr = "172.17.193.18";
        ssh_forward_host_port = 22018;
      };
    };

    "8ff22e8e-ead7-433a-a921-c7206face09d" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_switch_port = "ge-0/0/8";
      nbd_netboot_host_vlan = 1005;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.20";
        prefixlen = 30;
        supervisor_addr = "172.17.193.21";
        addr = "172.17.193.22";
        ssh_forward_host_port = 22022;
      };
    };

    "1bdc10a7-9bea-4da5-9e9c-02c046223dfb" = {
      qemu_host_ip4 = {
        network = "172.17.193.24";
        prefixlen = 30;
        supervisor_addr = "172.17.193.25";
        addr = "172.17.193.26";
        ssh_forward_host_port = 22026;
      };
    };

    "0af84b36-1d44-4e0e-9046-1f3fd8ec1cbf" = {
      qemu_host_ip4 = {
        network = "172.17.193.28";
        prefixlen = 30;
        supervisor_addr = "172.17.193.29";
        addr = "172.17.193.30";
        ssh_forward_host_port = 22030;
      };
    };

    "25b97cf7-cf3c-4955-8f33-a8ea938c4f5b" = {
      qemu_host_ip4 = {
        network = "172.17.193.32";
        prefixlen = 30;
        supervisor_addr = "172.17.193.33";
        addr = "172.17.193.34";
        ssh_forward_host_port = 22034;
      };
    };
  };
}
