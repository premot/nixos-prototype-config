{
	description = "Disposable legacy-BIOS NixOS prototype";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
# nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

		disko = {
			url = "github:nix-community/disko/v1.12.0";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		evalbar = {
			url = "github:premot/evalbar";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs =
	inputs@{ nixpkgs, disko, home-manager, ... }:
	{
		nixosConfigurations.prototype = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";

			specialArgs = {
				inherit inputs;
			};
			modules = [
				disko.nixosModules.disko
					home-manager.nixosModules.home-manager
					./disk.nix
					./configuration.nix

					{
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.extraSpecialArgs = { inherit inputs; };
						home-manager.users.prototype = import ./home.nix;
					}
			];
		};
	};
}
