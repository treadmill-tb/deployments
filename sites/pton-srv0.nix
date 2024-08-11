{
  switches."pton-srv0-sw0" = {
    trunk_supervisor_netdev = "enp3s0";
  };

  supervisors = {
    "524aa422-3ea7-47be-99d3-b78430449589" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_port = "ge-0/0/1";
      nbd_netboot_host_vlan = 1000;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.0";
        prefixlen = 30;
        supervisor_addr = "172.17.193.1";
        addr = "172.17.193.2";
      };
    };

    "0679be07-6106-48aa-8057-b1d4f2e18a99" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_port = "ge-0/0/2";
      nbd_netboot_host_vlan = 1001;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.4";
        prefixlen = 30;
        supervisor_addr = "172.17.193.5";
        addr = "172.17.193.6";
      };
    };

    "8723bd6d-88d4-4605-94f1-331b8d54a202" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_port = "ge-0/0/3";
      nbd_netboot_host_vlan = 1002;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.8";
        prefixlen = 30;
        supervisor_addr = "172.17.193.9";
        addr = "172.17.193.10";
      };
    };

    "56f98833-da16-4ba0-9f38-2b02cfd01ddd" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_port = "ge-0/0/4";
      nbd_netboot_host_vlan = 1003;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.12";
        prefixlen = 30;
        supervisor_addr = "172.17.193.13";
        addr = "172.17.193.14";
      };
    };

    "64e5e94d-67e9-4276-9a0c-509a6789b372" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_port = "ge-0/0/5";
      nbd_netboot_host_vlan = 1004;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.16";
        prefixlen = 30;
        supervisor_addr = "172.17.193.17";
        addr = "172.17.193.18";
      };
    };

    "8ff22e8e-ead7-433a-a921-c7206face09d" = {
      nbd_netboot_host_switch = "pton-srv0-sw0";
      nbd_netboot_host_port = "ge-0/0/6";
      nbd_netboot_host_vlan = 1005;
      nbd_netboot_host_ip4 = {
        network = "172.17.193.20";
        prefixlen = 30;
        supervisor_addr = "172.17.193.21";
        addr = "172.17.193.22";
      };
    };

    "1bdc10a7-9bea-4da5-9e9c-02c046223dfb" = {
      qemu_host_ip4 = {
        network = "172.17.193.24";
        prefixlen = 30;
        supervisor_addr = "172.17.193.25";
        addr = "172.17.193.26";
      };
    };
  };
}