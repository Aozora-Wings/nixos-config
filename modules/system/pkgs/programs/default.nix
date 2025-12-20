{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    
    imports = [
        ./firefox.nix
        ./steam.nix
        ./gamescope.nix
        ./clash-verge.nix
        ./hyprland.nix
        ./niri
        ./gnupg.nix
        ./dconf.nix
        ./noctalia.nix
        ./vscode
        ./wechat.nix
    ];
}