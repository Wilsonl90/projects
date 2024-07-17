#!/usr/bin/python3
# //--------------------------------------------------------------
# // WILSON LAU SCRIPT                  ^__^
# // PROJECT: LOG ANALYZER              (oo)\_______
# // STUDENT ID : S16                   (__)\       )\/\
# // CLASS: CFC190324                       ||-----||
# // TRAINER: JAMES LIM                     ||     ||
# //--------------------------------------------------------------

# =========================================
# Modules
# =========================================

import time
import sys

# =========================================
# Font Colours
# =========================================

RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
NORM = "\033[35m"

# =========================================
# Reading of Log
# =========================================

def auth_log(file_path, option):
	with open(file_path, 'r') as file:
		for line in file:
			if option == 1:
				if "useradd[" in line:
					auth_add_user(line)
			elif option == 2:
				if "userdel[" in line:
					auth_delete_user(line)
			elif option == 3:
				if "passwd[" in line:
					auth_change_password(line)
			elif option == 4:
				if "su[" in line or "pam_unix(su-l:session): session opened" in line:
					auth_su_command(line)
			elif option == 5:
				if "sudo:" in line:
					if "authentication failure" in line or "incorrect password attempts" in line:
						auth_failed_sudo(line)
			elif option == 6:
				if "sudo:" in line:
					if "authentication failure" in line or "incorrect password attempts" in line:
						auth_failed_sudo(line)
					else:
						auth_sudo_command(line)
			elif option == 7:
				exitscript()
				
	return_mainmenu()

	
# =========================================
# Checking if any user has been added
# =========================================

def auth_add_user(line):
	parts = line.split()
	timestamp = " ".join(parts[0:3])
	if 'user: name=' in line:
		user = line.split('user: name=')[1].split(',')[0]
		print(f"{NORM}User added: {RED}{user} {NORM}at {CYAN}{timestamp}")
		time.sleep(1)
		
# =========================================
# Checking if any user has been deleted
# =========================================

def auth_delete_user(line):
	parts = line.split()
	timestamp = " ".join(parts[0:3])
	if 'user ' in line:
		user = line.split('user ')[1].split()[0]
		print(f"{NORM}User deleted : {RED}{user} {NORM}at {CYAN}{timestamp}")
		time.sleep(1)
		
# =========================================
# Checking if password has changed
# =========================================

def auth_change_password(line):
	parts = line.split()
	timestamp = " ".join(parts[0:3])
	if 'passwd[' in line and 'password for ' in line:
		user = line.split('password for ')[1].split()[0]
		print(f"{NORM}Password changed for user : {RED}{user} {NORM}at {CYAN}{timestamp}")
		time.sleep(1)
		
# =========================================
# SU commands lines
# =========================================
def auth_su_command(line):
	parts = line.split()
	timestamp = " ".join(parts[0:3])
	if 'session opened for user ' in line:
		user = line.split('session opened for user ')[1].split()[0]
		print(f"{NORM}SU command used by : {RED}{user} {NORM}at {CYAN}{timestamp}")
		time.sleep(1)
	elif '(to ' in line:
		user = line.split('(to ')[1].split(')')[0]
		print(f"{NORM}SU command used to switch to user : {RED}{user} {NORM}at {CYAN}{timestamp}")
		time.sleep(1)
		
# =========================================
# Sudo commands lines
# =========================================

def auth_sudo_command(line):
	parts = line.split()
	timestamp = " ".join(parts[0:3])
	if 'sudo: ' in line and ' COMMAND=' in line:
		user = line.split('sudo: ')[1].split()[0]
		command = line.split('COMMAND=')[1]
		print(f"{NORM}Sudo command used by : {RED}{user} {NORM}at {GREEN}{timestamp} - {CYAN}Command: {command}")
		time.sleep(1)

def auth_failed_sudo(line):
	parts = line.split()
	timestamp = " ".join(parts[0:3])
	if 'sudo: ' in line and ('authentication failure' in line or 'incorrect password attempts' in line):
		user = line.split('sudo: ')[1].split()[0]
		print(f"{RED}ALERT!!!! {NORM}Failed sudo attempt by : {RED}{user} {NORM}at {CYAN}{timestamp}")
		time.sleep(1)

# =========================================
# Return back to main menu
# =========================================
def return_mainmenu():
	choice = input(f"\n{CYAN}Do you want to return to the main menu(y/n): ").lower()
	print("\n")
	if choice =='y':
		main()
	else:
		exitscript()

# =========================================
# Exit the script
# =========================================
def exitscript():
	print(f"{RED}==================================================")
	print(f"{GREEN}Exiting the script now .....")
	print(f"{GREEN}Goodbye, have a nice day =) ")
	print(f"{RED}==================================================")
	time.sleep(3)
	sys.exit()

# =========================================
# Main Menu 
# =========================================
print(f"\n")
print(f"{RED}==================================================")
print(f"{NORM}Welcome to {GREEN}Wilson's {RED}LOG ANALYZER")
print(f"{RED}==================================================\n")
time.sleep(3)

def main():
	print(f"{CYAN}Select an option to check from the log:\n")
	time.sleep(1)
	print(f"{RED}1.{YELLOW} Check user added. ")
	time.sleep(1)
	print(f"{RED}2.{YELLOW} Check user deleted. ")
	time.sleep(1)
	print(f"{RED}3.{YELLOW} Check password changed. ")
	time.sleep(1)
	print(f"{RED}4.{YELLOW} Check su commands used. ")
	time.sleep(1)
	print(f"{RED}5.{YELLOW} Check failed sudo commands. ")
	time.sleep(1)
	print(f"{RED}6.{YELLOW} Check all sudo commands. ")
	time.sleep(1)
	print(f"{RED}7.{YELLOW} Exit. ")
	time.sleep(1)
	option = int(input(f"{CYAN}Enter your choice {RED}(1-7): "))
	print("\n")
	auth_log('/var/log/auth.log', option)
	exitscript()
	
main()

