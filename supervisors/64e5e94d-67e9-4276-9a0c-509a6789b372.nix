{
  type = "nbd_netboot";

  nbd_netboot_host = {
    model = "Raspberry Pi 5 8GB";
    pxe_profile = "raspberrypi";
    serial_no = "";
    mac_addr = "2c:cf:67:09:7a:1b";
  };

  nbd_netboot_console = {
    udev_filters = [
      "ENV{ID_MODEL}==\"Debug_Probe__CMSIS-DAP_\""
      "ENV{ID_USB_SERIAL_SHORT}==\"E6633861A386AC2C\""
    ];
    baudrate = 115200;
  };

  board = {
    manufacturer = "Digilent";
    model = "Arty-A7 35T";
    hwrev = "";
    serial_no = "";
  };
}
