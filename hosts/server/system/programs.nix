{ pkgs
, lib
, install-config
, unstable
, stable
,...
}:
let

  username = install-config.username;
  hyprlandConfigPath = "${toString ../config/hyprland.conf}";

in
{
  # virtualisation = {
  #   docker = {
  #     enable = true;
  #     #extraOptions = "--registry-mirror=https://docker.fxxk.dedyn.io";
  #     #extraOptions = "--default-runtime=nvidia";
  #     #enableNvidia = true;
  #     daemon.settings = {
  #       "registry-mirrors" = [ "https://v1o98k8rh462su.xuanyuan.run" ];
  #       "insecure-registries" = [ ];
  #       "debug" = false;
  #       "log-level" = "info";
  #       "ipv6" = true;
  #     };
  #   };
  #   hypervGuest.enable = true;
  # };
  systemd.services = {
    # docker = {
    #   environment = {
    #     HTTP_PROXY = install-config.docker.httpProxy;
    #     HTTPS_PROXY = install-config.docker.httpsProxy;
    #     NO_PROXY = "localhost,127.0.0.1,.docker.internal";
    #   };
    # };
  };
  environment.systemPackages = with pkgs; [
    jq
    lsof
    openssl
    git
    vim
    wget
    curl
    nano
    nginx
    docker
    docker-compose
    wayland
    wayland-utils
    code-server
    stable.kodi-wayland
    vscode
    clash-verge-rev
    htop
    mariadb.client
    python3
  ];
  programs = {
        nh = {
      enable = true;
      flake = "/developer/nixos-config";
    };
  };
  iports = [
    ./vscode
  ];
}
