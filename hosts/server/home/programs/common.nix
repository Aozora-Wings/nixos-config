{ lib
, pkgs
, catppuccin-bat
, config
, install-config
, unstable
, ...
}:
let

  unstable = import <unstable> { config = { allowUnfree = true; }; };
in
{
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
    firefox
  ];
  programs = {
    git = {
        enable = true;
        settings = {
          user = {
            name = install-config.username;
            email = install-config.useremail;
          };
        };
      };
   bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
eval "$(starship init bash)"
'';
      shellAliases = {
        nhsw = "nh os switch --impure";
      };
   };
  };
}
