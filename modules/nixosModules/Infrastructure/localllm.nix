{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
let
  cfg = config.hostSystemSpecific.enablePythonRocmSupport;
in
lib.mkIf enableInfrastructure {
  services.ollama = {
    enable = true;
    loadModels =
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
    rocmOverrideGfx = "10.3.0";
    openFirewall = true;
    package = if cfg then pkgs.ollama-rocm else pkgs.ollama-vulkan;
  };
}
