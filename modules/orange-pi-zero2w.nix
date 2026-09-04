{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.orangePiZero2W;
  hardwareCheck = pkgs.writeShellApplication {
    name = "orange-pi-zero2w-hardware-check";
    runtimeInputs = with pkgs; [
      alsa-utils
      coreutils
      gnugrep
      iproute2
      iw
      libgpiod
      systemd
      usbutils
      util-linux
    ];
    text = builtins.readFile ../scripts/hardware-check.sh;
  };
in
{
  options.hardware.orangePiZero2W.enable = lib.mkEnableOption "Orange Pi Zero 2W board support";

  config = lib.mkIf cfg.enable {
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible = {
      enable = true;
      configurationLimit = 5;
    };
    boot.loader.timeout = 3;
    boot.kernelPackages = pkgs.linuxPackagesOrangePiZero2W;
    boot.kernelParams = [
      "console=tty1"
      "console=ttyS0,115200n8"
      "usbcore.autosuspend=-1"
    ];
    boot.initrd.availableKernelModules = [ "mmc_block" ];
    boot.initrd.includeDefaultModules = false;
    boot.kernelModules = [
      "hid_multitouch"
      "panfrost"
      "sun50i-cpufreq-nvmem"
    ];

    hardware.deviceTree = {
      enable = true;
      dtbSource = pkgs.orangePiZero2WDeviceTree;
      name = "allwinner/sun50i-h618-orangepi-zero2w.dtb";
    };
    hardware.firmware = [ pkgs.uwe5622Firmware ];
    hardware.graphics.enable = true;

    systemd.services.usb-gadget = {
      description = "USB ECM recovery network";
      wantedBy = [ "multi-user.target" ];
      after = [
        "local-fs.target"
        "systemd-modules-load.service"
      ];
      before = [ "sshd.service" ];
      path = with pkgs; [
        coreutils
        iproute2
        kmod
        util-linux
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "usb-gadget-start" ''
          set -eu

          gadget=/sys/kernel/config/usb_gadget/orangepizero2w

          modprobe libcomposite
          mountpoint -q /sys/kernel/config || mount -t configfs configfs /sys/kernel/config
          mkdir -p "$gadget"

          printf '0x1d6b' > "$gadget/idVendor"
          printf '0x0104' > "$gadget/idProduct"
          printf '0x0200' > "$gadget/bcdUSB"
          printf '0x0100' > "$gadget/bcdDevice"

          mkdir -p "$gadget/strings/0x409"
          printf 'orangepizero2w' > "$gadget/strings/0x409/serialnumber"
          printf 'NixOS' > "$gadget/strings/0x409/manufacturer"
          printf 'Orange Pi Zero 2W recovery network' > "$gadget/strings/0x409/product"

          mkdir -p "$gadget/functions/ecm.usb0"
          printf '02:00:00:00:07:01' > "$gadget/functions/ecm.usb0/host_addr"
          printf '02:00:00:00:07:02' > "$gadget/functions/ecm.usb0/dev_addr"

          mkdir -p "$gadget/configs/c.1/strings/0x409"
          printf 'ECM network' > "$gadget/configs/c.1/strings/0x409/configuration"
          printf '250' > "$gadget/configs/c.1/MaxPower"
          ln -s "$gadget/functions/ecm.usb0" "$gadget/configs/c.1/ecm.usb0"

          udc=
          for candidate in /sys/class/udc/*; do
            [ -e "$candidate" ] || continue
            udc="''${candidate##*/}"
            break
          done
          if [ -z "$udc" ]; then
            echo "No USB device controller found" >&2
            exit 1
          fi
          printf '%s' "$udc" > "$gadget/UDC"

          attempts=0
          until [ -e /sys/class/net/usb0 ]; do
            attempts=$((attempts + 1))
            if [ "$attempts" -ge 50 ]; then
              echo "USB ECM interface did not appear" >&2
              exit 1
            fi
            sleep 0.1
          done
          ip address replace 192.168.7.2/24 dev usb0
          ip link set usb0 up
        '';
        ExecStop = pkgs.writeShellScript "usb-gadget-stop" ''
          set -u

          gadget=/sys/kernel/config/usb_gadget/orangepizero2w
          [ -d "$gadget" ] || exit 0
          : > "$gadget/UDC"
          rm -f "$gadget/configs/c.1/ecm.usb0"
          rmdir "$gadget/configs/c.1/strings/0x409"
          rmdir "$gadget/configs/c.1"
          rmdir "$gadget/functions/ecm.usb0"
          rmdir "$gadget/strings/0x409"
          rmdir "$gadget"
        '';
      };
    };

    systemd.services.usb-host-rescan = {
      description = "Rescan USB1 host devices after PHY initialization";
      wantedBy = [ "multi-user.target" ];
      after = [ "usb-gadget.service" ];
      path = with pkgs; [ coreutils ];
      unitConfig.ConditionPathExists = "/sys/bus/platform/devices/5200000.usb";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "usb-host-rescan" ''
          set -eu

          if [ -L /sys/bus/platform/devices/5200000.usb/driver ]; then
            printf '5200000.usb' > /sys/bus/platform/drivers/ehci-platform/unbind
          fi
          if [ -L /sys/bus/platform/devices/5200400.usb/driver ]; then
            printf '5200400.usb' > /sys/bus/platform/drivers/ohci-platform/unbind
          fi

          sleep 1
          printf '5200400.usb' > /sys/bus/platform/drivers/ohci-platform/bind
          sleep 1
          printf '5200000.usb' > /sys/bus/platform/drivers/ehci-platform/bind

          for control in /sys/bus/platform/devices/5200*.usb/usb*/power/control; do
            [ -e "$control" ] || continue
            printf 'on' > "$control"
          done
        '';
      };
    };

    systemd.services.uwe5622-wifi = {
      description = "Initialize onboard AW859A/UWE5622 Wi-Fi";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      before = [ "NetworkManager.service" ];
      wants = [ "systemd-udev-settle.service" ];
      path = with pkgs; [
        coreutils
        kmod
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "uwe5622-wifi-start" ''
          set -eu

          mkdir -p /lib/firmware/uwe5622
          ln -sfn ${pkgs.uwe5622Firmware}/lib/firmware/uwe5622/wcnmodem.bin \
            /lib/firmware/uwe5622/wcnmodem.bin
          ln -sfn ${pkgs.uwe5622Firmware}/lib/firmware/wifi_2355b001_1ant.ini \
            /lib/firmware/wifi_2355b001_1ant.ini

          attempts=0
          sdio_device=
          for candidate in /sys/bus/mmc/devices/mmc1:*; do
            [ -e "$candidate" ] || continue
            sdio_device="$candidate"
            break
          done
          while [ -z "$sdio_device" ]; do
            attempts=$((attempts + 1))
            if [ "$attempts" -ge 100 ]; then
              echo "UWE5622 SDIO function did not appear" >&2
              exit 1
            fi
            sleep 0.1
            for candidate in /sys/bus/mmc/devices/mmc1:*; do
              [ -e "$candidate" ] || continue
              sdio_device="$candidate"
              break
            done
          done
          modprobe sprdwl_ng
        '';
      };
    };

    environment.systemPackages = [ hardwareCheck ];
  };
}
