#! /bin/bash

# Reset
Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UWhite='\033[4;37m'       # White
ANSWER='\t\t\t\t\t'	  # Tab for answers
EXPLOIT=""
VERBOSE=""
scriptVersion='1.0'


banner="
                                   ╓
                        ╕         ╒╣╕                     ╣╣╣─    ╦╣╣
                ╓      ║╬         ╣╣╣      ╒             ╣╣╣─  ╒╣╣╩╙╣╬║╣
                ╣╕     ╣╣        ╫╣ ╫╣     ╡  ╔         ╣╣╣   ╦╣╩   ║╣╬
               ╣╣╣    ║╣╣╬      ╔╣╩  ╫╣╖  ╞╬  ╣╣       ╣╣╣   ╣╣╬    ╞╩
             ╒╣╣╩╣╣╖ ╔╣╬╣╣╕    ╔╣╣╗╗╦╦╣╣╦╦╣╣  ╣╣╣     ╣╣╣     ╙╣╣╣╦╗╖
            ╔╣╣╜  ╝╣╣╣╜ ╙╣╣═╩╜║╣╣╜     ╫╣╖     ╣╣╣  ╒╣╣╣          ╠╜╝╣╣╣╣╗╖
          ╓╣╣╩           ╚╣╣ ╦╣╬        ╚╣╗     ╣╣╬╓╣╣╬      ╓╦╣╣╣╩      ╙╙╝╣╣╣╗╖
        ╒╣╣╬╗╗╗           ╚╣╣╖           ╙╣╣╗   ╙╣╣╣╣╩    ╓╣╣╩╙ ║╣             ╙╣╣╣╖
      ╓╣╣╝╜╙╙╙╙            ╚╣╣╖╦           ╙╝╣╗╖ ╫╣╣╬    ├╣╣╖    ╬           ╓╓╗╣╣╣╩
                       ║╣╣╣╣╣╣╣╣╣╖           ╓╣╣╣ ╣╬      ╙╙╝╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╝╝╜╙╙
                             └╙╙╨╝╝╝╝╝╝╝╝╝╨╜╜╙╙╙   ╣

		${BWhite}Mobile Application Vulnerability Scanner${Off} | ${BYellow}@sho_luv${Off}
"

# code from: https://natelandau.com/boilerplate-shell-script-template/

usage() {
  echo -e "${Off}${banner}${Off} 

Usage: $(basename $0) [OPTIONS]

 Required:
  -f <apk>	Andorid APK file to decompile and run static analysis
 
 Options:
  -v 		Verbose, show affected files
  -e 		Show how to exploit finding
  -h 		Show this help

"
}

if [ $# -eq 0 ]; then
	usage >&2;
    exit 0
else
	while getopts "hf:ve" option; do
	  case ${option} in
		h ) usage
			exit 0
			#echo "Usage: $0 -f file.apk [-h]"
			;;
		f ) APK="$OPTARG"
			rflag=true
			;;
		v ) VERBOSE=true
			;;
		e ) EXPLOIT=true
			;;
		*)
			echo "Invalid Option: -$OPTARG" 1>&2
			exit 1
			;;
	  esac
	done
fi

if [ -z $rflag ]; then
	usage
    echo "Required -f option is missing" >&2
    exit 1
fi

