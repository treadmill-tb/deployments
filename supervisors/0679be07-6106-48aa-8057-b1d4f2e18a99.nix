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

  pin_mappings = {
    "GPIO_20" = {
      target_pin = "P0.13";
      target_pin_function = "LED1";
      target_pin_mode = "output";
      target_pin_active = "low";
    };
    "GPIO_19" = {
      target_pin = "P0.14";
      target_pin_function = "LED2";
      target_pin_mode = "output";
      target_pin_active = "low";
    };
    "GPIO_21" = {
      target_pin = "P0.11";
      target_pin_function = "BUTTON1";
      target_pin_mode = "input";
      target_pin_active = "low";
    };
    "GPIO_26" = {
      target_pin = "P0.12";
      target_pin_function = "BUTTON2";
      target_pin_mode = "input";
      target_pin_active = "low";
    };
  };
}
