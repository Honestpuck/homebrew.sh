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
# 2021-04-11 | Some Big Sur cleanup. Posting as 3.3

# v3.4 | 2026-10-05 | be-bu fork: Homebrew/brew dropped the "master" branch, and
#   brew now refuses to operate against it. Replaced the tarball-of-master
#   bootstrap with a real `git clone` (default branch, i.e. "main"), since
#   `brew update`/`brew doctor` require an actual git checkout. Also added a
#   repair path for Macs that already have a tarball-based (non-git) install,
#   since the "already installed" fast path never reached the install block.
#   Fixed brew shellenv being written to ~/.profile (which zsh never reads)
#   instead of ~/.zprofile. Updated "M1" references to "Apple Silicon" and
#   noted Intel is now deprecated by Apple - this script is 5+ years old and
#   zsh has been the default macOS shell for 3+ years.

# Set up variables and functions here
consoleuser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
UNAME_MACHINE="$(uname -m)"



# Logging stuff starts here
LOGFOLDER="/private/var/log/"
LOG="${LOGFOLDER}Homebrew.log"

if [ ! -d "$LOGFOLDER" ]; then
    mkdir $LOGFOLDER
fi

# Set the prefix based on the machine type
if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # Apple Silicon (arm64) machines - the default Mac since 2020
    HOMEBREW_PREFIX="/opt/homebrew"
else
    # Intel machines - deprecated by Apple, no longer receiving new macOS versions
    HOMEBREW_PREFIX="/usr/local"
fi

