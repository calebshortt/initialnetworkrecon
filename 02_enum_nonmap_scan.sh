#!/bin/bash

#	NON-NMAP Port Scanner
#	
#	Author:	Caleb Shortt
#	Date: 	July 2020
#
#	Usage:	./script.sh <IP>
#	

# NOTE: If you need to scan a list of IPs, try this in bash:
# 
# 	for host in {1..255}; do ./02_enum_nonmap_scan.sh 10.11.1.${host}; done
# 



if [[ $# -eq 0 ]]; then
	echo "Usage: ./script.sh <IP>"
	exit 1
fi

echo "Scanning Target: $1..."
echo ""

top10=(20 21 22 23 25 80 110 139 443 445 3389)

for port in "${top10[@]}"; do
	timeout 1 (echo > /dev/tcp/"$1/${port}") > /dev/null 2>&1 && echo "Host $1 has ${port} open" || echo "Host $1 has ${port} closed"
done




