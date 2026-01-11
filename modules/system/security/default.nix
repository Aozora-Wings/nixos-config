{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, secrets_file ,... }:
let
  hasHomepath = builtins.pathExists "/home/${install-config.username}";
in
{
      security = {
    # Real-time kit for audio processing
    rtkit.enable = true;

    # Public Key Infrastructure
    pki = install-config.security.pki;

    # PolicyKit for privilege escalation
    polkit.enable = true;

    # Yubico PAM configuration (conditional)
    pam.yubico =
      if install-config.security.pam.enable then
        install-config.security.pam
      else {
        enable = false;
      };
  };
  age =lib.mkIf hasHomepath  {
      identityPaths = [
    /home/${install-config.username}/.ssh/vw_wt
  ];
    secrets."azure-token" = {
      file = secrets_file.azure;
      owner = install-config.username;
    };
    # secrets."MonoLisa-Normal" = {
    #   file = secrets_file.MonoLisaVariableNormal;
    #   owner = install-config.username;
    # };
    # secrets."MonoLisa-Italic" = {
    #   file = secrets_file.MonoLisaVariableItalic;
    #   owner = install-config.username;
    # };
  };
    home-manager.extraSpecialArgs = {
    monolisaItalicPath = "/run/agenix/MonoLisa-Italic";
    monolisaNormalPath = "/run/agenix/MonoLisa-Normal";
  };
}