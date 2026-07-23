#!/usr/bin/env bash
#the users personal convenience script
set -Eeuo pipefail
nix flake check "path:$PWD"
sudo nixos-rebuild test --flake "path:$PWD#prototype"
sudo nixos-rebuild switch --flake "path:$PWD#prototype"
