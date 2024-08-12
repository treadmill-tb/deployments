{
  type = "nbd_netboot";

  nbd_netboot_host = {
    model = "Raspberry Pi 5 8GB";
    serial_no = "";
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
