{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
networking = {
    # Disable firewall (use with caution)
    firewall.enable = false;

    # Custom hosts configuration
    hosts = install-config.hosts;
};
}