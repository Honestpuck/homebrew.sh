#!/bin/sh

# EA to find installed package version
RESULT="Not Found"
# Find machine type
UNAME_MACHINE="$(uname -m)"

if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # M1/arm64 machines
    if [[ -e /opt/homebrew/bin/wget ]]; then
    RESULT=$(/opt/homebrew/bin/wget -V | grep "built on" | awk '{ print $3 }')
    echo "$RESULT"
    fi
else
    # Intel machines
    if [[ -e /usr/local/bin/wget ]]; then
    RESULT=$(/usr/local/bin/wget -V | grep "built on" | awk '{ print $3 }')
    echo "$RESULT"
    fi
fi


echo "<result>$RESULT</result>"