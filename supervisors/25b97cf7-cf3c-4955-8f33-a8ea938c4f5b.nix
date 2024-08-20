{
  type = "qemu";

  qemu_host = {
    # https://www.hellion.org.uk/cgi-bin/randmac.pl
    mac_addr = "1e:f0:64:c8:a6:0e";

    usb_passthrough_devs = {
      "board" = {
        udev_filters = [
          "ENV{ID_MODEL}==\"J-Link\""
          "ENV{ID_SERIAL_SHORT}==\"000681946098\""
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
