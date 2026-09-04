# Hardware support

Tested board: Orange Pi Zero 2W, Allwinner H618, 1 GiB RAM, without the expansion board.

Validated on 2026-09-04 with the pinned nixpkgs revision `61b7c44c4073` and Linux 7.1.3.

## Working

| Subsystem | Notes |
| --- | --- |
| CPU | Four Cortex-A53 cores online. `sun50i-cpufreq-nvmem` enables `cpufreq-dt`, 480 MHz to 1.416 GHz. |
| Memory | 938 MiB usable; the example image enables zram. |
| Boot and microSD | U-Boot, extlinux, SDHCI/MMC root filesystem, and the FIRMWARE partition work. |
| UART0 | Serial console works at 115200 baud. |
| Thermal | CPU, GPU, VE, and DDR zones report plausible temperatures; `cpufreq-dt` provides thermal cooling. |
| Mini-HDMI video | `sun4i-drm`, DE33, TCON, and HDMI bind. `HDMI-A-1` connects at 1920x1080. |
| Mali-G31 GPU | Panfrost identifies the GPU and registers a DRM render node. |
| USB0 device mode | The ConfigFS ECM gadget provides the recovery network at `192.168.7.2/24`. |
| USB1 host mode | A SiS `0457:0819` touch controller survives the boot-time OHCI/EHCI rescan. |
| Onboard Wi-Fi | The UWE5622 device enumerates on SDIO, loads firmware, registers `wlan0`, and scans 2.4 and 5 GHz networks. |
| Hardware video decode | Cedrus exposes the V4L2 Request API. GStreamer MPEG-2, H.264, H.265, and VP8 stateless decoders complete real streams. |
| Firewall modules | nftables plus `pkttype`, IPv4 `rpfilter`, and IPv6 `rpfilter` modules load. |

## Partially validated

| Subsystem | Status |
| --- | --- |
| SPI NOR | The 16 MiB flash binds as `/dev/mtd0` and was read-tested. Erase/write tests are intentionally excluded. |
| Touch input | `hid-multitouch` binds the SiS controller. Interactive input and display mapping still require physical testing. |
| Analog audio | The H616 codec registers as ALSA card 0 with one playback PCM. Physical line output requires the expansion board and was not tested. |
| GPIO | Two controllers are exposed. Electrical I/O was not tested without a fixture. |
| I2C | PMIC and HDMI DDC buses work. Header I2C remains disabled until a pin configuration is supplied. |
| Header SPI | Onboard SPI NOR works. Header SPI requires a pin configuration and fixture. |
| CEC | `/dev/cec0` and the HDMI CEC input device exist, but no CEC device was tested. |
| RTC | The SoC RTC exists but has no battery-backed accurate wall clock. Use network time synchronization. |

## Unsupported

| Subsystem | Reason |
| --- | --- |
| Bluetooth | Requires `sprdbt_tty`, proprietary `hciattach_opi`, and an HCI initialization quirk. |
| HDMI audio | H618 AHUB/HDMI audio support is outside the current patch set. |
| Hardware video encode | Cedrus exposes decoder formats only; no maintained H618 encoder driver is included. |
| Expansion-board Ethernet | AC300 Ethernet requires additional device-tree, PHY, and stmmac work. |
| Expansion-board USB | USB2/USB3 require additional device-tree and PHY work. |

## Validation

Run the installed report on the board:

```sh
sudo orange-pi-zero2w-hardware-check
```

The report checks CPU frequency scaling, DRM, GPU, USB, Wi-Fi, ALSA, root storage, SPI NOR, GPIO controllers, thermal zones, and failed systemd units.

Video decode must be tested with GStreamer's stateless elements: `v4l2slmpeg2dec`, `v4l2slh264dec`, `v4l2slh265dec`, and `v4l2slvp8dec`. FFmpeg's `v4l2m2m` codecs use the stateful API and are not valid Cedrus tests for this board.

USB1 uses `usbcore.autosuspend=-1`, an OHCI-then-EHCI rebind, and disabled root-hub runtime power management. This preserves devices that were attached before boot.

Device-tree patches are applied by `pkgs/devicetree`, not by the kernel package. DTS-only changes do not rebuild the kernel.

## Test boundaries

The following tests were intentionally avoided:

- SPI NOR erase or write operations
- GPIO voltage changes without an electrical fixture
- Blind I2C address scans
- Storage corruption tests

Unsupported hardware is reported as unsupported even when partial vendor support exists elsewhere.
