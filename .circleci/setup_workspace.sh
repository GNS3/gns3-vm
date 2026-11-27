#!/bin/bash

set -euo pipefail
umask 022

workspace=${1:?Build workspace path is required}
revision=${2:?Git revision is required}

if [[ "$workspace" != /* || "$workspace" == / || -L "$workspace" ]]; then
    echo "Build workspace must be an absolute, non-symlink directory: $workspace" >&2
    exit 1
fi

mkdir -p "$workspace"
if ! mountpoint -q "$workspace"; then
    first_entry=$(find "$workspace" -mindepth 1 -maxdepth 1 -print -quit)
    if [[ -n "$first_entry" ]]; then
        echo "Refusing to mount tmpfs over a non-empty workspace: $workspace" >&2
        exit 1
    fi
    mount -t tmpfs -o size=75%,mode=0755 tmpfs "$workspace"
fi

if ! findmnt -rn -t tmpfs -M "$workspace" >/dev/null; then
    echo "Build workspace is not mounted as tmpfs: $workspace" >&2
    exit 1
fi

for path in "$workspace/tmp" "$workspace/virtualbox" "$workspace/gns3-vm"; do
    if [[ -L "$path" ]]; then
        echo "Refusing to use a symlink in the build workspace: $path" >&2
        exit 1
    fi
    mkdir -p "$path"
    if ! findmnt -rn -t tmpfs -T "$path" >/dev/null; then
        echo "Build directory is not on tmpfs: $path" >&2
        exit 1
    fi
done

chmod 755 "$workspace"
chmod 700 "$workspace/tmp"
export TMPDIR="$workspace/tmp"

if [[ ! -d "$workspace/gns3-vm/.git" ]]; then
    git clone https://github.com/GNS3/gns3-vm.git "$workspace/gns3-vm"
fi
git -C "$workspace/gns3-vm" checkout "$revision"
