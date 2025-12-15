{ config, lib, pkgs, ... }:

let
  cfg = config.services.azure-ddns;
  scriptPath = ./azure_ddns_client.py;
in
with lib; {
  options.services.azure-ddns = {
    enable = mkEnableOption "Azure DDNS client";

    user = mkOption {
      type = types.str;
      default = "azure-ddns";
      description = "User to run the Azure DDNS service";
    };

    recordSet = mkOption {
      type = types.str;
      default = "service";
      description = "DNS record set name";
    };

    subscriptionId = mkOption {
      type = types.str;
      description = "Azure subscription ID";
    };

    resourceGroup = mkOption {
      type = types.str;
      default = "dns";
      description = "Azure resource group";
    };
    clientId = mkOption {
      type = types.str;
      default = "dns";
      description = "Azure resource group";
    };
    tenantId = mkOption {
      type = types.str;
      default = "dns";
      description = "Azure resource group";
    };
    clientSecret = mkOption {
      type = types.str;
      default = "dns";
      description = "Azure resource group";
    };

    dnsZone = mkOption {
      type = types.str;
      description = "DNS zone name";
    };

    recordType = mkOption {
      type = types.enum [ "A" "AAAA" ];
      default = "AAAA";
      description = "Record type (A for IPv4, AAAA for IPv6)";
    };

    interval = mkOption {
      type = types.int;
      default = 300;
      description = "Check interval in seconds";
    };

    azureConfigDir = mkOption {
      type = types.str;
      default = "~/.azure";
      description = "Azure configuration directory";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.azure-ddns = {
      description = "Azure DDNS Client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      path = [
        pkgs.azure-cli
        pkgs.python3
      ];

      script =
        let
          pythonWithPkgs = pkgs.python3.withPackages (ps: [
            ps.requests
            ps.azure-identity
            ps.azure-mgmt-dns
            ps.netifaces
          ]);
        in
        ''
          ${pythonWithPkgs}/bin/python ${scriptPath}
        '';

      serviceConfig = {
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW";
        PrivateNetwork = false;
        BindReadOnlyPaths = [
          "/proc/net"
          "/sys/class/net"
        ];
        StandardOutput = "journal+console";
        StandardError = "journal+console";
        User = cfg.user;
        Group = "users";
        Environment = [
          "PYTHONUNBUFFERED=1"
          "HOME=/home/${cfg.user}"
          "PATH=${pkgs.azure-cli}/bin:${pkgs.python3}/bin"
          "AZURE_CONFIG_DIR=/home/${cfg.user}/.azure"
          "NETIFACES_NO_LOOPBACK=1"

      "AZURE_SUBSCRIPTION_ID=${cfg.subscriptionId}"
      "AZURE_RESOURCE_GROUP=${cfg.resourceGroup}"
      "AZURE_DNS_ZONE=${cfg.dnsZone}"
      "AZURE_RECORD_SET=${cfg.recordSet}"
      "AZURE_RECORD_TYPE=${cfg.recordType}"
      "AZURE_CHECK_INTERVAL=${toString cfg.interval}"
      "AZURE_CLIENT_ID=${cfg.clientId}"
      "AZURE_CLIENT_SECRET=${cfg.clientSecret}"
      "AZURE_TENANT_ID=${cfg.tenantId}"
        ];
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    users.users.${cfg.user} = mkIf (cfg.user == "azure-ddns") {
      isSystemUser = true;
      group = "users";
      home = "/home/${cfg.user}";
      createHome = true;
    };
  };
}
