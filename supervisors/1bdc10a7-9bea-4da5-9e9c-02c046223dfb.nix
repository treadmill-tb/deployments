{
  type = "qemu";

  qemu_host = {
    # https://www.hellion.org.uk/cgi-bin/randmac.pl
    mac_addr = "9e:0a:c5:73:e6:25";

    usb_passthrough_devs = {
      "board" = {
        udev_filters = [
          "ENV{ID_MODEL}==\"J-Link\""
          "ENV{ID_SERIAL_SHORT}==\"000683931878\""
        ];
      };
    };
  };

  board = {
    manufacturer = "Nordic Semiconductor";
    model = "nRF52840DK";
    hwrev = "";
    serial_no = "";
  };
}
