{
  services.samba = {
    enable = true;
    openFirewall = true; # 自动打开 139 和 445 端口

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "WSdlly02-PC Samba Server From Host NixOS";
        "netbios name" = "WSdlly02-PC-NixOS";
        "security" = "user";

        # 安全加固：只允许 Libvirt 的默认网段访问 (通常是 192.168.122.x)
        # 同时也允许 localhost，防止自己连不上
        "hosts allow" = "192.168.122. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";

        "acl allow execute always" = "yes";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      "Files" = {
        "path" = "/home/wsdlly02/Disks/Files";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0777";
        "directory mask" = "0777";
        "force create mode" = "0777";
        "force directory mode" = "0777";
        # 关键：强制将所有操作映射为你当前用户
        # 这样避免了 NTFS/Linux 权限打架的问题
        "force user" = "wsdlly02";
        "force group" = "users";
      };
      "Files-M" = {
        "path" = "/home/wsdlly02/Disks/Files-M";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0777";
        "directory mask" = "0777";
        "force create mode" = "0777";
        "force directory mode" = "0777";
        "force user" = "wsdlly02";
        "force group" = "users";
      };
    };
  };
}
