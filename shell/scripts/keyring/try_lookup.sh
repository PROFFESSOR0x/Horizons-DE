#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Look up under the new "horizons" identity first; fall back to the legacy
# "illogical-impulse" application name so existing installs don't lose
# previously stored secrets (API keys etc.) after the rebrand.
data=$(secret-tool lookup 'application' 'horizons')
if [[ -z "$data" ]]; then
    data=$(secret-tool lookup 'application' 'illogical-impulse')
fi
if [[ -z "$data" ]]; then
    if "${SCRIPT_DIR}/is_unlocked.sh"; then
        echo 'not found'
        exit 1
    else 
        echo 'locked'
        exit 2
    fi
fi
echo "$data"
