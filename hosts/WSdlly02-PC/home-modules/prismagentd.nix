{ pkgs, ... }:
{
  systemd.user.services.prismagentd = {
    Unit.Description = "Prism Agent Daemon service";
    Service = {
      EnvironmentFile = "%h/Documents/PrismAgent/.env";
      ExecStart = "${pkgs.prismagent}/bin/prismagentd";
    };
  };
}
