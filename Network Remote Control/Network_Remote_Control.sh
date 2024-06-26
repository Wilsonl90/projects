#!/bin/bash
#//--------------------------------------------------------------
#// WILSON LAU SCRIPT                  ^__^
#// Network Remote Control             (oo)\_______
#// STUDENT ID: S16                    (__)\       )\/\
#// CLASS: CFC190324                       ||----w||
#// CFC TRAINER: Samson Xiao               ||     ||
#//--------------------------------------------------------------    
#==================================================================
#==================================================================
# Script Config

#Define color variables
Y='\033[1;33m' 
P='\033[0;35m' 
R="\033[0;31m" 

# Set permissions and environment variable
sudo chmod o+w /var/log  												#Give permission for log files
export DEBIAN_FRONTEND=noninteractive									#Set the DEBIAN_FRONTEND environment variable to noninteractive

#==================================================================
#==================================================================
# Checking if Nipe is installed.
if [ ! -x ./nipe ]; 
then
	echo -e "${Y}Nipe is not installed.${R}(Require apt-get and apt-upgrade). ${Y}"
    read -p "Do you want to install it? (Yes/No): " installnipe
		if [ "$installnipe" == "Yes" ] || [ "$installnipe" == "yes" ]
		then
			echo "Installing Nipe..."
			sudo apt-get update && sudo apt-get -y upgrade
			git clone --quiet https://github.com/htrgouvea/nipe && cd nipe
			sudo apt-get -y install cpanminus							 #Cpanminus installment
			cpanm --installdeps --notest --auto-cleanup -n 				 #Installs the dependencies
			sudo cpan install Switch JSON LWP::UserAgent Config::Simple	 #Installs Switch json
			sudo perl nipe.pl install									 #Installs Nipe
			echo -e "\nNipe installed successful. Bashing the script in 5 seconds"
			sleep 5
		else
			echo "Exiting script. Nipe will not be installed..."
		fi
    exit 1
fi

#==================================================================
#==================================================================
# Check if GEOIPLOOKUP is installed.

if ! command -v geoiplookup &> /dev/null
then
    echo "geoiplookup is not installed. Installing now..."
    sudo apt update
    sudo apt-get update
    sudo apt-get -y install geoip-bin									#Install Geoiplookup
fi

#==================================================================
#==================================================================
# Check if SSHPASS is installed

if ! command -v sshpass &> /dev/null; then
    echo "sshpass is not installed. Installing now..."
    sudo apt-get -y install sshpass										#Install SSHAPASS
    echo -e "\n${Y}Installation of application sucessful."
fi

#==================================================================
#==================================================================
# Startup script message

echo -e "\n${R}======================================================"
figlet " Network RC"
echo -e "${R}======================================================"

#==================================================================
#==================================================================
# Connecting to Nipe services.

MAX_RETRIES=5
cd nipe

check_nipe_connection() {
	
# Check if connected through Nipe.

for ((attempt=1; attempt<=$MAX_RETRIES; attempt++)); 
do
    echo -e  "${Y}\nConnecting to Nipe... Attempt $attempt \n"
    sudo perl nipe.pl start
    sleep 5  															# Wait for a few seconds to ensure connection.
    # Check if connected through Nipe
    if sudo perl nipe.pl status | grep -q "true"; 
    then
        echo "Connected through Nipe successfully."
        sleep 5
        return 0
    else
        echo -e  "\nUnable to connect through Nipe on attempt $attempt."
        sleep 5
        if [ $attempt -lt $MAX_RETRIES ]; 
        then
            echo "Retrying in $RETRY_DELAY seconds..."
            sudo perl nipe.pl restart
            sleep 5
        fi
	fi
done
		echo "Failed to connect through Nipe after $MAX_RETRIES attempts. Exiting script."
		sudo perl nipe.pl stop
		exit 1
}

#==================================================================
#==================================================================
# Start of the Script // Check if connected through NIPE.

check_nipe_connection

