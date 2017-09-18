#!/bin/bash

# Author by: Joe


LogFile="chromiumBuild.log"

echo "*************** Ready to start compiling ***************"
echo ""
echo $(date) | tee -a $LogFile
echo ""
echo "***************   Check macOS version.   ***************"
echo ""
OSVersion=$(sw_vers -productVersion)
echo "OS X Version "$OSVersion" detected" | tee -a $LogFile


echo "***************       Check Git.         ***************"
echo ""
if command -V git >/dev/null 2>&1; then

	for cmd in git; do
		[[ $("$cmd" --version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		var1=$(echo "$version" | cut -d. -f1)
		var2=$(echo "$version" | cut -d. -f2)
		var3=$(echo "$version" | cut -d. -f3)
		
		if [[ $var1 -lt 2 ]]; then
			echo 'Error: '$cmd' version 2.2.1 or higher required' | tee -a $LogFile
			exit 1;
		fi
		if [[ $var1 -gt 2 && $var2 -lt 2 ]]; then
			echo 'Error: '$cmd' version 2.2.1 or higher required' | tee -a $LogFile
			exit 1;
		fi
		if [[ $var1 -gt 2 && $var2 -gt 2 && $var3 -lt 1 ]]; then
			echo 'Error: '$cmd' version 2.2.1 or higher required' | tee -a $LogFile
			exit 1;
		fi
	done
else 
	echo "ERROR: git is not installed, please install Xcode and xcode-cli to get git, or brew install git" | tee -a $LOGFILE
	exit 1;
fi


echo "***************       Check Xcode.       ***************"
echo ""
XcodeCheck="$(command xcodebuild -version 2>&1)"
if [[ "$XcodeCheck" =~ "requires" ]]; then
	echo "Xcode not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LogFile
	exit 1;

elif [[ "$XcodeCheck" =~ "note" ]]; then
	echo "Xcode and xcode-cli not found, please see xcodehelp.txt in this repository and install Xcode." | tee -a $LOGFILE
	exit 1;

else
	echo "Xcode detected, testing version" | tee -a $LogFile
	for cmd in xcodebuild; do
		[[ $("$cmd" -version) =~ ([0-9][.][0-9.]*) ]] && version="${BASH_REMATCH[1]}"
		if ! awk -v ver="$version" 'BEGIN { if (ver < 5.0) exit 1; }'; then
			echo 'Error: '$cmd' version 5.0 or higher required' | tee -a $LogFile
			echo 'Xcode version detected was: '$version | tee -a $LogFile
			exit 1;
		fi
		echo 'XCode version detected was: '$version | tee -a $LogFile
	done
fi


echo "***************   Install depot_tools.   ***************"
echo ""
if [ -d ./depot_tools/ ]
	then
	echo "./depot_tools/ already exists" | tee -a $LogFile
else
	echo "Start download..." | tee -a $LogFile
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
	if [[ $? -eq 0 ]]; then
		echo "depot_tools download successful" | tee -a $LogFile
	else
		echo "depot_tools download failed, exiting" | tee -a $LogFile
		exit 1;
	fi
fi

