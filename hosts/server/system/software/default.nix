{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    ./clouddrive2.nix
  ];
  services = {
    clouddrive2 = {
      enable = true;
      mountPoints = [
        "/cloud/115open"
        "/cloud/ct-共享空间" # 整个路径用字符串
        "/cloud/ct-私人空间"
      ];
      #extraArgs = [ "--port" "8080" ]; # 示例参数
    };
  };
}
