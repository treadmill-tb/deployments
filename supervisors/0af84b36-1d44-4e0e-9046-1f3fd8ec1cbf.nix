{
  type = "qemu";

  qemu_host = {
    # https://www.hellion.org.uk/cgi-bin/randmac.pl
    mac_addr = "f6:fb:f5:dd:1e:1b";

    usb_passthrough_devs = {
      "board" = {
        udev_filters = [
          "ENV{ID_MODEL}==\"J-Link\""
          "ENV{ID_SERIAL_SHORT}==\"000683188086\""
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
