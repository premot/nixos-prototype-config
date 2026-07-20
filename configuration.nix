{ pkgs, ... }:
{
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
    extraGroups = [ "wheel" ];
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

  security.rtkit.enable = true;

services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
};


  environment.systemPackages = with pkgs; [
    git
    neovim
    nodejs_22
    fzf
    ripgrep
    fd
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
