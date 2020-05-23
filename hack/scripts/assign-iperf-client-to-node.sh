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

container_ip="$2"

cat <<EOF > /dev/stdout | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: iperf-client-$1-$RANDOM
  namespace: default
spec:
  privileged: true
  hostNetwork: true
  containers:
  - name: iperf-client
    image: quay.io/jharrington22/network-toolbox:latest
    command: ["iperf"]
    args: ["-c", "$container_ip", "-t", "600", "-P", "300"]
  nodeSelector:
    kubernetes.io/hostname: $1
EOF
