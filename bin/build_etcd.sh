#!/bin/bash

work_dir=`pwd`
etcd_hostname=etcd
pass=$(openssl passwd vmware) 

cp ../coreos_image/coreos_production_vmware_image.vmdk ${etcd_hostname}_image.vmdk
sed "s/PASSWD/${pass}/g;s/VM_HOST/${etcd_hostname}/g" ../etcd_cloud_init_tmpl.yaml > ${etcd_hostname}_cloud_init.yaml
sed "s/VM_HOST/${etcd_hostname}/g;s|WORK_DIR|${work_dir}|g" ../vm_tmpl.vmx > ${etcd_hostname}.vmx
mkdir -p /tmp/new-drive/openstack/latest
cp ${etcd_hostname}_cloud_init.yaml /tmp/new-drive/openstack/latest/user_data
mv ${work_dir}/${etcd_hostname}.iso ${work_dir}/${etcd_hostname}.iso.bak
hdiutil makehybrid -iso -joliet -joliet-volume-name "config-2" -o ${work_dir}/${etcd_hostname}.iso /tmp/new-drive

sudo vmrun start ${etcd_hostname}.vmx
#sudo vmrun getGuestIPAddress ${etcd_hostname}.vmx
