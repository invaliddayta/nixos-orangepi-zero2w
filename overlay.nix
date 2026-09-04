{ armbianBuild, uwe5622Source }:

final: prev: {
  ubootOrangePiZero2W = prev.ubootOrangePiZero3.override {
    defconfig = "orangepi_zero2w_defconfig";
  };

  orangePiZero2WKernel = final.callPackage ./pkgs/kernel {
    inherit armbianBuild uwe5622Source;
    features = { };
    kernelPatches = [ ];
    randstructSeed = "";
    structuredExtraConfig = { };
  };
  linuxPackagesOrangePiZero2W = final.linuxPackagesFor final.orangePiZero2WKernel;

  orangePiZero2WDeviceTree = final.callPackage ./pkgs/devicetree {
    inherit armbianBuild;
  };

  uwe5622Firmware = final.callPackage ./pkgs/uwe5622-firmware { };
}
