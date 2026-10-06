#!/bin/sh
# searchhook.sh
UPM_BIN="/mnt/us/upm/bin/upm"

lipc-wait-event -s com.lab126.searchBar searchText | while read ev txt; do
  cmd="$(echo "$txt" | sed 's/^[ \t]*//;s/[ \t]*$//')"
  case "$cmd" in
    \;*)
      args="${cmd#;}"
      if echo "$args" | grep -qE '^upm\b'; then
        rest="$(echo "$args" | sed 's/^upm[ \t]*//')"
        # call upm with the rest of the tokens
        set -- $rest
        "$UPM_BIN" "$@"
      fi
    ;;
  esac
done
