{
  imports = [
    ./system-modules/networking.nix
    ./system-modules/nixpkgs-x86_64.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "wsdlly02";
    startMenuLaunchers = true;
    interop.register = true;
    useWindowsDriver = true;
  };

  environment.etc."resolv.conf".source = ./.;
}
