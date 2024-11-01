{
  type = "nbd_netboot";

  nbd_netboot_host = {
    model = "Raspberry Pi 5 8GB";
    pxe_profile = "raspberrypi";
    serial_no = "0e921369";
    mac_addr = "d8:3a:dd:e4:e8:cc";
  };

  nbd_netboot_console = {
    udev_filters = [
      "ENV{ID_MODEL}==\"Debug_Probe__CMSIS-DAP_\""
      "ENV{ID_USB_SERIAL_SHORT}==\"E6633861A32C9A38\""
    ];
    baudrate = 115200;
  };

  board = {
    manufacturer = "Nordic Semiconductor";
    model = "nRF52840DK Cluster (4 Boards)";
    hwrev = "v3.0.2";
    serial_no = "";
  };
}
