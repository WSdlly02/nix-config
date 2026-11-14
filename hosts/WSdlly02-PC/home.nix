{ inputs, pkgs' }:
let
  homeModule =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        ../../profiles/home/base.nix
        ./home/epson-maintenance.nix
        ./home/ollama.nix
        ./home/mihomo-updater.nix
      ];
      home = {
        packages = with pkgs; [
          # pkgs from my-codes.exposedPackages overlay
          # !! Already installed in $HOME/.local/bin
          # duplicate-file-finder
          # mihomo-updater

          ffmpeg
          telegram-desktop

          (texliveMedium.withPackages (
            f: with f; [
              ctex
              latexmk
              biblatex
              biber
            ]
          ))
          texlab

          yt-dlp
        ];
        stateVersion = "24.11";
      };
      programs.zen-browser = {
        enable = true;
        nativeMessagingHosts = [ pkgs.firefoxpwa ];
        policies = {
          DisableAppUpdate = true;
          DisableTelemetry = true;
        };
      };

      systemd.user.services.atrust-rs = {
        Unit.Description = "aTrust client service";
        Service.ExecStart = "${pkgs.atrust-rs}/bin/atrust-client serve --credentials %h/Documents/atrust-rs/.env --node-cert-sha256 6c289777da91769114efa5acd35d1b1a3c078d20fb1a2da36bb5e1bb0679642b";
        Install.WantedBy = lib.mkForce [ ]; # start on demand
      };

      systemd.user.services.prismagentd = {
        Unit.Description = "Prism Agent Daemon service";
        Service = {
          EnvironmentFile = "%h/Documents/PrismAgent/.env";
          ExecStart = "${pkgs.prismagent}/bin/prismagentd";
        };
      };

      services.mpris-proxy.enable = true;

      services.syncthing = {
        enable = true;
        guiAddress = "127.0.0.1:8384";
        overrideDevices = false;
        overrideFolders = false;
      };
    };
in
inputs.home-manager.lib.homeManagerConfiguration {
  extraSpecialArgs = { inherit inputs; };
  modules = [
    inputs.quadlet-nix.homeManagerModules.quadlet
    inputs.zen-browser.homeModules.beta
    homeModule
  ];
  pkgs = pkgs' { system = "x86_64-linux"; };
}
