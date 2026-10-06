#!/usr/bin/env python3
import os
import sys
import json
import shutil

MOD_DEV_DIR = "/mnt/us/upm/dev"
MOD_OUT_DIR = "/mnt/us/upm/mods"

os.makedirs(MOD_DEV_DIR, exist_ok=True)
os.makedirs(MOD_OUT_DIR, exist_ok=True)


# -----------------------------
# Create a new mod scaffold
# -----------------------------

def create_mod(name):
    mod_path = os.path.join(MOD_DEV_DIR, name)
    if os.path.isdir(mod_path):
        print("Mod already exists:", name)
        return

    os.makedirs(mod_path)

    # details.json template
    details = {
        "name": name,
        "version": "1.0.0",
        "author": "Unknown",
        "description": "A UPM mod."
    }

    with open(os.path.join(mod_path, "details.json"), "w") as f:
        json.dump(details, f, indent=4)

    # install.sh
    with open(os.path.join(mod_path, "install.sh"), "w") as f:
        f.write("#!/bin/sh\n")
        f.write(f"echo 'Installing {name}...'\n")

    # uninstall.sh
    with open(os.path.join(mod_path, "uninstall.sh"), "w") as f:
        f.write("#!/bin/sh\n")
        f.write(f"echo 'Uninstalling {name}...'\n")

    # launch.sh
    with open(os.path.join(mod_path, "launch.sh"), "w") as f:
        f.write("#!/bin/sh\n")
        f.write(f"echo 'Launching {name}...'\n")

    # Make scripts executable
    for f in ["install.sh", "uninstall.sh", "launch.sh"]:
        os.chmod(os.path.join(mod_path, f), 0o755)

    print("Created mod scaffold:", name)


# -----------------------------
# Validate mod structure
# -----------------------------

def validate_mod(name):
    mod_path = os.path.join(MOD_DEV_DIR, name)
    if not os.path.isdir(mod_path):
        print("Mod not found:", name)
        return

    required = ["details.json", "install.sh", "uninstall.sh", "launch.sh"]
    missing = []

    for r in required:
        if not os.path.isfile(os.path.join(mod_path, r)):
            missing.append(r)

    if missing:
        print("Missing files:", ", ".join(missing))
    else:
        print("Mod structure valid:", name)


# -----------------------------
# Package mod into /mods
# -----------------------------

def package_mod(name):
    src = os.path.join(MOD_DEV_DIR, name)
    dst = os.path.join(MOD_OUT_DIR, name)

    if not os.path.isdir(src):
        print("Mod not found:", name)
        return

    if os.path.isdir(dst):
        shutil.rmtree(dst)

    shutil.copytree(src, dst)
    print("Packaged mod:", name)


# -----------------------------
# Delete dev mod
# -----------------------------

def delete_mod(name):
    path = os.path.join(MOD_DEV_DIR, name)
    if os.path.isdir(path):
        shutil.rmtree(path)
        print("Deleted dev mod:", name)
    else:
        print("Mod not found:", name)


# -----------------------------
# CLI Router
# -----------------------------

def main():
    if len(sys.argv) < 2:
        print("UPM Dev Helper: no command provided")
        return

    cmd = sys.argv[1]

    if cmd == "new" and len(sys.argv) >= 3:
        create_mod(sys.argv[2])

    elif cmd == "validate" and len(sys.argv) >= 3:
        validate_mod(sys.argv[2])

    elif cmd == "package" and len(sys.argv) >= 3:
        package_mod(sys.argv[2])

    elif cmd == "delete" and len(sys.argv) >= 3:
        delete_mod(sys.argv[2])

    else:
        print("Unknown or incomplete command:", cmd)


if __name__ == "__main__":
    main()
