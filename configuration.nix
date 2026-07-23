{ inputs, pkgs, ... }:
let
	# Multilingual Whisper base model.  It is fetched reproducibly during the
	# Nix build, so transcription never downloads a model at run time.
	whisperModel = pkgs.fetchurl {
		url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
		hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
	};

	# Record from PipeWire's selected microphone, then transcribe locally.
	whisperMic = pkgs.writeShellApplication {
		name = "whisper-mic";
		runtimeInputs = [ pkgs.coreutils pkgs.pipewire pkgs.whisper-cpp ];
		text = ''
			if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && ! [[ "$1" =~ ^[1-9][0-9]*$ ]]; }; then
				echo "Usage: whisper-mic [recording-seconds]" >&2
				exit 2
			fi

			seconds="''${1:-10}"
			audio="$(mktemp --suffix=.wav)"
			trap 'rm -f "$audio"' EXIT

			echo "Recording from the default microphone for $seconds second(s)..." >&2
			pw-record --media-category Capture --media-role Communication \
				--rate 16000 --channels 1 --format s16 "$audio" &
			recorder=$!
			sleep "$seconds"
			kill -INT "$recorder" 2>/dev/null || true
			wait "$recorder" || true

			if [ ! -s "$audio" ]; then
				echo "No audio was captured. Select or unmute a microphone in GNOME Sound settings." >&2
				exit 1
			fi

			exec whisper-cli --model ${whisperModel} --language auto --no-timestamps "$audio"
		'';
	};
in
{

programs.nix-ld.enable = true;
# todo clean up and use
#{
#  imports = [
#    ./hardware-configuration.nix
#  ];
#
#  # ...
#}
# instead
	boot.initrd.availableKernelModules = [
		"ahci"
			"sd_mod"
	];

#  boot.loader.grub = {
#    enable = true;
#    efiSupport = false;
#    # disk.nix supplies the GRUB install device from its BIOS boot partition.
#  };

	time.timeZone = "Europe/Helsinki";
	hardware.enableRedistributableFirmware = true;
	virtualisation = {
		libvirtd.enable = true;
		podman.enable = true;
	};



	boot.loader = {
		systemd-boot.enable = true;
		efi.canTouchEfiVariables = true ;
	};

	networking = {
		hostName = "nixos-prototype";
		networkmanager.enable = true;
	};

	services.openssh = {
		enable = true;
		settings = {
			PasswordAuthentication = true;
			KbdInteractiveAuthentication = false;
			PermitRootLogin = "no";
		};
	};

	users.users.prototype = {
		isNormalUser = true;
		description = "Prototype Administrator";
		initialPassword = "nixos";
		extraGroups = [ "wheel" "dialout" ];
	};
	security.sudo.wheelNeedsPassword = false;

	services.xserver.enable = true;
# services.xserver.displayManager.lightdm.enable = true;
# services.xserver.desktopManager.xfce.enable = true;
# services.displayManager.defaultSession = "xfce";
	services.desktopManager.gnome.enable = true;
	services.displayManager.gdm.enable = true;
	services.displayManager.defaultSession = "gnome";
	services.displayManager.autoLogin = {
		enable = true;
		user = "prototype";
	};

	programs = {
		gnome-terminal.enable = true;
	};

# Use separate autostart entries so the Neovim command only belongs to the
# second terminal. A command at the end of one multi-window invocation can
# otherwise be applied to both windows by GNOME Terminal.

	environment.etc."xdg/autostart/nixos-configuration-shell.desktop".text = ''
		[Desktop Entry]
		Type=Application
			Name=NixOS configuration shell
			Comment=Open a shell in the NixOS configuration directory
			Exec=gnome-terminal --window --working-directory=/home/prototype/nixos-prototype-config
			OnlyShowIn=GNOME;
	X-GNOME-Autostart-enabled=true
		Terminal=false
		'';

	environment.etc."xdg/autostart/nixos-configuration-editor.desktop".text = ''
		[Desktop Entry]
		Type=Application
			Name=NixOS configuration editor
			Comment=Edit the NixOS configuration in Neovim
			Exec=gnome-terminal --window --working-directory=/home/prototype/nixos-prototype-config -- nvim configuration.nix
			OnlyShowIn=GNOME;
	X-GNOME-Autostart-enabled=true
		Terminal=false
		'';

	security.rtkit.enable = true;

	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
	};

	environment.systemPackages = with pkgs; [
		inputs.evalbar.packages.${pkgs.system}.default
		git
		zoxide
		neovim
		avrdude
		gnumake
		arduino-cli
		picocom
		pkgsCross.avr.buildPackages.gcc
		nodejs_22
		fzf
		ripgrep
		fd
		python3
		uv
		gh
		unzip
		foot
		btop
		htop
		tree
		wofi
		bemenu
		emacs
		chromium
		tldr
		fish
		cargo
		rustc
		gcc
		clang
		jdk25
		curl
		distrobox
		virt-manager
		virt-viewer
		libvirt
		qemu
		# Offline speech recognition and a PipeWire microphone recorder wrapper.
		whisper-cpp
		whisperMic
		];

	services.keyd = {
		enable = true;

		keyboards.default = {
			ids = [ "*" ];
			settings.main = {
				capslock = "leftcontrol";
				leftcontrol = "esc";
				rightcontrol = "esc"; # Remove this line if you want Right Ctrl unchanged.
				rightalt = "backspace";
				# Print Screen/SysRq becomes Tab; the grave key always produces tilde.
				print = "tab";
				sysrq = "tab";
				grave = "S-grave";
			};
		};
	};

	nix.settings.experimental-features = [
		"nix-command"
			"flakes"
	];

	system.stateVersion = "25.05";
}
