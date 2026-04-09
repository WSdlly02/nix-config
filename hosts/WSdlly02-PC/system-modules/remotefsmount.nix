{
  fileSystems."/home/wsdlly02/Disks/Lily-PC" = {
    device = "lily-pc:/";
    fsType = "fuse.sshfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "nofail"
      "_netdev"
      "users"
      "idmap=user"
      "ssh_command=ssh"
      "IdentityFile=/home/wsdlly02/.ssh/id_rsa_lily"
      "allow_other"
      "reconnect"
      "ServerAliveInterval=15"
      "port=10022"
    ];
  };
}
