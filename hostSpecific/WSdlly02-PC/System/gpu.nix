{
  /*
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  */
  hardware.amdgpu = {
    initrd.enable = true;
    # opencl.enable = true; # Add Rocm support to opencl driver
  };
  environment.sessionVariables = {
    HSA_OVERRIDE_GFX_VERSION = "10.3.0";
    VDPAU_DRIVER = "radeonsi";
  };
}
