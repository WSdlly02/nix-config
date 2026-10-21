{ inputs, ... }:
{
  imports = [
    inputs.codex-desktop-linux.nixosModules.default
  ];

  programs.codexDesktopLinux = {
    enable = true;
    linuxFeatures = [
      "appshots"
      "computer-use-linux"
      "global-dictation"
      "codex-micro"
      "pet-overlay"
      "remote-control-ui"
      "remote-mobile-control"
    ];
  };
}
