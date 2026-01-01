{
  config,
  lib,
  pkgs,
  ...
}:
let
  modelsList = [
    "qwen3:0.6b"
    "qwen3:8b"
    "qwen3-vl:8b"
  ];
in
{
  virtualisation.quadlet.containers.ollama = {
    containerConfig = {
      image = "docker.io/ollama/ollama:rocm";
      publishPorts = [
        "127.0.0.1:11433:11434"
      ];
      volumes = [ "${config.home.homeDirectory}/.ollama:/root/.ollama" ];
      devices = [
        "/dev/kfd"
        "/dev/dri"
      ];
      environments = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        OLLAMA_ORIGINS = "*";
        OLLAMA_HOST = "0.0.0.0";
      };
      autoUpdate = "registry";
    };
    serviceConfig = {
      Delegate = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.ollama";
      Restart = "on-failure";
      TimeoutStartSec = "300";
    };
    unitConfig = {
      Description = "Ollama ROCm in Podman container";
      BindsTo = [ "ollama-proxy.service" ];
    };
  };

  systemd.user.services.ollama-model-loader = {
    Unit = {
      Description = "Ollama Model Loader";
      Requires = [
        "ollama.service"
        "ollama-proxy.service"
      ];
      After = [
        "ollama.service"
        "ollama-proxy.service"
      ];
    };
    Service = {
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
        ) modelsList}
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  # 1. Systemd Socket 监听 11434 端口并进行 IP 过滤
  systemd.user.sockets.ollama-proxy = {
    Unit.Description = "Socket for Ollama Proxy with IP Filtering";
    Socket = {
      ListenStream = "0.0.0.0:11434";
      # 限制访问来源：本地、LAN、Tailscale
      IPAddressAllow = [
        "127.0.0.1"
        "::1"
        "192.168.0.0/16"
        "100.64.16.0/24"
      ];
      IPAddressDeny = "any";
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  # 2. Socket Proxy 服务：转发流量到容器监听的 11435 端口
  systemd.user.services.ollama-proxy = {
    Unit = {
      Description = "Proxy for Ollama with IP Filtering";
      # 确保容器服务在代理启动时也启动
      Requires = [ "ollama.service" ];
      After = [ "ollama.service" ];
    };
    Service = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:11433";
    };
  };
}
