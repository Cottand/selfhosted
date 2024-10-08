{ buildGoModule
, dockerTools
, bash
, buildEnv
, system
, util
, curlMinimal
, pkg-config
, nixVersions
, cacert
, ...
}:
let
  name = "services-go";
  src = util.devGoSrc;

  assetsEnv = buildEnv {
    name = "${name}-assets";
    paths = [
      # has files under /srv
      (builtins.getFlake "github:cottand/web-portfolio/7ac5c39d4903bc80e890e4422d271ef09427c617").packages.${system}.static
    ];
  };

  bin = buildGoModule {
    inherit name src;
    vendorHash = null;
    ldflags = [ "-X github.com/cottand/selfhosted/dev-go/lib/bedrock.nixAssetsDir=${assetsEnv.outPath}" ];
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ nixVersions.nix_2_23 ];
    CGO_ENABLED = 1;
    subPackages = [ "services" ];
    postInstall = ''
      mv $out/bin/services $out/bin/${name}
    '';
  };

  binaryEnv = buildEnv {
    inherit name;
    paths = [ (bin.overrideAttrs { doCheck = false; }) assetsEnv bash curlMinimal ];
  };
  image = dockerTools.buildImage {
    inherit name;
    copyToRoot = binaryEnv;
    config.Cmd = [ "/bin/${name}" ];
    config.Env = [
      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };
in
binaryEnv // { inherit image bin; }
