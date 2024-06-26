#! /bin/sh

DEVICE=$1
FILES_PATH='.'

usage() { echo "usage: $0 <device> [<path>]"; }

if [ -d "$2" ]; then
	FILES_PATH=$2
else
	echo "Error: $2 is not a valid path."
	usage
	exit 2
fi

if [ -z "$DEVICE" ]; then
	echo "Error: No device specified."
	usage
	exit 2
fi

if [ ! -b "$DEVICE" ]; then
	echo "Error: $DEVICE is not a valid device."
	usage
	exit 2
fi

echo "This script will destroy all data on the device you have selected ($DEVICE) and create"
echo "a bootable Alpine installation for the Orange Pi Zero. Running fdisk from a script is"
echo "generally not recommended, you will not have an opportunity to inspect changes to the"
echo "partition table before they are written. You need to be confident that the device you"
echo "have specified ($DEVICE) is the correct device."
echo
while true; do
	read -p "Are you sure you want to continue? " confirmation
	case $(echo "$confirmation" | tr '[:upper:]' '[:lower:]') in
			y|yes ) break;;
			n|no ) echo "Discretion is the better part of valour. Exiting."; exit;;
			* ) echo "Please answer yes or no.";;
	esac
done
echo

if parted --script "$DEVICE"1 > /dev/null 2>&1; then
	echo "Wiping signatures.."
	wipefs --all --force "$DEVICE"1 > /dev/null 2>&1 \
		|| { echo "Error: failed to remove signatures"; exit 1; }
fi

echo "Writing zeroes.."
dd if=/dev/zero of=$DEVICE bs=1M count=1 status=none \
	|| { echo "Error: failed to write zeros"; exit 1; }


echo "Writing u-boot.."
dd if=$FILES_PATH/u-boot-sunxi-with-spl.bin of=$DEVICE bs=1024 seek=8 status=none \
	|| { echo "Error: failed to write u-boot"; exit 1; }

echo "Creating partition.."
# from https://superuser.com/a/984637
# include comments so we can see what operations are taking place, but
# strip the comments with sed before sending arguments to fdisk
FDISK_OUTPUT=$(sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $DEVICE
	n		# add new
	p		# primary partition
	1		# numbered 1
	2048	# from sector 2048
	+200M	# up to 200M
	t		# of type
	c		# W95 FAT32 (LBA)
	a		# make it bootable
	w		# save changes and exit
EOF
)

# wait for fdisk to finish
sleep 5

FDISK_OUTPUT=$(sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $DEVICE
	n		# add new
	p		# primary partition
	2		# numbered 2
	411648	# from sector 411648
			# to the last sector
	w		# save changes and exit
EOF
)

# wait for fdisk to finish
sleep 5

echo "Formating boot partition.."
mkfs.vfat -n ALPINE_BOOT "$DEVICE"1 >/dev/null \
	|| { echo "Error: failed to make vfat partition"; exit 1; }

echo "Formating root partition.."
mkfs.ext4 -F -L ALPINE_DATA "$DEVICE"2 >/dev/null \
	|| { echo "Error: failed to make ext4 partition"; exit 1; }

cleanup() {
	mountpoint -q $TEMP_MOUNT && umount "$TEMP_MOUNT"
	[ -d $TEMP_MOUNT ] && rm -rf $TEMP_MOUNT
}

TEMP_MOUNT=$(mktemp -d -t opizero-alpine-XXXXXXXX)

trap 'cleanup' EXIT

echo "Mounting device.."
mount "$DEVICE"1 $TEMP_MOUNT \
	|| { echo "Error: failed to mount ${DEVICE}1"; exit 1; }

echo "Copying files.."
{ cp -r $FILES_PATH/apks "$TEMP_MOUNT"/ && cp -r $FILES_PATH/boot "$TEMP_MOUNT"/; } \
	|| { echo "Error: failed to copy from $FILES_PATH"; exit 1; }

echo "Ejecting device.."
eject $DEVICE || true

echo "Done!"
