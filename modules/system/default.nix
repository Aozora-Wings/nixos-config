{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
let
  # Define commonly used variables
  username = install-config.username;
  rpcSecretFile = pkgs.writeTextFile {
    name = "aria2-rpc-secret";
    text = install-config.aria2Secret;
  };
  in
{
  _module.args = {
    inherit username rpcSecretFile;
  };
    imports = [
    # 通过函数传递变量
    ({ ... }: {
      imports = [
        ./users
        ./nix
        ./local_time
        ./file
        ./security
        ./fonts
        ./network
        ./pkgs
        ./service
        ./install
      ];
    })
  ];
  environment.variables.PATH = lib.mkForce "${pkgs.nss}/bin:$PATH";
  environment.variables = {
    #PATH = "${pkgs.nss}/bin:$PATH";
    GTK_IM_MODULE = "fcitx5";
    QT_IM_MODULE = "fcitx5";
    INPUT_METHOD = "fcitx5";
    SDL_IM_MODULE = "fcitx5";
  };

  # ============================= Virtualization =============================

  virtualisation = {
    # Waydroid for Android apps
    waydroid.enable = true;

    # Docker configuration
    docker.enable = false;

    # Hyper-V guest support
    hypervGuest.enable = true;

  };
}