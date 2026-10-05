#!/bin/sh

# Extension attribute for homebrew install

# M Lamont

# base result
RESULT="Not Found"
# Find machine type
UNAME_MACHINE="$(uname -m)"

if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # Apple Silicon (arm64) machines - the default Mac since 2020
    if [[ -e /opt/homebrew/bin/brew ]]; then
    RESULT=$(/opt/homebrew/bin/brew -v | head -n 1 | awk '{ print $2 }')
    fi
else
    # Intel machines - deprecated by Apple, no longer receiving new macOS versions
    if [[ -e /usr/local/bin/brew ]]; then
    RESULT=$(/usr/local/bin/brew -v | head -n 1 | awk '{ print $2 }')
    fi
fi

echo "<result>$RESULT</result>"
