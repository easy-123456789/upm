#!/bin/sh
set -eu

VNC_HOME="/mnt/us/upm/vnc"
VNC_SCRIPT="$VNC_HOME/vnc.sh"

mkdir -p "$VNC_HOME"

install_x11vnc() {
  if command -v x11vnc >/dev/null 2>&1; then
    echo "x11vnc already installed"
    return 0
  fi

  if command -v opkg >/dev/null 2>&1; then
    echo "Installing x11vnc via opkg..."
    opkg update && opkg install x11vnc
    return $?
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo "Installing x11vnc via apt-get..."
    apt-get update && apt-get install -y x11vnc
    return $?
  fi

  if command -v apk >/dev/null 2>&1; then
    echo "Installing x11vnc via apk..."
    apk add x11vnc
    return $?
  fi

  echo "No supported package manager found to install x11vnc."
  return 1
}

create_vnc_launcher() {
  cat > "$VNC_SCRIPT" <<'SH'
#!/bin/sh
set -eu

VNC_PORT="${VNC_PORT:-5900}"
VNC_LOG="/mnt/us/upm/vnc/x11vnc.log"

mkdir -p /mnt/us/upm/vnc

case "${1:-status}" in
  start)
    if ! command -v x11vnc >/dev/null 2>&1; then
      echo "x11vnc is not installed. Run the VNC install step again."
      exit 1
    fi

    if pgrep -f "x11vnc.*-rfbport.*${VNC_PORT}" >/dev/null 2>&1; then
      echo "VNC already running on port ${VNC_PORT}"
      exit 0
    fi

    echo "Starting VNC server on port ${VNC_PORT}..."
    x11vnc -display :0 \
      -rfbport "$VNC_PORT" \
      -noxdamage \
      -shared \
      -forever \
      -bg \
      -nopw \
      -o "$VNC_LOG" \
      >/dev/null 2>&1

    echo "VNC started. Connect to the Kindle on port ${VNC_PORT}."
    ;;

  stop)
    echo "Stopping VNC server on port ${VNC_PORT}..."
    pkill -f "x11vnc.*-rfbport.*${VNC_PORT}" || true
    ;;

  status)
    if pgrep -f "x11vnc.*-rfbport.*${VNC_PORT}" >/dev/null 2>&1; then
      echo "VNC is running on port ${VNC_PORT}."
    else
      echo "VNC is not running."
    fi
    ;;

  *)
    echo "Usage: vnc.sh {start|stop|status}"
    exit 1
    ;;
esac
SH

  chmod +x "$VNC_SCRIPT"
}

install_x11vnc || {
  echo "Failed to install x11vnc."
  exit 1
}

create_vnc_launcher

echo "x11vnc installed successfully."
echo "Run: /mnt/us/upm/vnc/vnc.sh start"
