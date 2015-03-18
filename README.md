---
layout: post
title: "CoreS VMware Cluster Scripts"
date: 2015-03-17 12:00:00 
categories: coreos,docker,vmware
---

# CoreOS VMware Cluster Scripts

The purpose of the simple [```coreos_cluster_vmware```](https://github.com/CaptTofu/coreos_cluster_vmware) repo is to provide simple scripts for building a CoreOS cluster using the methodology that Kelsey Hightower gave me insight into using the official VMware CoreOS image. 

## Inspiration

There is an excellent [blog post](https://coreos.com/blog/vmware-vcloud-air-and-vsphere/) on CoreOS's blog by [Kelsey Hightower](https://github.com/kelseyhightower) about CoreOS on VMware Vspher and VMware vCloud Air that was the inspiration for this post. I simply wanted to automate the process and have a means of showing a working cluster, hence this blog post.

## What does this cluster consist of?

Four machines total:

- standalone etcd node. Keep it Simple for development and feel free to create a full cluster in production.
- 3 coreOS nodes that are using the single etcd node


## What is in this repo?

In the base directory, there are "templates" for:

- ```vm_tmpl.vmx``` - The VMX file used by all VMs 
- ```etcd_cloud_init_tmpl.yaml``` - A cloud init file for the etcd VM
- ```node_cloud_init_tmpl.yaml``` - A cloud init file for the CoreOS VM nodes

In the ```./bin``` directory:

- ```get_image.sh``` - Simple script to fetch the official VMware CoreOS image and un-compress it (bzip)
- ```build_etcd.sh``` - The script used to build configuration files for and to launch the etcd VM
- ```build_nodes.sh``` - The script that is used to build configuration files for and to launch all three of the CoreOS node VMs
- ```teardown_nodes.sh``` - Stops and deletes the files for CoreOS node VMs
- ```teardown_etcd.sh``` - Stops and deletes the files for the etcd VM 

## Basic idea

The basic idea is this - 
- Obtain the official VMware CoreOS image
- Produce both a cloud init file and VMX file for a given VM
- Create a config drive, using the cloud init file (.iso)
- Make a copy of the official VMware CoreOS image for that machine named accordingly 
- Boot the VM using the generated files

For the etcd VM, this only happens once and requires not cognizance of any other machines. For each CoreOS node VM, they boot the same way but also need to know the IP address of the etcd VM. 

Upon launching all CoreOS node VMs, everything should be up and running!

## Usage

There is a directory in the repo with nothing in it ```work_dir```. Enter that directory. This is where all the generated files and VMware images will exist.

### Determine location of VMware CLI 

You will need to find the utility ```vmlist```. On OSX Yosemite, this location should be ```/Applications/VMware Fusion.app/Contents/Library```. Set up the $PATH environment variable to have this in your path:

```export PATH=$PATH:/Applications/VMware\ Fusion.app/Contents/Library```

When this utility is run, it will need to be run via ```sudo```, or you can change it to allow the user you use to have the execute privilege to it.


### Get the official VMware CoreOS image

```
../bin/get_image.sh
```

After this script is completed, there should be the image in the expected location ```../coreos_image```

```
reason:work_dir patg$ ls -l ../coreos_image/*.vmdk
total 1036072
-rw-r--r--  1 patg  staff  396820480 Mar 12 12:59 coreos_production_vmware_image.vmdk

```

### Lanch the etcd VM

```
reason:work_dir patg$ ../bin/build_etcd.sh 
Creating hybrid image...
....
```

This will lanch the etcd VM. A window will present itself with a dialog box 

![etcd launch prompt]({{ site.url }}/assets/etcd_launch1.png)

Select "I copied it".

You can then find out what the IP address of the Virtual Machine is either by looking at the output in the VM window

![etcd VM initial window]({{ site.url }}/assets/etcd_launch2.png)

 or by running the following command:

```
reason:work_dir patg$ sudo vmrun getGuestIPAddress etcd.vmx
192.168.1.24
```

Log into the instance. The password that was set from the cloud init data file ```etcd_clout_init.yaml``` results in the VM having a password for both the core and root user of "vmware" (NOTE: this is not for production, obviously!)

```
reason:work_dir patg$ ssh core@192.168.1.24
Warning: Permanently added '192.168.1.24' (RSA) to the list of known hosts.
core@192.168.1.24's password: 
CoreOS alpha (618.0.0)
```

Now, verify that etcd is running:

```
core@etcd ~ $ etcdctl ls --recursive
/coreos.com
/coreos.com/updateengine
/coreos.com/updateengine/rebootlock
/coreos.com/updateengine/rebootlock/semaphore
```

### Launch the cluster

Now the cluster can be launched. As the above example shows, the IP address for etcd is 192.168.1.24. This will be the single argument to the next script:

```
reason:work_dir patg$ ../bin/build_nodes.sh 192.168.1.24
```

This will result in the same sequence of steps as the etcd server, but 3 times. Once all VMs are launched, you can verify that they are up:

```
reason:work_dir patg$ sudo vmrun list
Total running VMs: 5
/Users/patg/code/coreos-vmware-cluster/work_dir/core_03.vmx
/Users/patg/code/coreos-vmware-cluster/work_dir/core_01.vmx
/Users/patg/code/coreos-vmware-cluster/work_dir/etcd.vmx
/Users/patg/code/coreos-vmware-cluster/work_dir/core_02.vmx
```

Next, pick one of the nodes to log into:

```
reason:work_dir patg$ ssh core@192.168.1.27
Warning: Permanently added '192.168.1.27' (RSA) to the list of known hosts.
core@192.168.1.27's password: 
CoreOS alpha (618.0.0)
```

Test that everything is working:

```
core@core_03 ~ $ fleetctl --endpoint=http://192.168.1.24:4001 list-machines
MACHINE		IP		METADATA
11cf48ee...	192.168.1.26	role=node
6b196b24...	192.168.1.25	role=node
8203d85a...	192.168.1.27	role=node
```

Excellent! A working cluster! Next, create a test service and launch it. In this example, the "hello" service shown on [Core OS Quickstart](https://coreos.com/docs/quickstart/)

Once the service is created as a file with the editor of choice, submit it and run it. Additionally, export the environment variable ```FLEETCTL_ENDPOINT``` to make submission not require it explicitely:

```
core@core_03 ~ $ export FLEETCTL_ENDPOINT=http://192.168.1.24:4001
core@core_03 ~ $ fleetctl submit hello.service 
core@core_03 ~ $ fleetctl list-unit-files
UNIT		HASH	DSTATE		STATE		TARGET
hello.service	0d1c468	inactive	inactive	-
core@core_03 ~ $ fleetctl start hello          
Unit hello.service launched on 11cf48ee.../192.168.1.26
core@core_03 ~ $ fleetctl list-units
UNIT		MACHINE				ACTIVE		SUB
hello.service	11cf48ee.../192.168.1.26	activating	start-pre
core@core_03 ~ $ fleetctl list-units
UNIT		MACHINE				ACTIVE	SUB
hello.service	11cf48ee.../192.168.1.26	active	running
```

The cluster is now open for business!

## Summary

This document has shown how to easily set up a CoreOS cluster, as well as how to do some useful work with the VMware command line tools. For more information, do join the ```#coreos``` IRC channel on Freenode, as well as the [documentation](https://coreos.com/docs/) on CoreOS's site.

Lastly, many many thanks to [Kelsey Hightower](https://github.com/kelseyhightower) for his patience and help with setting this up and answering a slew of questions!
