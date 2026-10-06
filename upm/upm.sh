#!/bin/sh

MOD_BASE="https://raw.githubusercontent.com/easy-123456789/upm/refs/heads/main/mods"
MOD_DIR="/mnt/us/upm/mods"

# Ensure mod directory exists
mkdir -p "$MOD_DIR"

# -----------------------------
# Helper: download a mod folder
# -----------------------------
download_mod() {
    mod="$1"
    dest="$MOD_DIR/$mod"
    mkdir -p "$dest"

    for file in details.json install.sh uninstall.sh launch.sh; do
        url="$MOD_BASE/$mod/$file"
        wget -q -O "$dest/$file" "$url"
    done

    chmod +x "$dest/"*.sh
}

# -----------------------------
# Command Handlers
# -----------------------------

handle_upm_update() {
    echo "Updating all installed mods..."
    for mod in "$MOD_DIR"/*; do
        [ -d "$mod" ] || continue
        name="$(basename "$mod")"
        echo "Updating $name..."
        download_mod "$name"
    done
}

handle_upm_remove() {
    mod="$1"
    if [ -d "$MOD_DIR/$mod" ]; then
        echo "Running uninstall for $mod..."
        sh "$MOD_DIR/$mod/uninstall.sh"
        rm -rf "$MOD_DIR/$mod"
        echo "$mod removed."
    else
        echo "Mod not installed: $mod"
    fi
}

handle_upm_list() {
    echo "Installed mods:"
    for mod in "$MOD_DIR"/*; do
        [ -d "$mod" ] || continue
        echo " - $(basename "$mod")"
    done
}

handle_upm_install_url() {
    url="$1"
    mod="$(basename "$url" .git)"

    echo "Installing from GitHub URL: $url"
    tmp="/mnt/us/upm/tmp/$mod"
    rm -rf "$tmp"
    mkdir -p "$tmp"

    git clone "$url" "$tmp"

    if [ -f "$tmp/install.sh" ]; then
        sh "$tmp/install.sh"
    fi

    rm -rf "$tmp"
}

handle_upm_search() {
    query="$1"
    echo "Searching mods for: $query"

    curl -s "$MOD_BASE/" | grep -i "$query"
}

handle_upm_compile() {
    src="$1"
    echo "Compiling source: $src"
    /mnt/us/upm/compiler/compile.sh "$src"
}

handle_upm_install_local() {
    mod="$1"
    echo "Installing pre-installed mod: $mod"

    if [ -d "$MOD_DIR/$mod" ]; then
        sh "$MOD_DIR/$mod/install.sh"
    else
        echo "Mod not found locally: $mod"
    fi
}

# -----------------------------
# Main Kindle Search Listener
# -----------------------------

lipc-wait-event -s com.lab126.searchBar searchText | while read event text; do
    cmd="$(echo "$text" | sed 's/^[ \t]*//;s/[ \t]*$//')"

    case "$cmd" in
        \;*)
            args="${cmd#;}"
            set -- $args
            main="$1"
            sub="$2"
            third="$3"

            case "$main" in
                upm)
                    case "$sub" in
                        update)
                            handle_upm_update
                        ;;
                        remove)
                            handle_upm_remove "$third"
                        ;;
                        list)
                            handle_upm_list
                        ;;
                        install)
                            # Case 1: install <github-url>
                            if echo "$third" | grep -q "http"; then
                                handle_upm_install_url "$third"
                            else
                                # Case 2: install <local-mod>
                                handle_upm_install_local "$third"
                            fi
                        ;;
                        search)
                            handle_upm_search "$third"
                        ;;
                        compile)
                            handle_upm_compile "$third"
                        ;;
                        *)
                            echo "Unknown UPM command: $sub"
                        ;;
                    esac
                ;;
                *)
                    echo "Unknown command group: $main"
                ;;
            esac
        ;;
        *)
            echo "User searched: $cmd"
        ;;
    esac
done
