#!/bin/bash
#
###############################################################################################################################################
#
# ABOUT THIS PROGRAM
#
#   This Script is designed for use in JAMF
#
#   - This script will ...
#			Detect if the JAMF Management Account has a Secure Token, and add it if not.
#
###############################################################################################################################################
#
# HISTORY
#
#	Version: 1.1 - 21/04/2018
#
#	- 15/03/2018 - V1.0 - Created by Headbolt
#
#   - 21/10/2019 - V1.1 - Updated by Headbolt
#							More comprehensive error checking and notation
#
###############################################################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
# Grab the username for the admin user we will use to change the password from JAMF variable #4 eg. username
adminUser=$4
# Grab the password for the admin user we will use to change the password from JAMF variable #5 eg. password
adminPass=$5
# Grab the username for the user we want to create a token for from JAMF variable #6 eg. username
User=$6
# Grab the password for the user we want to create a token for from JAMF variable #7 eg. password
Pass=$7
#
# Set the name of your usual JAMF Management Account Name eg. JAMF
MANAGEMENT="JAMF"
# Set the name of your usual Default Zero Touch Build Account eg. Enroll
ZTI="Enroll"
# Set the name of your usual Default Filevault Admin eg. VAULT
FVadd="CRYPTO"
#
# Set the Trigger Name of your Policy to set the JAMF Management Account to a Known Password incase
# it is used for the Admin User from Variable #8 eg. JAMF-NonComplex
NonCOMP="JAMF-NonComplex"
#
# Set the Trigger Name of your Policy to set the JAMF Management Account to an unknown complex Password incase
# it is used for the Admin User from Variable #9 eg. JAMF-Complex
COMP="JAMF-Complex"
#
# Set the name of the script for later logging
ScriptName="append prefix here as needed - Set Secure Token on Management Account"
#
###############################################################################################################################################
#
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
###############################################################################################################################################
#
# Defining Functions
#
###############################################################################################################################################
#
# TokenCheck Function
#
TokenCheck(){
#
/bin/echo Grabbing Secure Token Status for all relevant Accounts
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
JAMFstatus=$(sysadminctl -secureTokenStatus $MANAGEMENT 2>&1)
JAMFtoken=$(echo $JAMFstatus | awk '{print $7}')
/bin/echo $MANAGEMENT secureTokenStatus = $JAMFtoken
#
ADMINISTRATORstatus=$(sysadminctl -secureTokenStatus administrator 2>&1)
ADMINISTRATORtoken=$(echo $ADMINISTRATORstatus | awk '{print $7}')
/bin/echo Administrator secureTokenStatus = $ADMINISTRATORtoken
#
FVaddStatus=$(sysadminctl -secureTokenStatus $FVadd 2>&1)
FVaddToken=$(echo $FVaddStatus | awk '{print $7}')
/bin/echo $FVadd secureTokenStatus = $FVaddToken
#
ZTIstatus=$(sysadminctl -secureTokenStatus $ZTI 2>&1)
ZTItoken=$(echo $ZTIstatus | awk '{print $7}')
/bin/echo $ZTI secureTokenStatus = $ZTItoken
#
ADMINstatus=$(sysadminctl -secureTokenStatus $adminUser 2>&1)
ADMINtoken=$(echo $ADMINstatus | awk '{print $7}')
/bin/echo "Admin Account for this process ( $adminUser ) secureTokenStatus = $ADMINtoken"
#
}
#
###############################################################################################################################################
#
# Section End Function
#
SectionEnd(){
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
# Outputting a Dotted Line for Reporting Purposes
/bin/echo  -----------------------------------------------
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
}
#
###############################################################################################################################################
#
# Script End Function
#
ScriptEnd(){
#
# Outputting a Blank Line for Reporting Purposes
#/bin/echo
#
/bin/echo Ending Script '"'$ScriptName'"'
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
# Outputting a Dotted Line for Reporting Purposes
/bin/echo  -----------------------------------------------
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
}
#
###############################################################################################################################################
#
# End Of Function Definition
#
###############################################################################################################################################
#
# Beginning Processing
#
###############################################################################################################################################
#
# Outputs a blank line for reporting purposes
/bin/echo
SectionEnd
# 
Stamp=$(date)
#Display Current Time
/bin/echo $Stamp
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
/bin/echo Checking Initial Token States
SectionEnd
#
TokenCheck
SectionEnd
#
TokenSetProceed=$(/bin/echo NO)
#
if [ $JAMFtoken == "DISABLED" ]
	then
		if [ $adminUser == "${ZTI}" ]
			then
				if [ "$ZTItoken" == "ENABLED" ]
					then
						TokenSetProceed=$(echo YES)
				fi
		fi
		#
		if [ "$adminUser" == "administrator" ]
			then
				if [ $ADMINISTRATORtoken == "ENABLED" ]
					then
						TokenSetProceed=$(echo YES)
				fi
		fi
		#
		if [ "$adminUser" == "Administrator" ]
			then
				if [ $ADMINISTRATORtoken == "ENABLED" ]
					then
						TokenSetProceed=$(echo YES)
				fi
		fi
		#
		if [ "$adminUser" == "${FVadd}" ]
			then
				if [ $FVaddToken == "ENABLED" ]
					then
						TokenSetProceed=$(echo YES)
				fi
		fi
		#
	else
		# Outputs a blank line for reporting purposes
		/bin/echo
		#
		/bin/echo $MANAGEMENT Account already has a Secure Token, Nothing to do
		#
		# Outputs a blank line for reporting purposes
		/bin/echo
		#
fi
#
if [ $TokenSetProceed == "YES" ]
	then
		#
		/bin/echo Triggering Policy to set JAMF Management Account to a known non-complex Password
		#
		# Outputs a blank line for reporting purposes
		/bin/echo
		#
		sudo /usr/local/bin/jamf policy -trigger $NonCOMP
		SectionEnd
		#
		/bin/echo ensuring $adminUser account is temporarily a local Admin
		#
		dseditgroup -o edit -a $adminUser admin
		/bin/echo
		/bin/echo Enabling $User with a Secure Token
		/bin/echo Enabling using $adminUser as the AdminUser
		#
		# Outputs a blank line for reporting purposes
		/bin/echo
		#
		sysadminctl -adminUser $adminUser -adminPassword $adminPass -secureTokenOn $User -password $Pass 
		SectionEnd
		#
		/bin/echo Triggering Policy to reset JAMF Management Account to an unknown complex Password
		#
		# Outputs a blank line for reporting purposes
		/bin/echo
		sudo /usr/local/bin/jamf policy -trigger $COMP
		SectionEnd
		#
fi
#       
/bin/echo Checking New Token States
#
TokenCheck
#
SectionEnd
ScriptEnd
