{
  looking-glass-client,
  fetchFromGitHub,
  fuse3,
  libunwind,
  elfutils,
  usbredir,
}:

looking-glass-client.overrideAttrs (old: rec {
  version = "B7-895-432f4a0c";

  src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = "432f4a0c9a227d9ab0fd968d95b51fbb4d84ee91";
    hash = "sha256-ropEJC9+Gg85DS9XRuTb2IRGNNmUcA09Sy/cN6DTvZE=";
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
