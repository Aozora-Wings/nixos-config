{ config, pkgs, install-config, unstable,hostName, ... }:
{
  imports = [
    <nixos-wsl/modules>
    ../../modules/system
    #../../modules/wsl.nix
    #./desktop.nix
    ./nvidia.nix
    ../Common-Service
    ./programs/niri
  ];
  wsl.enable = true;
  wsl.defaultUser = install-config.username;
  networking = {
    hostName = hostName;
    networkmanager = {
      enable = true;
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
