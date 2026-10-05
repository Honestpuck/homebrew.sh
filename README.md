# homebrew.sh
Install homebrew via Jamf without giving users admin rights

This script installs homebrew for the logged in user without requiring them to be an Administrator.

It is designed to be used in an MDM such as Jamf Pro.

Thanks to Richard Purves for the first version.

Thanks to all my users for feedback and improvements.

## be-bu fork notes (2026-10-05)

This fork picks up maintenance after ~5 years without updates. Homebrew/brew
dropped its `master` branch, so the old tarball-based bootstrap in
`homebrew-3.4.sh` no longer works (`brew update`/`brew doctor` require a real
git checkout) - it now does a proper `git clone` and self-repairs any Mac
that already has a tarball-based install. See the changelog at the top of
`homebrew-3.4.sh` for the full list of fixes.

Still universal (Apple Silicon and Intel), but worth noting: Apple Silicon
has been the default Mac since 2020, Intel is deprecated by Apple and no
longer gets new macOS versions, and zsh has been the default shell for 3+
years - `homebrew-3.4.sh` now sets up `~/.zprofile` accordingly rather than
the long-unused `~/.profile`.


# brewEA.sh
This EA compliments the script to produce a Jamf extension attribute to record brew version.
It uses the same method to detect device type and looks where the script installs.
 *If brew is installed in different locations this will not detect it!*

# brew-install-program.sh
This script can be used to install any brew program that installs using *brew install <name>* command.
It is designed to work with the brew install script here and be used in jamf.
Specify the install name as the first jamf variable.

# brew-install-cask.sh
Like the *brew-install-program* script this variation is used to install casks where the *brew install --cask <name>* is used.
It is designed to work with the brew install script here and be used in jamf.
Specify the cask name as the first jamf variable.
