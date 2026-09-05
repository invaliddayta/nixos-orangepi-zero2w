{
  lib,
  runCommand,
  kernel,
}:

runCommand "orangepi-zero2w-kernel-config-check" { } ''
  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: ''
      if ! grep -Fx 'CONFIG_${name}=${value.tristate}' ${kernel.configfile}; then
        echo 'Missing requested kernel configuration: CONFIG_${name}=${value.tristate}' >&2
        exit 1
      fi
    '') kernel.structuredExtraConfig
  )}

  for option in MMC_SUNXI PWRSEQ_SIMPLE EXT4_FS USB_CONFIGFS USB_CONFIGFS_ECM USB_MUSB_SUNXI DRM_PANFROST CPUFREQ_DT; do
    if ! grep -Ex "CONFIG_$option=[ym]" ${kernel.configfile}; then
      echo "Missing essential kernel feature: CONFIG_$option" >&2
      exit 1
    fi
  done
  touch "$out"
''
