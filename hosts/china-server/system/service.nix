{ pkgs
, lib
, install-config
, unstable
, secrets_file
, config
, ...
}:
let

  username = install-config.username;
  hyprlandConfigPath = "${toString ../config/hyprland.conf}";
  mkAgeConfig = lib.mkIf (builtins.pathExists "/home/${username}/.ssh/vw_wt");

in
{
  imports = [
     ./service
     (mkAgeConfig ./age-secrets.nix)
      ];
  services = {
    code-server = {
      enable = true;
      auth = "password";
      hashedPassword = install-config.code-server.password;
      port = install-config.def_ports.code_server;
      user = install-config.username;
    };
    #    displayManager = {
    #      sddm = {
    #        enable = true;
    #        wayland.enable = true;
    #      };
    #    };
    #    desktopManager = {
    #      plasma6.enable = true;
    #    };

    openssh = {
      #      enable = true;
      settings = {
        #        X11Forwarding = true;
        #        PermitRootLogin = "no"; # disable root login
        PasswordAuthentication = false; # disable password login
        PubkeyAuthentication = true;
      };
      #      openFirewall = true;
    };
    # xserver={
    #     videoDrivers = ["nvidia"];
    # }
  };


}
