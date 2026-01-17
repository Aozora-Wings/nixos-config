#service/default.nix
{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    ./CodeSite.nix
    ./ConnectxuyeVWSite.nix
    ./DefaultAppSite.nix
    ./pan.nix
    #./clouddrive.nix
  ];
}
