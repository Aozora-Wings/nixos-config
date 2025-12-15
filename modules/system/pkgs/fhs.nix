{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
let
  baseLibraries = with pkgs; [
    zlib
    zstd
    stdenv.cc.cc
    curl
    openssl
    attr
    libssh
    bzip2
    libxml2
    acl
    libsodium
    util-linux
    xz
    systemd
  ];
  myExtraLibraries = with pkgs; [
    glibc
    nss
    libunwind
  ];
in
{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = baseLibraries ++ myExtraLibraries;
}