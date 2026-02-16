#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Get current date and time for subject
CURRENT_DATE=$(date +'%Y-%m-%d %H:%M')
HOSTNAME=$(hostname)
SUBJECT="script output - $HOSTNAME - $CURRENT_DATE"

if [ -z "$RECIPIENT" ]; then
    echo "ERROR: RECIPIENT not set in .env" >&2
    exit 1
fi

# Check if mail command exists
if ! command -v mail &> /dev/null; then
    echo "ERROR: 'mail' command not found. Please install mailutils or equivalent." >&2
    exit 1
fi

# Read input from stdin and pipe to mail command
if cat | mail -s "$SUBJECT" "$RECIPIENT"; then
    exit 0
else
    echo "ERROR: Mail command failed." >&2
    exit 1
fi
