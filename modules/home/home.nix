{ config, pkgs, lib, install-config, unstable, stable, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.nur.overlays.default
  ];
  nixpkgs.config.allowUnfree = true;
  #  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #      "obsidian"
  #      "vscode"
  #    ];
  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
  ];

  imports = [
    #    ./fcitx5
    #    ./i3
    ./programs
    ./rofi
    ./shell
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = install-config.username;
    homeDirectory = "/home/${install-config.username}";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
