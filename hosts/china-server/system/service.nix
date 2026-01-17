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
  keyExists = builtins.pathExists "/home/${username}/.ssh/vw_wt";

in
{
  imports = [ ./service ];
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
  config = lib.mkIf keyExists {
    # 这里是完整的 age/secrets 配置
    age.identityPaths = [
      "/home/${username}/.ssh/vw_wt"
    ];
    
    age.secrets."azure-token" = {
      file = secrets_file.azure;
      owner = username;
    };
    
    age.secrets."web" = {
      file = secrets_file.web;
      owner = username;
    };
    
    # 其他依赖 age 的配置也可以放在这里
    some-other-service.config = {
      tokenFile = config.age.secrets."azure-token".path;
    };
  };

}