if [ -n "$APK" ]; then 
  	echo -e "${banner}"
	info=($(apkinfo $APK 2> /dev/null))
	echo -e " App Name: \t${BWhite}${info[4]}${Off}"
	echo -e " APK File: \t${BWhite}${info[1]}${Off}"
	echo -e " Package Name: \t${BWhite}${info[6]}${Off}"
	echo -e " Version Name: \t${BWhite}${info[9]}${Off}"
	echo -e " Version Code: \t${BWhite}${info[12]}${Off}"

	echo -e "\n${UWhite} Checking JAR File Misconfigurations ${Off}\n"
	d2j-dex2jar $APK -o apk.jar > /dev/null 2>&1	# create jar file from apk

		# Check is SSL is broken 

			echo -e " ${UWhite}Insufficient Certificate Validation${Off}\n"
			check1="$(zipgrep -al ALLOW_ALL_HOSTNAME_VERIFIER apk.jar 2>&1)"
			check2="$(zipgrep -al canAuthenticateAgainstProtectionSpace apk.jar 2>&1)"
			if [ -z "$check1" ]||[ -z "$check2" ]; then
				echo -n " Check Hostname Verified: "
				if [ -z "$check1" ]; then
					echo -e "\t\t${Green}ALLOW_ALL_HOSTNAME_VERIFIER not found! Manual testing needed.${Off}"
				else
					echo -e "\t\t${BRed}Vulnerable ${VERBOSE}${Off}"
					if [ -n "$VERBOSE" ]; then
						echo -e "ALLOW_ALL_HOSTNAME_VERIFIER found! :-> ${check1}"
					fi
				fi
				echo -n " Check can auth to protected space: "
				if [ -z "$check2" ]; then
					if [ -n "$VERBOSE" ]; then
						echo -e "\t${Yellow}canAuthenticateAgainstProtectionSpace not found! Manual testing needed.${Off}"
					else
						echo -e "\t${Green}Not Vulnerable${Off}"
					fi
				else
					echo -e "\t${BRed}Vulnerable ${Off}"
					if [ -n "$VERBOSE" ]; then 
						echo "canAuthenticateAgainstProtectionSpace found! :-> ${check2}"
					fi
				fi
			fi

			# Show how to exploit SSL Pinning
				if [ -n "$EXPLOIT" ]; then
					echo -ne " \n\t${BYellow}Exploit Cert Not Validated:${Off}"
					echo -e "\tInstall any valid certificat on device and attempt to capture "
					echo -e "${ANSWER}application traffic. This can be done with Burp Suite or Bettercatp"
					echo -e "${ANSWER}Install Cert iOS: ${BCyan}https://t.ly/WgJ9${Off}"
					echo -e "${ANSWER}Install Cert Android: ${BCyan}https://t.ly/MpIl${Off}"
					echo -e "${ANSWER}Install Cert Windows Mobile: ${BCyan}https://t.ly/In0K${Off}\n"
				fi


		# Check if application logs stuff

		echo -n " Checking app logging (Log.e calls): "
			location="$(zipgrep -al Log.e apk.jar 2>&1)"
			if [ -z "$location" ]; then
				echo -e "\t${Green}No calls to Log.e found${Off}"
			else
				echo -e "\t${BRed}Vulnerable ${Off}"
				if [ -n "$VERBOSE" ]; then
					echo -e "Log.e found! :-> check logs"
				fi
				#echo -e " Verify Commands: \n\t${Cyan}adb logcat${Collor_Off}"
				#echo "Log.e found! :-> ${location}" # list all affected files
			fi
			# Show how to exploit logging
				if [ -n "$EXPLOIT" ]; then
					echo -en " \n\t${BYellow}Exploit logging:${Off}"
					echo -e "\t\tLogging can be examined with logcat. This traffic can be captured and"
					echo -e "${ANSWER}examined or paresed while being captured. As an examples:"
					echo -e "${ANSWER}${BCyan}adb logcat -v time | grep '${info[6]}'${Off}"
					echo -e "${ANSWER}${BCyan}adb logcat -v time | grep -E \"credit|passw|ssn|social\"${Off}"
					echo -e "${ANSWER}${BCyan}adb logcat -v time > '${info[4]}.log'${Off}"
				fi

	rm apk.jar	# clean up jar file

	echo -e "\n${UWhite} Checking androidManifest.xml For Misconfigurations ${Off}\n"
	# decompile apk file to examin androidManifest.xml file
	apktool d $APK -f -o apk > /dev/null 2>&1

		# Check if app allows backups.

			echo -ne " Checking ${BWhite}Backups Allowed:${Off} "
			check1="$(grep 'android:allowBackup="false"' apk/AndroidManifest.xml)"
			if [ -z "$check1" ]; then 	# true if string is empty
				echo -e "\t\t${BRed}Vulnerable ${Off}"
				if [ -n "$VERBOSE" ]; then
					check2="$(grep 'android:allowBackup="true"' apk/AndroidManifest.xml)"
					if [ -n "$check2" ]; then
						echo "android:allowBackup=\"true\" found! :-> in apk/AndroidManifest.xml"
					else
						echo "android:allowBackup=\"false\" not explicitly set to prevent backups"
					fi
				fi
				# Show how to exploit logging
				if [ -n "$EXPLOIT" ]; then
					echo -en " \n\t${BYellow}Exploit Backups Allowed:${Off}"
					echo -e "\tIf backups are allowed it is possible to make a backup without"
					echo -e "${ANSWER}rooting the phone. This means any user can make a backup and view files"
					echo -e "${ANSWER}Commands to run:"
					echo -e "${ANSWER}${BCyan}adb backup ${info[6]}${Off}"
					echo -e "${ANSWER}${BCyan}( printf \"\\x1f\\x8b\\x08\\x00\\x00\\x00\\x00\\x00\" ; tail -c +25 backup.ab ) |  tar xfvz -${Off}\n"
				fi
			else
				echo -e "\t${Green}Not vulnerable${Off}"
			fi
		
		# Check if app allows auto backups.

			echo -ne " Checking ${BWhite}Auto Backups Allowed:${Off} "
			backup="$(grep 'android:fullBackupOnly="true"' apk/AndroidManifest.xml)"
			if [ -n "$backup" ]; then
				echo -e "\t${BRed}Vulnerable ${Off}"
				echo "android:fullBackupOnly=\"true\" found! :-> in apk/AndroidManifest.xml"
			else
				echo -e "\t${Green}Not vulnerable${Off}"
			fi

		# Check if app allows Key/Value backups.

			echo -ne " Checking ${BWhite}Key/Value Backups Allowed:${Off} "
			backup="$(grep 'android:backupAgent="true"' apk/AndroidManifest.xml)"
			if [ -n "$backup" ]; then
				echo -e "\t${BRed}Vulnerable ${Off}"
				echo "android:backupAgent=\"true\" found! :-> in apk/AndroidManifest.xml"
			else
				echo -e "\t${Green}Not vulnerable${Off}"
			fi

		# Check if app allows debugging.

			echo -ne " Checking ${BWhite}Debugging Enabled:${Off} "
			backup="$(grep 'android:debuggable="true"' apk/AndroidManifest.xml)"
			if [ -n "$backup" ]; then
				if [ -n "$VERBOSE" ]; then 
					echo -ne "\t\t${BRed}Vulnerable ${Off}"
					echo -e "android:debuggable=\"true\" found in apk/AndroidManifest.xml"
				else
					echo -e "\t\t${BRed}Vulnerable ${Off}"
				fi
				# Show how to exploit logging
				if [ -n "$EXPLOIT" ]; then
					echo -en " \n\t${BYellow}Exploit debuggable:${Off}"
					echo -e "\t\tIf debugging is enabled, it is possible to login as the application"
					echo -e "${ANSWER}and access the applications directory/files. Command to run"
					echo -e "${ANSWER}${BCyan}adb shell run-as ${info[6]}${Off}"
				fi
			else
				echo -e "\t\t${Green}Not vulnerabled${Off}"
			fi

	echo ""
	rm -rf apk	# delete decompiled apk files
fi
