{ lib
, pkgs
, catppuccin-bat
, config
, install-config
, unstable
, ...
}: {
  home.packages = with pkgs; [
    #bilibili download tool
    yutto
  ];
}
