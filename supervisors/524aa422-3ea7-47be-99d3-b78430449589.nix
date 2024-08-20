{
  id = "524aa422-3ea7-47be-99d3-b78430449589";
  type = "nbd_netboot_static";

  nbd_netboot_host = {
    model = "Raspberry Pi 5 8GB";
    pxe_profile = "raspberrypi";
    serial_no = "";
    mac_addr = "2c:cf:67:09:60:6c";
  };

  nbd_netboot_static = {
    # Image e6d58309b80f4f21e40deed9ff736baee053f32f824d06319b06754c13914d3a
    root_base_image = "/var/lib/treadmill/store/blobs/58/7f/b3/587fb3c958b30607cae8cbc12a4311ecf2abeeb51344af2ce0f15bb86eea6f6a";
    root_dev_size = "64G";
    boot_archive = "/var/lib/treadmill/store/blobs/b1/d8/40/b1d840cd148760a8d10c216736e0df737341ea4044649365ab4516a2b5e89e9b";
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
