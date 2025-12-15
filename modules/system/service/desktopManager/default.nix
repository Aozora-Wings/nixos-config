{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    imports = [
        ./plasma6.nix
    ];
}