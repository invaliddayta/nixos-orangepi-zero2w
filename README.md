# NixOS board support for Orange Pi Zero 2W

Reusable NixOS hardware support for the Allwinner H618-based Orange Pi Zero 2W.

This flake provides:

- A NixOS module for board hardware
- A Linux 7.1 kernel package with H616 display, Cedrus, MMC, and UWE5622 changes
- An independently compiled device-tree package
- UWE5622 Wi-Fi firmware
- U-Boot and extlinux integration
- A minimal SD-card image for smoke testing

The repository is hardware enablement only. Application-specific users, services, and UI policy belong in a downstream configuration.

## Hardware status

| Subsystem | Status |
| --- | --- |
| U-Boot, extlinux, microSD, UART0 | Working |
| CPU frequency scaling and thermal zones | Working |
| Mini-HDMI video and Mali-G31/Panfrost | Working |
| USB0 ECM recovery network and USB1 host | Working |
| AW859A/UWE5622 Wi-Fi | Working |
| ALSA analog codec | Driver-tested; physical output untested |
| Cedrus MPEG-2, H.264, H.265, and VP8 decode | Working through GStreamer |
| Touch controller | Detected; interactive mapping untested |
| Header GPIO, I2C, and SPI | Present; electrical operation requires a fixture/configuration |
| Bluetooth | Unsupported |
| HDMI audio | Unsupported |
| Hardware video encoding | Unsupported |
| Expansion-board Ethernet and USB | Unsupported |

[`HARDWARE.md`](HARDWARE.md) is the authoritative support matrix and records the validation boundaries.

## Use from a flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/61b7c44c4073";
    orangepi-zero2w.url = "github:OWNER/orangepi-zero2w-nixos";
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

The flake pins the nixpkgs revision used for hardware validation. Following a newer downstream nixpkgs may work, but that combination is not the tested baseline.

## Build

```sh
nix build .#sdImage
nix build .#kernel
nix build .#devicetree
nix build .#firmware
nix build .#uboot
```

The default package is the SD image. It uses `examples/minimal.nix`: local user `nixos` has initial password `nixos`, and SSH is disabled. Treat it as a boot and hardware smoke-test image, not as an appliance image.

Check the target device with `lsblk` before writing:

```sh
sudo dd if=result/sd-image/*.img of=/dev/disk/by-id/CHANGE_ME bs=16M conv=fsync status=progress
```

## USB recovery network

The module configures USB0 as an ECM Ethernet gadget:

- Board: `192.168.7.2/24`
- Suggested host address: `192.168.7.1/24`
- USB0 is the device-capable Type-C port
- USB1 is the host-only Type-C port

Use a USB-A-to-C data cable if the host does not enumerate the gadget through a direct C-to-C cable. The minimal image brings up the network device but does not enable SSH.

## Verify on the board

```sh
sudo orange-pi-zero2w-hardware-check
```

The command reports CPU frequency scaling, DRM, GPU, USB, Wi-Fi, ALSA, storage, GPIO, thermal, and failed systemd units.

## Repository layout

- `modules/` — reusable NixOS module
- `pkgs/kernel/` — kernel source composition, patches, and configuration
- `pkgs/devicetree/` — independently compiled board DTB
- `pkgs/uwe5622-firmware/` — pinned UWE5622 firmware files
- `patches/` — local kernel and device-tree patches
- `examples/minimal.nix` — minimal image configuration
- `scripts/hardware-check.sh` — on-device verification report

Device-tree-only changes are built in `pkgs/devicetree` and do not invalidate the kernel derivation.

## Upstream sources

The kernel package uses nixpkgs' pinned Linux 7.1 source, selected Armbian sunxi 7.1 patches, and Armbian's UWE5622 driver. UWE5622 firmware files are fetched by hash from Armbian's firmware repository.

The Nix code and documentation in this repository are MIT licensed. Upstream kernel code, patches, driver source, and firmware retain their original licenses.
