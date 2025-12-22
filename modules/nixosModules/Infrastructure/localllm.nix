{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
let
  user = config.hostSystemSpecific.defaultUser.name;
  cfg = config.hostSystemSpecific.enablePythonRocmSupport;
  models =
    if cfg then
      [
        "qwen3:0.6b"
        "qwen3:8b"
        "qwen3-vl:8b"
      ]
    else
      [
        "qwen3:0.6b"
        "qwen3:1.7b"
        "qwen3-vl:2b"
      ];
in
lib.mkIf enableInfrastructure {
  networking.firewall.allowedTCPPorts = [ 11434 ];

  virtualisation.quadlet.containers.ollama = {
    containerConfig = {
      image = if cfg then "docker.io/ollama/ollama:rocm" else "docker.io/ollama/ollama:latest";
      publishPorts = [
        "11434:11434"
      ];
      volumes = [ "/home/${user}/.ollama:/root/.ollama" ];
      devices = [
        "/dev/kfd"
        "/dev/dri"
      ];
      environments = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };
      user = "0";
      autoUpdate = "registry";
    };

    serviceConfig = {
      Delegate = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/${user}/.ollama";
      Restart = "always";
      TimeoutStartSec = "300";
    };

    unitConfig = {
      Description = "Ollama ROCm in Podman container";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
  };

  systemd.services.ollama-model-loader = {
    description = "Ollama Model Loader";
    after = [ "ollama.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ollama-load-models" ''
        # Wait for ollama to be ready
        until ${pkgs.curl}/bin/curl -s http://localhost:11434/api/tags > /dev/null; do
          echo "Waiting for Ollama API..."
          sleep 1
        done
        ${lib.concatMapStringsSep "\n" (
          model:
          "${pkgs.curl}/bin/curl -X POST http://localhost:11434/api/pull -d '{\"model\": \"${model}\"}'"
        ) models}
      '';
      RemainAfterExit = true;
    };
  };
}
