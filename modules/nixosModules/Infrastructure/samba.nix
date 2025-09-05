{ lib, enableInfrastructure, ... }:
lib.mkIf enableInfrastructure {
  services.samba = {
    enable = true;
    openFirewall = true;
    nsswins = true;
    extraConfig = ''
      workgroup = WORKGROUP
      server string = samba server
      netbios name = WSdlly02-PC
      security = USER
      guest account = nobody
    '';
    shares = {
      "WSdlly02-Lib" = {
        comment = "File Libs";
        path = "/home/wsdlly02/Disks/Files-N/WSdlly02-Lib/";
        "guest ok" = "no";
        browseable = "yes";
        writable = "yes";
      };

      "Personal Files" = {
        comment = "File Libs";
        path = "/home/wsdlly02/Disks/Files-E/个人文件/";
        "guest ok" = "no";
        browseable = "yes";
        writable = "yes";
      };

      "Files-E" = {
        path = "/home/wsdlly02/Disks/Files-E/Files-E/";
        "guest ok" = "no";
        browseable = "yes";
        writable = "yes";
      };
    };
  };
  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
  };
}
