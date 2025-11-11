{
  lib,
  stdenv,
  fetchurl,
  rpmextract,
  autoreconfHook,
  file,
  libjpeg,
  cups,
}:
let
  pname = "epson-inkjet-printer-201601w";
  version = "1.0.1";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    urls = [
      "https://download3.ebz.epson.net/dsc/f/03/00/15/66/51/1046e0a9f8d8ec892806a8d4921335cf6f5fd1ea/${pname}-${version}-1.src.rpm"
    ];
    sha256 = "sha256-BI1y3U3EvVqqFfQ7YnQxiuIby6GJ5B0TCC2jQH1Uos0=";
  };

  preferLocalBuild = true;
  allowSubstitutes = false;

  nativeBuildInputs = [
    rpmextract
    autoreconfHook
    file
  ];

  buildInputs = [
    libjpeg
    cups
  ];

  unpackPhase = ''
    rpmextract $src
    tar -zxf epson-inkjet-printer-201601w-${version}.tar.gz
    tar -zxf epson-inkjet-printer-filter-1.0.2.tar.gz
    for ppd in epson-inkjet-printer-201601w-${version}/ppds/*; do
      substituteInPlace $ppd --replace-fail "/opt/epson-inkjet-printer-201601w" "$out"
      substituteInPlace $ppd --replace-fail "/cups/lib" "/lib/cups"
    done
    cd epson-inkjet-printer-filter-1.0.2
  '';

  preConfigure = ''
    chmod +x configure
    export LDFLAGS="$LDFLAGS -Wl,--no-as-needed"
  '';

  postInstall = ''
    cd ../epson-inkjet-printer-201601w-${version}
    cp -a lib64 resource watermark $out
    mkdir -p $out/share/cups/model/epson-inkjet-printer-201601w
    cp -a ppds $out/share/cups/model/epson-inkjet-printer-201601w/
    cp -a Manual.txt $out/doc/
    cp -a README $out/doc/README.driver
  '';

  meta = with lib; {
    homepage = "https://www.openprinting.org/driver/epson-201601w";
    description = "Epson printer driver (L380)";
    longDescription = ''
      This software is a filter program used with the Common UNIX Printing
      System (CUPS) under Linux. It supplies high quality printing with
      Seiko Epson Color Ink Jet Printers.

      List of printers supported by this package:
         Epson L380 Series

      To use the driver adjust your configuration.nix file:
        services.printing = {
          enable = true;
          drivers = [ pkgs.epson-inkjet-printer-201601w ];
        };
    '';
    license = with licenses; [ lgpl21 ];
    maintainers = [ ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
