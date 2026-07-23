# GNOME-session application shortcuts.
#
# Add entries here for actions such as launchers. Unlike keyd mappings, these
# do not change what a physical key means outside the graphical session.
{ lib, pkgs, inputs, ... }:
let
  evalbar = inputs.evalbar.packages.${pkgs.stdenv.hostPlatform.system}.default;

  bindings = [
    {
      # Keep IDs stable: they identify the corresponding GNOME dconf path.
      id = "nixos-evalbar";
      name = "Nix package launcher";
      binding = "F12";
      command = "${evalbar}/bin/wofiprompt";
    }
  ];

  mediaKeysSchema = "org.gnome.settings-daemon.plugins.media-keys";
  customBindingSchema = "${mediaKeysSchema}.custom-keybinding";
  bindingPath = binding: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${binding.id}/";
  pathArguments = lib.concatMapStringsSep " " lib.escapeShellArg (map bindingPath bindings);

  bindingCommands = lib.concatMapStringsSep "\n" (binding:
    let
      schemaPath = "${customBindingSchema}:${bindingPath binding}";
    in
    ''
      gsettings set ${lib.escapeShellArg schemaPath} name ${lib.escapeShellArg binding.name}
      gsettings set ${lib.escapeShellArg schemaPath} command ${lib.escapeShellArg binding.command}
      gsettings set ${lib.escapeShellArg schemaPath} binding ${lib.escapeShellArg binding.binding}
    '') bindings;

  applyGnomeKeybindings = pkgs.writeShellApplication {
    name = "apply-gnome-keybindings";
    runtimeInputs = [ pkgs.glib pkgs.python3 ];
    text = ''
      # Preserve non-NixOS custom shortcuts, then add each managed binding path.
      binding_list="$(gsettings get ${mediaKeysSchema} custom-keybindings)"
      binding_list="$(python3 - "$binding_list" ${pathArguments} <<'PY'
      import ast
      import sys

      paths = ast.literal_eval(sys.argv[1])
      for path in sys.argv[2:]:
          if path not in paths:
              paths.append(path)
      print("[" + ", ".join(repr(path) for path in paths) + "]")
      PY
      )"
      gsettings set ${mediaKeysSchema} custom-keybindings "$binding_list"

      ${bindingCommands}
    '';
  };
in
{
  # The launcher is user-scoped. Its exact Nix store path is written into the
  # GNOME shortcut, so the desktop does not depend on an ambient PATH.
  home.packages = [ evalbar applyGnomeKeybindings ];

  # GSettings needs the GNOME session D-Bus. Re-apply the declarative entries
  # at login while preserving any unrelated custom shortcuts already in dconf.
  xdg.configFile."autostart/apply-gnome-keybindings.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Apply managed GNOME keybindings
    Comment=Install GNOME shortcuts declared in gnome-keybindings.nix
    Exec=${applyGnomeKeybindings}/bin/apply-gnome-keybindings
    OnlyShowIn=GNOME;
    X-GNOME-Autostart-enabled=true
    Terminal=false
  '';
}
