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

cat <<EOF > /dev/stdout | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: network-test-$1
  namespace: default
spec:
  privileged: true
  hostNetwork: true
  containers:
  - name: network-test
    image: quay.io/jharrington22/network-toolbox:latest
  nodeSelector:
    kubernetes.io/hostname: $1
EOF
