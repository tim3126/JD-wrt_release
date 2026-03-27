#!/usr/bin/env bash

set -e
set -o errexit
set -o errtrace

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_PATH=$(cd "$SCRIPT_DIR/.." && pwd)

error_handler() {
    echo "Error occurred in script at line: ${BASH_LINENO[0]}, command: '${BASH_COMMAND}'" >&2
}

trap 'error_handler' ERR

source <(sed '/^main "\$@"$/d' "$BASE_PATH/update.sh")

error_handler() {
    echo "Error occurred in script at line: ${BASH_LINENO[0]}, command: '${BASH_COMMAND}'" >&2
}

trap 'error_handler' ERR

THEME_SET="bootstrap"

main "$@"

if declare -f has_feed_locks >/dev/null 2>&1 && declare -f save_feed_locks >/dev/null 2>&1; then
    if [ "${UPDATE_FEEDS:-0}" = "1" ] || ! has_feed_locks; then
        save_feed_locks
    fi
fi
