#!/usr/bin/env bash
# common.sh - colorized output helpers

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

info() {
    # yellow for informational messages
    echo -e "${YELLOW}$*${NC}"
}

success() {
    # green for success
    echo -e "${GREEN}$*${NC}"
}

error() {
    # red for errors
    echo -e "${RED}$*${NC}" 1>&2
}
