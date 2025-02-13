#!/bin/bash
# usage: ./autodiscovery.sh [community] [mapping_file] [ip_or_subnet ...]
# example: ./autodiscovery.sh public sysObjectIDs.json 45.10.11.1 20.20.21.1 15.15.15.2

community=${1:-public}
mapping_file=${2:-sysObjectIDs.json}
shift 2
targets=("$@")

if [ ${#targets[@]} -eq 0 ]; then
  local_cidr=$(ip -o -f inet addr show | grep -m1 'scope global' | awk '{print $4}')
  if [[ -z "$local_cidr" ]]; then
    echo "unable to auto-discover local subnet"
    exit 1
  fi
  targets=("$local_cidr")
fi

ip_to_int() {
  IFS=. read -r a b c d <<< "$1"
  echo $(( (a << 24) | (b << 16) | (c << 8) | d ))
}

int_to_ip() {
  local ip_int=$1
  echo "$(( (ip_int >> 24) & 0xFF )).$(( (ip_int >> 16) & 0xFF )).$(( (ip_int >> 8) & 0xFF )).$(( ip_int & 0xFF ))"
}

scan_ip() {
  local ip="$1"
  output=$(timeout 1 snmpget -v2c -c "$community" "$ip":161 1.3.6.1.2.1.1.2.0 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    return
  fi
  oid=$(echo "$output" | awk -F"OID: " '{print $2}')
  [[ -z "$oid" ]] && return
  # remove trailing .0 if present
  [[ "$oid" == *.0 ]] && oid=${oid%.0}
  # replace "iso" prefix with "1"
  if [[ "$oid" == iso.* ]]; then
    oid="1${oid:3}"
  fi
  mapping=$(jq -r --arg oid "$oid" 'if .[$oid] then "\(.[$oid].vendor) \(.[$oid].category) \(.[$oid].model)" else empty end' "$mapping_file")
  if [[ -n "$mapping" ]]; then
    echo "$ip: $mapping"
  else
    echo "$ip: unknown device with sysobjectid $oid"
  fi
}

scan_subnet() {
  local target="$1"
  if [[ "$target" == */* ]]; then
    local base_ip="${target%/*}"
    local cidr="${target#*/}"
    local ip_int=$(ip_to_int "$base_ip")
    local netmask=$(( (0xffffffff << (32 - cidr)) & 0xffffffff ))
    local network_int=$(( ip_int & netmask ))
    local broadcast_int=$(( network_int | (0xffffffff - netmask) ))
    echo "scanning subnet $(int_to_ip $network_int)/$cidr ..."
    for (( i = network_int + 1; i < broadcast_int; i++ )); do
      scan_ip "$(int_to_ip $i)"
    done
  else
    scan_ip "$target"
  fi
}

for target in "${targets[@]}"; do
  scan_subnet "$target"
done
