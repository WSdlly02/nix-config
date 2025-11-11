{
  buildFHSEnv,
  lib,
  rocmPackages,
  symlinkJoin,
  writeShellScriptBin,
}:
let
  entrypoint = writeShellScriptBin "entrypoint" ''
    echo "[INFO] FHS Entrypoint: Setting up environment..."
    export ROCM_PATH=/usr
    export LD_LIBRARY_PATH=/usr/lib
    # export ROCM_PATH=${rocmtoolkit_joined}
    # export ROCM_SOURCE_DIR=${rocmtoolkit_joined}
    # export CMAKE_CXX_FLAGS="-I${rocmtoolkit_joined}/include -I${rocmtoolkit_joined}/include/rocblas"
    # export AOTRITON_INSTALLED_PREFIX = "${rocmPackages.aotriton}";
    source ~/Documents/rocmFHSEnv/bin/activate
    fish
  '';
  vendorComposableKernel = !rocmPackages.composable_kernel.anyMfmaTarget;
  rocmtoolkit_joined = symlinkJoin {
    name = "rocm-merged";
    paths =
      with rocmPackages;
      [
        rocm-core
        clr
        rccl
        miopen
        aotriton
        rocrand
        rocblas
        rocsparse
        hipsparse
        rocthrust
        rocprim
        hipcub
        roctracer
        rocfft
        rocsolver
        hipfft
        hiprand
        hipsolver
        hipblas-common
        hipblas
        hipblaslt
        rocminfo
        rocm-comgr
        rocm-device-libs
        rocm-runtime
        rocm-smi
        clr.icd
        hipify
        # Optional
        # magma-hip
        # llvm.openmp
        # nccl
        # clr
      ]
      ++ lib.optionals (!vendorComposableKernel) [
        composable_kernel
      ];
    postBuild = ''
      rm -rf $out/nix-support
    '';
  };
in
buildFHSEnv {
  name = "rocmFHSEnv";
  targetPkgs =
    f: with f; [
      # Common pkgs
      dbus
      fish
      libdrm
      libglvnd
      stdenv.cc # gcc
      stdenv.cc.libc # glibc
      # stdenv.cc.cc -> gcc-unwrapped
      stdenv.cc.cc.lib # gcc-unwrapped-lib
      udev
      zlib
      zstd
      rocmtoolkit_joined
    ];
  runScript = "${entrypoint}/bin/entrypoint";
}
