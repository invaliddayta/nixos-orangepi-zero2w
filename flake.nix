{
  description = "NixOS board support for the Orange Pi Zero 2W";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/61b7c44c4073";
  inputs.armbian-build = {
    url = "github:armbian/build/34e66c37211c70ef5cfad9c80dd76389720e19b7";
    flake = false;
  };
  inputs.uwe5622-source = {
    url = "github:armbian/uwe5622/b64c5d6c36015049bdc34aad5f7b307545bfa29c";
    flake = false;
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "aarch64-linux";
      overlay = import ./overlay.nix {
        armbianBuild = inputs.armbian-build;
        uwe5622Source = inputs.uwe5622-source;
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      };
      boardModules = [
        self.nixosModules.default
        { hardware.orangePiZero2W.enable = true; }
      ];
      minimal = nixpkgs.lib.nixosSystem {
        modules = boardModules ++ [ ./examples/minimal.nix ];
      };
      minimalSd = nixpkgs.lib.nixosSystem {
        modules = boardModules ++ [
          ./examples/minimal.nix
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
          (
            {
              config,
              lib,
              pkgs,
              ...
            }:
            {
              hardware.enableAllHardware = lib.mkForce false;
              sdImage.compressImage = false;
              sdImage.firmwareSize = 8;
              sdImage.populateFirmwareCommands = "";
              sdImage.populateRootCommands = ''
                mkdir -p ./files/boot
                ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
              '';
              sdImage.postBuildCommands = ''
                dd if=${pkgs.orangePiZero2W.uboot}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
              '';
            }
          )
        ];
      };
    in
    {
      overlays.default = overlay;
      nixosModules.default = import ./modules/default.nix overlay;
      formatter.${system} = pkgs.nixfmt-tree;

      nixosConfigurations.minimal = minimal;

      packages.${system} = {
        default = minimalSd.config.system.build.sdImage;
        sdImage = minimalSd.config.system.build.sdImage;
        kernel = pkgs.orangePiZero2W.kernel;
        devicetree = pkgs.orangePiZero2W.deviceTree;
        firmware = pkgs.orangePiZero2W.uwe5622Firmware;
        uboot = pkgs.orangePiZero2W.uboot;
      };
    };
}
