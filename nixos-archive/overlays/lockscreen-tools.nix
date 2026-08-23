# lockscreen-tools.nix
{ inputs }:
final: prev: {
  windowtolayer = final.rustPlatform.buildRustPackage {
    pname = "windowtolayer";
    version = "0.2.0";
    src = inputs.windowtolayer-src;
    cargoHash = "sha256-XuSlbBLWUkPsA0DYC4qemvAGyynkkuznA5FGBKRmNso=";
    nativeBuildInputs = [
      final.pkg-config
      final.python3
      final.rustfmt
    ];
    buildInputs = [
      final.wayland
      final.wayland-protocols
      final.libxkbcommon
    ];
  };

  lavat = final.stdenv.mkDerivation {
    pname = "lavat";
    version = "unstable";
    src = inputs.lavat-src;
    installPhase = ''
      mkdir -p $out/bin
      cp lavat $out/bin/
    '';
  };
}
