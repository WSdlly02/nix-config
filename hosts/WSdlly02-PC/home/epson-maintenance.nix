{ pkgs, ... }:
{
  systemd.user = {
    services.epson-maintenance = {
      Unit.Description = "Send Epson maintenance PDF by email";
      Service = {
        Type = "oneshot";
        EnvironmentFile = "%h/Documents/my-codes/SOPs/epson-maintenance/.env";
        ExecStart = "${pkgs.epson-maintenance}/bin/epson-maintenance";
      };
    };
    timers.epson-maintenance = {
      Unit.Description = "Timer for Epson maintenance";
      Timer = {
        OnCalendar = "Wed 19:00";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
