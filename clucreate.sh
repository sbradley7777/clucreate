#!/bin/bash

#
# Set up a virtual machine cluster based on the command line arguments
#
#usage:
#	clucreate <plataform> <nodes>
#
MAX_NODES=5
RHEL4_TEMPLATE="/var/lib/libvirt/images/RHEL4.img"
RHEL5_TEMPLATE="/var/lib/libvirt/images/RHEL5.img"
RHEL6_TEMPLATE="/var/lib/libvirt/images/RHEL6.img"

TEMPLATE_DIR="/var/lib/libvirt/images"
SNAPSHOTS_DIR="/var/lib/libvirt/snapshots"
PLATAFORM=$1
NODES=$2
NODE_NUM=1

#Find executables

QEMU_IMG=`which qemu-img`
VIRT_INSTALL=`which virt-install`

#Define MAC ADDRESSSES:

MAC_RHEL4_DEF='52:54:00:aa:e4:0'
MAC_RHEL5_DEF='52:54:00:aa:e5:0'
MAC_RHEL6_DEF='52:54:00:aa:e6:0'

# CREATE SNAPSHOTS
snap_create()
{
TEMPLATE=$1
NODE_NAME=$2

echo Creating node $NODE_NAME...
$QEMU_IMG create -f qcow2 -o backing_file=$TEMPLATE $SNAPSHOTS_DIR/$NODE_NAME
echo Node $NODE_NAME created...
echo
}

#DELETE SNAPSHOTS
snap_delete()
{
echo delete_vm
}

vm_create()
{

OS=$1
NODE=$2
MAC=$3
$VIRT_INSTALL --name=$OS-node$NODE --ram=1024 --vcpus=2 --import --os-type=linux --os-variant=$OS --disk path=$SNAPSHOTS_DIR/$OS-node$NODE.img,bus=ide -w network=default,mac=$MAC,model=e1000 --vnc --noautoconsole -v --virt-type kvm --video=cirrus
}

vm_delete()
{
echo vm_delete
}


RHEL4()
{
echo Setting up a RHEL4 cluster...
echo

while [ $NODE_NUM -le $NODES ]; do
	snap_create $RHEL4_TEMPLATE rhel4-node$NODE_NUM.img
	vm_create rhel4 $NODE_NUM $MAC_RHEL4_DEF$NODE_NUM 
	NODE_NUM=$(($NODE_NUM+1))
	
done
}

RHEL5()
{
echo Setting up a RHEL5 cluster...
echo

while [ $NODE_NUM -le $NODES ]; do
	snap_create $RHEL5_TEMPLATE rhel5-node$NODE_NUM.img
	vm_create rhel5 $NODE_NUM $MAC_RHEL5_DEF$NODE_NUM
	NODE_NUM=$(($NODE_NUM+1))
done
}

RHEL6()
{
echo Setting up a RHEL6 cluster...
echo

while [ $NODE_NUM -le $NODES ]; do
	snap_create $RHEL6_TEMPLATE rhel6-node$NODE_NUM.img
	vm_create rhel6 $NODE_NUM $MAC_RHEL6_DEF$NODE_NUM
	NODE_NUM=$(($NODE_NUM+1))
done
}

usage()
{
echo "Usage:"
echo 	"clucreate <plataform> <nodes>"
echo		"<plataform> == rhel4|rhel5|rhel6"
echo		"<nodes> number of cluster nodes (max nodes: 5)"
}

if [ $1 == rhel4 ] ; then
RHEL4
elif [ $1 == rhel5 ]; then
RHEL5
elif [ $1 == rhel6 ]; then
RHEL6
else
usage
fi
