# Shared state helpers for wallpaper scripts.
# Persists per-output wallpaper choices across sessions and reconnects.
# Format: tab-separated "OUTPUT<TAB>PATH" lines (one per output).

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/niri"
STATE_FILE="$STATE_DIR/wallpapers"
LOCK_FILE="$STATE_DIR/wallpapers.lock"

state_init() {
  mkdir -p "$STATE_DIR"
}

# Print the saved path for an output on stdout (empty if none).
state_get() {
  local output="$1"
  [[ -f "$STATE_FILE" ]] || return 0
  awk -F'\t' -v o="$output" '$1 == o { print $2; exit }' "$STATE_FILE"
}

# Save (output, path), replacing any existing entry for that output.
state_set() {
  local output="$1" path="$2"
  state_init
  (
    flock -x 9
    local tmp="$STATE_FILE.tmp.$$"
    if [[ -f "$STATE_FILE" ]]; then
      awk -F'\t' -v o="$output" '$1 != o' "$STATE_FILE" > "$tmp"
    else
      : > "$tmp"
    fi
    printf '%s\t%s\n' "$output" "$path" >> "$tmp"
    mv "$tmp" "$STATE_FILE"
  ) 9>"$LOCK_FILE"
}
