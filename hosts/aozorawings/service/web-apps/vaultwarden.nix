{ config, lib, pkgs, install-config, unstable, mapPort, ... }:
let
  #port = import ../lib/ports.nix { inherit lib install-config; };
in
{
  myWebsites = {
    VaultWarden = {
      domain = "vw.app.qkzy.net";
      enableSSL = true;
      ociContainer = {
        enable = true;
        image = "vaultwarden/server";
        imageTag = "latest";
        ports = [
          (mapPort "VaultWarden" 80) # Web 界面
          "3012:3012" # WebSocket 端口
        ];
        environment = {
          DATABASE_URL = "mysql://bitwarden:JptR8jEaHy2dH2my@db-qkzy-net:3306/bitwarden";
          WEBSOCKET_ENABLED = "true"; # 如果需要 WebSocket 支持
          SIGNUPS_ALLOWED = "true"; # 是否允许注册
          ADMIN_TOKEN = "$argon2id$v=19$m=65540,t=3,p=4$SE9APwmr3blN9eorpvQ3hdAmhDRCHwrBf1qHA4FaIXE$WL2qy3+i0bMOkTuFbUjvd5O3T1iY8MKgr2ZoagrvVx0"; # 管理令牌
        };
        volumes = [ "vw_data:/data" ];
        joinCustomNetwork = true; # 加入同一网络
      };
    };
  };
}
