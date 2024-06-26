#!/bin/bash
#//--------------------------------------------------------------
#// WILSON LAU SCRIPT                  ^__^
#// PROJECT:INFO EXTRACTOR             (oo)\_______
#//                                    (__)\       )\/\
#// CLASS: CFC190324                       ||----w||
#//			                   ||     ||
#//--------------------------------------------------------------

#Define color variables
YELLOW='\033[1;33m'
WHITE='\033[0m'

#==================================================================
#==================================================================
#Fetch user name.
	name=$(id -u -n)

#Display user name out.
	figlet "Hello $name$"
	
#Fetch sudo password.
echo "This script requires sudo privileges. 
Please enter your password."
	sudo -v
#==================================================================
#==================================================================

#Fetch public IP using ifconfig.
	PUBLIC_IP=$(curl -s ifconfig.io)

#Display public IP address.
	echo -e "\nYour Public IP Address:\n${YELLOW}$PUBLIC_IP${WHITE}"
	
#==================================================================
#==================================================================

#Fetch LAN IP using ifconfig.
	LAN_IP=$(ifconfig | grep inet | awk '{print $2}' | head -n1)

#Display public IP address.
	echo -e "\nYour Internal IP Address:\n${YELLOW}$LAN_IP${WHITE}"

#==================================================================
#==================================================================

#Fetch MAC Address.
	MAC_ADD=$(ifconfig | grep ether | awk '{print $2}' | sed -r 's/([0-9a-fA-F]{2}:){3}/xx:xx:xx:/')

	
#Display MAC Address.
	echo -e "\nYour Mac Address:\n${YELLOW}$MAC_ADD${WHITE}"

#==================================================================
#==================================================================

#Fetch Top5 CPU usage in %.
    CPU5=$(ps -eo comm,%cpu --sort=-%cpu | head -n 6 | tail -n +2)

#Display Top5 CPU usage in %.4d res
	echo -e "\nYour Top 5 CPU Usage In Percentage:\n${YELLOW}$CPU5${WHITE}"

#==================================================================
#==================================================================

#Fetch Top5 Memory usage in %.
    MEM5=$(free -h | awk 'NR==1 {print $1,$2,$3} NR==2 {print $1,$2,$3,$4}')
    
#Display Top5 Memory usage in %.
	echo -e "\nYour Top 5 Memory Usage In Percentage:\n${YELLOW}$MEM5${WHITE}"

#==================================================================
#==================================================================

#Fetch Active System Service and Status .
    System_Service=$(systemctl list-units --type=service --state=active)
    
#Display Active System Service and Status.
	echo -e "\nYour Active Service and Status:\n${YELLOW}$System_Service${WHITE}"

#==================================================================
#==================================================================

#Fetch Top 10 Files by size from /home dir .
    TOP10_SIZE=$(sudo du -ah /home | sort -n -r | head -n 10)
    
#Display Top10 Files by size from /home dir.
	echo -e "\nTop 10 Files by size from /HOME/:\n${YELLOW}$TOP10_SIZE${WHITE}"


echo -e 
figlet "Have A Nice Day"
#==================================================================
#=========================END OF SCRIPT============================
#==================================================================
exit 0
