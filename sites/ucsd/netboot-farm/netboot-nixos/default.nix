  let
    # We pin a specific Nixpkgs revision here, to make the built image
    # independent of the build host's Nixpkgs revision. Don't forget to
    # update this periodically as well!

    # NixOS 24.05 of 2026-06-12
    nixpkgsRev = "47b604b07d1e8146d5398b42d3306fdebd343986";

    # nixpkgs = builtins.fetchTarball {
    #   url = "https://github.com/NixOS/nixpkgs/";
    #   ref = "nixos-24.05";
    #   rev = "47b604b07d1e8146d5398b42d3306fdebd343986";
    # };

    nixpkgs = builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${nixpkgsRev}.tar.gz";
      sha256 = "sha256:0g0nl5dprv52zq33wphjydbf3xy0kajp0yix7xg2m0qgp83pp046";
    };


    pkgs = import nixpkgs {};

    targetSystem = import "${nixpkgs}/nixos" {
      # Note that `config.nix` contains a function, which takes an
      # attribute set (the inputs) and returns an attribute set (the
      # configuration). This is the type expected to be passed into the
      # `configuration` paramter of the $nixpkgs/nixos/default.nix
      # expression. In fact, `nix-rebuild` works quite similar to what
      # we're doing here!
      configuration = import ./config.nix;
    };

    targetInitrd = tsys: let
      rootPaths =
        tsys.config.netboot.storeContents;

      nixPathRegistration =
        "${pkgs.closureInfo { inherit rootPaths; }}/registration";
    in
      pkgs.makeInitrdNG {
        inherit (tsys.config.boot.initrd) compressor;
        prepend = [ "${tsys.config.system.build.initialRamdisk}/initrd" ];

        # When Nix store is mounted via 9pfs or NFS, we can avoid including a
        # SquashFS in the initial ramdisk, occupying less RAM on the target:
        #
        contents = [{
          object = nixPathRegistration;
          symlink = "/nix-path-registration";
        }];

        # When the Nix store should be included in the ramdisk as a SquashFS:
        #
        # contents = [{
        #   object =
        #     pkgs.callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
        #       storeContents = tsys.config.netboot.storeContents;
        #     };
        #   symlink = "/nix-store.squashfs";
        # }];
      };

    qemuBaseCommand = pkgs.lib.concatStringsSep " " ([
      "${pkgs.qemu}/bin/qemu-kvm"
      "-boot n"
      "-m" "2G"
      "-smp" "4"
      "-netdev" "user,id=n0,hostfwd=tcp::5826-:5826,tftp=./,bootfile=netboot.ipxe"
      "-device" "e1000,netdev=n0,mac=02:00:00:00:00:01"
      "-device" "virtio-9p-pci,id=nixstore9p,fsdev=nixstorefs,mount_tag=nixstore"
      "-fsdev" "local,id=nixstorefs,path=/nix/store,security_model=none,writeout=immediate"
    ]);

  in
    # As stated above, the kernel and initial ramdisk are served
    # separately via TFTP. Hence we build a top-level derivation which
    # contains symlinks to the kernel, initial ramdisk and a special
    # IPXE script which instructs the target host on how to load both
    # these files.
    (pkgs.linkFarm "nixos-netboot" [ {
      name = "initrd";
      path = "${targetInitrd targetSystem}/initrd";
    } {
      name = "bzImage";
      path = "${targetSystem.config.system.build.kernel}/bzImage";
    } {
      name = "netboot.ipxe";
      path = "${targetSystem.config.system.build.netbootIpxeScript}/netboot.ipxe";
    } {
      name = "run";
      path = pkgs.writeScript "qemucmd" ''
        #!${pkgs.bash}/bin/bash
        exec ${qemuBaseCommand} -nographic
      '';
    }
  ])
