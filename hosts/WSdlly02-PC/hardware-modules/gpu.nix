{
  /*
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  */
  hardware.amdgpu = {
    initrd.enable = true;
    overdrive = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
    # opencl.enable = true; # Add ROCm support for opencl driver
    # zluda.enable = true; # Add support for AMD GPUs to the CUDA driver
  };
  environment.sessionVariables = {
    HSA_OVERRIDE_GFX_VERSION = "10.3.0";
    VDPAU_DRIVER = "radeonsi";
  };
}
