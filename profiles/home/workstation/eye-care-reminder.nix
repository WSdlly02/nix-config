{ pkgs, ... }:
{
  systemd.user = {
    services.eye-care-reminder = {
      Unit = rec {
        Description = "eye-care-reminder service";
        Requires = "graphical-session.target";
        After = Requires;
        PartOf = Requires;
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "eye-care-reminder.sh" ''
          isLocked=$(qdbus org.kde.screensaver /ScreenSaver org.freedesktop.ScreenSaver.GetActive 2>/dev/null)
          if [[ $isLocked == "false" ]]; then
            ifLock=$(notify-send "Take a break 👀" "You have been using the screen for more than 20 minutes." \
                      --transient --icon system-lock-screen --action 1="Lock Screen 🔒" --app-name "WSdlly02" --expire-time 10000)
            if [[ $ifLock == 1 ]]; then
              qdbus org.kde.screensaver /ScreenSaver org.freedesktop.ScreenSaver.Lock
            fi
          fi
        ''}";
        Environment = with pkgs; [
          "PATH=${libnotify}/bin:${kdePackages.qttools}/bin"
        ];
      };
      Install.WantedBy = [ "default.target" ];
    };
    timers.eye-care-reminder = {
      Unit.Description = "Timer for eye-care-reminder";
      Timer = {
        OnBootSec = "20min";
        OnUnitActiveSec = "20min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
