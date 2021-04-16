#!/bin/sh

# EA to find installed package version

RESULT="Not Found"
# Find machine type
UNAME_MACHINE="$(uname -m)"

if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # M1/arm64 machines
    if [[ -e /opt/homebrew/Caskroom/google-cloud-sdk ]]; then
    RESULT=$(/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/gcloud -v | grep "Google" | awk '{ print $4 }')
    echo "$RESULT"
    fi
else
    # Intel machines
    if [[ -e /usr/local/Caskroom/google-cloud-sdk ]]; then
    RESULT=$(/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/gcloud -v | grep "Google" | awk '{ print $4 }')
    echo "$RESULT"
    fi
fi


echo "<result>$RESULT</result>"