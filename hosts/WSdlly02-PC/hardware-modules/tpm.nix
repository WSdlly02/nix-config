{
  boot.initrd.systemd.tpm2.enable = true;
  systemd.tpm2.enable = true;
  security.tpm2 = {
    enable = true;
    # pkcs11.enable = true;
  };
}
