{ runCommand, service }:

assert service.ExecStartPre == service.ExecStopPost;
runCommand "orangepi-zero2w-usb-gadget-check" { } ''
  substitute ${service.ExecStart} start --replace-fail /sys/ "$TMPDIR/sys/"
  substitute ${service.ExecStopPost} cleanup --replace-fail /sys/ "$TMPDIR/sys/"
  bash ${./usb-gadget.sh}
  touch "$out"
''
