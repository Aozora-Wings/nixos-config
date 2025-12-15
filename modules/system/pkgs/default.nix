{ inputs,pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    imports = [
      ./programs
      ./fhs.nix
    ];
      environment.systemPackages = with pkgs; [
    # System utilities
    lsof
    openssl
    git
    vim
    wget
    curl
    nginx
    c-ares
    nano
    ntfs3g

    # Network tools
    clash-meta
    #clash-verge-rev
    shadowsocks-rust
    shadowsocks-v2ray-plugin

    # Development tools
    glibcLocales
    go
    dotnet-runtime
    code-server

    # Hardware tools
    at-spi2-core
    lshw
    dconf
    pciutils
    usbutils
    dmidecode
    hwinfo

    # Yubikey tools
    yubico-pam
    yubico-piv-tool
    yubikey-manager
    yubikey-personalization
    yubioath-flutter
    pcsclite

    # Container tools
    docker
    docker-compose

    # System monitoring
    htop
    strace

    # Graphics and display
    alacritty
    wayland
    wayland-utils
    efibootmgr
    mesa
    vulkan-tools
    nss
    mesa-demos
    libva-utils

    # Audio
    alsa-utils
    alsa-oss
    mpd
    flac

    # Desktop environment components
    dbus-glib
    freeglut
    xorg.libXft
    libvdpau
    pango
    cairo
    atk
    gdk-pixbuf
    fontconfig
    freetype
    dbus
    alsa-lib
    expat

    # Font tools
    nerd-font-patcher

    # Wayland compositor and utilities
    weston
    waybar
    mako
    hyprpaper
    kdePackages.dolphin
    grim
    wofi
    slurp
    swappy
    xclip

    # Desktop applications
    gparted
    unstable.kdePackages.kleopatra
    stable.kodi-wayland

    # Desktop utilities
    desktop-file-utils
    kmscon
    numlockx
    #netease-music-electron
    #flakeSoftware.connecttool-qt
    podman
    #inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    wechat
  ];
}