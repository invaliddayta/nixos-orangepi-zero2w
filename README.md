# NixOS on Orange Pi Zero 2W

**Small board. Full NixOS.** A reproducible NixOS flake for the Orange Pi Zero 2W, with the board-specific kernel, firmware, and bootloader already wired up. Build an SD image, flash it, and boot, or bring the hardware module into your own configuration.

<p align="center">
  <a href="https://www.armbian.com/orange-pi-zero-2w/">
    <img src="https://www.armbian.com/api/v1/images/boards/480/orangepizero2w.png" width="480" alt="Orange Pi Zero 2W board with its Allwinner H618 chip, two USB-C ports, micro-HDMI port, and microSD slot" />
  </a>
  <br />
  <strong>Allwinner H618 &middot; Quad-core Cortex-A53 &middot; Tested with 1 GiB RAM</strong>
  <br />
  <sub>Board photo via <a href="https://www.armbian.com/orange-pi-zero-2w/">Armbian</a>.</sub>
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> &middot;
  <a href="#hardware-status">Hardware status</a> &middot;
  <a href="#use-the-module">Use the module</a> &middot;
  <a href="#usb-recovery">USB recovery</a>
</p>

## What you get

- **A bootable NixOS image:** U-Boot, extlinux, a minimal system, and zram enabled.
- **The board support included:** Linux 7.1 with selected Armbian patches, a board-specific device tree, and UWE5622 Wi-Fi firmware.
- **More than a serial prompt:** working HDMI video, Panfrost GPU support, and Cedrus hardware video decoding. Bring your own desktop or application.
- **A recovery path over USB:** optional USB0 Ethernet gadget networking, enabled by default.

> Tested on the **1 GiB Orange Pi Zero 2W**, without the expansion board. Other RAM sizes are untested. The Orange Pi Zero 2 and Zero 3 are different boards.

## Quick start

### 1. Build the image

Use an `aarch64-linux` machine or a configured ARM64 remote builder. The first build includes a patched kernel, so a faster ARM64 machine is preferable to building on the board itself.

```sh
git clone https://github.com/invaliddayta/nixos-orangepi-zero2w.git
cd nixos-orangepi-zero2w
nix build .#sdImage
```

### 2. Flash a microSD card

**This erases the target disk.** Use `lsblk` to identify the card, unmount any mounted partitions, and replace `CHANGE_ME` with its whole-disk identifier, not a partition.

```sh
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS
sudo dd if=result/sd-image/*.img of=/dev/disk/by-id/CHANGE_ME bs=16M conv=fsync status=progress
```

### 3. Boot and log in

Insert the card, connect a local console, and power on. Use a micro-HDMI display and USB1 keyboard, or the UART0 serial console at **115200 baud** with a 3.3 V USB-to-TTL adapter.

| Local login | Value |
| --- | --- |
| Username | `nixos` |
| Initial password | `nixos` |

Change the password with `passwd` after logging in. The image uses [`examples/minimal.nix`](examples/minimal.nix): **SSH is disabled**, and no graphical session or application is installed. USB recovery provides a network link, not an automatic remote login.

## Hardware status

| Status | Features |
| --- | --- |
| **Working** | Boot, microSD, UART, CPU frequency scaling, thermal sensors, HDMI video, Panfrost, onboard Wi-Fi, USB0 gadget, USB1 host, and Cedrus MPEG-2/H.264/H.265/VP8 decoding |
| **Partly tested** | Analog ALSA output, touch input, GPIO, header I2C/SPI, SPI NOR, CEC, and RTC |
| **Not supported** | Bluetooth, HDMI audio, hardware video encoding, and expansion-board Ethernet/USB |

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

## Build individual components

The default package is the SD image (`nix build` is equivalent to `nix build .#sdImage`). You can also build its components separately on an ARM64 builder:

```sh
nix build .#kernel
nix build .#devicetree
nix build .#firmware
nix build .#uboot
```

Each command updates the `result` symlink. Before flashing, run `nix build .#sdImage` again so `result` points to the image rather than an individual component.

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
