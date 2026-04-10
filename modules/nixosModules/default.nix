{
  config,
  lib,
  ...
}:
let
  cfg = config.hostSystemSpecific;
in
{
  options.hostSystemSpecific = {
    enablePythonRocmSupport = lib.mkEnableOption "Enable Python Rocm Support";
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
    services.pipewire.socketActivation = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Automatically run PipeWire when connections are made to the PipeWire socket.
      '';
    };
  };
  config = {
    nixpkgs.overlays = lib.optionals cfg.enablePythonRocmSupport [
      (final: prev: {
        python3 = prev.python3.override {
          packageOverrides =
            pyfinal: pyprev:
            builtins.mapAttrs (
              _: pypkg: if pypkg ? rocmSupport then pypkg.override { rocmSupport = true; } else pypkg
            ) pyprev;
        };
        python3Packages = final.python3.pkgs;
      })
    ];
  };
}
