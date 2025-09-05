{
  config,
  lib,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  hardware.bluetooth = {
    enable = config.hostSystemSpecific.enableBluetooth;
    settings = {
      General = {
        JustWorksRepairing = "always";
        FastConnectable = true;
        KernelExperimental = true;
        Experimental = true;
      };
    };
  };
}
