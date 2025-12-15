{ pkgs
, install-config
, unstable
, ...
}: {
  home.packages = [ pkgs.gh ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = install-config.username;
        email = install-config.useremail;
      };
    };
  };
}
