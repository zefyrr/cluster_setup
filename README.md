#Cluster Setup
This guide is for setting up a kubernetes enabled cluster that is enabled with glusterfs

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
On each node `vim /etc/hostname` and change the hostname entry to `master.local` and `worker00.local` for the master and worker nodes respectively

Reboot and check if master and worker are reachable from each other:

From master
```
$ ping worker00
```
From worker00
```
$ ping master
```

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
      replace text with:
        [masters]
        master

        [etcd]
        master

        [nodes]
        master
        worker00

    $ vim ~/contrib/ansible/group_vars/all.yml
      replace line 17 with:
        ansible_ssh_user: root

    $ cd ~/contrib/ansible/
    $ ./setup.sh
  
### Attach Gluster Volume to Container

These instructions can be used to provide a gluster volume to a container. Instruction attribution [here](https://github.com/kubernetes/kubernetes/tree/master/examples/volumes/glusterfs)

#### Create endpoints

Write a spec file for the endpoints. Use the sample [glusterfs-endpoints.json](https://github.com/shuaib88/cluster_setup/blob/initialSetup/gluster_vol_examples/glusterfs-endpoints.json) as a guide

Ping each node and obtain the IP address. Your spec file should use the IPv4 format to declare each node. For example:

```
    {
      "addresses": [
        {
          "ip": "192.168.1.68"
        }
      ],
      "ports": [
        {
          "port": 1
        }
      ]
    }
```

Create the endpoints
```
$ kubectl create -f glusterfs-endpoints.json
```
Verify that the endpoints are successfully created by running
```
$ kubectl get endpoints 
NAME                ENDPOINTS                       
glusterfs-cluster   192.168.1.68:1,192.168.1.69:1   
```
Create a service for these endpoints so that they will be persistent. See [glusterfs-service.json](https://github.com/shuaib88/cluster_setup/blob/initialSetup/gluster_vol_examples/glusterfs-services.json) for details 
```
$ kubectl create -f glusterfs-service.json
```

#### Create a POD

The following volume spec in [glusterfs-pod.json](https://github.com/shuaib88/cluster_setup/blob/initialSetup/gluster_vol_examples/glusterfs-pod.json) illustrates a sample configuration.
```
  { 
      "name": "glusterfsvol",
      "glusterfs": {
          "endpoints": "glusterfs-cluster",
          "path": "gv0",
          "readOnly": false
      }
  }
```
The parameters are explained as follows:
- **endpoints** the endpoints name we defined in our endpoints service. The pod will randomly pick one of the endpoints to mount. 
- **path** is the Glusterfs volume name.
- **readOnly** is the boolean which sets the mountpoint as readOnly or readWrite.

Create a pod that has a container using Glusterfs volume
```
$ kubectl create -f glusterfs-pod.json
```

Verify the pod is running
```
$ kubectl get pods
NAME        READY     STATUS    RESTARTS   AGE
glusterfs   1/1       Running   0          7h

$ kubectl get pods glusterfs --template '{{.status.hostIP}}{{"\n"}}'
192.168.1.68
```

Check if the Glusterfs volume is mounted. ssh into host and run 'mount'
```
$ mount | grep gv0
192.168.1.68:gv0 on /var/lib/kubelet/pods/68c71672-5733-11e6-90eb-08002713a57e/volumes/kubernetes.io~glusterfs/glusterfsvol type fuse.glusterfs (rw,relatime,user_id=0,group_id=0,default_permissions,allow_other,max_read=131072)
```

You can also run `docker ps` on the host to see the actual container
