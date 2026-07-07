# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{
  config,
  pkgs,
  lib,
  helium-browser,
  noctalia,
  quickshell,
  whisper-dictation,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # ── boot ───────────────────────────────────────────────────────────────────
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

  # ── nix ────────────────────────────────────────────────────────────────────
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
  # lets bun/npm-installed prebuilt binaries (esbuild, native addons, etc.) run
  programs.nix-ld.enable = true;
  # nix-index: command-not-found suggestions + `nix-locate` file search
  programs.nix-index.enable = true;

  # ── networking ─────────────────────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;

  # ── audio (pipewire) ─────────────────────────────────────────────────────
  # required for spotify-player, whisper-dictation mic input, notification sounds, Beeper calls, etc.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # ── graphics ─────────────────────────────────────────────────────────────
  # required for OpenGL/Vulkan (niri, ghostty's GL renderer, browsers, etc.)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ── fonts ────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans # Chinese/Japanese/Korean coverage (HK locale + Korean music)
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];

  # ── gtk app support (nautilus, xdg-desktop-portal-gtk, dconf-backed settings) ──
  programs.dconf.enable = true;
  services.gvfs.enable = true; # trash, network mounts, and file operations for nautilus

  # ── ydotool (used by whisper-dictation to simulate paste/typing) ──────────
  systemd.user.services.ydotool = {
    description = "ydotool daemon";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "on-failure";
    };
  };

  # ── wireshark (needs module for capture permissions, not just the package) ──
  programs.wireshark.enable = true;

  # ── localization ───────────────────────────────────────────────────────────
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

  # ── users ──────────────────────────────────────────────────────────────────
  users.users."isaac" = {
    isNormalUser = true;
    description = "Isaac Wong";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "wireshark"
    ]; # input: whisper-dictation/ydotool; wireshark: packet capture
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };

  # ── session environment ───────────────────────────────────────────────────
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    GTK_USE_PORTAL = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # ── desktop: niri + greetd + portals ──────────────────────────────────────
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
      niri = {
        default = lib.mkForce "gtk";
      };
      common = {
        default = lib.mkForce "gtk";
      };
    };
  };

  # ── shell: zsh + starship + zoxide ────────────────────────────────────────
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

  # ── dictation ───────────────────────────────────────────────────────────────
  systemd.user.services.whisper-dictation = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
  };

  # ── git ────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    config = {
      user.name = "isaacwong05";
      user.email = "isaacwong0510@gmail.com";
      init.defaultBranch = "main";
    };
  };
  # ── packages ───────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # cli — core
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

    # cli — modern replacements / viewers
    bat
    eza
    dust
    btop
    jq
    tldr
    hexyl
    xxd

    # archives
    unzip
    zip
    p7zip
    unrar
    xz

    # compilers / build
    gcc
    gnumake
    cmake
    gdb
    python3

    # security / pentest
    nmap

    # nix tooling
    nh # nicer rebuild wrapper (nh os switch)
    nix-output-monitor # prettier build output (nh uses it)
    nvd # diff generations — what changed each rebuild
    nix-tree # visualise dependency trees
    nixfmt # official Nix formatter
    statix # Nix linter (antipatterns)
    deadnix # find unused Nix code
    nixd # Nix language server (for nvim)
    nix-search-tv # fuzzy pkg/option finder
    nix-init # generate Nix packages from URLs (handy for MacTahoe etc.)

    # media
    mpv
    imv
    zathura

    # terminal + browser
    ghostty
    firefox

    # gui apps
    obsidian
    vicinae
    bitwarden-desktop
    beeper
    nautilus

    # audio / media control
    pwvucontrol
    playerctl
    brightnessctl

    # screen recording
    wf-recorder

    # gtk theming
    nwg-look
    glib

    # secrets / passwords
    bitwarden-cli

    # voice / transcription
    spotify-player
    whisper-cpp
    ydotool

    # screenshot / clipboard / notifications
    grim
    slurp
    wl-clipboard
    libnotify

    # theming
    bibata-cursors
    qt6Packages.qt6ct

    # shell tooling
    zoxide
    zsh-vi-mode
    zsh-completions

    # flake-based packages
    helium-browser.packages.${pkgs.system}.default
    noctalia.packages.${pkgs.system}.default
    quickshell.packages.${pkgs.system}.default
    whisper-dictation.packages.${pkgs.system}.default
  ];

  # ── optional programs (uncomment as needed) ───────────────────────────────
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  # services.openssh.enable = true;

  # ── system state version ──────────────────────────────────────────────────
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
