{ config, pkgs, install-config, unstable, ... }: {
  environment.systemPackages = with pkgs; [
    xwayland
    kdePackages.plasma-desktop
  ];
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
}
