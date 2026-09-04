# Hardware status

Board used for testing: Orange Pi Zero 2W, Allwinner H618, 1 GiB RAM, no expansion board.

Last tested on 2026-09-04 with nixpkgs revision `61b7c44c4073` and Linux 7.1.3.

## Working

- **CPU:** all four Cortex-A53 cores come up. `cpufreq-dt` exposes 480 MHz to 1.416 GHz.
- **Memory:** 938 MiB usable on the 1 GiB board. The example image enables zram.
- **Boot and microSD:** U-Boot, extlinux, the root filesystem, and the FIRMWARE partition work.
- **UART0:** serial console works at 115200 baud.
- **Thermal:** CPU, GPU, VE, and DDR sensors report sensible values. CPU frequency scaling is available to the thermal framework.
- **HDMI video:** `sun4i-drm`, DE33, TCON, and HDMI bind. `HDMI-A-1` works at 1920x1080.
- **GPU:** Panfrost detects the Mali-G31 and creates a DRM render node.
- **USB0:** the ECM gadget provides `192.168.7.2/24`.
- **USB1:** a SiS `0457:0819` touch controller survives the boot-time USB rescan.
- **Wi-Fi:** the UWE5622 radio enumerates over SDIO, loads firmware, creates `wlan0`, and scans 2.4 and 5 GHz networks.
- **Video decode:** Cedrus works through the V4L2 Request API. GStreamer MPEG-2, H.264, H.265, and VP8 stateless decoders completed test streams.

## Present but not fully tested

- **SPI NOR:** the 16 MiB flash appears as `/dev/mtd0` and was read. Erase and write tests were not run.
- **Touch input:** the controller binds to `hid-multitouch`. Interactive use and screen mapping still need testing.
- **Analog audio:** the H616 codec registers with ALSA. Physical line output needs the expansion board and was not tested.
- **GPIO:** both controllers are visible. Electrical I/O needs a loopback fixture.
- **I2C:** PMIC and HDMI DDC work. Header I2C needs a pin configuration and a device to test against.
- **Header SPI:** onboard SPI NOR works. Header SPI needs a pin configuration and a device to test against.
- **CEC:** `/dev/cec0` exists, but no CEC device was connected.
- **RTC:** the SoC RTC exists, but there is no battery-backed clock. Use network time.

## Not supported

- **Bluetooth:** needs `sprdbt_tty`, proprietary `hciattach_opi`, and an HCI initialization quirk.
- **HDMI audio:** H618 AHUB/HDMI audio support is not part of the current patch set.
- **Hardware video encoding:** Cedrus only exposes decoding formats on this board.
- **Expansion-board Ethernet:** AC300 Ethernet needs additional device-tree, PHY, and stmmac work.
- **Expansion-board USB:** USB2/USB3 need additional device-tree and PHY work.

## Running the check

```sh
sudo orange-pi-zero2w-hardware-check
```

The script checks CPU frequency scaling, DRM, GPU, USB, Wi-Fi, ALSA, root storage, SPI NOR, GPIO controllers, thermal zones, and failed systemd units.

For Cedrus, use GStreamer's stateless decoders: `v4l2slmpeg2dec`, `v4l2slh264dec`, `v4l2slh265dec`, and `v4l2slvp8dec`. FFmpeg's `v4l2m2m` codecs use the stateful API and do not test this hardware.

USB1 disables USB autosuspend, rebinds OHCI before EHCI during boot, and keeps both root hubs awake. This preserves devices connected before power-on.

## Test limits

These tests were not run:

- SPI NOR erase or write
- GPIO voltage changes without a fixture
- Blind I2C address scans
- Storage corruption tests
