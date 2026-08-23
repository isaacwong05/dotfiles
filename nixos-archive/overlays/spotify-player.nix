# Spotify changed its Web API token behavior; 0.23.0 rejects new tokens and
# leaves the UI loading. Keep the system pin while using the upstream fixed release.
final: prev: {
  spotify-player = prev.spotify-player.overrideAttrs (old: rec {
    version = "0.24.1";
    src = final.fetchFromGitHub {
      owner = "aome510";
      repo = "spotify-player";
      tag = "v0.24.1";
      hash = "sha256-+GADmRl4XMwV8TfYZjEeyKDDfda3bDPzeerhYryX6vA=";
    };
    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-CSZ5sZ+d7Jhi43ipaWXKupYPFgWCbCx4RMTQN8emu9o=";
    };
  });
}