#==================================================================
#==================================================================
# Connected to nipe and grepping for spoofed IP & Country.

echo -e "\n${R}======================================================"
echo -e "\n${P}YOU ARE CONNECTED AS ${R}ANONYMOUS"
spoofed_ip=$(curl -s ifconfig.io)
spoofed_country=$(geoiplookup $spoofed_ip )
echo -e  "\n${P}Spoofed IP: $spoofed_ip \n$spoofed_country \n "
echo -e "${R}======================================================"
sleep 5

#==================================================================
#==================================================================
# Get the user input for the domain/url to scan.

echo -e "\n${Y}Input the domain/URL to scan:${P}" 
read domain
sleep 3

#==================================================================
#==================================================================
# Require input for SSH details.
echo -e "${Y}Input Remote Server IP : ${P}" 
read ssh_ip
sleep 3
echo -e "${Y}Input Username : ${P}" 
read ssh_username
sleep 3
echo -e "${Y}Input Password : ${P}" 									#Hide input due to privacy
read -s ssh_password

#==================================================================
#==================================================================
# SSH config details
remoteserver_ip=$(sshpass -p $ssh_password ssh -o StrictHostKeyChecking=no $ssh_username@$ssh_ip "curl -s https://api.ipify.org")																		
remoteserver_country=$(sshpass -p $ssh_password ssh -o StrictHostKeyChecking=no $ssh_username@$ssh_ip "whois $remoteserver_ip | grep -i country | awk '{print $2}' | head -1") 								
remoteserver_uptime=$(sshpass -p $ssh_password ssh -o StrictHostKeyChecking=no $ssh_username@$ssh_ip "uptime -p | awk -F, '{print $1}'")

#==================================================================
#==================================================================
# SSHPASS with NMAP commands and output to a .log
echo -e "\n${Y}Connecting to ${R}$ssh_ip ${Y}... \n"
sleep 5
echo -e "${R}======================================================"
echo -e "\n${Y}Connected to${R} $ssh_ip"
echo -e  "\n${P}Remote Server External IP: $remoteserver_ip \nRemote server country:$remoteserver_country \nRemote server uptime: $remoteserver_uptime \n "																				
sleep 5
echo -e "${Y}Scanning with Nmap at${R} $ssh_ip ......"
sshpass -p $ssh_password ssh -o StrictHostKeyChecking=no $ssh_username@$ssh_ip "nmap -Pn -sV $domain > /tmp/nmapscan_${domain}_results.txt"
sleep 5
echo -e "${Y}Nmap Scan completed. Results save to ${P} /tmp/nmapscan_${domain}_result.txt"
sleep 5

if [ $? -ne 0 ]; 
then
echo -e "${Y}\nFailed to connect to the remote server or perform the scan. Exiting the script..."
    exit
fi

#==================================================================
#==================================================================
# SSHPASS with SCP commands 

echo -e "${Y}\nCopying ${R}/tmp/nmap_${domain}_result.txt ${Y}to local machine directory ${R}/var/log/nmap_${domain}_result.txt...${Y}"
sshpass -p "$ssh_password" scp -o StrictHostKeyChecking=no $ssh_username@$ssh_ip:/tmp/nmapscan_${domain}_results.txt /var/log/nmap_${domain}_results.txt
sleep 5
timestamp=$(date '+%A %Y-%m-%d %H:%M:%S')
echo -e " $timestamp - Scanned domain: ${domain}\n" | sudo tee -a >> /var/log/nmap_${domain}_results.txt
sleep 5
echo -e "${Y}\nLog saved in ${R}var/log/nmap_${domain}_results.txt\n"
sleep 5
#==================================================================
#==================================================================
# Stop nipe

sudo perl nipe.pl stop													#Stop nipe service
echo -e "${P}Script completed. Nipe service stopped\n\n"
sleep 4
echo -e "${R}======================================================"
figlet "Goodbye"
echo -e "${R}======================================================"
sleep 4


exit
#==================================================================
#==================================================================
# End of script.
