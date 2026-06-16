USB support for keyboard and mouse in ZealOS

UTM target setup:

Input USB: USB 3.0 (XHCI)
PS/2 Controller: Off
Additional Arguments: empty

Use `build/setup-utm-usb-ui.sh` to apply that UTM configuration, sync the USB sources, and queue the guest-side kernel rebuild. After the reboot, `USB boot: active=0x3` means keyboard plus mouse/tablet input bound.
