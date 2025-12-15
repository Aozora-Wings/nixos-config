{ config, lib, pkgs, install-config, unstable, hostName, parseConfigFile,... }:
let

  azureToken = parseConfigFile "/run/agenix/azure-token";
  hasDecryptedSecret = builtins.pathExists "/run/agenix/azure-token";
in
{
  
  imports = [ ./Azure-ddns ];
  
  services.azure-ddns = lib.mkIf hasDecryptedSecret  {
    enable = true;
    user = "${install-config.username}";
    recordSet = "${hostName}";
    subscriptionId = azureToken.subscriptionId;
    resourceGroup = "dns";
    dnsZone = "qkzy.net";
    recordType = "AAAA";
    tenantId = azureToken.tenantId;
    clientId = azureToken.clientId;
    clientSecret = azureToken.clientSecret;
    interval = 300;
  };
}