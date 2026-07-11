{
  description = "Isaac's NixOS config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    helium-browser.url = "github:schembriaiden/helium-browser-nix-flake";
    whisper-dictation.url = "github:jacopone/whisper-dictation";
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/v4.7.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    anifetch = {
      url = "github:Notenlish/anifetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    windowtolayer-src = {
      url = "git+https://gitlab.freedesktop.org/mstoeckl/windowtolayer.git?ref=refs/tags/v0.2.0";
      flake = false;
    };
    lavat-src = {
      url = "github:AngelJumbo/lavat";
      flake = false;
    };
    wlctl = {
      url = "github:aashish-thapa/wlctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      helium-browser,
      quickshell,
      noctalia,
      whisper-dictation,
      home-manager,
      anifetch,
      wlctl,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit
            helium-browser
            noctalia
            quickshell
            anifetch
            whisper-dictation
            wlctl
            ;
        };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = [ (import ./overlays/lockscreen-tools.nix { inherit inputs; }) ]; }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.isaac = import ./home.nix;
          }
        ];
      };
    };
}
