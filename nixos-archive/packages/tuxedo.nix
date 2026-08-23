{
  rustPlatform,
  fetchFromGitHub,
  lib,
}:

rustPlatform.buildRustPackage rec {
  pname = "tuxedo";
  version = "2026.5.12"; # update to the latest release tag (without leading 'v')

  src = fetchFromGitHub {
    owner = "webstonehq";
    repo = "tuxedo";
    rev = "v${version}";
    hash = "sha256-s4GIHq4kjj+FiNBJJjWeXmg4f40ARUILzwsEl0CDV1o=";
  };

  cargoHash = "sha256-rIdjrwNuY0DySdk4jc880JrFgoIuKTYEcx6XoSfllp4=";

  doCheck = false;
  meta = with lib; {
    description = "Fast, keyboard-driven terminal UI for todo.txt";
    homepage = "https://github.com/webstonehq/tuxedo";
    license = licenses.mit;
    mainProgram = "tuxedo";
  };
}
