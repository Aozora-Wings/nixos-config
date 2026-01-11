{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
      fonts = {
    packages = with pkgs; [
      # Icon fonts
      material-design-icons

      # Normal fonts
      noto-fonts
      noto-fonts-color-emoji

      # Nerd fonts for development
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono

      # Symbol and special fonts
      corefonts
      vista-fonts
      symbola
      unifont

      # Mathematical formula fonts
      stix-otf
      lmmath
      tex-gyre-math.bonum
      tex-gyre-math.pagella
      tex-gyre-math.schola
      tex-gyre-math.termes
    ];

    # Use only user-defined fonts, not default ones
    enableDefaultPackages = false;

    # Font configuration defaults
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" "Noto Color Emoji" ];
      sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
      monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  imports = [ ./monolisa-dev.nix ];
}