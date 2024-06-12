{ config, pkgs, lib, modulesPath, ... }: {

  imports = [
    # This imports the `netboot` module, which defines some new
    # outputs, including an initramfs with all required Nix store
    # derivations packed into an embedded SquashFS.
    #
    # Using `modulesPath` here instead of `<nixos/...>` ensures that
    # we're using the modules of our desired Nixpkgs revision, instead
    # of the system-wide one on the build machine.
    (modulesPath + "/installer/netboot/netboot.nix")

    # Avoid bloating our image by excluding not strictly necessary
    # derivations, such as manpages:
    (modulesPath + "/profiles/minimal.nix")
  ];

  # Some network configuration, this is not actually required for the
  # boot process itself.
  networking.hostName = "test-host";
  networking.useDHCP = true;

  # This avoids us having to embed a password hash or SSH key in the
  # configuration. Probably want to remove this on production systems.
  services.getty.autologinUser = lib.mkForce "root";

  # Let's add some useful utilities:
  environment.systemPackages = with pkgs; [
    vim tmux htop nload
  ];

  # Always be sure to set `system.stateVersion`, if you don't want
  # Nixpkgs to yell at you!
  system.stateVersion = "24.05";

  boot.kernelParams = [ "console=ttyS0" ];

  boot.initrd.kernelModules = [
    "9p" "virtio" "9pnet_virtio" "virtio_net" "virtio_rng" "virtio_pci"
  ];

  boot.initrd.postMountCommands = ''
    echo "Copying /nix-path-registration to /mnt-root/nix/store/"
    cat /nix-path-registration > /mnt-root/nix/store/nix-path-registration
  '';

  fileSystems."/nix/.ro-store" = lib.mkForce {
    device = "nixstore";
    fsType = "9p";
    options = [ "trans=virtio,msize=12582912" ];
    neededForBoot = true;
  };
}
