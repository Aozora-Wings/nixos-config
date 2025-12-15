{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
          hardware = {
    # Bluetooth support
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    # NVIDIA container toolkit
    nvidia-container-toolkit.enable = true;
  };
    services = {
  
  logind.settings = {
    Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
      # 其他电源相关设置
      HandlePowerKey = "poweroff";
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
      IdleAction = "ignore";
    };
  };
        };

  boot.kernelModules = [ "uinput" ];
}