#!/usr/bin/bash

set -e

PRESERVE_DAYS="$PRESERVE_DAYS:-30"

if [[ -z "$BACKUP_DIR" ]]; then
    echo "BACKUP_DIR must be set." >&2
    exit 1
fi

if [[ -z "$SAVE_DIR" ]]; then
    echo "SAVE_DIR must be set." >&2
    exit 1
fi

if [[ ! -d "$SAVE_DIR" ]]; then
    echo "$SAVE_DIR is not a directory." >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <stateful_set_name>" >&2
fi

today=$(date '+%Y-%m-%d')
setname="$1"

current_replicas=$(kubectl get sts -o=jsonpath='{.status.replicas}')

scale_down () {
    echo "Scaling down $setname"
    kubectl scale sts "$setname" --replicas=0
}
scale_up () {
    echo "Scaling up $setname"
    kubectl scale sts "$setname" --replicas="$current_replicas"
}

prune () {
    echo "Pruning backups older than ${PRESERVE_DAYS} days."
    find "$BACKUP_DIR" -mtime "+${PRESERVE_DAYS}" -name 'save_data.*.tgz' -delete
}

backup_world () {
    world_dir=$1
    world=$(basename "$world_dir")

    latest="${world}-current.tgz"
    if [[ -f "$latest" ]]; then
        if ! tar -C "$world_dir" -dzvf "$latest"; then
            modified=$(stat -c '%Y' "$latest")
            mv "$latest" "${world}-${modified}.tgz"
        else
            echo "No changes to world ${world} since last backup."
            return
        fi
    fi
    echo "Backing up world ${world}"
    tar -C "$world_dir" -czvf "$latest" ./
}

backup_saves () {
    echo "Backing up saves."
    tar -C "$SAVE_DIR/Saves" -czvf "save_data-${today}.tgz" ./
}


scale_down
trap scale_up EXIT

shopt -s nullglob
for world_dir in "${SAVE_DIR}/GeneratedWorlds/*/"; do
    backup_world "$world_dir"
done

backup_world
backup_saves
prune
