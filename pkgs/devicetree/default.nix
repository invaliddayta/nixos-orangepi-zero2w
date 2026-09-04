{
  applyPatches,
  armbianBuild,
  deviceTree,
  linux_latest,
  runCommand,
}:

let
  source = applyPatches {
    name = "orangepi-zero2w-device-tree-source";
    src = linux_latest.src;
    patches = [
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.drm/0031-arm64-dts-allwinner-sun50i-h616-Add-SRAM-nodes.patch"
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.drm/0046-arm64-dts-allwinner-h616-Add-display-pipeline.patch"
      ../../patches/orangepi-zero2w-hdmi.patch
      ../../patches/orangepi-zero2w-wifi.patch
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.armbian/arm64-dts-sun50i-h618-orangepi-zero2w-zero3-cpu-dvfs.dtsi.patch"
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.armbian/arm64-dts-sun50i-h616-add-vpu-node.patch"
    ];
  };
  compiled = deviceTree.compileDTS {
    name = "sun50i-h618-orangepi-zero2w.dtb";
    dtsFile = "${source}/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero2w.dts";
    includePaths = [
      "${source}/arch/arm64/boot/dts"
      "${source}/arch/arm64/boot/dts/allwinner"
      "${source}/include"
    ];
  };
in
runCommand "orangepi-zero2w-device-tree-${linux_latest.version}"
  {
    passthru = { inherit source; };
  }
  ''
    install -Dm644 ${compiled} $out/allwinner/sun50i-h618-orangepi-zero2w.dtb
  ''
