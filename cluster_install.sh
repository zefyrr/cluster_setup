#!/bin/bash
set -x #echo on

rm -rf contrib
git clone https://github.com/kubernetes/contrib
cp kubernetes_config/inventory contrib/ansible
cp kubernetes_config/all.yml contrib/ansible/group_vars/all.yml
cd contrib/ansible/
./setup.sh
