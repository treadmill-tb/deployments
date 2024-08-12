{
  id = "524aa422-3ea7-47be-99d3-b78430449589";
  type = "nbd_netboot";

  nbd_netboot_host = {
    model = "Raspberry Pi 5 8GB";
    serial_no = "";
  };

  nbd_netboot_console = {
    udev_filters = [
      "ENV{ID_MODEL}==\"Debug_Probe__CMSIS-DAP_\""
      "ENV{ID_USB_SERIAL_SHORT}==\"E6633861A354302C\""
    ];
    baudrate = 115200;
  };

  board = {
    manufacturer = "Nordic Semiconductor";
    model = "nRF52840DK";
    hwrev = "";
    serial_no = "";
  };
}
