{ pkgs, ... }:
{
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "atk-f1-mouse-webhid-udev-rules";
      destination = "/lib/udev/rules.d/70-atk-f1-mouse-webhid.rules";
      text = ''
        # Allow the active local desktop session to use the mouse configuration website.
        # Display Name: Compx Wireless mouse 8k NANO dongle-L
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="11fe", TAG+="uaccess"
      '';
    })
  ];
}
