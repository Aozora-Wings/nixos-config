{ config, lib, pkgs, install-config, unstable,mySoftware, ... }:

# let
#   mySoftware = builtins.fetchGit {
#     #url = "git@ssh.dev.azure.com:v3/wt-qkzy/my-nixos-app/my-nixos-app";
#     url = "https://dev.azure.com/wt-ives/my-nixos-app/_git/my-nixos-app/";
#     ref = "main";
#     #rev = "0";
#     allRefs = true;
#   };
# in
{
  nixpkgs.overlays = import (mySoftware + "/overlays.nix");
  home.packages = with pkgs; [
    #microsoft-edge-dev
    #qq-my
    SteamTools-my
    pc115-my
    #verysync-my
    #wallpaperengine-steam
  ];

}
