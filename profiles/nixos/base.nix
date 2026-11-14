{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  users.users.wsdlly02 = {
    isNormalUser = true;
    uid = 1000;
    linger = true;
    extraGroups = [
      "wsdlly02"
      "audio"
      "networkmanager"
      "input"
      "render"
      "video"
      "users"
      "wheel"
    ];
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

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [
      # "C.UTF-8/UTF-8" is already included
      # "en_US.UTF-8/UTF-8" is already included
      "zh_CN.UTF-8/UTF-8"
    ];
    # extraLocaleSettings = {};
  };
  time.timeZone = "Asia/Singapore";
  # Select internationalisation properties.
  /*
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
      useXkbConfig = true; # use xkb.options in tty.
    };
  */

  programs = {
    command-not-found = {
      enable = true;
      dbPath = lib.mkForce "${config.nixpkgs.flake.source}/programs.sqlite";
    };
    fish.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
    };
    htop.enable = true;
    lazygit.enable = true;
  };
  # security.apparmor.enable = true; # disable for now, as it causes some issues with docker and flatpak
  services = {
    atd.enable = true;
    fstrim.enable = true;
    dbus.implementation = "broker";
    journald = {
      settings.Journal = {
        Compress = true;
        Storage = "auto";
        SystemMaxUse = if ("${pkgs.stdenv.hostPlatform.system}" == "x86_64-linux") then "512M" else "256M";
      };
    };
  };
  environment.systemPackages = with pkgs; [
    # Drivers and detection tools
    android-tools
    aria2
    btop
    compsize
    cryptsetup
    # currentNixConfig !!!
    dnsutils
    fastfetch
    fzf
    iperf
    iptables
    jq
    lm_sensors
    lsof
    # nixd
    # nixfmt
    # nix-diff
    # nix-output-monitor
    # nix-tree
    ncdu
    net-tools
    nmap
    pciutils
    psmisc
    rclone
    ripgrep
    rsync
    tree
    usbutils
    wget
    zellij
  ];
  # system.etc.overlay = {
  #   enable = true;
  #   mutable = true;
  # };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    configure = {
      customRC = ''
        set nu
        set showmatch
        set encoding=utf-8
        set fenc=utf-8
        set mouse=a
        set tabstop=2
        filetype plugin indent on
        syntax on
      '';
      packages.vimPlugins = with pkgs.vimPlugins; {
        # loaded on launch
        start = [
          LazyVim
          lazy-nvim
          lazygit-nvim
          yazi-nvim
        ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ ];
      };
    };
  };

  nix = {
    channel.enable = false;
    registry = {
      "home-manager" = {
        from = {
          id = "home-manager";
          type = "indirect";
        };
        to = {
          path = "${inputs.home-manager}";
          type = "path";
        };
      };
      "nixpkgs".to = {
        path = "${config.nixpkgs.flake.source}";
        type = "path";
      };
      "my-codes" = {
        from = {
          id = "my-codes";
          type = "indirect";
        };
        to = {
          type = "git";
          url = "file:///home/wsdlly02/Documents/my-codes";
        };
      };
      "nix-config" = {
        from = {
          id = "nix-config";
          type = "indirect";
        };
        to = {
          type = "git";
          url = "file:///home/wsdlly02/Documents/nix-config";
        };
      };
    };
    settings = {
      accept-flake-config = true; # Experimental
      auto-optimise-store = true;
      experimental-features = [
        "flakes"
        "nix-command"
      ];
      /*
        extra-sandbox-paths = lib.optionals config.programs.ccache.enable [
          config.programs.ccache.cacheDir
        ];
      */
      max-jobs = lib.mkDefault 32;
      nix-path = [
        "home-manager=${inputs.home-manager}"
        "nixpkgs=${config.nixpkgs.flake.source}"
        "my-codes=git+file:///home/wsdlly02/Documents/my-codes"
        "nix-config=git+file:///home/wsdlly02/Documents/nix-config"
      ];
      substituters = [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
      ];
      trusted-users = [ "wsdlly02" ];
    };
    package = pkgs.lix;
  };
}
