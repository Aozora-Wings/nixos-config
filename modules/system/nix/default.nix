{ pkgs, lib,username, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{

  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
    "electron-25.9.0"
    "freeimage-unstable-2021-11-01"
  ];

  # Grant trusted users the right to specify additional substituters
  nix.settings.trusted-users = [ username ];

  # Nix configuration settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    
    # 修正 substituters（去掉重复和斜杠）
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    
    # 必须添加对应的公钥
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Automatic garbage collection to manage disk space
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}