# ports.nix
{ lib, install-config, ... }:

let
  defaultPorts = {
    jxbShoopSite = 11003;
    jxbShoopApi = 11004;
    phpmyadmin = 11005;
    jxbShoopFrontend = 8082;
    jxbShoopBackend = 8083;
    WordPressSite = 80;
    VaultWarden = 80;
    nps = 8080;
    nps_connect = 8024;
  };

  getPort = service:
    let
      port = if install-config.def_ports ? ${service} then install-config.def_ports.${service} else defaultPorts.${service};
    in
    port;

  mapPort = (service: containerPort:
    "${toString (getPort service)}:${toString containerPort}"
  );

  npsPorts = lib.flatten (lib.mapAttrsToList
    (name: clientConfig:
      lib.range clientConfig.start clientConfig.end
    )
    install-config.def_ports.nps_client);
in
{
  _module.args = {
    inherit getPort mapPort npsPorts;
  };
}
