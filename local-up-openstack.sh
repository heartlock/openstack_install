#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Should setup those environment variables before running this scripts.
export HOSTNAME=${HOSTNAME:-"k8s"}
export IF_NAME=${IF_NAME:-"eth0"}
export IF_IP=${IF_IP:-""}

# Import essential files
source util.sh
source openstack.sh

if [[ "${IF_IP}" == "" ]]; then
	local_ip=$(kube::util::get_ip)
	export IF_IP=${local_ip}
fi

# Verify system
kube::util::verify_system

# Common setup
kube::util::setup_hostname
kube::util::setup_ssh
kube::util::setup_network

# Install packages
kube::util::setup_openstack

echo "Local up openstack done."
