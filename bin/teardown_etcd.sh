#!/bin/bash

etcd_host=etcd
# I would love to know how to remove the VM from the
# virtual machine library
echo "stopping and deleting ${etcd_host}"
sudo vmrun stop ${etcd_host}.vmx
rm -rf ${etcd_host}.vmx.lck
sudo vmrun deleteVM ${etcd_host}.vmx
rm -f ${etcd_host}.iso
rm -f ${etcd_host}_image.vmdk
rm -f ${etcd_host}.vmxf
rm -f ${etcd_host}.vmsd
rm -f ${etcd_host}.plist
rm -f ${etcd_host}-*.vmem
rm -f ${etcd_host}-*.vmss
