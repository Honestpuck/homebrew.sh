#!/bin/bash

# Script to install Homebrew on a Mac.
# Author: richard at richard - purves dot com
# Version: 1.0 - 21st May 2017

# Heavily hacked by Tony Williams (honestpuck@gmail.com)
# Latest version at https://github.com/Honestpuck/homebrew.sh
# v2.0 - 19th Sept 2019
# v2.0.1 Fixed global cache error
# v2.0.2 Fixed brew location error
# v2.0.3 Added more directories to handle

# v3.0 Catalina version 2020-02-17
# v3.1 | 2020-03-24 | Fix permissions for /private/tmp
# v3.2 2020-07-18 Added Caskroom to directories created and added check for binary
# update if it exists then exit

# 2021-01-11 | Support for osx arm64 added by Shawn Smith (https://github.com/HelixSpiral)

# Set up variables and functions here
consoleuser="$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
UNAME_MACHINE="$(uname -m)"

# Set the prefix based on the machine type
if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # M1/arm64 machines
    HOMEBREW_PREFIX="/opt/homebrew"
else
    # Intel machines
    HOMEBREW_PREFIX="/usr/local"
fi

if [[ -e "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    su -l "$consoleuser" -c "${HOMEBREW_PREFIX}/bin/brew update"
    exit 0
fi

# are we in the right group
check_grp=$(groups ${consoleuser} | grep -c '_developer')
if [[ $check_grp != 1 ]]; then
    /usr/sbin/dseditgroup -o edit -a "${consoleuser}" -t user _developer
fi

# Logging stuff starts here
LOGFOLDER="/private/var/log/"
LOG="${LOGFOLDER}Homebrew.log"

if [ ! -d "$LOGFOLDER" ]; then
    mkdir $LOGFOLDER
fi

function logme()
{
# Check to see if function has been called correctly
    if [ -z "$1" ] ; then
        echo "$(date) - logme function call error: no text passed to function! Please recheck code!"
        echo "$(date) - logme function call error: no text passed to function! Please recheck code!" >> $LOG
        exit 1
    fi

# Log the passed details
    echo -e "$(date) - $1" >> $LOG
    echo -e "$(date) - $1"
}

# Check and start logging
logme "Homebrew Installation"

# Have the xcode command line tools been installed?
logme "Checking for Xcode Command Line Tools installation"
check=$( pkgutil --pkgs | grep -c "CLTools_Executables" )

if [[ "$check" != 1 ]]; then
    logme "Installing Xcode Command Tools"
    # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    clt=$(softwareupdate -l | grep -B 1 -E "Command Line (Developer|Tools)" | awk -F"*" '/^ +\\*/ {print $2}' | sed 's/^ *//' | tail -n1)
    # the above don't work in Catalina so ...
    if [[ -z $clt ]]; then
    	clt=$(softwareupdate -l | grep  "Label: Command" | tail -1 | sed 's#\* Label: \(.*\)#\1#')
    fi
    softwareupdate -i "$clt"
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    /usr/bin/xcode-select --switch /Library/Developer/CommandLineTools
fi

# Is homebrew already installed?
if [[ ! -e "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    # Install Homebrew. This doesn't like being run as root so we must do this manually.
    logme "Installing Homebrew"

    mkdir -p "${HOMEBREW_PREFIX}/Homebrew"
    # Curl down the latest tarball and install to ${HOMEBREW_PREFIX}/Homebrew
    curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "${HOMEBREW_PREFIX}/Homebrew"

    # Manually make all the appropriate directories and set permissions
    mkdir -p "${HOMEBREW_PREFIX}/Cellar" "${HOMEBREW_PREFIX}/Homebrew"
    mkdir -p "${HOMEBREW_PREFIX}/Caskroom" "${HOMEBREW_PREFIX}/Frameworks" "${HOMEBREW_PREFIX}/bin"
    mkdir -p "${HOMEBREW_PREFIX}/include" "${HOMEBREW_PREFIX}/lib" "${HOMEBREW_PREFIX}/opt" "${HOMEBREW_PREFIX}/etc" "${HOMEBREW_PREFIX}/sbin"
    mkdir -p "${HOMEBREW_PREFIX}/share/zsh/site-functions" "${HOMEBREW_PREFIX}/var"
    mkdir -p "${HOMEBREW_PREFIX}/share/doc" "${HOMEBREW_PREFIX}/man/man1" "${HOMEBREW_PREFIX}/share/man/man1"
    chown -R "${consoleuser}":_developer "${HOMEBREW_PREFIX}/*"
    chmod -R g+rwx "${HOMEBREW_PREFIX}/*"
    chmod 755 "${HOMEBREW_PREFIX}/share/zsh" "${HOMEBREW_PREFIX}/share/zsh/site-functions"

    # Create a system wide cache folder  
    mkdir -p /Library/Caches/Homebrew
    chmod g+rwx /Library/Caches/Homebrew
    chown "${consoleuser}:_developer" /Library/Caches/Homebrew

    # put brew where we can find it
    ln -s "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/brew"

    # Install the MD5 checker or the recipes will fail
    su -l "$consoleuser" -c "${HOMEBREW_PREFIX}/bin/brew install md5sha1sum"
    echo 'export PATH="${HOMEBREW_PREFIX}/opt/openssl/bin:$PATH"' | \
	tee -a /Users/${consoleuser}/.bash_profile /Users/${consoleuser}/.zshrc
    chown ${consoleuser} /Users/${consoleuser}/.bash_profile /Users/${consoleuser}/.zshrc
    
    # clean some directory stuff for Catalina
    chown -R root:wheel /private/tmp
    chmod 777 /private/tmp
    chmod +t /private/tmp
fi

# Make sure everything is up to date
logme "Updating Homebrew"
su -l "$consoleuser" -c "${HOMEBREW_PREFIX}/bin/brew update" 2>&1 | tee -a ${LOG}

# logme user that all is completed
logme "Installation complete"

exit 0
