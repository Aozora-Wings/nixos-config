{ pkgs
, lib
, install-config
, stable
, ...
}:
let

  unstable = import <unstable> { config = { allowUnfree = true; }; };
  username = install-config.username;

in
{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = install-config.openssh.publicKey;
  };

  users.defaultUserShell = pkgs.bash;
  nix.settings.trusted-users = [ username ];
  nix.settings = {
    # enable flakes globally
    experimental-features = [ "nix-command" "flakes" ];

    substituters = [
      # cache mirror located in China
      # status: https://mirror.sjtu.edu.cn/
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      # status: https://mirrors.ustc.edu.cn/status/
      "https://mirrors.ustc.edu.cn/nix-channels/store"

      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    builders-use-substitutes = true;
  };
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };
  # Enable CUPS to print documents.
  security.pam.yubico =
    let
      yubicoSettings =
        if install-config.security.pam.enable then
          install-config.security.pam
        else
          {
            enable = false;
          };
    in
    yubicoSettings;
  security.pki = install-config.security.pki;
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-design-icons

      # normal fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji

      # nerdfonts
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];

    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" "Noto Color Emoji" ];
      sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
      monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  networking = {
    firewall.enable = false;
    hosts = install-config.hosts;
  };
  system.activationScripts.createPublicFolder-mpd =
    if install-config.mpd.enable then {
      text = ''
        mkdir -p /home/public/mpd/Playlists
        chmod 777 -R /home/public
        #mpd service needs this directory
        #chown mpd:audio /home/public/mpd
      '';
    } else {
      text = "";
    };
  #     system.activationScripts.createPublicFolder-hyprland = if install-config.hyprland.enable then {
  # text = ''
  #   mkdir -p /home/${username}/.config/hypr
  #   cp ./config/hyprland.conf /home/${username}/.config/hypr/hyprland.conf
  #   chmod 777 -R /home/${username}/.config/hypr
  # '';
  # } else {
  #   text = "";
  # };
  # security.wrappers.dotnet = {
  #   source = "${pkgs.dotnet-runtime_8}/bin/dotnet";
  #   owner = "root";
  #   group = "root";
  #   permissions = "4755";
  #   capabilities = "cap_net_bind_service=ep";
  # };
  environment.systemPackages = with pkgs; [
    nix-ld
    openssl
    git
    vim
    wget
    curl
    nginx
    # c-ares
    nano
    at-spi2-atk
    alacritty
    glibcLocales
    # yubico-pam
    # yubico-piv-tool
    # yubikey-manager
    # yubikey-personalization
    # yubioath-flutter
    pcsclite
    lshw
    dconf
    docker
    htop
    # security tools
    #unstable.kdePackages.kleopatra
    #(writeShellScriptBin "gpg1" "${gnupg}/bin/gpg $*")
    #(writeShellScriptBin "gpg" "${gnupg1}/bin/gpg $*")
    #yubioath-flutter
    alsa-utils
    alsa-oss
    #nerd-fonts
    nerd-font-patcher
    mpd
    strace
    dbus-glib
    flac
    freeglut
    # libjpeg
    # libpng
    # libpng12
    # libsamplerate
    # libmikmod
    # libtheora
    # libtiff
    pixman
    speex
    # SDL_image
    # SDL_ttf
    # SDL_mixer
    # SDL2_ttf
    # SDL2_mixer
    # libappindicator-gtk2
    # libdbusmenu-gtk2
    # libindicator-gtk2
    # libcaca
    # libcanberra
    # libgcrypt
    # libvpx
    # librsvg
    # xorg.libXft
    # libvdpau
    pango
    cairo
    atk
    gdk-pixbuf
    fontconfig
    freetype
    dbus
    alsa-lib
    expat
    # Needed for electron
    libdrm
    mesa
    libxkbcommon
    nss
    go
    ympd
    weston
  ];
  #     environment.variables = {
  #   NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
  #  # Required
  #     glib
  #     gtk2
  #     bzip2
  # # Verified games requirements
  #     xorg.libXt
  #     xorg.libXmu
  #     libogg
  #     libvorbis
  #     SDL
  #     SDL2_image
  #     glew110
  #     libidn
  #     tbb

  #     # Other things from runtime
  #     flac
  #     freeglut
  #     libjpeg
  #     libpng
  #     libpng12
  #     libsamplerate
  #     libmikmod
  #     libtheora
  #     libtiff
  #     pixman
  #     speex
  #     SDL_image
  #     SDL_ttf
  #     SDL_mixer
  #     SDL2_ttf
  #     SDL2_mixer
  #     libappindicator-gtk2
  #     libdbusmenu-gtk2
  #     libindicator-gtk2
  #     libcaca
  #     libcanberra
  #     libgcrypt
  #     libvpx
  #     librsvg
  #     xorg.libXft
  #     libvdpau
  #     gnome2.pango
  #     cairo
  #     atk
  #     gdk-pixbuf
  #     fontconfig
  #     freetype
  #     dbus
  #     alsaLib
  #     expat
  #     # Needed for electron
  #     libdrm
  #     mesa
  #     libxkbcommon
  #   ];
  #     };

  virtualisation.docker.enable = true;
  programs = {

    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableBrowserSocket = true;
      enableExtraSocket = true;
      #pinentryFlavor = "qt";
      settings = {
        log-file = "/home/public/gpg/gpg-agent.log";
        #disable-ccid = "";
      };
    };
  };
  services = {
    onlyoffice = {
      enable = false;
      enableExampleServer = true;
      examplePort = 9001;
    };
  };
}
