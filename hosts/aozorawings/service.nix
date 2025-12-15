{ pkgs
, lib
, ...
}:
let

  unstable = import <unstable> { config = { allowUnfree = true; }; };
  username = install-config.username;
  hyprlandConfigPath = "${toString ../config/hyprland.conf}";

in
{
  import = [
    ./service
  ];
  services = {
    xserver = {
      enable = true;

      # 启用 libinput 触摸板支持
      libinput = {
        enable = true;
        touchpad = {
          enable = true;
          naturalScrolling = true;
          disableWhileTyping = true;
          tapping = true;
          tappingDragLock = false;
          accelProfile = "adaptive";
          clickMethod = "clickfinger"; # 使用 clickfinger 而不是 button-areas
          scrollMethod = "twofinger";
          horizontalScrolling = true;
        };
      };
    };
  };

}
