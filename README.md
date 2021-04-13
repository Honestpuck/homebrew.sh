# homebrew.sh
Install homebrew via Jamf without giving users admin rights

This script installs homebrew for the logged in user without requiring them to be an Administrator.

It is designed to be used in an MDM such as Jamf Pro.

Thanks to Richard Purves for the first version.

Thanks to all my users for feedback and improvements.


# brewEA.sh
This EA compliments the script to produce a Jamf extension attribute to record brew version.
It uses the same method of detecting device type and look in the same places as the script installs to.
 *If brew is installed in different locations this will not detect it!*

# brew-install-program.sh
This script can be used to install any brew program that installs using *brew install* command.
It is designed to work with the brew install here and be used in jamf.
Specify the install name as the first jamf variable.
