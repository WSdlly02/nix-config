{
  lib,
  pkgs,
  ...
}:
let
  # check every 60 seconds if the server
  # need to be stopped
  frequency-check-players = "60s";

  # minecraft port
  # used in a few places in the code
  # this is not the port that should be used publicly
  # don't need to open it on the firewall
  minecraft-port = 25564;

  # this is the port that will trigger the server start
  # and the one that should be used by players
  # you need to open it in the firewall
  public-port = 12024;

  # a rcon password used by the local systemd commands
  # to get information about the server such as the
  # player list
  # this will be stored plaintext in the storeMC_SE_LIangyicheng02
  rcon-password = "MC_SE_LIangyicheng02";

  # a script used by hook-minecraft.service
  # to start minecraft and the timer regularly
  # polling for stopping it
  start-mc = pkgs.writeShellScriptBin "start-mc" ''
    systemctl start minecraft-server.service
    systemctl start stop-minecraft.timer
    sleep 5s
    systemctl start stop-minecraft.service
  '';

  # wait 60s for a TCP socket to be available
  # to wait in the proxifier
  # idea found in https://blog.developer.atlassian.com/docker-systemd-socket-activation/
  wait-tcp = pkgs.writeShellScriptBin "wait-tcp" ''
    for i in `seq 60`; do
      if ${pkgs.libressl.nc}/bin/nc -z 127.0.0.1 ${toString minecraft-port} > /dev/null ; then
        exit 0
      fi
      ${pkgs.busybox.out}/bin/sleep 1
    done
    exit 1
  '';
