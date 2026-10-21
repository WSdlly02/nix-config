{
  looking-glass-client,
  fetchFromGitHub,
  fuse3,
  libunwind,
  elfutils,
  usbredir,
}:

looking-glass-client.overrideAttrs (old: rec {
  version = "B7-829-cdba29f2";

  src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = "cdba29f2f6bcae3ded26369fc231a067cbca3752";
    hash = "sha256-/QE1Hre4Q7YplkudZZ7DSzmosY/MJc1XiAy69xcBXg4=";
    fetchSubmodules = true;
  };

  # The B7 NanoSVG unvendoring patch targets the old CMake layout.
  # Use the upstream-pinned NanoSVG submodule for this development build.
  patches = [ ];
  buildInputs = old.buildInputs ++ [
    fuse3
    libunwind
    elfutils
    usbredir
  ];
  postUnpack = ''
    echo ${version} > source/VERSION
    export sourceRoot="source/client"
  '';
})
