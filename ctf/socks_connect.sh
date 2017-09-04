#!/bin/bash

# Start a SOCKS proxy for a target machine. Flags:
# -D: Tunnel port number
# -f: Fork to background
# -C: Compresses data to send
# -q: Quiet mode
# -N: No remote command (just forwarding)

# Default vars
default_user="ctfuser"
default_url="ctf.example.com"
default_port_num=1337

# Default
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then

    printf "Usage: $0 <sudoUserName> <domainOrIP> <portNum>\n"
    printf "Assuming default: $default_user@$default_url:$default_port_num\n"
    ssh -D $default_port_num -f -C -q -N $default_user"@"$default_url

# User-specified target
else

    ssh -D $3 -f -C -q -N $1@$2

fi

# Verify
ps aux | grep ssh
