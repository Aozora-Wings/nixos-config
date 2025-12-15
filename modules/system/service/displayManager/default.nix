{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    imports = [
        ./sddm.nix
        ./dms-greeter.nix
    ];
}