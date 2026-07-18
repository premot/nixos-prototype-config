#!/usr/bin/env bash
# Configure the nine muted-dark GNOME Terminal profiles documented in
# docs/GNOME_TERMINAL_PROFILE_SETUP.md. Run as the logged-in GNOME user.
set -euo pipefail

readonly PROFILES_SCHEMA='org.gnome.Terminal.ProfilesList'
readonly BINDINGS_SCHEMA='org.gnome.settings-daemon.plugins.media-keys'
readonly BINDING_SCHEMA_PREFIX='org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:'
readonly LEGACY_BLUE_BINDING='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-terminal-blue-alt-1/'
readonly FOREGROUND='#e7edf3'

# Profile 1 deliberately reuses the former Blue Terminal profile ID.
PROFILE_IDS=(
  'be6414ee-9e03-4012-ad40-0e78afd7621c'
  '1176592f-46e7-4f84-a3ec-bb2a5ef7c14d'
  '2118bdf7-2f03-4e21-bf32-c55924117e7d'
  'bd50ad3a-75cf-41bd-abaf-f3353099a548'
  '94d869e3-5e3d-47e7-b73f-71deee311584'
  '4101aa5a-a2a6-4505-96a5-452f33ab0a92'
  '5f5dd616-92b0-46b0-b158-4c01b2ce083f'
  '0940d36f-eace-40e9-bb34-9867ccffb9aa'
  'e6c6f0f2-baa7-40ba-ba80-354b9cb605c5'
)
PROFILE_NAMES=(
  'Deep Navy' 'Harbor Teal' 'Pine' 'Moss' 'Umber'
  'Oxblood' 'Mulberry' 'Indigo' 'Slate'
)
BACKGROUNDS=(
  '#172a46' '#123c42' '#173f30' '#3c4120' '#49311f'
  '#48242a' '#402442' '#2d2949' '#28383b'
)

# Print a valid GSettings string-array literal after adding/removing values.
# Python's repr uses the same single-quoted form accepted by gsettings here.
update_string_list() {
  local current=$1 add=$2 remove=$3
  python3 - "$current" "$add" "$remove" <<'PY'
import ast
import sys

values = ast.literal_eval(sys.argv[1])
add = [value for value in sys.argv[2].split('\n') if value]
remove = set(value for value in sys.argv[3].split('\n') if value)
values = [value for value in values if value not in remove]
for value in add:
    if value not in values:
        values.append(value)
print('[' + ', '.join(repr(value) for value in values) + ']')
PY
}

set_profile() {
  local id=$1 name=$2 background=$3
  local path="/org/gnome/terminal/legacy/profiles:/:${id}/"
  local schema="org.gnome.Terminal.Legacy.Profile:${path}"

  gsettings set "$schema" visible-name "$name"
  gsettings set "$schema" use-theme-colors false
  gsettings set "$schema" background-color "$background"
  # The previous Blue Terminal profile had a near-black foreground inherited
  # from the light default profile; set a shared light foreground explicitly.
  gsettings set "$schema" foreground-color "$FOREGROUND"
  gsettings set "$schema" cursor-background-color "$FOREGROUND"
  gsettings set "$schema" cursor-foreground-color '#171b22'
}

binding_paths=()
for i in "${!PROFILE_IDS[@]}"; do
  number=$((i + 1))
  binding_paths+=("/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-terminal-palette-${number}/")
done

# Preserve every existing terminal profile (including the original default)
# and every unrelated custom keybinding. The former Blue Alt+1 path is
# replaced by the palette's consistently named Alt+1 path.
profile_list=$(gsettings get "$PROFILES_SCHEMA" list)
profile_list=$(update_string_list "$profile_list" "$(printf '%s\n' "${PROFILE_IDS[@]}")" '')
gsettings set "$PROFILES_SCHEMA" list "$profile_list"

binding_list=$(gsettings get "$BINDINGS_SCHEMA" custom-keybindings)
binding_list=$(update_string_list "$binding_list" "$(printf '%s\n' "${binding_paths[@]}")" "$LEGACY_BLUE_BINDING")
gsettings set "$BINDINGS_SCHEMA" custom-keybindings "$binding_list"
gsettings reset-recursively "${BINDING_SCHEMA_PREFIX}${LEGACY_BLUE_BINDING}"

for i in "${!PROFILE_IDS[@]}"; do
  number=$((i + 1))
  set_profile "${PROFILE_IDS[i]}" "${PROFILE_NAMES[i]}" "${BACKGROUNDS[i]}"

  binding_schema="${BINDING_SCHEMA_PREFIX}${binding_paths[i]}"
  gsettings set "$binding_schema" name "${PROFILE_NAMES[i]} Terminal"
  gsettings set "$binding_schema" command "gnome-terminal --profile=${PROFILE_IDS[i]}"
  gsettings set "$binding_schema" binding "<Alt>${number}"
done

printf 'Configured %d GNOME Terminal palette profiles (Alt+1 through Alt+9).\n' "${#PROFILE_IDS[@]}"
