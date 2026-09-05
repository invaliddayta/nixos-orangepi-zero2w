#!/usr/bin/env bash
set -euo pipefail

export gadget="$TMPDIR/sys/kernel/config/usb_gadget/orangepizero2w"
mkdir -p "$TMPDIR/sys/class/udc" "$TMPDIR/sys/class/net"

# Exercise the generated service scripts without root or real USB hardware.
modprobe() { return 0; }
mountpoint() { return 0; }
sleep() { return 0; }
ip() { [ "${FAIL_IP:-0}" = 0 ]; }
rmdir() {
  local entry
  if [ -e "$gadget/UDC" ]; then
    test -z "$(cat "$gadget/UDC")" || return 1
    # sysfs requires an actual write, not just truncating the attribute.
    test -s "$gadget/UDC" || return 1
  fi
  # configfs removes virtual attributes and default groups with their owner.
  for entry in "$1"/*; do
    if [ -f "$entry" ] && [ ! -L "$entry" ]; then
      rm "$entry"
    fi
  done
  if [ -d "$1/strings" ]; then command rmdir "$1/strings"; fi
  if [ "$1" = "$gadget" ]; then
    command rmdir "$1/configs" "$1/functions"
  fi
  command rmdir "$1"
}
export -f modprobe mountpoint sleep ip rmdir

bash cleanup
if bash start; then
  echo "Startup succeeded without a UDC" >&2
  exit 1
fi
test -L "$gadget/configs/c.1/ecm.usb0"
bash cleanup
test ! -e "$gadget"
bash cleanup

mkdir "$TMPDIR/sys/class/udc/test-udc"
if bash start; then
  echo "Startup succeeded without a network interface" >&2
  exit 1
fi
test "$(cat "$gadget/UDC")" = test-udc
bash cleanup
test ! -e "$gadget"

mkdir "$TMPDIR/sys/class/net/usb0"
if FAIL_IP=1 bash start; then
  echo "Startup ignored an IP configuration failure" >&2
  exit 1
fi
bash cleanup
test ! -e "$gadget"

for _ in 1 2; do
  bash cleanup
  bash start
  test "$(cat "$gadget/UDC")" = test-udc
  test -L "$gadget/configs/c.1/ecm.usb0"
done
bash cleanup
test ! -e "$gadget"
echo "USB gadget failure, cleanup, and retry checks passed"
