# Initial Network Recon (INR)
A simple Linux script for initial network reconnaissance on a target network

# Usage
```
sudo ./01_enum_init_recon.sh <IP>
```

# Behaviour
The script runs four nmap scans in separate processes: 

- Top 1000 TCP ports
- All TCP ports
- Top 100 UDP ports
- All UDP ports (Takes a VERY long time -- usually cancelled)

If a host with port 53 (DNS) is discovered, the script will automatically attempt DNS enumeration against that host.

A directory called inr_scans will automatically be created in the location that the script is executed to store the various nmap results.

The banner contains the commands executed for the specific host so that the assessor can copy and paste them and modify them as needed.

**IMPORTANT**

- This script will not compensate for hosts that do not respond to ping requests. In this case, nmap will require the -Pn flag, and the assessor will have to manually run the scripts. 
- It is **HIGHLY** recommended that you **DO NOT** run this script against an entire subnet (10.10.10.10/24) as all scripts will be run against all hosts in the subnet and cause a lot of traffic/headaches.

