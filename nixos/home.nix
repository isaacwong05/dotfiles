{ pkgs, ... }:
{
  home.username = "isaac";
  home.homeDirectory = "/home/isaac";
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.swaylock-plugin
    pkgs.windowtolayer
    pkgs.lavat
  ];

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "swaylock-plugin --command-each 'windowtolayer ghostty -e lavat -g -c FFFFFF -G'";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "swaylock-plugin --command-each 'windowtolayer ghostty -e lavat -g -c FFFFFF -G'";
      }
    ];
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Blue-Dark";
      package = pkgs.catppuccin-gtk;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
}
