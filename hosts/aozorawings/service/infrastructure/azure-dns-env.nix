{ config, lib,install-config, ... }:
{
  # 为ACME服务创建环境变量文件
  environment.etc."acme/azure.env".text = ''
    AZURE_SUBSCRIPTION_ID=${install-config.AzureToken.subscriptionId}
    AZURE_TENANT_ID=${install-config.AzureToken.tenantId}
    AZURE_CLIENT_ID=${install-config.AzureToken.clientId}
    AZURE_CLIENT_SECRET=${install-config.AzureToken.clientSecret}
  '';
}