{
  inputs,
  buildRustPackage,
  buildNpmPackage,
  pkg-config,
  aws-lc,
  cacert,
  lib,
}:
let
  prismagent-web = buildNpmPackage {
    pname = "prismagent-web";
    version = "0.9.0";

    src = inputs.prismagent + "/web";

    npmDepsHash = "sha256-LxAasxT/cpwWWHDhs5NSs63OPiC5MWcuZ7q26BJTEek=";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r dist/. "$out/"
      runHook postInstall
    '';

  };
in
buildRustPackage {
  pname = "prismagent";
  version = "0.9.0";

  src = inputs.prismagent;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ aws-lc ];

  preBuild = ''
    mkdir -p web/dist
    cp -r ${prismagent-web}/. web/dist/
  '';
  preCheck = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  '';
  cargoLock.lockFile = inputs.prismagent + "/Cargo.lock";

  meta = {
    description = "Prism Agent";
    license = lib.licenses.mit;
    mainProgram = "prismagentd";
  };
}
