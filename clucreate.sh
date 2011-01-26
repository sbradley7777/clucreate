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

QEMU_IMG=`which qemu-img`

# CREATE SNAPSHOTS
snap_create()
{
TEMPLATE=$1
NODE_NAME=$2

echo Creating node $NODE_NAME...
$QEMU_IMG create -f qcow2 -o backing_file=$TEMPLATE $SNAPSHOTS_DIR/$NODE_NAME &> /dev/null
echo Node $NODE_NAME created...
echo
}

#DELETE SNAPSHOTS
snap_delete()
{
echo delete_vm
}


RHEL4()
{
echo Setting up a RHEL4 cluster...
echo

while [ $NODE_NUM -le $NODES ]; do
	snap_create $RHEL4_TEMPLATE RHEL4-NODE$NODE_NUM.img
	NODE_NUM=$(($NODE_NUM+1))
done
}

RHEL5()
{
echo Setting up a RHEL5 cluster...
echo

while [ $NODE_NUM -le $NODES ]; do
	snap_create $RHEL5_TEMPLATE RHEL5-NODE$NODE_NUM.img
	NODE_NUM=$(($NODE_NUM+1))
done
}

RHEL6()
{
echo Setting up a RHEL5 cluster...
echo

while [ $NODE_NUM -le $NODES ]; do
	snap_create $RHEL6_TEMPLATE RHEL6-NODE$NODE_NUM.img
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