{ pkgs
, lib
, install-config
, unstable
, secrets_file
, ...
}:
let

  username = install-config.username;
  hyprlandConfigPath = "${toString ../config/hyprland.conf}";

in
{
  # imports = [ ./service ];
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
  age = {
      identityPaths = [
    /home/${install-config.username}/.ssh/vw_wt
  ];
    secrets."azure-token" = {
      file = secrets_file.azure;
      owner = install-config.username;
    };
    secrets."web" = {
      file = secrets_file.web;
      owner = install-config.username;
    };
  };

}
