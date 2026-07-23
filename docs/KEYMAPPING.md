# Keymapping

This host deliberately separates **physical-key translations** from
**desktop actions**. That keeps the configuration predictable as more custom
bindings are added.

| Layer | Source | Use it for | Scope |
| --- | --- | --- | --- |
| Physical keys | [`keymap.nix`](../keymap.nix) (`keyd`) | exchanging keys, changing a key's character, modifier behavior | every graphical session and TTY |
| GNOME actions | [`gnome-keybindings.nix`](../gnome-keybindings.nix) | launching programs and GNOME-only commands | `prototype`'s GNOME session |

Do not use a GNOME shortcut to change what a key *is*, and do not use keyd to
launch applications. For example, Print Screen → Tab belongs in `keymap.nix`;
F12 → the Nix package launcher belongs in `gnome-keybindings.nix`.

## Current mappings

### Physical keys

`keymap.nix` applies the following mappings to every keyboard keyd recognizes:

- Caps Lock → Left Control
- Left Control → Escape
- Right Control → Escape
- Right Alt → Backspace
- Print Screen and SysRq → Tab
- grave/backtick → tilde

The ThinkPad can identify its Print Screen key as either `print` or `sysrq`, so
both are mapped. Mapping SysRq also means `Alt` + Print Screen cannot be used
for Linux Magic SysRq commands.

### GNOME actions

- **F12** opens `wofiprompt`, the launcher supplied by the `evalbar` flake. It
  prompts for a Nix package name, then opens that package in Foot.

## Add a physical key mapping

Add a `key = "action";` entry under `services.keyd.keyboards.default.settings.main`
in `keymap.nix`. Keyd uses Linux key names, not the visible keycap labels. For
example:

```nix
settings.main = {
  f13 = "leftmeta";
  menu = "compose";
};
```

Find the actual key name with `sudo keyd monitor`. While keyd is running, that
shows keyd's translated events; stop keyd first only when you need to inspect
raw hardware events. The installed keyd documentation includes a recovery
chord: `Backspace` + `Escape` + `Enter` terminates keyd if a bad mapping makes
normal input unusable.

## Add a GNOME launcher/action

Add an entry to the `bindings` list in `gnome-keybindings.nix`:

```nix
{
  id = "nixos-my-tool";       # stable and unique; do not reuse an old ID
  name = "My tool";           # label shown by GNOME Settings
  binding = "F11";            # GNOME accelerator syntax
  command = "${pkgs.myTool}/bin/my-tool";
}
```

The module generates an `apply-gnome-keybindings` program and GNOME autostart
entry. At login it adds only the paths whose IDs begin with `nixos-`; existing
custom GNOME shortcuts are retained. Keeping IDs stable lets the script update
a binding in place. To retire one, remove it from the list and remove its old
shortcut once in GNOME Settings, or reset its dconf path with `gsettings`.

Commands are stored as exact Nix store paths rather than relying on the
session `PATH`. Add the relevant application to `home.packages` (or use an
already available package) before referencing it.

## Apply and test

From the configuration repository:

```bash
nix flake check "path:$PWD"
sudo nixos-rebuild test --flake "path:$PWD#prototype"
```

`keyd` is restarted by the test activation, so physical mappings take effect
immediately. The GNOME shortcut installer needs the graphical session D-Bus;
apply it immediately after a rebuild with:

```bash
apply-gnome-keybindings
```

It also runs automatically at every GNOME login. After testing, make the
configuration survive reboot with:

```bash
sudo nixos-rebuild switch --flake "path:$PWD#prototype"
```

## Inspecting the active configuration

```bash
# Generated physical-key configuration and daemon health
cat /etc/keyd/default.conf
systemctl status keyd

# GNOME's registered custom shortcut paths
gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
```
