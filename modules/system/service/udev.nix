{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
  udev = {
    extraRules = ''
    # uinput 设备权限
    KERNEL=="uinput", GROUP="input", MODE="0660"
    # 可选：其他输入设备权限
    KERNEL=="event*", GROUP="input", MODE="0660"
  '';
  packages = with pkgs; [
    steam-unwrapped  # Steam 设备
    # 其他你实际需要的设备规则
  ];
        
        };

  };
}