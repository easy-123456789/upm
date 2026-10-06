#!/bin/sh
#
# install-upm.sh
# Place in /mnt/us/documents and tap to run on the Kindle.
# Installs UPM CLI and the searchhook, then deletes this installer.
#

# --- configuration ---
CLI_URL="https://raw.githubusercontent.com/easy-123456789/upm/refs/heads/main/upm/upm"
SEARCHHOOK_URL="https://raw.githubusercontent.com/easy-123456789/upm/refs/heads/main/upm/search%20hook/searchhook.sh?_sm_au_=iVVnMfQJRHLFnr7P6kkGkK0L1KKKp"

UPM_ROOT="/mnt/us/upm"
UPM_BIN="$UPM_ROOT/bin"
EXT_DIR="/mnt/us/extensions/searchhook/bin"
TMP_DIR="$UPM_ROOT/tmp"

mkdir -p "$UPM_BIN" "$EXT_DIR" "$TMP_DIR"

# --- downloader helper ---
download_file() {
  url="$1"
  out="$2"
  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$out" "$url" && return 0
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -sL "$url" -o "$out" && return 0
  fi
  return 1
}

# --- try to fetch remote CLI ---
CLI_DEST="$UPM_BIN/upm"
if download_file "$CLI_URL" "$CLI_DEST"; then
  chmod +x "$CLI_DEST" 2>/dev/null || true
  CLI_INSTALLED=1
else
  CLI_INSTALLED=0
fi

# --- try to fetch searchhook ---
SEARCH_DEST="$EXT_DIR/searchhook.sh"
if download_file "$SEARCHHOOK_URL" "$SEARCH_DEST"; then
  chmod +x "$SEARCH_DEST" 2>/dev/null || true
  SEARCH_INSTALLED=1
else
  SEARCH_INSTALLED=0
fi

# --- fallback: write a minimal embedded CLI if remote CLI missing ---
if [ "$CLI_INSTALLED" -ne 1 ]; then
  cat > "$CLI_DEST" <<'SH'
#!/bin/sh
# Minimal embedded UPM CLI (fallback)
MOD_DIR="/mnt/us/upm/mods"
log() { echo "[upm] $*"; }
download_file() {
  url="$1"; out="$2"
  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$out" "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -sL "$url" -o "$out"
  else
    log "No downloader available"
    return 1
  fi
}
download_mod_files() {
  mod="$1"
  dest="$MOD_DIR/$mod"
  mkdir -p "$dest"
  for f in details.json install.sh uninstall.sh launch.sh; do
    url="https://raw.githubusercontent.com/easy-123456789/upm/refs/heads/main/mods/$mod/$f"
    download_file "$url" "$dest/$f" || true
  done
  chmod +x "$dest"/*.sh 2>/dev/null || true
}
cmd_install() {
  mod="$1"
  [ -n "$mod" ] || { log "Usage: upm install <mod-name>"; return 1; }
  log "Installing $mod..."
  download_mod_files "$mod"
  [ -x "$MOD_DIR/$mod/install.sh" ] && sh "$MOD_DIR/$mod/install.sh"
  log "Installed $mod"
}
cmd_remove() {
  mod="$1"
  [ -n "$mod" ] || { log "Usage: upm remove <mod-name>"; return 1; }
  if [ -d "$MOD_DIR/$mod" ]; then
    [ -x "$MOD_DIR/$mod/uninstall.sh" ] && sh "$MOD_DIR/$mod/uninstall.sh"
    rm -rf "$MOD_DIR/$mod"
    log "Removed $mod"
  else
    log "Mod not installed: $mod"
  fi
}
cmd_list() {
  echo "Installed mods:"
  for d in "$MOD_DIR"/*; do
    [ -d "$d" ] || continue
    echo " - $(basename "$d")"
  done
}
cmd_launch() {
  mod="$1"
  [ -n "$mod" ] || { log "Usage: upm launch <mod-name>"; return 1; }
  if [ -x "$MOD_DIR/$mod/launch.sh" ]; then
    sh "$MOD_DIR/$mod/launch.sh"
  else
    log "No launch script for $mod"
    return 1
  fi
}
case "$1" in
  install) shift; cmd_install "$@" ;;
  remove) shift; cmd_remove "$@" ;;
  list) cmd_list ;;
  launch) shift; cmd_launch "$@" ;;
  update) for d in "$MOD_DIR"/*; do [ -d "$d" ] || continue; name="$(basename "$d")"; log "Refreshing $name"; download_mod_files "$name"; done ;;
  *) echo "Usage: upm {install|remove|list|launch|update}"; exit 1 ;;
esac
SH
  chmod +x "$CLI_DEST" 2>/dev/null || true
fi

# --- ensure mods and tmp exist ---
mkdir -p /mnt/us/upm/mods "$TMP_DIR"

# --- start listener (best-effort) ---
if command -v lipc-wait-event >/dev/null 2>&1 && [ -x "$SEARCH_DEST" ]; then
  sh "$SEARCH_DEST" >/tmp/upm_searchhook.log 2>&1 &
fi

# --- confirmation dialog ---
lipc-set-prop com.lab126.dialog show \
'{ "title": "UPM Installed", "text": "UPM CLI and searchhook installed. Use /mnt/us/upm/bin/upm to manage mods.", "timeout": 6 }' 2>/dev/null || true

# --- self-delete installer ---
if [ -n "$0" ]; then
  rm -f -- "$0" 2>/dev/null || true
fi

exit 0
