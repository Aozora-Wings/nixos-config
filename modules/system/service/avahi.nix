{ pkgs, lib, rpcSecretFile, hostName, unstable, stable, flakeSoftware, hyprlandConfigPath, ... }:
{
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
      };
    } // lib.optionalAttrs (hostName == "AozoraWings-GTX1660") {
    #domainName = "host";  # 将 mDNS 域改为 .host
    hostName = "xiaoya";  # 组合起来就是 xiaoya.host
    };
  };
}