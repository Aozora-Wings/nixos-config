{ config, lib, ... }:

let
  inherit (lib) mkIf;
  
  anySSLEnabled = lib.any (cfg: cfg.enable && cfg.enableSSL) (lib.attrValues config.myWebsites);
in
{
  config = mkIf (config.myWebsites != {}) {
    networking.firewall = {
      allowedTCPPorts = 
        if anySSLEnabled then [ 80 443 ]
        else [ 80 ];
      
      # 新增功能：允许容器网络通信
      trustedInterfaces = [ "podman+" ];
      
      # 新增功能：允许内部容器通信
      extraCommands = ''
        iptables -A nixos-fw -i podman+ -j ACCEPT
        iptables -A nixos-fw -o podman+ -j ACCEPT
      '';
    };
  };
}