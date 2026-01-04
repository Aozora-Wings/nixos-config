{ pkgs, lib, username, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "docker" "input" "uinput" "shared" ];
    openssh.authorizedKeys.keys = install-config.openssh.publicKey;
    shell = pkgs.nushell;
};
  users.groups.shared = {};
}