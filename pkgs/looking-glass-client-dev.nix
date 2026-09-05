{
  looking-glass-client,
  fetchFromGitHub,
  fuse3,
  libunwind,
  elfutils,
  usbredir,
}:

looking-glass-client.overrideAttrs (old: rec {
  version = "B7-826-236efcb1";

  src = fetchFromGitHub {
    owner = "gnif";
    repo = "LookingGlass";
    rev = "236efcb155f952f5d7d9fcd5891a3060ad254e68";
    hash = "sha256-NAfV4Z0RZp2IGBzVAFysm53aGMEReT03RIN+45TveUU=";
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
