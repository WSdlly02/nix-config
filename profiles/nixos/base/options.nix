{
  lib,
  ...
}:
{
  options = {
    my.mainUser.name = lib.mkOption {
      default = "root";
      type = lib.types.str;
      description = "Primary interactive user name for modules that need a canonical per-host username.";
    };
    my.networking.firewall = {
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
  };
}
