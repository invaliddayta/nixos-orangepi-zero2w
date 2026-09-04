# nixos-orangepi-zero2w

NixOS board support for the Orange Pi Zero 2W, based on the Allwinner H618.

The flake provides a reusable NixOS module, a patched Linux 7.1 kernel, an independently compiled device tree, UWE5622 firmware, U-Boot/extlinux integration, and a minimal SD-card image.

This repository contains board support only. Applications and machine-specific policy belong downstream.

## Status

Tested on the 1 GiB Orange Pi Zero 2W without the expansion board. Only the Zero 2W is supported; the Zero 2 and Zero 3 require separate board support. Other RAM capacities are untested.

| Area | Status |
| --- | --- |
| Boot, microSD, UART, CPU frequency scaling, thermal | Working |
| Mini-HDMI video, Mali-G31/Panfrost | Working |
| USB0 recovery gadget, USB1 host | Working |
| AW859A/UWE5622 Wi-Fi | Working |
| Cedrus MPEG-2, H.264, H.265, VP8 decode | Working |
| Analog ALSA codec, touch controller, GPIO/I2C/SPI headers | Partially validated |
| Bluetooth, HDMI audio, hardware video encode | Unsupported |
| Expansion-board Ethernet and USB | Unsupported |

See [`HARDWARE.md`](HARDWARE.md) for the full support matrix and validation boundaries.

## Usage

Add the flake as an input:

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

The pinned nixpkgs revision is the tested baseline. Other revisions may require changes.

The USB recovery network is enabled by default. To disable it:

```nix
hardware.orangePiZero2W.recoveryNetwork.enable = false;
```

The overlay exposes its packages under `pkgs.orangePiZero2W`:

- `kernel`
- `kernelPackages`
- `deviceTree`
- `uwe5622Firmware`
- `uboot`

## Build

Builds require an `aarch64-linux` host or a configured ARM64 remote builder.

```sh
nix build .#sdImage
nix build .#kernel
nix build .#devicetree
nix build .#firmware
nix build .#uboot
```

`default` and `sdImage` build `examples/minimal.nix`. The image creates local user `nixos` with initial password `nixos`; SSH is disabled. It is intended for boot and hardware validation, not as a ready-made appliance.

Check the target with `lsblk` before writing an image:

```sh
sudo dd if=result/sd-image/*.img of=/dev/disk/by-id/CHANGE_ME bs=16M conv=fsync status=progress
```

## USB recovery network

USB0 is configured as an ECM Ethernet gadget:

- Board address: `192.168.7.2/24`
- Suggested host address: `192.168.7.1/24`
- USB0 is the device-capable Type-C port
- USB1 is the host-only Type-C port

Use a USB-A-to-C data cable if a direct C-to-C cable does not enumerate the gadget. Enabling SSH and allowing it on `usb0` remains the responsibility of the downstream NixOS configuration.

## Hardware report

The module installs an on-device report:

```sh
sudo orange-pi-zero2w-hardware-check
```

It checks CPU frequency scaling, DRM, GPU, USB, Wi-Fi, ALSA, storage, GPIO, thermal zones, and failed systemd units.

## Development

```sh
nix fmt
nix flake check --no-build
```

Repository layout:

- `modules/` — NixOS module
- `pkgs/kernel/` — kernel source composition, patches, and configuration
- `pkgs/devicetree/` — final board DTB
- `pkgs/uwe5622-firmware/` — pinned UWE5622 firmware
- `patches/` — local kernel and device-tree patches
- `examples/minimal.nix` — minimal boot image
- `scripts/hardware-check.sh` — hardware report source

Device-tree patches are applied by `pkgs/devicetree`; changing them does not rebuild the kernel.

## Upstream sources and license

The kernel package uses nixpkgs' Linux 7.1 source, selected Armbian sunxi 7.1 patches, and Armbian's UWE5622 driver. UWE5622 firmware is fetched by hash from Armbian's firmware repository.

Repository Nix code, documentation, and scripts are available under the MIT license. Kernel and device-tree patches retain the licenses of the code they modify. UWE5622 driver and firmware files retain their upstream licenses.
