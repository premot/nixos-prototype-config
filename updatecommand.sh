nix flake check "path:$PWD"
sudo nixos-rebuild test --flake "path:$PWD#prototype"
sudo nixos-rebuild switch --flake "path:$PWD#prototype"
