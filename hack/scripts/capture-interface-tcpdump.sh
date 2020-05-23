#!/bin/bash

usage() {
    cat <<EOF
    usage: $0 [ ARG ]

    ARG 
    <label-name>    Node label value for kubernetes.io/arch=amd64,kubernetes.io/hostname
EOF
}

if [ -z $1 ]; then
    usage
    exit 1
fi

oc exec -ti "$1" -- tcpdump -i vxlan_sys_4789 -nn -s0 -w vxlan_sys_4789-${HOSTNAME}-$(date +%d%m%Y-%H%M%S).pcap
