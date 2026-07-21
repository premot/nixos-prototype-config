{ ... }:
{
# Home Manager manages configuration for the existing NixOS user.
	home = {
		username = "prototype";
		homeDirectory = "/home/prototype";
		stateVersion = "25.05";
	};

	programs.home-manager.enable = true;

# Installs Foot for this user and starts `foot --server` as a systemd user
# service in the graphical session. Launch terminals with `footclient`.
	programs.foot = {
		enable = true;
		server.enable = true;
		settings.main = {
			font = "monospace:size=16";                                                                                                                                                                                       
		};
	};
}
