#!/bin/zsh

item="$4"
#######################
# check something set #
if [[ "$item" == "" ]]; then
echo "****  No item set! exiting ****"
exit 1
fi

UNAME_MACHINE="$(uname -m)"

ConsoleUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Check if the item is already installed. If not, install it

if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # Apple Silicon (arm64) machines - the default Mac since 2020
    brew=/opt/homebrew/bin/brew
else
    # Intel machines - deprecated by Apple, no longer receiving new macOS versions
    brew=/usr/local/bin/brew
fi

cd /tmp/ # This is required to use sudo as another user or you get a getcwd error
if [[ $(sudo -H -iu ${ConsoleUser} ${brew} info ${item}) != *Not\ installed* ]]; then
	echo "${item} is installed already. Skipping installation"
else
	echo "${item} is either not installed or not available. Attempting installation..."
	sudo -H -iu ${ConsoleUser} ${brew} install ${item}
fi
