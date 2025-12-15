{ lib
, pkgs
, catppuccin-bat
, config
, install-config
, unstable
, ...
}:

{
  xresources.properties = {
    "Xcursor.size" = install-config.display.size;
    "Xft.dpi" = install-config.display.dpi;
  };
  home.sessionVariables = {
    DISPLAY = ":0";
    PULSE_SERVER = "unix:/mnt/wslg/PulseServer";
    WAYLAND_DISPLAY = "wayland-0";
    XDG_RUNTIME_DIR = "/mnt/wslg/runtime-dir";

    # 额外的图形相关变量
    LIBVA_DRIVER_NAME = "nvidia";
    NVIDIA_DRIVER_CAPABILITIES = "all";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  home.packages = with pkgs; [
    home-manager
    #security
    xca
    # archives
    zip
    zx
    unzip
    p7zip

    # utils
    ripgrep
    yq-go # https://github.com/mikefarah/yq
    htop

    kdePackages.kleopatra
    #bitwarden-wrapped
    insomnia
    docker
    docker-compose
    socat
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
    "qq"
  ];
  programs = {


    git = {
      enable = true;
      userName = install-config.username;
      userEmail = install-config.useremail;
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
          export NIX_LD_LIBRARY_PATH="/home/wt/.nix-profile/lib"
          export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin:/home/wt/.nix-profile/bin"
          export XMODIFIERS="fcitx5"
          export GTK_IM_MODULE="fcitx5"
          export INPUT_METHOD="fcitx5"
          export QT_IM_MODULE="fcitx5"
          export SSH_AUTH_SOCK="/run/user/1000/gnupg/S.gpg-agent.ssh"
          (setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork SOCKET-CONNECT:40:0:x0000x33332222x02000000x00000000 >/dev/null 2>&1)
          export DISPLAY=:0
        export PULSE_SERVER=unix:/mnt/wslg/PulseServer
        export WAYLAND_DISPLAY=wayland-0
        export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
      
        # NVIDIA 相关变量
        export LIBVA_DRIVER_NAME=nvidia
        export NVIDIA_DRIVER_CAPABILITIES=all
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
      '';

      # TODO 设置一些别名方便使用，你可以根据自己的需要进行增删
      shellAliases = {
        k = "kubectl";
        urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
        urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
        xiaoya = "docker compose -f '/mnt/g/home/public/xiaoya/wsl.yml'";
      };
    };

    btop.enable = true; # replacement of htop/nmon
    eza.enable = true; # A modern replacement for ‘ls’
    jq.enable = true; # A lightweight and flexible command-line JSON processor
    ssh.enable = true;
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
    #syncthing.enable = true;

    # auto mount usb drives
    udiskie.enable = true;
  };
}
