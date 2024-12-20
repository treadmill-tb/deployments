{
  id = "56f98833-da16-4ba0-9f38-2b02cfd01ddd";
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
      "ENV{ID_USB_SERIAL_SHORT}==\"E6633861A3404A38\""
    ];
    baudrate = 115200;
  };

  board = {
    manufacturer = "STMicroelectronics";
    model = "NUCLEO-F429ZI";
    hwrev = "";
    serial_no = "";
  };
}
