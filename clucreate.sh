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
FEDORA_TEMPLATE="/var/lib/libvirt/images/fedora.img"

TEMPLATE_DIR="/var/lib/libvirt/images"
SNAPSHOTS_DIR="/var/lib/libvirt/snapshots"
VM_CONFIG_DIR="/etc/libvirt/qemu"
NODES=$3
NODE_NUM=1

#Find executables

QEMU_IMG=`which qemu-img`
VIRT_INSTALL=`which virt-install`
DNS_MASQ=`which dnsmasq`
RM=`which rm`
SERVICE=`which service`
#Define MAC ADDRESSSES:

MAC_RHEL4_DEF='52:54:00:aa:e4:0'
MAC_RHEL5_DEF='52:54:00:aa:e5:0'
MAC_RHEL6_DEF='52:54:00:aa:e6:0'
MAC_FEDORA_DEF='52:54:00:aa:fe:0'

# CREATE SNAPSHOTS
snap_create()
{
TEMPLATE=$1
NODE_NAME=$2

echo Creating node $NODE_NAME...
$QEMU_IMG create -f qcow2 -o backing_file=$TEMPLATE $SNAPSHOTS_DIR/$NODE_NAME
echo $QEMU_IMG create -f qcow2 -o backing_file=$TEMPLATE $SNAPSHOTS_DIR/$NODE_NAME
echo Node $NODE_NAME created...
echo
}

#DELETE SNAPSHOTS
snap_delete()
{
CLUSTER=$1
$RM $SNAPSHOTS_DIR/$CLUSTER*
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
CLUSTER=$1

if [ $CLUSTER == rhel4 ]; then
	$RM $VM_CONFIG_DIR/rhel4-*
	snap_delete $CLUSTER
elif [ $CLUSTER == rhel5 ]; then
	$RM $VM_CONFIG_DIR/rhel5-*
	snap_delete $CLUSTER
elif [ $CLUSTER == rhel6 ]; then
	$RM $VM_CONFIG_DIR/rhel6-*
	snap_delete $CLUSTER
elif [ $CLUSTER == fedora ]; then
	$RM $VM_CONFIG_DIR/fedora13-*
	snap_delete $CLUSTER
else
	echo "WRONG PARAMETER"
	exit
fi

$SERVICE libvirtd restart
	
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

FEDORA()
{
echo Setting up a FEDORA cluster...
echo

while [ $NODE_NUM -le $NODES ]; do
	snap_create $FEDORA_TEMPLATE fedora13-node$NODE_NUM.img
	vm_create fedora13 $NODE_NUM $MAC_FEDORA_DEF$NODE_NUM
	NODE_NUM=$(($NODE_NUM+1))
done
}

usage()
{
echo
echo "Usage:"
echo 	"clucreate <action> <plataform> <nodes>"
echo		"<action> == Action to be performed by the script"
echo		"<plataform> == rhel4|rhel5|rhel6|fedora"
echo		"<nodes> number of cluster nodes (max nodes: 5)"
echo
echo		"<action>"
echo		"	create: create a new cluster set"
echo		"	delete: delete a already created cluster"
echo		"	dnsrestart: restart cluster dns and dhcp settings"
echo
echo		"<plataform>"
echo		"	rhel4: Action performed on a RHEL4 cluster"
echo		"	rhel5: Action performed on a RHEL5 cluster"
echo		"	rhel6: Action performed on a RHEL6 cluster"
echo		"	fedora: Action performed on a FEDORA cluster"
echo
echo		"<nodes>"
echo		"	The clucreate currently supports only a max of 5 nodes on a cluster"
}

#dhcp_enable() starts the dnsmasq dhcp server and setup the hostnames 
#to be assigned to each hosts using the cluster_hosts file.
#It will not discard /etc/hosts to setup the hosts files,
#but also read cluster_hosts, 
#which will avoid to overwrite the system hosts file

dhcp_enable()
{
echo "Setting up dhcp server..."
echo $DNS_MASQ
killall -9 dnsmasq
cp ./cluster_hosts /etc/dnsmasq.d/cluster_hosts
sleep 1
$DNS_MASQ \
--conf-file=./dnsmasq.conf
echo "Done"
echo
}

create()
{

if [ $1 == rhel4 ]; then
dhcp_enable
RHEL4
elif [ $1 == rhel5 ]; then
dhcp_enable
RHEL5
elif [ $1 == rhel6 ]; then
dhcp_enable
RHEL6
elif [ $1 == fedora ]; then
dhcp_enable
FEDORA
else
	echo "Plataform not found"
	usage
fi
}

#main()

case "$1" in

"create" )

	if [ $# != 3 ]; then
		usage
		exit
	fi
 
	create $2
;;

"delete")
	
	if [ $# != 2 ]; then
		usage
		exit
	fi
	vm_delete $2
;;

"dnsrestart")
	
	if [ $# != 1 ]; then
		usage
		exit
	fi
	dhcp_enable
;;

* )
	usage
esac