NEEDS_INSTALL=0
if [[ ! -e "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    NEEDS_INSTALL=1
elif [[ ! -d "${HOMEBREW_PREFIX}/Homebrew/.git" ]]; then
    # Legacy install from the old tarball/master bootstrap - not a git repo,
    # so brew update/doctor can't work. Clear it out and let the install
    # block below re-clone it. This only touches brew's own code; installed
    # formulae/casks live under Cellar/Caskroom/opt and are left alone.
    NEEDS_INSTALL=1
    rm -rf "${HOMEBREW_PREFIX}/Homebrew"
    rm -f "${HOMEBREW_PREFIX}/bin/brew"
fi

if [[ $NEEDS_INSTALL -eq 0 ]]; then
    su -l "$consoleuser" -c "${HOMEBREW_PREFIX}/bin/brew update"
    exit 0
fi

# are we in the right group
check_grp=$(groups ${consoleuser} | grep -c '_developer')

if [[ $check_grp != 1 ]]; then
    /usr/sbin/dseditgroup -o edit -a "${consoleuser}" -t user _developer
fi

function logme()
{
# Check to see if function has been called correctly
    if [ -z "$1" ] ; then
        echo "$(date) - logme function call error: no text passed to function! Please recheck code!" | tee -a $LOG
        exit 1
    fi

# Log the passed details
    echo -e "$(date) - $1" | tee -a $LOG
}

# Check and start logging
logme "Homebrew Installation"
#############################
# debug - commented out     #
# remove comments if needed #
############################# 
# logme "user is $consoleuser"
# logme "is user in dev group? $check_grp"

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

# Is homebrew already installed (and a valid git checkout)?
if [[ $NEEDS_INSTALL -eq 1 ]]; then
    # Install Homebrew. This doesn't like being run as root so we must do this manually.
    logme "Installing Homebrew"

    mkdir -p "${HOMEBREW_PREFIX}/Homebrew"
    # Clone brew's git repo (default branch, i.e. "main") into ${HOMEBREW_PREFIX}/Homebrew.
    # brew update/doctor require a real git checkout, so this must be a clone, not a tarball.
    git clone https://github.com/Homebrew/brew "${HOMEBREW_PREFIX}/Homebrew"
    if [[ ! -d "${HOMEBREW_PREFIX}/Homebrew/.git" ]]; then
        logme "ERROR: git clone of Homebrew/brew into ${HOMEBREW_PREFIX}/Homebrew failed - aborting install"
        exit 1
    fi

    # Manually make all the appropriate directories and set permissions
    mkdir -p "${HOMEBREW_PREFIX}/Cellar" "${HOMEBREW_PREFIX}/Homebrew"
    mkdir -p "${HOMEBREW_PREFIX}/Caskroom" "${HOMEBREW_PREFIX}/Frameworks" "${HOMEBREW_PREFIX}/bin"
    mkdir -p "${HOMEBREW_PREFIX}/include" "${HOMEBREW_PREFIX}/lib" "${HOMEBREW_PREFIX}/opt" "${HOMEBREW_PREFIX}/etc" "${HOMEBREW_PREFIX}/sbin"
    mkdir -p "${HOMEBREW_PREFIX}/share/zsh/site-functions" "${HOMEBREW_PREFIX}/var"
    mkdir -p "${HOMEBREW_PREFIX}/share/doc" "${HOMEBREW_PREFIX}/man/man1" "${HOMEBREW_PREFIX}/share/man/man1"
    #chown -R "${consoleuser}":_developer "${HOMEBREW_PREFIX}/*"
    ##################################################################
    ### M Lamont changed to not overwrite existing folders, e.g jamf # 
    ###  also took th ebrackets out as this was stopping it working  #
    ###  and No I don't know why                                     #
    ##################################################################
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/Cellar"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/Homebrew"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/Caskroom"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/Frameworks"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/bin"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/include"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/lib"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/opt"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/etc"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/sbin"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/share"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/var"
    chown -R "$consoleuser":_developer "${HOMEBREW_PREFIX}/man"

    # Quoted, so chmod each directory explicitly rather than relying on a
    # glob that double quotes would stop the shell from ever expanding.
    chmod -R g+rwx "${HOMEBREW_PREFIX}/Cellar" "${HOMEBREW_PREFIX}/Homebrew" "${HOMEBREW_PREFIX}/Caskroom" \
        "${HOMEBREW_PREFIX}/Frameworks" "${HOMEBREW_PREFIX}/bin" "${HOMEBREW_PREFIX}/include" \
        "${HOMEBREW_PREFIX}/lib" "${HOMEBREW_PREFIX}/opt" "${HOMEBREW_PREFIX}/etc" "${HOMEBREW_PREFIX}/sbin" \
        "${HOMEBREW_PREFIX}/share" "${HOMEBREW_PREFIX}/var" "${HOMEBREW_PREFIX}/man"
    chmod 755 "${HOMEBREW_PREFIX}/share/zsh" "${HOMEBREW_PREFIX}/share/zsh/site-functions"

    # Create a system wide cache folder  
    mkdir -p /Library/Caches/Homebrew
    chmod g+rwx /Library/Caches/Homebrew
    chown "${consoleuser}:_developer" /Library/Caches/Homebrew

    # put brew where we can find it
    ln -s "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/brew"

    # Install the MD5 checker or the recipes will fail
    su -l "$consoleuser" -c "${HOMEBREW_PREFIX}/bin/brew install md5sha1sum"
    # Double-quoted so HOMEBREW_PREFIX resolves now, while $PATH stays
    # escaped so it's evaluated later, at shell-startup time.
    echo "export PATH=\"${HOMEBREW_PREFIX}/opt/openssl/bin:\$PATH\"" | \
	tee -a /Users/${consoleuser}/.bash_profile /Users/${consoleuser}/.zshrc
    chown ${consoleuser} /Users/${consoleuser}/.bash_profile /Users/${consoleuser}/.zshrc
    
    # clean some directory stuff for Catalina
    chown -R root:wheel /private/tmp
    chmod 777 /private/tmp
    chmod +t /private/tmp

    ############################
    ## M Lamont Add to paths.d #
    ############################
    touch /etc/paths.d/brew
    echo "${HOMEBREW_PREFIX}/bin" > /etc/paths.d/brew
fi

# Make sure everything is up to date
logme "Updating Homebrew"
su -l "$consoleuser" -c "${HOMEBREW_PREFIX}/bin/brew update" 2>&1 | tee -a ${LOG}

# set shellenv for Apple Silicon users
# zsh (the default login shell on all current macOS versions) reads
# ~/.zprofile for login shells, not ~/.profile - so write there, and
# only once, since this runs on every policy execution, not just install.
if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    ZPROFILE="/Users/${consoleuser}/.zprofile"
    touch "$ZPROFILE"
    chown "$consoleuser" "$ZPROFILE"
    if ! grep -q 'brew shellenv' "$ZPROFILE"; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$ZPROFILE"
    fi
fi

# logme user that all is completed
logme "Installation complete"

exit 0
