#!/bin/bash
set -x #echo on

## Install packages
dnf upgrade -y
dnf install -y git python-netaddr avahi vim docker glusterfs-server ntpdate ansible tmux

## Configure
### Ntp
systemctl enable ntpd
### Docker
systemctl enable docker
### Avahi
systemctl enable avahi-daemon.service
firewall-cmd --permanent --add-service=mdns
### GlusterFS
firewall-cmd --permanent --add-service=glusterfs
systemctl enable glusterd.service
mkdir -p /gfs/gv0
### SSH key-less login
rm -rf ~/.ssh
ssh-keygen -t rsa -b 2048 -N '' -f /root/.ssh/id_rsa
cd ~/.ssh
cp id_rsa.pub authorized_keys
### Setup environment for developing 
mkdir -p ~/projects/
cd ~/projects
git clone https://github.com/zefyrr/environment_mojo_linux
cd environment_mojo_linux
./setupEnv.sh

