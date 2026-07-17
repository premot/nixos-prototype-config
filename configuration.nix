{ pkgs, ... }:
{
  boot.initrd.availableKernelModules = [
    "ahci"
    "sd_mod"
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    # disk.nix supplies the GRUB install device from its BIOS boot partition.
  };

  networking = {
    hostName = "nixos-prototype";
    networkmanager.enable = true;
  };

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.displayManager.defaultSession = "xfce";

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

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
