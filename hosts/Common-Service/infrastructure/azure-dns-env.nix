{ config, lib, install-config, parseConfigFile, ... }:
let
  # 检查文件是否存在
  hasDecryptedSecret = builtins.pathExists "/run/agenix/azure-token";
  
  # 只有在文件存在时才解析
  azureToken = if hasDecryptedSecret then
    parseConfigFile "/run/agenix/azure-token"
  else {
    subscriptionId = "PLACEHOLDER";
    tenantId = "PLACEHOLDER";
    clientId = "PLACEHOLDER";
    clientSecret = "PLACEHOLDER";
  };
in
{
  # 为 ACME 服务创建环境变量文件
  environment.etc."acme/azure.env" = lib.mkIf hasDecryptedSecret {
    text = ''
      AZURE_SUBSCRIPTION_ID=${azureToken.subscriptionId}
      AZURE_TENANT_ID=${azureToken.tenantId}
      AZURE_CLIENT_ID=${azureToken.clientId}
      AZURE_CLIENT_SECRET=${azureToken.clientSecret}
    '';
    mode = "0400";  # 只读权限
  };
}