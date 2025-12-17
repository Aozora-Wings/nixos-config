#service/default.nix
{ config, lib, pkgs, install-config, unstable, ... }: {
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true; # 提供 Docker 兼容的 socket
  #   dockerSocket.enable = true;
  # };
  myWebsitesAcme = {
    acceptTerms = true;
    defaultsEmail = install-config.useremail;
    server = "https://acme-v02.api.letsencrypt.org/directory"; # 指定使用Let's Encrypt生产服务器
  };
  imports = [
    ./lib/ports.nix
    ./infrastructure
    ./python
    # ./web-apps
    # ./network-services
    # ./static-sites
    #./web
  ];
}
