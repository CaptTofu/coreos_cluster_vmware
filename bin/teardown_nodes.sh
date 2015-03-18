#!/bin/bash

prefix=core_0
host_list=${@-"core_01 core_02 core_03"}

# I would love to know how to remove the VM from the
# virtual machine library
for core_host in $host_list 
do
    echo "stopping and deleting ${core_host}"
    sudo vmrun stop ${core_host}.vmx
    rm -rf ${core_host}.vmx.lck
    sudo vmrun deleteVM ${core_host}.vmx
    rm -f ${core_host}.iso
    rm -f ${core_host}_image.vmdk
    rm -f ${core_host}.vmxf
    rm -f ${core_host}.vmsd
    rm -f ${core_host}.plist
    rm -f ${core_host}-*.vmem
    rm -f ${core_host}-*.vmss
done
