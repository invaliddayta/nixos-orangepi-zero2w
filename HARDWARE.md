# Hardware support

Board: Orange Pi Zero 2W, Allwinner H618, 1 GiB RAM variant.

Validated baseline: NixOS 26.11 pre-release revision `61b7c44c4073` and Linux 7.1.3.

| Subsystem | Status | Notes |
| --- | --- | --- |
| CPU | Working | Four Cortex-A53 cores online. `sun50i-cpufreq-nvmem` enables `cpufreq-dt`, 480 MHz to 1.416 GHz. |
| Memory | Working | 938 MiB usable plus zram swap in the example system. |
| microSD | Working | SDHCI/MMC root filesystem and FIRMWARE partition mount successfully. |
| SPI NOR | Present, read-tested | 16 MiB JEDEC flash binds as `/dev/mtd0`. Erase and write operations are intentionally untested. |
| Mini-HDMI video | Working | `sun4i-drm`, DE33, TCON, and HDMI bind. `HDMI-A-1` connects at 1920x1080. |
| Mali-G31 GPU | Working | The H616 PRCM PPU allows Panfrost to identify the GPU and register a DRM render node. |
| USB0 device mode | Working | ConfigFS ECM gadget enumerates and provides the fixed recovery network at `192.168.7.2/24`. |
| USB1 host mode | Working with mitigation | The SiS `0457:0819` touch controller survives an OHCI-then-EHCI boot rescan without physical reconnection. |
| Touch input | Detected | `hid-multitouch` binds the SiS controller. Interactive input and output mapping require a physical UI test. |
| Onboard Wi-Fi | Working | MMC power sequencing exposes `mmc1:8800`; the UWE5622 driver reads chip ID `0x2355b001`, loads firmware, registers `wlan0`, and scans 2.4 and 5 GHz networks through NetworkManager. |
| Bluetooth | Unsupported | Requires `sprdbt_tty`, proprietary `hciattach_opi`, and an HCI initialization quirk that are not included. |
| Thermal sensors | Working | CPU, GPU, VE, and DDR zones report plausible temperatures. |
| CPU thermal cooling | Working | `cpufreq-dt` exposes the full frequency range to the thermal framework. |
| Analog audio | Driver-tested | The H616 codec registers as ALSA card 0 with one playback PCM. Physical line output requires the expansion board and was not electrically tested. |
| HDMI audio | Unsupported | H618 AHUB/HDMI audio support is outside the current patch set. |
| GPIO | Present | Two GPIO controllers are exposed. No external loopback fixture was attached, so electrical I/O is not claimed. |
| I2C | Limited | PMIC and HDMI DDC buses work. Header I2C controllers remain disabled until a pin configuration is supplied. |
| SPI | Working for onboard NOR | SPI0 CS0 is occupied by the board flash. Header SPI requires a deliberate pin configuration. |
| UART0 | Working | Serial console runs at 115200 baud on the debug UART. |
| CEC | Present, untested | `/dev/cec0` and the HDMI CEC input device exist. |
| RTC/time | Limited | The SoC RTC exists but has no battery-backed accurate wall clock. Use network time synchronization. |
| Hardware video decode | Working | Cedrus exposes the V4L2 Request API on `/dev/video0`. GStreamer stateless decoders completed MPEG-2, H.264, H.265, and VP8 streams and produced tiled NV12 frames. |
| Hardware video encode | Unsupported | Cedrus exposes decoder formats only. An H.264 `v4l2m2m` encode probe found no valid encoder device. |
| Firewall | Working | nftables and the required `pkttype`, IPv4 `rpfilter`, and IPv6 `rpfilter` modules load successfully. |
| Expansion-board Ethernet/USB | Unsupported | USB2/USB3 and AC300 Ethernet require additional device-tree, PWM, PHY, and stmmac patches. No expansion board was tested. |

## Validation method

Run the installed report on the target board:

```sh
sudo orange-pi-zero2w-hardware-check
```

Video decode validation uses GStreamer's `v4l2slmpeg2dec`, `v4l2slh264dec`, `v4l2slh265dec`, and `v4l2slvp8dec` elements. These use the stateless V4L2 Request API. FFmpeg's `v4l2m2m` codecs target the stateful API and are not valid Cedrus tests on this board.

The USB1 mitigation combines `usbcore.autosuspend=-1` with a boot-time OHCI-then-EHCI rebind. It also disables runtime power management for both host root hubs.

Device-tree changes are applied by `pkgs/devicetree`, not by the kernel package. DTS-only changes therefore do not rebuild the kernel.

## Test boundaries

The following operations were intentionally avoided:

- Destructive SPI NOR erase or write tests
- GPIO voltage changes without an electrical fixture
- Blind I2C address scans
- Storage corruption tests

Unsupported hardware is reported as unsupported rather than implied by partial vendor support.
