#Cluster Setup
This guide is for setting up a kubernetes enabled cluster that is enabled with glusterfs and an installation of gogs

## Base OS

Start with fedora 24, download from here https://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/24/Server/x86_64/iso/Fedora-Server-netinst-x86_64-24-1.2.iso
Create root & userspace accounts

    $ cd /tmp
    $ dnf install -y git
    $ git clone https://github.com/zefyrr/cluster_setup
    $ cd cluster_setup
    $ ./base_install.sh


## Node setup
### Clone installation
### Rename hosts
Rename /etc/hostname to:
* master.local
* worker00.local

Then reboot
Check if master and worker are reachable from each other:
* from master
    $ ping worker00
* from worker00
    $ ping master

### GlusterFS

    $ gluster peer probe worker00
    $ gluster volume create gv0 replica 2 master:/gfs/gv0 worker00:/gfs/gv0 force
    $ gluster volume start gv0

### Kubernetes
Clone kubernetes-contrib on master  
Follow guide here - http://kubernetes.io/v1.1/docs/getting-started-guides/fedora/fedora_ansible_config.html

    $ git clone https://github.com/kubernetes/contrib
    $ cd contrib/ansible
    $ cp inventory.example.ha inventory
    
Edit inventory  

    $ vim inventory
    $ vim ~/contrib/ansible/group_vars/all.yml
    $ cd ~/contrib/ansible/
    $ ./setup.sh
  

