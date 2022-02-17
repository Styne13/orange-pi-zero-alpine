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

#clone and switch to project directory
if [ ! -d "orange-pi-zero-alpine" ]; then
	git clone https://github.com/moonbuggy/orange-pi-zero-alpine.git
fi
cd orange-pi-zero-alpine

#display Tags
echo "linux-stable LTS tag: ${LINUX_TAG}"
echo "u-boot tag: ${UBOOT_TAG}"
echo "alpine version: ${ALPINE_VERSION}"

#create changelog file
echo "linux-stable LTS tag: ${LINUX_TAG}" >> CHANGELOG.md
echo "u-boot tag: ${UBOOT_TAG}" >> CHANGELOG.md
echo "alpine version: ${ALPINE_VERSION}" >> CHANGELOG.md

#save tags for later use (e.g. automated export of build artifacts, tag/release)
echo "${LINUX_TAG}" > LINUX_TAG
echo "${UBOOT_TAG}" > UBOOT_TAG
echo "${ALPINE_VERSION}" > ALPINE_VERSION

./configure

make -j ${CORES} uboot-defconfig
make -j ${CORES} linux-default
make -j ${CORES} xradio
make -j ${CORES} install

#rename image folder
mv files/ "orangepi-zero-alpine-image-${ALPINE_VERSION}"

#create tar image archive
tar czvf "orangepi-zero-alpine-image-${ALPINE_VERSION}.tar.gz" "orangepi-zero-alpine-image-${ALPINE_VERSION}"
exit 0
