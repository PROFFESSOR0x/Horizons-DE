#!/usr/bin/env bash
# Apply one .desktop handler to a MIME/scheme category. Arguments are passed
# positionally from QML, never interpolated into a shell command.
set -euo pipefail

handler="${1:?desktop entry is required}"
shift

for mime in "$@"; do
    xdg-mime default "$handler" "$mime"
done
