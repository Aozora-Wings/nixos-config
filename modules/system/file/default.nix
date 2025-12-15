{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
      # Container registries configuration
  environment.etc."containers/registries.conf".text = lib.mkForce (''
    unqualified-search-registries = ["docker.io"]
  '' + lib.concatStrings (lib.mapAttrsToList
    (prefix: location: ''
      [[registry]]
      prefix = "${prefix}"
      location = "${location}"
      insecure = false
      blocked = false
    '')
    {
      "docker.io" = "v1o98k8rh462su.xuanyuan.run";
      "ghcr.io" = "v1o98k8rh462su-ghcr.xuanyuan.run";
      "quay.io" = "v1o98k8rh462su-quay.xuanyuan.run";
      "registry.k8s.io" = "v1o98k8rh462su-k8s.xuanyuan.run";
      "docker.elastic.co" = "v1o98k8rh462su-elastic.xuanyuan.run";
      "gcr.io" = "v1o98k8rh462su-gcr.xuanyuan.run";
      "nvcr.io" = "v1o98k8rh462su-nvcr.xuanyuan.run";
      "mcr.microsoft.com" = "v1o98k8rh462su-mcr.xuanyuan.run";
      "container-registry.oracle.com" = "v1o98k8rh462su-oracle.xuanyuan.run";
    }));

  # Docker daemon configuration
  environment.etc."docker/daemon.json".text = builtins.toJSON {
    "registry-mirrors" = [ "https://v1o98k8rh462su.xuanyuan.run" ];
    "insecure-registries" = [ ];
    "debug" = true;
    "log-level" = "info";
  };

  # Docker registry mirrors configuration
  environment.etc."docker/registry-mirrors.json".text = builtins.toJSON {
    "docker.io" = "v1o98k8rh462su.xuanyuan.run";
    "ghcr.io" = "v1o98k8rh462su-ghcr.xuanyuan.run";
    "quay.io" = "v1o98k8rh462su-quay.xuanyuan.run";
    "registry.k8s.io" = "v1o98k8rh462su-k8s.xuanyuan.run";
    "docker.elastic.co" = "v1o98k8rh462su-elastic.xuanyuan.run";
    "gcr.io" = "v1o98k8rh462su-gcr.xuanyuan.run";
    "nvcr.io" = "v1o98k8rh462su-nvcr.xuanyuan.run";
    "mcr.microsoft.com" = "v1o98k8rh462su-mcr.xuanyuan.run";
    "container-registry.oracle.com" = "v1o98k8rh462su-oracle.xuanyuan.run";
  };
    # Create public folder for MPD if enabled
  system.activationScripts.createPublicFolder-mpd =
    if install-config.mpd.enable then {
      text = ''
        mkdir -p /home/public/mpd/Playlists
        chmod 777 -R /home/public
      '';
    } else {
      text = "";
    };

  # Temporary files rules
  systemd.tmpfiles.rules = [
    "d /opt/todesk 0777 root root -"
    "d /opt/todesk/config 0777 root root -"
  ];

}