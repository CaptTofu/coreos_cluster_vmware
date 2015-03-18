#!/bin/bash

work_dir=`pwd`
core_prefix=core_0
etcd_host=${1-127.0.0.1}
pass=$(openssl passwd vmware) 

for i in 1 2 3;
do
  core_host=${core_prefix}${i}
  echo "Building node ${core_host}"
  cp ../coreos_image/coreos_production_vmware_image.vmdk ${core_host}_image.vmdk
  sed "s/PASSWD/${pass}/g;s/VM_HOST/${core_host}/g;s/ETCD_HOST/$etcd_host/g" ../node_cloud_init_tmpl.yaml > ${core_host}_cloud_init.yaml
  sed "s/VM_HOST/${core_host}/g;s|WORK_DIR|${work_dir}|g" ../vm_tmpl.vmx > ${core_host}.vmx
  mkdir -p /tmp/new-drive/openstack/latest
  cp ${core_host}_cloud_init.yaml /tmp/new-drive/openstack/latest/user_data
  mv ${work_dir}/${core_host}.iso ${work_dir}/${core_host}.iso.bak
  hdiutil makehybrid -iso -joliet -joliet-volume-name "config-2" -o ${work_dir}/${core_host}.iso /tmp/new-drive
  sudo vmrun start ${core_host}.vmx
  sleep 10
done
