#!/usr/bin/env bash
# Run an already-installed face-authentication provider with a bounded timeout.
# This bridge deliberately trusts only the provider's exit status: 0 means the
# provider authenticated the user; every other result leaves the lock intact.
set -u

FACE_COMMAND=${1:-}
TIMEOUT_SECONDS=${2:-8}

[[ -n "$FACE_COMMAND" ]] || exit 64
[[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || TIMEOUT_SECONDS=8
(( TIMEOUT_SECONDS < 1 )) && TIMEOUT_SECONDS=1
(( TIMEOUT_SECONDS > 60 )) && TIMEOUT_SECONDS=60

if command -v timeout >/dev/null 2>&1; then
    exec timeout --foreground "${TIMEOUT_SECONDS}s" bash -c "$FACE_COMMAND"
fi

exec bash -c "$FACE_COMMAND"