in
{
  # use NixOS module to declare your Minecraft
  # rcon is mandatory for no-player-connected
  services.minecraft-server = {
    enable = true;
    package = pkgs.callPackage ../../Packages/fabric-survivals.nix { };
    jvmOpts = "-server -Xmx3072M -Xms3072M -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3  -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:+PerfDisableSharedMem -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150 -XX:GCTimeRatio=99 -XX:+UseLargePages -XX:LargePageSizeInBytes=2m";
    declarative = true;
    dataDir = "/srv/fabric-survival";
    eula = true;
    openFirewall = false;
    serverProperties = {
      allow-flight = true;
      allow-nether = true;
      broadcast-console-to-ops = true;
      broadcast-rcon-to-ops = true;
      difficulty = "hard";
      enable-command-block = true;
      enable-jmx-monitoring = false;
      enable-query = true;
      enable-rcon = true;
      enable-statu = true;
      enforce-secure-profile = true;
      enforce-whitelist = true;
      entity-broadcast-range-percentage = 80;
      force-gamemode = false;
      function-permission-level = 2;
      gamemode = "survival";
      generate-structures = true;
      ##generator-settings = {};
      hardcore = false;
      hide-online-players = false;
      ##initial-disabled-packs = ;
      initial-enabled-packs = "vanilla";
      level-name = "world";
      ##level-seed = ;
      level-type = "minecraft\:normal";
      log-ips = true;
      max-chained-neighbor-updates = 1000000;
      max-players = 16;
      max-tick-time = 60000;
      max-world-size = 29999984;
      motd = "WSdlly02-SE-LO";
      network-compression-threshold = 1280;
      online-mode = true;
      op-permission-level = 4;
      player-idle-timeout = 0;
      prevent-proxy-connections = false;
      pvp = true;
      "query.port" = 12024;
      rate-limit = 0;
      "rcon.password" = rcon-password;
      "rcon.port" = 22024;
      require-resource-pack = false;
      ##resource-pack = ;
      ##resource-pack-prompt = ;
      ##resource-pack-sha1=;
      ##server-ip=;
      server-port = minecraft-port;
      simulation-distance = 10;
      spawn-animals = true;
      spawn-monsters = true;
      spawn-npcs = true;
      spawn-protection = 0;
      sync-chunk-writes = true;
      ##text-filtering-config = ;
      use-native-transport = true;
      view-distance = 10;
      white-list = true;
    };
    whitelist = {
      WSdlly02 = "2d4b4759-54e8-4304-8434-2ae02fdd0537";
      beclcolud = "080af814-0c31-4241-9a76-23bef4764f77";
      ZoD1AC0 = "5ffa6f38-b847-4ea7-b909-8f617e77d079";
      iven233 = "dfa30c4c-a23b-4e72-ae74-f329536e99f7";
    };
  };

  # don't start Minecraft on startup
  systemd.services.minecraft-server = {
    wantedBy = lib.mkForce [ ];
  };

  # this waits for incoming connection on public-port
  # and triggers listen-minecraft.service upon connection
  systemd.sockets.listen-minecraft = {
    enable = true;
    wantedBy = [ "sockets.target" ];
    requires = [ "network.target" ];
    listenStreams = [ "${toString public-port}" ];
  };

  # this is triggered by a connection on TCP port public-port
  # start hook-minecraft if not running yet and wait for it to return
  # then, proxify the TCP connection to the real Minecraft port on localhost
  systemd.services.listen-minecraft = {
    path = with pkgs; [ systemd ];
    enable = true;
    requires = [
      "hook-minecraft.service"
      "listen-minecraft.socket"
    ];
    after = [
      "hook-minecraft.service"
      "listen-minecraft.socket"
    ];
    serviceConfig.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString minecraft-port}";
  };

  # this starts Minecraft is required
  # and wait for it to be available over TCP
  # to unlock listen-minecraft.service proxy
  systemd.services.hook-minecraft = {
    path = with pkgs; [
      systemd
      libressl
      busybox
    ];
    enable = true;
    serviceConfig = {
      ExecStartPost = "${wait-tcp}/bin/wait-tcp";
      ExecStart = "${start-mc}/bin/start-mc";
    };
  };

  # create a timer running every frequency-check-players
  # that runs stop-minecraft.service script on a regular
  # basis to check if the server needs to be stopped
  systemd.timers.stop-minecraft = {
    enable = true;
    timerConfig = {
      OnUnitActiveSec = "${frequency-check-players}";
      Unit = "stop-minecraft.service";
    };
    wantedBy = [ "timers.target" ];
  };

  # run the script no-player-connected
  # and if it returns true, stop the minecraft-server
  # but also the timer and the hook-minecraft service
  # to prepare a working state ready to resume the
  # server again
  systemd.services.stop-minecraft = {
    enable = true;
    serviceConfig.Type = "oneshot";
    script = ''
      current_time=$(date "+%Y-%m-%d %H:%M:%S")
      fabric_survival_pid=$(systemctl show --property MainPID --value fabric-survival.service)
      function stop-server() {
        rm /run/fabric_survival_players_count
        echo "stopping server"
        systemctl stop fabric-survival.service fabric-survival.socket
        sleep 4s
        echo $current_time | xargs -I {} ${pkgs.btrfs}/bin/btrfs subvolume snapshot -r /srv/fabric-survival/ /srv/backup/fabric-survival/{}
        cd /srv/backup/fabric-survival
        ls -t | sed -n '6,$p' | xargs -I {} ${pkgs.btrfs}/bin/btrfs subvolume delete {}
        sleep 1s
        systemctl start listen-fabric-survival.socket listen-forge-pvp.socket listen-vanilla-survival.socket
        systemctl stop stop-fabric-survival.timer
      }
      if [[ $fabric_survival_pid == 0 ]];
      then
       stop-server
      else
       current_players=$(${pkgs.iproute2}/bin/ss -a | grep 12024 | grep  -o ESTAB | xargs)
       if [ -z $current_players ];
       then
        echo -n 0 >> /run/fabric_survival_players_count
       else
        echo -n "" > /run/fabric_survival_players_count
       fi
       idle_time=$(cat /run/fabric_survival_players_count)
       if [[ $idle_time == 000000000000000 ]];
       # 15 Minutes
       then
        stop-server
       fi
      fi
    '';
  };
}
