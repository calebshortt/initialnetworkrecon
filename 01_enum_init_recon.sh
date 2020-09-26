#!/bin/bash

#	INR
#	Initial Network Recon (INR) Scan of Targeted Network
#	
#	Author: Caleb Shortt
#	Date: July 2020
#
#	Usage: 		./script.sh <ip/subnet>
#	Example:	./script.sh 192.168.34.1/24
#


dir_inr_scans="inr_scans"


GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
NC='\033[0m'

if [[ $# -eq 0 ]]; then
	echo "Usage: ./$0 <target>"
	echo "Example: ./$0 192.128.34.1"
	echo "Example: ./$0 192.168.34.1/24     << NOTE: This is ill-advised."
	exit 1
fi

echo ""
echo ""
echo -e "${ORANGE}                Caleb's Sweet Sweet Network Recon Script...?${NC}"
echo ""
echo ""
echo "Running Initial Network Recon (INR) on $1"
echo "Commands to be run:"
echo "    [1] sudo nmap -sV -sC -O --top-ports 100 --open --reason -oA $dir_inr_scans/nmap_initial_$1 $1"
echo "    [2] sudo nmap -sUV --top-ports 100 --open --reason -oA $dir_inr_scans/nmap_initial_udp_$1 $1"
echo "    [3] sudo nmap -sC -sV -O -p- --open --reason -oA $dir_inr_scans/nmap_full_$1 $1"
echo "    [DISABLED] [4] sudo nmap -sUV -p- --open --reason -oA $dir_inr_scans/nmap_udp_$1 $1"
echo ""
echo "    If :53 found, will attempt to dns enumerate all machines on subnet"
echo "    [DISABLED] If :80 found, will kick off gobuster and nikto"
echo "        [NOT RUN] gobuster dir -u $1 -w /usr/share/seclists/Discovery/Web-Content/common.txt -t 80 -a Linux -e -k"
echo "        [NOT RUN] gobuster dir -s '200,204,301,302,307,403' -u $1 -w /usr/share/seclists/Discovery/Web-Content/common.txt -t 80 -a 'Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0' -e -k"
echo "        [NOT RUN] nikto -h http://$1"
echo "        [NOT RUN] wpscan -u $1"
echo ""
echo "    [DISABLED] If SMB, run..."
echo "        [NOT RUN] sudo nmap -p 445 -vv --script=smb-vuln-cve2009-3103.nse,smb-vuln-ms06-025.nse,smb-vuln-ms07-029.nse,smb-vuln-ms08-067.nse,smb-vuln-ms10-054.nse,smb-vuln-ms10-061.nse,smb-vuln-ms17-010.nse $1"
echo "        [NOT RUN] sudo nmap -p 445 -vv --script=smb-enum-shares.nse,smb-enum-users.nse $1"
echo "        [NOT RUN] sudo enum4linux -a $1"
echo ""
echo ""
echo -e "${RED}    THIS script requires sudo to fully complete. Did you sudo?${NC}"
echo -e "${RED}    If you entered a subnet you are about to hit it hard with scans. You've been warned.${NC}"
echo ""
echo ""

sleep 5s

if [[ ! -d "./$dir_inr_scans" ]]; then
	echo "$dir_inr_scans directory does not exist. Creating it."
	mkdir ${dir_inr_scans}
fi


subnet=$(echo "$1" | awk -F"." '{printf("%s.%s.%s", $1, $2, $3)}')
num_top_ports=1000

echo -e "${BLUE}Starting scans as background processes...${NC}"

sudo nmap -sV -sC -O --top-ports $num_top_ports --open --reason -oA $dir_inr_scans/nmap_initial_$1 $1 2>&1 > /dev/null & echo -e "${GREEN}[1] PID: $!${NC}"
PID1=$!

sudo nmap -sUV --top-ports $num_top_ports --open --reason -oA $dir_inr_scans/nmap_initial_udp$1 $1 2>&1 > /dev/null & echo -e "${GREEN}[2] PID: $!${NC}"
PID2=$!

sudo nmap -sC -sV -O -p- --open --reason -oA $dir_inr_scans/nmap_full_$1 $1 2>&1 > /dev/null & echo -e "${GREEN}[3] PID: $!${NC}"
PID3=$!

sudo nmap -sUV -p- --open --reason -oA $dir_inr_scans/nmap_udp_$1 $1 2>&1 > /dev/null & echo -e "${GREEN}[4] PID: $!${NC}"
PID4=$!

echo -e "${BLUE}Results will be saved to $dir_inr_scans/${NC}"
echo -e "${BLUE}Waiting for initial scan [1] to complete before proceeding...${NC}"

wait $PID1
echo -e "${GREEN}[1] (PID:$PID1) has completed.${NC}"
cat $dir_inr_scans/nmap_initial_$1.nmap

# DNS SCAN ------------------------------------------------------------------------------
# Get all machines with port 53 open and try to enumerate all the machines on the subnet
pt53_results=$(cat $dir_inr_scans/nmap_initial_$1.gnmap | grep 53/ | cut -f 2 -d " ")
dns_lookup=($pt53_results)

if [[ ! -z "${dns_lookup}" ]]; then
	echo ""
	echo ""
	echo -e "${GREEN}DNS servers discovered. Attempting Enumeration...${NC}"

	dns_server=""
	echo "    Testing discovered DNS servers for response..."
	for srv in ${dns_lookup[*]}; do
		echo "    Trying ${srv}..."
		tmp=$(nslookup ${subnet}.1 ${srv} | grep -E "no servers could be reached|SERVFAIL")
		# SPECIFICALLY look for failures, if none, we're good to go
		if [[ -z "${tmp}" ]]; then
			echo -e "${GREEN}    RESPONDED!${NC}"
			dns_server=${srv}
			break
		fi
	done

	if [[ -n "${dns_server}" ]]; then
		echo "    Using ${dns_server} to enumerate network machines..."
		echo -e "${BLUE}    Results will be saved to ${dir_inr_scans}/dns_sweep_$1.txt${NC}"

		rm -f ${dir_inr_scans}/dns_sweep_$1.txt
		touch ${dir_inr_scans}/dns_sweep_$1.txt
		for host in {1..255}; do
			tmp=$(nslookup ${subnet}.${host} ${dns_server})
			echo "${subnet}.${host} ${tmp}" | grep -v "can't find" | awk -F" " '{printf("%s %s\n", $1, $5)}' | sed 's/.$//' | sed -e /^$/d | tee ${dir_inr_scans}/dns_sweep_$1.txt
		done
	else
		echo -e "${RED}    No DNS servers responding to queries${NC}"
	fi
fi



# :80 SCANS ------------------------------------------------------------------------------
pt80_results=$(cat inr_scans/nmap_initial_10.11.1.71.gnmap | grep 80/ | cut -f 2 -d " ")
pt80_IPs=($pt80_results)

cmd_nikto="nikto -h http://${pt80_IPs[0]} -o ./${dir_inr_scans}/nikto_${pt80_IPs[0]}.txt 2>&1 > /dev/null"

#if [[ ! -z "${pt80_IPs}" ]]; then
#	echo "Running nikto and gobuster against the FIRST IP with open HTTP port..."
#
#	#nikto -h http://${pt80_IPs[0]} -o ./${dir_inr_scans}/nikto_${pt80_IPs[0]}.txt 2>&1 > /dev/null & 
#	$cmd_nikto &
#	echo -e "    ${GREEN}nikto @ ${pt80_IPs[0]} [PID]: $!${NC}"
#
#fi


#for ip in ${pt80_IPs[*]}; do
#	echo "Attempting to run gobuster and nikto against ${ip}..."
#
#	nikto -h http://${ip} -o ./${dir_inr_scans}/nikto_${ip}.txt 2>&1 > /dev/null & 
#	echo -e "    ${GREEN}nikto @ ${ip} [PID]: $!${NC}"
#done


#if [[ ! -z "${pt80_IPs}" ]]; then
#	echo -e "${GREEN}Discovered open port 80 (HTTP).${NC}"
#	sleep 3s
#	for pt80ip in ${pt80_IPs[*]}; do
#		sleep 2s
#		target="http://${pt80ip}"
#		echo "Attempting to run gobuster and nikto against ${pt80ip}..."
#
#		#gobuster dir -w /usr/share/seclists/Discovery/Web-Content/common.txt -u "http://${pt80ip}" -o "./${dir_inr_scans}/gobuster_${pt80ip}" -r -s "200,204,301,302,307,401,403,500" -e 2>&1 > /dev/null & echo -e "    ${GREEN}gobuster @ $pt80ip [PID]: $!${NC}"
#
#		#gobuster dir -w /usr/share/seclists/Discovery/Web-Content/common.txt -u http://${pt80ip}
#
#		#nikto -h ${pt80ip} -output "./${dir_inr_scans}/nikto_${pt80ip}.txt" 2>&1 > /dev/null & echo -e "    ${GREEN}nikto @ $pt80ip [PID]: $!${NC}"
#		sudo nikto -h http://10.11.1.71 -output "./${dir_inr_scans}/nikto_${pt80ip}.txt"
#	done
#
#fi






wait $PID2
echo -e "${GREEN}[2] (PID:$PID2) has completed.${NC}"
wait $PID3
echo -e "${GREEN}[3] (PID:$PID3) has completed.${NC}"
wait $PID4
echo -e "${GREEN}[4] (PID:$PID4) has completed.${NC}"


echo -e "${BLUE}All initial scans complete.${NC}"








echo ""
echo ""
echo -e "${GREEN}Initial Network Recon Debrief"
echo -e ""
echo -e "    All results are saved in <current_dir>/${dir_inr_scans}/"
echo -e ""
echo -e "    Scan Inventory:"
echo -e "        nmap:    initial (top ${num_top_ports} ports), full, and udp scans"
echo -e "        dns:     (if :53 found) DNS enumeration attempt of subnet"
echo -e ""

echo -e "${NC}"










