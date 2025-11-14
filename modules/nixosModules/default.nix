{
  config,
  lib,
  ...
}:
let
  cfg = config.hostSystemSpecific;
in
{
  imports = [
    ./Daily
    ./Development
    ./Infrastructure
  ];
  options.hostSystemSpecific = {
    boot.kernel.sysctl."vm.swappiness" = lib.mkOption {
      default = 20;
      type = lib.types.int;
      description = ''
        This option defines the value of vm.swappiness
      '';
    };
    enableBtrfsScrub = lib.mkEnableOption "Enable Btrfs scrub";
    enableDevEnv = lib.mkEnableOption "Install development softwares";
    enableInfrastructure = lib.mkEnableOption "Install infrastructure softwares";
    enableBluetooth = lib.mkEnableOption "Enable bluetooth";
    enableSmartd = lib.mkEnableOption "Enable smart daemon";
    environment.extraSystemPackages = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.package;
      description = ''
        The set of packages that appear in
        /run/current-system/sw
      '';
    };
    defaultUser = {
      name = lib.mkOption {
        default = "wsdlly02";
        type = lib.types.str;
        description = "default user to operate system";
      };
      linger = lib.mkEnableOption "set enable-linger in logind";
      extraGroups = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        description = "The user's auxiliary groups.";
      };
    };
    networking.firewall = {
      extraAllowedPorts = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.port;
        apply = ports: lib.unique (builtins.sort builtins.lessThan ports);
        description = ''
          List of ports on which incoming connections are
          accepted.
        '';
      };
      extraAllowedPortRanges = lib.mkOption {
        default = [ ];
        type = lib.types.listOf (lib.types.attrsOf lib.types.port);
        description = ''
          A range of ports on which incoming connections are
          accepted.
        '';
      };
      lanOnlyPorts = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.port;
        apply = ports: lib.unique (builtins.sort builtins.lessThan ports);
        description = ''
          List of ports will be excluded from allowedPorts
        '';
      };
      lanOnlyPortRanges = lib.mkOption {
        default = [ ];
        type = lib.types.listOf (lib.types.attrsOf lib.types.port);
        description = ''
          A range of ports will be excluded from allowedPortRanges
        '';
      };
    };
    nix.settings.max-jobs = lib.mkOption {
      default = 32;
      type = lib.types.int;
      description = ''
        This option defines the maximum number of jobs that Nix will try to
        build in parallel.
      '';
    };
    services.pipewire.socketActivation = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Automatically run PipeWire when connections are made to the PipeWire socket.
      '';
    };
  };
  config = {
    _module.args = {
      # Add configs to specialArgs in order to accelerate eval
      enableDevEnv = cfg.enableDevEnv;
      enableInfrastructure = cfg.enableInfrastructure;
    };
  };
}
