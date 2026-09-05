# nixos-orangepi-zero2w

NixOS support for the Orange Pi Zero 2W (Allwinner H618).

Included:

- Linux 7.1 with H616 display, Cedrus, MMC, and UWE5622 changes
- A board DTB built separately from the kernel
- UWE5622 Wi-Fi firmware
- U-Boot and extlinux configuration
- Optional USB0 recovery networking
- A minimal SD-card image

## Hardware status

Tested on the 1 GiB model without the expansion board. Other RAM sizes are untested. The Zero 2 and Zero 3 are different boards.

- **Working:** boot, microSD, UART, CPU frequency scaling, thermal sensors, HDMI video, Panfrost, onboard Wi-Fi, USB0 gadget, USB1 host, and Cedrus MPEG-2/H.264/H.265/VP8 decoding
- **Partly tested:** analog ALSA output, touch input, GPIO, header I2C/SPI, SPI NOR, CEC, and RTC
- **Not supported:** Bluetooth, HDMI audio, hardware video encoding, and expansion-board Ethernet/USB

Details and test limits are in [`HARDWARE.md`](HARDWARE.md).

## Use the module

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/61b7c44c4073";
    orangepi-zero2w.url = "github:invaliddayta/nixos-orangepi-zero2w";
    orangepi-zero2w.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, orangepi-zero2w, ... }: {
    nixosConfigurations.orangepizero2w = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        orangepi-zero2w.nixosModules.default
        {
          hardware.orangePiZero2W.enable = true;
        }
      ];
    };
  };
}
```

The pinned nixpkgs revision is the tested configuration. Newer revisions may require patch updates.

The USB recovery gadget is enabled by default. To turn it off:

```nix
hardware.orangePiZero2W.recoveryNetwork.enable = false;
```

Overlay packages are namespaced under `pkgs.orangePiZero2W`:

```nix
pkgs.orangePiZero2W.kernel
pkgs.orangePiZero2W.kernelPackages
pkgs.orangePiZero2W.deviceTree
pkgs.orangePiZero2W.uwe5622Firmware
pkgs.orangePiZero2W.uboot
```

## Build

Use an `aarch64-linux` machine or an ARM64 remote builder.

```sh
nix build .#sdImage
nix build .#kernel
nix build .#devicetree
nix build .#firmware
nix build .#uboot
```

The default package is the SD image. It uses `examples/minimal.nix`, creates local user `nixos` with password `nixos`, leaves SSH disabled, and installs no graphical session or application.

Check the target with `lsblk` first:

```sh
sudo dd if=result/sd-image/*.img of=/dev/disk/by-id/CHANGE_ME bs=16M conv=fsync status=progress
```

## USB recovery

USB0 is configured as an ECM Ethernet device:

- Board: `192.168.7.2/24`
- Host: `192.168.7.1/24`
- USB0 is the device-capable port
- USB1 is host-only

If a C-to-C cable does not enumerate the gadget, use a USB-A-to-C data cable. SSH is not enabled by the example image.

## Hardware check

On the board:

```sh
sudo orange-pi-zero2w-hardware-check
```

The report covers CPU frequency scaling, DRM, GPU, USB, Wi-Fi, ALSA, storage, GPIO, thermal zones, and failed systemd units.

## Development

```sh
nix fmt
nix flake check --all-systems --max-jobs 1 --cores 2
```

Checks build the DTB, firmware, U-Boot, and hardware report, validate the generated
kernel configuration, and exercise USB gadget failure/cleanup/retry paths using a
mock filesystem. They do not replace testing on the board. CI runs these checks
on ARM64 for pull requests, main, and weekly scheduled runs. Full kernel and
SD-image builds run only for version tags and manual workflow runs.

Device-tree patches are built by `pkgs/devicetree`, so changing them does not rebuild the kernel.

## Sources and license

The kernel starts from nixpkgs' `linux_7_1` package and applies selected Armbian sunxi 7.1 patches. The UWE5622 driver comes from Armbian's `uwe5622` repository. Its firmware files are fetched by hash from Armbian's firmware repository.

The repository's own Nix code, shell code, and documentation are MIT licensed. Patches and fetched upstream code or firmware keep their original licenses.
