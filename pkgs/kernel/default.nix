{
  armbianBuild,
  gnutar,
  kernelPatches ? [ ],
  lib,
  linux_latest,
  features ? { },
  randstructSeed ? "",
  runCommand,
  structuredExtraConfig ? { },
  uwe5622Source,
  xz,
}:

let
  linuxWithUwe5622 =
    runCommand "linux-${linux_latest.version}-with-uwe5622-source"
      {
        nativeBuildInputs = [
          gnutar
          xz
        ];
      }
      ''
        mkdir -p $out
        tar -xf ${linux_latest.src} --strip-components=1 -C $out
        cp -R --no-preserve=mode,ownership ${uwe5622Source} $out/drivers/net/wireless/uwe5622
        printf '%s\n' 'obj-$(CONFIG_SPARD_WLAN_SUPPORT) += uwe5622/' >> $out/drivers/net/wireless/Makefile
        printf '%s\n' 'source "drivers/net/wireless/uwe5622/Kconfig"' >> $out/drivers/net/wireless/Kconfig
      '';

  # Device-tree-only patches are intentionally excluded. They are built by
  # orangePiZero2WDeviceTree so DTS changes do not invalidate this kernel.
  h616DrmCodePatchNames = [
    "0025-dt-bindings-sram-Document-Allwinner-H616-VE-SRAM.patch"
    "0026-dt-bindings-sram-sunxi-sram-Add-H616-SRAM-regions.patch"
    "0027-soc-sunxi-sram-Const-ify-sunxi_sram_func-data-and-re.patch"
    "0028-soc-sunxi-sram-Allow-SRAM-to-be-claimed-multiple-tim.patch"
    "0029-soc-sunxi-sram-Support-claiming-multiple-regions-per.patch"
    "0030-soc-sunxi-sram-Add-H616-SRAM-regions.patch"
    "0032-clk-sunxi-ng-de2-Fix-Display-Engine-3.3-definitions.patch"
    "0033-drm-sun4i-Add-support-for-DE33-CSC.patch"
    "0034-drm-sun4i-vi_layer-Limit-formats-for-DE33.patch"
    "0035-clk-sunxi-ng-de2-Export-register-regmap-for-DE33.patch"
    "0036-dt-bindings-display-allwinner-Add-DE33-planes.patch"
    "0037-drm-sun4i-Add-planes-driver.patch"
    "0038-dt-bindings-display-allwinner-Split-H616-DE33-layer-.patch"
    "0039-drm-sun4i-switch-DE33-to-new-bindings.patch"
    "0040-dt-bindings-display-Add-H616-display-engine-compatib.patch"
    "0041-drm-sun4i-Add-support-for-H616-TCON-TOP.patch"
    "0042-drm-sun4i-tcon-Add-support-for-R40-LCD.patch"
    "0043-drm-sun4i-Add-H616-TCON-TV-support.patch"
    "0044-drm-sun4i-Add-support-for-H616-HDMI-PHY.patch"
    "0045-drm-sun4i-Add-compatible-for-H616-display-engine.patch"
  ];
  h616DrmCodePatches = map (name: {
    name = "armbian-${name}";
    patch = "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.drm/${name}";
  }) h616DrmCodePatchNames;
in
linux_latest.override {
  autoModules = false;
  buildDTBs = false;
  inherit features randstructSeed;
  ignoreConfigErrors = true;
  argsOverride.src = linuxWithUwe5622;

  kernelPatches =
    h616DrmCodePatches
    ++ [
      {
        name = "mmc-pwrseq-simple-reset-gpio-fallback";
        patch = ../../patches/mmc-pwrseq-simple-reset-gpio-fallback.patch;
      }
      {
        name = "uwe5622-null-safe-loopcheck";
        patch = ../../patches/uwe5622-null-safe-loopcheck.patch;
      }
      {
        name = "cedrus-h616-variant";
        patch = "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.armbian/drv-staging-media-sunxi-cedrus-add-H616-variant.patch";
      }
      {
        name = "cedrus-use-h616-variant";
        patch = ../../patches/cedrus-use-h616-variant.patch;
      }
    ]
    ++ kernelPatches;

  structuredExtraConfig =
    (with lib.kernel; {
      ATH9K_HTC = module;
      DRM_SUN4I = yes;
      DRM_SUN8I_DW_HDMI = yes;
      DRM_SUN8I_MIXER = yes;
      IP6_NF_MATCH_RPFILTER = module;
      IP_NF_MATCH_RPFILTER = module;
      MT7601U = module;
      MT76x0U = module;
      MT76x2U = module;
      NETFILTER_XT_MATCH_PKTTYPE = module;
      NF_TABLES = module;
      NF_TABLES_INET = yes;
      NF_TABLES_IPV4 = yes;
      NF_TABLES_IPV6 = yes;
      NFT_COMPAT = module;
      NFT_CT = module;
      NFT_LOG = module;
      NFT_REJECT = module;
      NFT_REJECT_INET = module;
      NFT_REJECT_IPV4 = module;
      NFT_REJECT_IPV6 = module;
      RT2X00 = module;
      RT2800USB = module;
      RTL8XXXU = module;
      RTW88_8723DU = module;
      RTW88_8812AU = module;
      RTW88_8814AU = module;
      RTW88_8821AU = module;
      RTW88_8821CU = module;
      RTW88_8822BU = module;
      RTW88_8822CU = module;
      SND_SUN4I_CODEC = module;
      SPARD_WLAN_SUPPORT = yes;
      SUN50I_H6_PRCM_PPU = yes;
      TTY_OVERY_SDIO = module;
      UNISOC_WIFI_PS = yes;
      VIDEO_SUNXI = yes;
      VIDEO_SUNXI_CEDRUS = module;
      WLAN_UWE5622 = module;
      WLAN_VENDOR_RALINK = yes;
    })
    // structuredExtraConfig;
}
