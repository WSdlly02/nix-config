# configuration.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ <nixpkgs/nixos/modules/profiles/minimal.nix> ];
  # boot.loader.grub.device = "/dev/vda";
  # boot.loader.efi.canTouchEfiVariables = true;
  # fileSystems."/" = {
  #   device = "/dev/vda1";
  #   autoResize = true;
  # };
  # 1. 单用户模式，彻底干掉 nix-daemon（-50～80 MiB）
  nix = {
    package = pkgs.nix; # 保持默认就行
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  # 关键：单用户安装
  nix.settings.use-xdg-base-directories = true; # 24.11+ 支持
  # 如果你用的是 root 用户安装的系统，直接加这一行就行：
  # nix.daemon = false;   # 老方法，24.11 已废弃，改用环境变量 NIX_REMOTE=local

  # 2. 关闭几乎所有默认服务
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.doc.enable = false;

  services = {
    cron.enable = false;
    nscd.enable = false;
    dbus.enable = lib.mkForce false;
    udisks2.enable = false;
    geoclue2.enable = false;
    accounts-daemon.enable = false;
    gnome.glib-networking.enable = false;
    resolved.enable = false;
    timesyncd.enable = true; # 用 chrony 或手动 ntpdate 也行
    journald = {
      extraConfig = ''
        Storage=volatile
        SystemMaxUse=16M
        RuntimeMaxUse=16M
      '';
    };
  };
  system.nssModules = lib.mkForce [ ];
  # 3. 最小化 locale 和字体（-30～50 MiB）
  i18n.extraLocales = [ "C.UTF-8/UTF-8" ];
  fonts.enableDefaultPackages = false;
  fonts.fontconfig.enable = false;

  # 4. 用 musl + 静态编译核心工具（再砍 20～30 MiB）
  environment.systemPackages = [
  ];

  # 5. 极简内核 + zswap 代替 zram（内存更少）
  # boot.kernelPackages = pkgs.linuxPackages_zen; # 默认内核通常更稳定且内存占用合理
  boot.kernelParams = [
    # "slub_debug=FZ" # 移除调试选项以节省内存
    "page_alloc.shuffle=1"
    "panic=1"
    "boot.panic_on_fail"
  ];
  zramSwap.enable = false;
  swapDevices = [ ]; # 完全不建 swap

  # 6. 关闭 systemd-oomd、logind 等
  security.polkit.enable = false;
  security.audit.enable = false;
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    KillUserProcesses = false;
  };

  # 7. 只开必须的服务（举例只开 sshd）
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      X11Forwarding = false;
    };
  };
  services.cloud-init.enable = true;
  services.qemuGuest.enable = true;

  # 预设一个密码（生产建议用 ssh 密钥）
  users.users.root.password = "nixos";
  networking = {
    hostName = "WSdlly02-SRV";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  # 8. 关闭 mitigations（生产慎用，测试环境可以再降 5～10 MiB）
  # boot.kernelParams = [ "mitigations=off" ];

  system.stateVersion = "25.11";
}
