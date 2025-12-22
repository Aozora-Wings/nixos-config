{ pkgs, lib, rpcSecretFile, hostName, unstable, stable, flakeSoftware, hyprlandConfigPath, ... }:{
    systemd.sockets = let
    ports = [ 2345 5678 ];
    mkSocket = port: {
      "ipv6-to-ipv4-${toString port}" = {
        enable = true;
        description = "IPv6 to IPv4 forwarding for port ${toString port}";
        listenStreams = [ 
          "[::]:${toString port}"  # IPv6监听
        ];
        socketConfig = {
          Accept = false;
          FreeBind = true;
          IPv6Only = false;
        };
      };
    };
  in lib.foldl' (acc: port: acc // mkSocket port) {} ports;

  systemd.services = let
    ports = [ 2345 5678 ];
    mkService = port: {
      "ipv6-to-ipv4-${toString port}" = {
        enable = true;
        description = "Forward IPv6 to IPv4 on port ${toString port}";
        requires = [ "ipv6-to-ipv4-${toString port}.socket" ];
        after = [ "network.target" "ipv6-to-ipv4-${toString port}.socket" ];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat TCP6-LISTEN:${toString port},fork,reuseaddr TCP4:127.0.0.1:${toString port}";
          Type = "simple";
          Restart = "always";
          RestartSec = 3;
        };
      };
    };
  in lib.foldl' (acc: port: acc // mkService port) {} ports;

  environment.etc."containers/policy.json" = {
    text = builtins.toJSON {
      default = [
        {
          type = "insecureAcceptAnything";
        }
      ];
      transports = {
        docker = {
          "docker.io" = [
            {
              type = "insecureAcceptAnything";
            }
          ];
          "registry-1.docker.io" = [
            {
              type = "insecureAcceptAnything";
            }
          ];
          "*" = [
            {
              type = "insecureAcceptAnything";
            }
          ];
        };
        "docker-daemon" = {
          "" = [
            {
              type = "insecureAcceptAnything";
            }
          ];
        };
      };
    };
  };
}