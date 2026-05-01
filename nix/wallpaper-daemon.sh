# All-caps variables and state helpers above this line are injected by Nix.
#
# Long-running reconciler. On every poll, finds outputs that don't have a
# wallpaper currently set in awww and restores them — from the persisted
# state file when available, otherwise from a random pick which is then
# saved. This covers both session start (awww comes up empty) and monitor
# hotplug (a reconnected output reappears in awww with no displaying image).

state_init

# Wait for awww to come up.
for _ in {1..30}; do
  awww query -j &>/dev/null && break
  sleep 0.5
done

AWWW_ARGS=(
  --transition-type    "$TRANSITION_TYPE"
  --transition-duration "$TRANSITION_DURATION"
  --transition-fps     "$TRANSITION_FPS"
  --transition-angle   "$TRANSITION_ANGLE"
  --transition-pos     "$TRANSITION_POS"
  --transition-bezier  "$TRANSITION_BEZIER"
  --transition-wave    "$TRANSITION_WAVE"
  --resize             "$RESIZE"
  --fill-color         "$FILL_COLOR"
  --filter             "$FILTER"
)
[[ -n "$TRANSITION_STEP" ]]    && AWWW_ARGS+=(--transition-step "$TRANSITION_STEP")
[[ -n "$TRANSITION_INVERT_Y" ]] && AWWW_ARGS+=(--invert-y)

get_leaf_dirs() {
  while IFS= read -r -d '' dir; do
    if find "$dir" -maxdepth 1 -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
         -o -iname "*.gif" -o -iname "*.webp" \) \
      -print -quit 2>/dev/null | grep -q .; then
      printf '%s\0' "$dir"
    fi
  done < <(find "$WALLPAPERS_DIR" -mindepth 1 -type d -print0 | sort -z)
}

# Print a random image path from a random leaf directory under WALLPAPERS_DIR.
pick_random_image() {
  local -a leaf_dirs images
  mapfile -t -d '' leaf_dirs < <(get_leaf_dirs)
  local n=${#leaf_dirs[@]}
  (( n == 0 )) && return 1
  local dir="${leaf_dirs[$(( RANDOM % n ))]}"
  mapfile -t -d '' images < <(find "$dir" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
       -o -iname "*.gif" -o -iname "*.webp" \) \
    -print0 | sort -z)
  local m=${#images[@]}
  (( m == 0 )) && return 1
  printf '%s' "${images[$(( RANDOM % m ))]}"
}

apply_wallpaper() {
  local output="$1" path="$2"
  if awww img -o "$output" "${AWWW_ARGS[@]}" "$path" 2>/dev/null; then
    state_set "$output" "$path"
    return 0
  fi
  return 1
}

reconcile_outputs() {
  local query out saved target
  local -a outputs_without_wp
  query=$(awww query -j 2>/dev/null) || return 0

  mapfile -t outputs_without_wp < <(printf '%s' "$query" \
    | jq -r '.[""] | .[] | select(.displaying | has("image") | not) | .name' 2>/dev/null)

  (( ${#outputs_without_wp[@]} == 0 )) && return 0

  for out in "${outputs_without_wp[@]}"; do
    saved=$(state_get "$out")
    if [[ -n "$saved" && -f "$saved" ]]; then
      apply_wallpaper "$out" "$saved" || true
    else
      target=$(pick_random_image) || continue
      apply_wallpaper "$out" "$target" || true
    fi
  done
}

while :; do
  reconcile_outputs || true
  sleep 2
done
