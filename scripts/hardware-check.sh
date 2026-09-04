#!/bin/sh
set -u

pass() {
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1"
}

info() {
  printf 'INFO  %s\n' "$1"
}

printf 'Orange Pi Zero 2W hardware report\n'
printf '==================================\n'
info "kernel: $(uname -srmo)"
info "model: $(tr -d '\0' < /sys/firmware/devicetree/base/model)"
uptime_seconds=$(cut -d. -f1 /proc/uptime)
info "uptime: $uptime_seconds seconds"

cpu_count=$(getconf _NPROCESSORS_ONLN)
if [ "$cpu_count" -eq 4 ]; then
  pass "four CPU cores online"
else
  fail "$cpu_count CPU cores online"
fi
if [ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]; then
  pass "cpufreq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)"
  info "frequency range: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)-$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) kHz"
else
  fail "cpufreq unavailable"
fi

if [ -e /sys/class/drm/card0-HDMI-A-1/status ] && [ "$(cat /sys/class/drm/card0-HDMI-A-1/status)" = connected ]; then
  pass "mini-HDMI connected"
else
  fail "mini-HDMI disconnected or unavailable"
fi

if [ -L /sys/bus/platform/devices/1800000.gpu/driver ]; then
  pass "Mali-G31 bound to $(basename "$(readlink /sys/bus/platform/devices/1800000.gpu/driver)")"
else
  fail "Mali-G31 has no driver"
fi

if systemctl is-active --quiet usb-gadget.service && ip address show usb0 | grep -q '192\.168\.7\.2/24'; then
  pass "USB0 ECM recovery network"
else
  fail "USB0 ECM recovery network"
fi

if systemctl is-active --quiet usb-host-rescan.service; then
  pass "USB1 boot rescan completed"
else
  fail "USB1 boot rescan did not complete"
fi
lsusb

if iw dev | grep -q 'Interface '; then
  pass "onboard Wi-Fi interface present"
  iw dev
else
  fail "onboard Wi-Fi interface missing"
fi

if aplay -l | grep -q '^card '; then
  pass "ALSA sound card present"
  aplay -l
else
  fail "no ALSA sound card"
fi

if [ -b /dev/mmcblk0 ] && findmnt -n / >/dev/null; then
  pass "microSD root storage"
else
  fail "microSD root storage"
fi

if [ -c /dev/mtd0 ]; then
  pass "16 MiB SPI NOR present"
else
  fail "SPI NOR unavailable"
fi

gpio_count=$(gpiodetect 2>/dev/null | wc -l)
if [ "$gpio_count" -ge 2 ]; then
  pass "$gpio_count GPIO controllers"
else
  fail "$gpio_count GPIO controllers"
fi

for zone in /sys/class/thermal/thermal_zone*; do
  [ -r "$zone/type" ] || continue
  info "thermal $(cat "$zone/type"): $(cat "$zone/temp") millidegrees C"
done

if [ -z "$(systemctl --failed --no-legend)" ]; then
  pass "no failed systemd units"
else
  fail "failed systemd units"
  systemctl --failed --no-legend
fi
