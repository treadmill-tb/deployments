{
  id = "0679be07-6106-48aa-8057-b1d4f2e18a99";
  type = "nbd_netboot";

  nbd_netboot_host = {
    model = "Raspberry Pi 5 8GB";
    pxe_profile = "raspberrypi";
    serial_no = "";
    mac_addr = "2c:cf:67:09:78:f3";
  };

  nbd_netboot_console = {
    udev_filters = [
      "ENV{ID_MODEL}==\"Debug_Probe__CMSIS-DAP_\""
      "ENV{ID_USB_SERIAL_SHORT}==\"E6633861A3918138\""
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