# SNMP Auto Discovery
Simple bash script to autodiscover SNMP devices on provided subnets and identify device vendor, category and model

# How to use
$ ./autodiscovery.sh [community] [mapping_file] [ip_or_subnet ...]

# Usage examples
$ ./autodiscovery.sh public sysObjectIDs.json 15.15.15.0/24
scanning subnet 15.15.15.0/24 ...
15.15.15.2: Juniper Networks, Inc. Router Juniper T4000

$ ./autodiscovery.sh public sysObjectIDs.json 45.10.11.0/24
scanning subnet 45.10.11.0/24 ...
45.10.11.1: ciscoSystems Router Cisco ASR9006

$ ./autodiscovery.sh public sysObjectIDs.json
scanning subnet 10.10.100.0/24 ...
