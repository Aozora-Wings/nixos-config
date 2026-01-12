{ lib
, pkgs
, catppuccin-bat
, config
, install-config
, unstable
, stable
, ...
}:
let

  steamWithFcitx = pkgs.steam.override {
    extraEnv = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };
  };

niriConfig = builtins.readFile ./niri-config.kdl;
waybarConfig = builtins.readFile ./waybar-config;
  # fixedBitwarden = pkgs.bitwarden-desktop.overrideAttrs (finalAttrs: prevAttrs: {
  #   installPhase = prevAttrs.installPhase + ''
  #     # 重新创建包装脚本，直接设置 Wayland 参数
  #     rm -f "$out/bin/bitwarden"
  #     makeWrapper '${lib.getExe pkgs.electron_37}' "$out/bin/bitwarden" \
  #       --add-flags $out/opt/Bitwarden/resources/app.asar \
  #       --add-flags "--ozone-platform-hint=auto" \
  #       --add-flags "--enable-features=WaylandWindowDecorations" \
  #       --set ELECTRON_OZONE_PLATFORM_HINT wayland \
  #       --set NIXOS_OZONE_WL 1 \
  #       --set-default ELECTRON_IS_DEV 0 \
  #       --inherit-argv0
  #   '';
  # });

in
{
  xresources.properties = {
    "Xcursor.size" = install-config.display.size;
    "Xft.dpi" = install-config.display.dpi;
  };
  home.packages = with pkgs; [
    home-manager
    #security
    xca
    # archives
    zip
    stable.zx
    unzip
    p7zip
    opensc
    # utils
    ripgrep
    yq-go # https://github.com/mikefarah/yq
    htop

    # misc
    libnotify
    wineWowPackages.wayland
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    kdePackages.kleopatra
    #fixedBitwarden
    bitwarden-desktop
    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # productivity
    obsidian

    # IDE
    insomnia
    nixpkgs-fmt
    #vscode-extensions.b4dm4n.vscode-nixpkgs-fmt
    # cloud native

    kubectl

    python3
    nodePackages.npm
    nodePackages.pnpm
    yarn

    starship
    # db related
    #dbeaver-bin
    mycli
    pgcli

    #steam
    #steamPackages.steam
    steam-run
    gnupg1
    microsoft-edge
    kdePackages.plasma-browser-integration
    #microsoft-edge-beta
    #microsoft-edge
    #teams
    yutto
    #bilibili
    unstable.qq
    smartmontools
    unrar
    stable.virtualbox
    motrix
    mktorrent
    #lmms
    todesk
    # AI tools
    upscayl

    #teamspeak_client
    # java runtime
    # zulu8
    zulu11
    # zulu17
    #komorebi

    linux-wallpaperengine
    kdePackages.wallpaper-engine-plugin
    anime4k
    bilibili
    moonlight-qt
    azure-cli
    unstable.retroarch-full
    unstable.wayland-bongocat
    rofi
    rofi-emoji # 表情符号插件
    swww
    wpsoffice-cn
    qqmusic
    netease-cloud-music-gtk
    ariang
    #wechat
    strawberry
    feh
    polychromatic
    #steamWithFcitx
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
    "qq"
  ];


  programs = {

    nh = {
      enable = true;
      clean.enable = true;
      flake = install-config.root;
    };
    obs-studio = {
      enable = true;
    };
    ssh = {
      enable = true;
      matchBlocks = {
        "*" = {
          identitiesOnly = false;
          forwardAgent = true;
          serverAliveInterval = 60;
          #  identityAgent = "/run/user/1000/gnupg/S.gpg-agent.ssh";
          userKnownHostsFile = "~/.ssh/known_hosts";
          identityAgent = "/home/wt/.bitwarden-ssh-agent.sock";
        };
        "aozorawings" = {
          hostname = "aozorawings.local";
          user = "wt";
        };
        "aozorawings-gtx1660" = {
          hostname = "aozorawings-gtx1660.local";
          user = "wt";
        };
        "arch" = {
          hostname = "192.168.31.171";
          user = "wt";
          # 对于 YubiKey，通常不需要指定 identityFile
          # SSH 代理会自动提供可用的密钥
        };
        "azure-nixos" = {
          hostname = "vw.qkzy.net";
          user = "wt";
          # 对于 YubiKey，通常不需要指定 identityFile
          # SSH 代理会自动提供可用的密钥
        };
        "ssh.dev.azure.com" = {
          hostname = "ssh.dev.azure.com";
          user = "git";
          #identityFile = "~/.ssh/id_rsa";
          #identitiesOnly = true;
        };
      };

    };
    tmux = {
      enable = true;
      clock24 = true;
      keyMode = "vi";
      extraConfig = "mouse on";
    };

    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "catppuccin-mocha";
      };
      themes = {
        # https://raw.githubusercontent.com/catppuccin/bat/main/Catppuccin-mocha.tmTheme
        catppuccin-mocha = {
          src = ./themes;
          file = "Catppuccin_Mocha.tmTheme";
        };
      };
    };
    bash = {
      enable = true;
      enableCompletion = true;
      # TODO 在这里添加你的自定义 bashrc 内容
      # export SSH_AUTH_SOCK="/run/user/${toString uid}/gnupg/S.gpg-agent.ssh"
      bashrcExtra = ''
        # export $(kwalletd6 &)
        export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
        export XMODIFIERS="fcitx5"
        export GTK_IM_MODULE="fcitx5"
        export INPUT_METHOD="fcitx5"
        export QT_IM_MODULE="fcitx5"
        export SSH_AUTH_SOCK="/home/${install-config.username}/.bitwarden-ssh-agent.sock"
        if [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "xterm" ] || [ "$TERM" = "screen" ]; then
          PS1='\[\e]0;\u@\h: \w\a\]\u@\h:\w\$ '
      fi
      '';
      # export SSH_AUTH_SOCK="/run/user/1000/gnupg/S.gpg-agent.ssh"
      # TODO 设置一些别名方便使用，你可以根据自己的需要进行增删
      shellAliases = {
        k = "kubectl";
        urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
        urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
        nixup = "https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897 nix flake update";
        nhsw = "nh os switch --impure";
        nixdr = "nix-store --add";
      };
    };

    btop.enable = true; # replacement of htop/nmon
    eza.enable = true; # A modern replacement for ‘ls’
    jq.enable = true; # A lightweight and flexible command-line JSON processor
    #aria2.enable = true;

    skim = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "rg --files --hidden";
      changeDirWidgetOptions = [
        "--preview 'exa --icons --git --color always -T -L 3 {} | head -200'"
        "--exact"
      ];
    };
  };

  services = {
    syncthing.enable = true;

    # auto mount usb drives
    udiskie.enable = true;
  };

xdg.configFile."niri/config.kdl".text = niriConfig;
xdg.configFile."waybar/config".source = ./niri-waybar-config;
xdg.configFile."waybar/hypr/config".source = ./hypr-waybar-config;
}
