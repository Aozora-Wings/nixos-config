#def_ports.nix
{
  mpd = {
    api = 6600;
    http = "9000";
  };
  ympd = 9001;
  onlyoffice = 9002;
  code_server = 9003;
  webdav = 8080;
  WordPressSite = 11000;
  VaultWarden = 11001;
  jxbShoopAPI = 11002;
  jxbShoopSite = 11003;  # 前端映射端口
  jxbShoopApi = 11004;   # 后端API映射端口
  phpmyadmin = 11005;   # PHPMyAdmin映射端口
  jxbShoopFrontend = 8082;  # 可选：独立前端端口
  jxbShoopBackend = 8083;   # 可选：独立后端端口
  nps = 11006;
  nps_connect = 8024;
  nps_client = {
    xuye = {
    start = 9110;
    end = 9199;
};
  wt = {
      start = 9210;
      end = 9299;
  };
  };
}
