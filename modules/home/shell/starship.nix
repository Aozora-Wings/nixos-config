{ config, pkgs, install-config, ... }:
{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = install-config.starship;

}
