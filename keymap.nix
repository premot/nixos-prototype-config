# Physical keyboard translations. keyd runs below GNOME, Wayland, and TTYs,
# so only put changes to what a physical key *means* in this module.
#
# Application actions belong in gnome-keybindings.nix instead.
{ ... }:
{
  services.keyd = {
    enable = true;

    keyboards.default = {
      # Apply the physical layout consistently to every keyboard keyd recognizes.
      ids = [ "*" ];
      settings.main = {
        capslock = "leftcontrol";
        leftcontrol = "esc";
        rightcontrol = "esc";
        rightalt = "backspace";

        # This ThinkPad reports Print Screen as either of these Linux key names.
        print = "tab";
        sysrq = "tab";

        # The grave key emits its shifted form, tilde, even without Shift.
        grave = "S-grave";
      };
    };
  };
}
