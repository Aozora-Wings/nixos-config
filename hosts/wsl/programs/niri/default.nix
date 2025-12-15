{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    programs.niri.enable = true;
environment.systemPackages = with pkgs; [
   fuzzel
   alacritty
   bibata-cursors
   xwayland-satellite
   kitty
   helix
   cmatrix
   yazi
   waybar
  ];

  virtualisation.libvirtd = {
    enable = true;
   # 启用 virtiofsd 支持，这会自动处理 qemu 依赖
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
  };
  services.flatpak.enable = true;
programs.virt-manager.enable = true;
environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";  
  };
  imports = [
    ./virtualization.nix
  ];
}
