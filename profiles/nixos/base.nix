{ pkgs, ... }:
{
  users.users.wsdlly02 = {
    isNormalUser = true;
    uid = 1000;
    linger = true;
    extraGroups = [ "wheel" ];
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

  i18n.defaultLocale = "en_US.UTF-8";
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.git.lfs.enable = true;
  programs.htop.enable = true;
  programs.lazygit.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    configure.customRC = ''
      set nu
      set showmatch
      set encoding=utf-8
      set fenc=utf-8
      set mouse=a
      set tabstop=2
      filetype plugin indent on
      syntax on
    '';
  };

  environment.systemPackages = with pkgs; [
    aria2
    btop
    dnsutils
    fastfetch
    fzf
    iperf
    iptables
    jq
    lsof
    ncdu
    net-tools
    nmap
    rclone
    ripgrep
    rsync
    tree
    wget
    zellij
  ];

  nix = {
    channel.enable = false;
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "flakes"
        "nix-command"
      ];
      trusted-users = [ "wsdlly02" ];
    };
    package = pkgs.lix;
  };
}
