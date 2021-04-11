#!/bin/sh

# Extension attribute for homebrew install

# M Lamont

# base result
RESULT="Not Found"
# Find machine type
UNAME_MACHINE="$(uname -m)"

if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # M1/arm64 machines
    if [[ -e /opt/homebrew/bin/brew ]]; then
    RESULT=$(/opt/homebrew/bin/brew -v | head -n 1 | awk '{ print $2 }')
    fi
else
    # Intel machines
    if [[ -e /usr/local/bin/brew ]]; then
    RESULT=$(/usr/local/bin/brew -v | head -n 1 | awk '{ print $2 }')
    fi
fi

echo "<result>$RESULT</result>"
