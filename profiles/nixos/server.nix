{ lib, pkgs, ... }:
{
  i18n.defaultLocale = "en_US.UTF-8";
  nix = {
    channel.enable = false;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [ "wsdlly02" ];
    };
    package = pkgs.lix;
  };

  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.core.netdev_max_backlog" = 16384;
    "net.core.optmem_max" = 65536;
    "net.core.rmem_default" = 1048576;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_default" = 1048576;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.bootp_relay" = 0;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.default.bootp_relay" = 0;
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.ping_group_range" = "0 2147483647";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.udp_rmem_min" = 8192;
    "net.ipv4.udp_wmem_min" = 8192;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.disable_ipv6" = 0;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.default.disable_ipv6" = 0;
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 1;
    "kernel.randomize_va_space" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "vm.max_map_count" = 1048576;
    "vm.swappiness" = 10;
  };

  users.groups.wsdlly02.gid = 1000;
  users.users.wsdlly02 = {
    isNormalUser = true;
    uid = 1000;
    group = "wsdlly02";
    extraGroups = [
      "wheel"
      "systemd-journal"
    ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkH7l0JnwQeP+cmD+ty29i0kdxHdvnvedkiXKcp8dCYRYAoGBIS6FIzD6p058cNwp1DDHN+TTrlNZz9DEizKqbS1SOPJyiWrln6lx3jh9p/AD1pbPRjsgVLzvdBS6bJ6NgtXe2q0bV4UgGktVi6VxDAt4jBQPsUKfyGYx9hh95xeWjvt9AEYcD2hOak9bBRHkE4IQcus5xV1kXNSiVec0DMhB2IObADbx+6H4C+oIIAxVccr+SOivwrSgwmn9XhQ0VgopJomVKg9zmlr7idorwmDZdIsMmpeU346Gu2Piq+Amvn1FM7H37ThBNx81dUO18UZ/gw35zT7G6Hh4CisYFDJWocKfYKMdT4IdzxcyOWkUr3PSfcpOUc+60h+BlpI0ogxYRoXM6R9bWRGYM3x26hRrfcBR8fwTepTa9H+Vz70KNJh4qNrHuMICnyerX+h9igkVXoysPjbzfqidGPzLIbbi+iUU56/8C4JGL2haEppoZgq/bx1Lo5rv1BT7Q732BkhcnS96vaDqsAffAKupHWQ1eRFZ9uId8uRTNbKZmstgKJthcoSdizrbXvlx7b3Kzob9Y4mix9tlUU2Z5i5sm2FFa/AYfTNrLVg6jA4fSrB0vKRyeCaBBzHOhwPOIWZAa0MG/2LZ40M2jT3270HCToHH3kBCMQthByCos20h/IQ== wsdlly02@WSdlly02-PC"
    ];
  };

  environment = {
    homeBinInPath = true;
    localBinInPath = true;
  };

  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = false;
    extraConfig = "Defaults env_keep += \"http_proxy https_proxy all_proxy\"";
  };

  services.openssh = {
    enable = true;
    ports = [ 10022 ];
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      GatewayPorts = "yes";
      PrintMotd = true;
    };
  };

  services.logind.settings.Login = {
    NAutoVTs = 1;
    ReserveVT = 1;
  };

  programs.fish.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = with pkgs; [
    aria2
    btop
    curl
    dnsutils
    fastfetch
    fzf
    git
    htop
    iperf
    iptables
    jq
    lsof
    ncdu
    net-tools
    nmap
    python3
    rclone
    ripgrep
    rsync
    tree
    unzip
    wget
    zellij
  ];
}
