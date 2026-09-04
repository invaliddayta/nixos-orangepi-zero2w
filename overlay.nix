{ armbianBuild, uwe5622Source }:

final: prev:

let
  kernel = final.callPackage ./pkgs/kernel {
    inherit armbianBuild uwe5622Source;
    features = { };
    kernelPatches = [ ];
    randstructSeed = "";
    structuredExtraConfig = { };
  };
in
{
  orangePiZero2W = {
    inherit kernel;

    kernelPackages = final.linuxPackagesFor kernel;

    deviceTree = final.callPackage ./pkgs/devicetree {
      inherit armbianBuild;
    };

    uwe5622Firmware = final.callPackage ./pkgs/uwe5622-firmware { };

    uboot = prev.ubootOrangePiZero3.override {
      defconfig = "orangepi_zero2w_defconfig";
    };
  };
}
