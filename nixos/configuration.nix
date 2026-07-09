{
  config,
  pkgs,
  lib,
  helium-browser,
  noctalia,
  quickshell,
  whisper-dictation,
  anifetch,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # boot
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.limine.maxGenerations = 5;
  boot.loader.limine.style.wallpapers = lib.mkForce [ ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.limine.extraConfig = ''
    timeout: 5
    remember_last_entry: no
    term_palette: 0f0f0f;e8e8e8;ffffff;f0f0f0;c8c8c8;e0e0e0;d8d8d8;f5f5f5
    term_palette_bright: 1a1a1a;ffffff;ffffff;ffffff;e8e8e8;f5f5f5;eeeeee;ffffff
    term_background: 0f0f0f
    term_foreground: f0f0f0
    term_background_bright: 1a1a1a
    term_foreground_bright: ffffff
    interface_branding_colour: ffffff
    interface_help_color: ffffff
    interface_help_color_bright: ffffff
  '';

  boot.loader.limine.extraEntries = ''
    /+Other systems and bootloaders
    //Windows Boot Manager
        comment: Windows 11 25H2
        protocol: efi_chainload
        image_path: guid(88F3BEF0-F939-4420-97C0-431E89278101):/efi/Microsoft/Boot/bootmgfw.efi
  '';

  # nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];
  programs.nix-ld.enable = true;
  programs.nix-index.enable = true;

  # networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];

  # gtk / portals
  programs.dconf.enable = true;
  services.gvfs.enable = true;

  systemd.user.services.ydotool = {
    description = "ydotool daemon";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "on-failure";
    };
  };

  programs.wireshark.enable = true;

  # localization
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_HK.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # users
  users.users."isaac" = {
    isNormalUser = true;
    description = "Isaac Wong";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "wireshark"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };

  # session env
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    GTK_USE_PORTAL = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # desktop
  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session.command = ''
      ${pkgs.tuigreet}/bin/tuigreet \
        --time \
        --time-format '%H:%M:%S | %a %d %b' \
        --remember \
        --remember-session \
        --asterisks \
        --theme 'border=white;text=white;prompt=white;time=white;action=lightgray;button=white;container=black;input=white' \
        --kb-command 1 \
        --kb-sessions 2 \
        --kb-power 3 \
        --cmd niri-session
    '';
  };

  security.polkit.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      niri.default = lib.mkForce "gtk";
      common.default = lib.mkForce "gtk";
    };
  };

  # shell
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
  };
  programs.starship.enable = true;
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # dictation
  systemd.user.services.whisper-dictation = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
  };

  # git
  programs.git = {
    enable = true;
    config = {
      user.name = "isaacwong05";
      user.email = "isaacwong0510@gmail.com";
      init.defaultBranch = "main";
    };
  };

  # packages
  environment.systemPackages = with pkgs; [
    # cli
    neovim
    git
    github-cli
    curl
    wget
    superfile
    lazygit
    fastfetch
    tree-sitter
    ripgrep
    fd
    fzf
    bun
    nodejs
    bat
    eza
    dust
    btop
    jq
    cmatrix
    tty-clock
    lavat
    tldr
    hexyl
    xxd
    unzip
    zip
    p7zip
    unrar
    xz
    (callPackage ./packages/tuxedo.nix { })

    # dev
    gcc
    gnumake
    cmake
    gdb
    python3
    nmap

    # nix tooling
    nh
    nix-output-monitor
    nvd
    nix-tree
    nixfmt
    statix
    deadnix
    nixd
    nix-search-tv
    nix-init

    # gui apps
    ghostty
    firefox
    obsidian
    vicinae
    bitwarden-desktop
    beeper
    nautilus

    # media
    mpv
    imv
    zathura
    spotify-player
    whisper-cpp
    pwvucontrol
    playerctl
    brightnessctl
    wf-recorder

    # desktop utilities
    grim
    slurp
    wl-clipboard
    libnotify
    nwg-look
    glib
    bibata-cursors
    qt6Packages.qt6ct
    ydotool
    bitwarden-cli
    zoxide
    zsh-vi-mode
    zsh-completions

    # flakes
    helium-browser.packages.${pkgs.system}.default
    noctalia.packages.${pkgs.system}.default
    quickshell.packages.${pkgs.system}.default
    whisper-dictation.packages.${pkgs.system}.default
    anifetch.packages.${pkgs.system}.default
  ];

  # system
  system.stateVersion = "26.05";
}
