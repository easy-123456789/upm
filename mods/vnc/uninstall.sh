#!/bin/sh
set -eu

VNC_HOME="/mnt/us/upm/vnc"
mkdir -p "$VNC_HOME"

cat > "$VNC_HOME/vnc.sh" <<'SH'
#!/bin/sh
set -eu

VNC_HOME="/mnt/us/upm/vnc"
VNC_PORT="${VNC_PORT:-5900}"
VNC_LOG="$VNC_HOME/x11vnc.log"

mkdir -p "$VNC_HOME"

case "${1:-status}" in
  start)
    if command -v x11vnc >/dev/null 2>&1; then
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
      echo "VNC started. Connect using a VNC client to the Kindle on port ${VNC_PORT}."
    else
      echo "x11vnc not available on this device. Install x11vnc before launching VNC."
      exit 1
    fi
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
    echo "Usage: vnc {start|stop|status}"
    exit 1
    ;;
esac
SH

chmod +x "$VNC_HOME/vnc.sh"

echo "VNC helper installed. Use /mnt/us/upm/vnc/vnc.sh start"
