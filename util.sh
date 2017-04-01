#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

function kube::util::verify_system() {
	echo "Start $FUNCNAME"

	version=$(cat /etc/redhat-release)
	if [[ "$version" == "" ]]; then
		echo "Only CentOS 7 or newer is supported."
		exit 1
	fi

	if ! [[ "$version" =~ "CentOS Linux release 7." ]]; then
		echo "Only CentOS 7 or newer is supported."
		echo "Run 'yum -y update' upgrade the system."
		exit 1
	fi
}

function kube::util::setup_ssh() {
	echo "Start $FUNCNAME"
	local key_path="/root/.ssh/id_rsa"
        if ! [[ -e ${key_path} ]] ; then
		ssh-keygen -f ${key_path} -t rsa -N ''
	fi
	cat "${key_path}.pub" >> /root/.ssh/authorized_keys
	ssh-keyscan $HOSTNAME >> ~/.ssh/known_hosts
}

function kube::util::setup_hostname() {
	echo "Start $FUNCNAME"
	sed -i "/${HOSTNAME}/d" /etc/hosts
	echo "${IF_IP}    ${HOSTNAME}" >> /etc/hosts
	hostnamectl set-hostname ${HOSTNAME}
}

function kube::util::setup_network() {
	echo "Start $FUNCNAME"
	iptables -F
	iptables -X
	sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config
	if type sestatus &>/dev/null && sestatus | grep -i "Current mode" | grep enforcing ; then
		setenforce 0
	fi
	cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
fs.file-max=1000000
net.ipv4.tcp_keepalive_intvl=1
net.ipv4.tcp_keepalive_time=5
net.ipv4.tcp_keepalive_probes=5
EOF

	sysctl -p

	cat > /etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
EOF
}

function kube::util::upgrade_centos() {
	# Upgrade CentOS to latest version if not CentOS 7.2.
	echo "Start $FUNCNAME"
	yum clean all
	yum -y update
	echo "Do not forget to reboot the system."
}

function kube::util::get_ip() {
	ifconfig ${IF_NAME} | awk '/inet /{print $2}'
}

function kube::util::ensure_yum_ready() {
	if pgrep yum 2>&1 1>/dev/null; then
		rm -r /var/run/yum.pid
	fi
	sleep 3
}

