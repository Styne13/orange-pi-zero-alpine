#!/bin/bash

#update this value if another LTS version is the longest supported version
LINUX_LTS=5.10

if [ -v $CORES ]; then
	echo "no option for cores set, default to 4!"
	CORES=4
fi

if [ -v $LINUX_TAG ]; then
	#using github linux-stable mirror
	LINUX_TAG=$(python3 -m lastversion --format tag --major ${LINUX_LTS} gregkh/linux)
fi

if [ -v $UBOOT_TAG ]; then
	UBOOT_TAG=$(python3 -m lastversion --format tag u-boot/u-boot)
fi

if [ -v $ALPINE_VERSION ]; then
	ALPINE_VERSION=$(python3 -m lastversion --format tag alpine)
fi

#display Tags
echo "linux-stable LTS tag: ${LINUX_TAG}"
echo "u-boot tag: ${UBOOT_TAG}"
echo "alpine version: ${ALPINE_VERSION}"

#save tags for later use (e.g. automated export of build artifacts, tag/release)
echo "${LINUX_TAG}" > LINUX_TAG
echo "${UBOOT_TAG}" > UBOOT_TAG
echo "${ALPINE_VERSION}" > ALPINE_VERSION

if [ ! -d "orange-pi-zero-alpine" ]; then
	git clone https://github.com/moonbuggy/orange-pi-zero-alpine.git
fi
cd orange-pi-zero-alpine

./configure

make -j ${CORES} uboot-defconfig
make -j ${CORES} linux-default
make -j ${CORES} xradio
make -j ${CORES} install

exit 0
