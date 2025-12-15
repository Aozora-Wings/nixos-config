#!/bin/sh
export run_type=normal
#sudo NIXPKGS_ALLOW_INSECURE=1 nixos-rebuild switch -v --flake $1 --impure --show-trace -j 10 --profile-name $2 --accept-flake-config --option substituters "https://mirror.sjtu.edu.cn/nix-channels/store"#
sudo NIXPKGS_ALLOW_INSECURE=1 nixos-rebuild switch -v --flake $1 --impure --show-trace -j 10 --accept-flake-config
