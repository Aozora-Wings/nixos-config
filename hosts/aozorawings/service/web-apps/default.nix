#service/default.nix
{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    #./wordpress.nix
    #./vaultwarden.nix
    #./jxbshop.nix
    #./teamspeak.nix
    #./vlmcsd.nix
    ./clouddrive.nix
  ];
}
