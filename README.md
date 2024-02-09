# Orange Pi Zero Alpine
Alpine for the Orange Pi Zero

Running in RAM, using an SD card only for initial loading of the filesystem and configuration storage.

Pre-built files, ready to go, can be found in `builds/`. There is also a Makefile which allows easy customization and building using either files in `configs/` or defconfigs as a base to work from.

The built kernel images are intentionally quite minimal, and no modules are included other than for the WiFi, to keep the size down. The default build is intended to be a base to build from, it should be everything necessary to run all the hardware on the Orange Pi Zero, but nothing else. Any other builds in this repo will generally be the bare minimum for a particular application of mine. You'll probably need to build your own kernel to suit your application and/or support any devices you might attach, unless your application happens to be quite similar to something I've already built for.

## Versions
```
U-Boot 2020.04-rc5_opizero

# uname -r
5.6.0-rc4_opizero_default-g6a8c531e7

# cat /etc/alpine-release
3.11.3
```

## Current status
This is a work in progress. Not everything necessarily functions, not everything will necessarily be made to function. (Although if you want to make something function that doesn't feel free to fork and pull request.)

## Install on SD card

### Automatic 
The script `scripts/write_sd.sh` will automatically configure an SD card with a bootable Alpine from a build folder (it expects to see `apks/`, `boot/` and `u-boot-sunxi-with-spl.bin`). If no `<path>` argument is specified it default to the directory it was run from. Be careful about specifying the correct device because the script will happily rewrite the partition table of any device you point it at.

Usage: `sudo ./write_sd.sh <device> <path>`

Example: `sudo ./write_sd.sh /dev/sda builds/default/`

The script `scripts/copy_sd.sh` will copy kernel files to an already-prepared SD card (with U-Boot already written and the `apks/` folder already present), useful for testing new builds without losing Alpine configuration that is already done. As with the `write_sd.sh` script, it wants to be executed inside a build folder or with the path of a build folder specified as the `<path>` argument.

Usage: `sudo ./copy_sd.sh <device> <path>`

Example: `sudo ./copy_sd.sh /dev/sda builds/default/`

### Manual
A manual approach is safer, with less risk of accidentally aiming `dd` and `fdisk` at the wrong device.

1. zero the start of the SD card
	- `dd if=/dev/zero of=<device> bs=1M count=1`
2. write u-boot
	- `dd if=u-boot-sunxi-with-spl.bin of=<device> bs=1024 seek=8`
3. create a FAT32 partition with fdisk (although u-boot will handle other partition types if you prefer)
	- `fdisk <device>`
	- `n`       # add new
	- `p`       # primary partition
	- `1`       # numbered 1
	- `2048`    # from sector 2048
	- `<enter>` # to the last sector
	- `t`       # of type
	- `c`       # W95 FAT32 (LBA)
	- `a`       # make it bootable
	- `w`       # save changes
	- `q`       # exit fdisk
4. format and label partition
	- `mkfs.vfat -n ALPINE <partition>`
5. create folder (if necessary) and mount the SD card
	- `mkdir <mount_path>`
	- `sudo mount <partition> <mount_path>`
6. copy `apks` and `boot` folder
	- `cp -r apks <mount_path>`
	- `cp -r boot <mount_path>` 
7. unmount the SD card and remove the folder (if desired)
	- `sudo umount <partition>`  
	- `rm -rf <mount_path>`
8. eject the SD card before removing it
	- `eject <device>`

## Build
There's a basic Autoconf script and a Makefile to build any or all required files from source. To build with the default configuration all that's required is:

```
./configure
make install
```

This has been tested on Ubuntu Bionic, however, it should function just fine on other distros. The prerequisites for building can be installed with `apt-get` on distros that use it:

```
sudo apt-get -y --no-install-recommends --fix-missing install \
	gcc-arm-linux-gnueabihf gcc automake make bison flex swig python-dev musl \
	u-boot-tools dosfstools device-tree-compiler \
	git wget pv
```

### ./configure
At the moment this doesn't actually configure any part of the build process, it just checks the build environment for required dependencies and warns if any are missing. It doesn't strictly need to be run, missing dependencies will become evident during the build process itself, it's just for convenience.

### make
The Makefile will fetch all necessary source files and build whatever needs to be built. `make help` will give a list of options, `make info` will show build parameters (which can be changed by editing variables defined at the top of the Makefile). To build a complete set of files, ready to go onto an SD card, all you need to do is type `make install` and everything else should sort itself out.

Menuconfig will pop up for the builds of U-Boot and the linux kernel but the build process is otherwise non-interactive. Completed build files will output into `files/`, builds of individual components (e.g. `make uboot`, `make linux`) will output into the respective source folders.

It wouldn't be hard to adapt the Makefile to work with other devices, it's just a matter of providing appropriate config files and device trees.

## Configuration

### Alpine
At the moment the Alpine filesystem that loads is taken directly from the generic ARM distro and not modified.

The default login is `root` with no password.

Initial configuration on first boot can be done with `alpine-setup`. It's a good idea to `apk add haveged` and start it as a service as part of the initial setup (especially if you're using the [WiFi with WPS](#WiFi), but several services will load faster with more entropy available), once repos are configured. As we're running in RAM any config changes will need to be committed to the SD card with `lbu ci` or they'll be lost on reboot.

At some point I plan to customize the OS a bit more, integrating a rootfs builder that allows package selection into the build process in one way or another.

### Sys installation
Create an sd card with _write_sd.sh_ as usual, spin up the orangepi and run _setup-alpine_.

When asked to do the disk-setup answer the question about _mount installation medium '/dev/mmcblk0p1'_ with 'y', choose mmcblk0, format it and choose sys installation.

Before reboot you need to copy some files from the current system to the new rootfs and edit the esyslinux.conf to run our own kernel with boot options:
- mount mmcblk0p1 (boot) and mmcblk0p3 (root) e.g. in /media
- download and unpack the latest release of this git repo(e.g. on mmcblk0p3 to have enough space)
- copy zImage and dtbs folder to /media/mmcblk0p1/
- add xr819, dwc2 and g_cdc in a separat line in /media/mmcblk0p3/etc/modules to load additional kernel modules
- dump the initramfs:
```
apk add u-boot-tools
dumpimage -l initramfs-sunxi
dumpimage -T ramdisk -o rootfs.xz initramfs-sunxi
unxz rootfs.xz
mkdir initramfs-sunxi
cd initramfs-sunxi
cpio -id < ../rootfs
```
- copy lib/modules/x.x.xx_opizero_default folder from initramfs-sunxi to /media/mmcblk0p3/lib/modules/
- copy lib/firmware/ folder content from initramfs-sunxi to /media/mmcblk0p3/lib/firmware to have the xradio firmware in place
- adapt /media/mmcblk0p1/extlinux/extlinux.conf to load own kernel with g_cdc module for serial communication:
```
menu title Alpine Linux
timeout 50
default lts

label lts
menu label Linux lts
kernel /zImage
initrd /initramfs-lts
fdtdir /dtbs
fdt /dtbs/sun8i-h2-plus-orangepi-zero.dtb
fdtoverlays /dtbs/overlays/sun8i-h2-plus-usbhost0.dtbo /dtbs/overlays/sun8i-h2-plus-usbhost1.dtbo /dtbs/overlays/sun8i-h2-plus-usbhost2.dtbo /dtbs/overlays/sun8i-h2-plus-usbhost3.dtbo
append root=UUID={UUID-from-install-process} modules=sd-mod,usb-storage,ext4,xr819,dwc2,g_cdc quiet rootfstype=ext4 console=${console} console=ttyGS0,115200
```

### DT Overlays

DT overlays can be applied at boot using the `boot/bootEnv.txt` file (which will be in `/media/mmcblk0p1/` from within the booted OS). The environment variable `overlays` should be set to a space separated string of overlays to load. The overlay DTBO files themselves will be in `boot/dtbs/overlays` and prefixed with `sun8i-h2-plus-`.

The overlays created during the build process have generally not been individually tested, they're just pulled directly from the [relevant Armbian repo](https://github.com/armbian/sunxi-DT-overlays) and renamed. The main device tree file is (currently) built from the [linux-sunxi kernel source](https://github.com/linux-sunxi/linux-sunxi/tree/sunxi-next), however, so there may be some incompatibilities.

Preferentially, `make install` (via `make overlays`) will build overlays from `configs/overlays`. Any `*.dts` files in this folder will be used if they exist, regardless of any files with matching names existing in the source.

## What Works, What Doesn't
The comments in the sections below apply to the default build (`builds/default`, `configs/kernel.default.config`).

Any other `configs/*.config` files that may be present are works in progress and should be assumed to be entirely non-functional.

### Wired Ethernet
Seems to function just fine.

#### USB OTG Ethernet USB0
By default the g_cdc kernel module is loaded and an ethernet device _USB0_ is displayed, which can be used e.g. for ssh sessions and file transfer between host pc and orangepi.

### WiFi
The xradio WiFi is generally functional, although there will be many "missed interrupt" warnings in the log and some (presumably) associated packet loss. This seems to be caused by an issue in the hardware and/or the driver and is not exclusive to this build.

It can be started with `wpa_supplicant` directly from the command line, or as a service via OpenRC, adding the following to `/etc/conf.d/wpa_supplicant`:

```
wpa_supplicant_args="-B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf"
```

Starting wpa_supplicant at the boot runlevel will cause the boot process to pause for an annoying length of time as it tries to configure the WiFi, due to a lack on entropy at boot. Having haveged running before starting wpa_supplicant dramatically improves this, the easiest way to achieve this is to start haveged as a boot service and wpa_supplicant as a default service:

```
apk add haveged
rc-update add haveged boot
rc-update add wpa_supplicant default
```

In theory it should be possible to make haveged start before wpa_supplicant on the same runlevel by adding appropriate before/after/use/want parameters to the depends() block in the `/etc/init.d/` files, but this isn't working for me at the moment and I've so far not put the effort in to figure out why.

### Serial Console
The UART TX/RX/GND pins, next to the ethernet connector, work as advertised, allowing monitoring of the boot process and providing serial console access as you'd expect.

Make sure you're using a 3.3V serial adapter, the board won't like 5V RS-232 (and if you try +/-15V old-school RS-232 set up a video camera first because I'm curious which components will let the magic smoke out first).

#### USB OTG Serial
By default the g_cdc kernel module is loaded and console interface is set to ttyGS0, too. Host will display ttyACM0, which can be used to log into the device.

The serial console runs at 115,200 baud (8N1).

### USB
The USB 2.0 port detects and can read/write USB flash drives, I've not yet tested it beyond that. 

### Everything Else
Untested. `dmesg` will have a few complaints about various bits and pieces of hardware.

It's not been a priority for me so far to plug things into the pin headers to see what happens, or to investigate these issues more generally. My intended application for the OPiZero only requires ethernet and a functional UART, although ideally I will get around to looking at other aspects at some point.

## To Do
- build a better initramfs with Alpine rootfs build tools, rather than cut and paste from the generic ARM release
- build a more complete kernel with a variety of modules for common hardware included so we have a device that has working header/GPIO pins and a USB port all sorts of things can be attached to
- see what an absolute minimal build looks like in terms of functionality, and how much of a size reduction it provides
- with a bit of luck, fit the whole thing on a 128Mb/16MB SPI NOR
- try not to get distracted and/or lose interest and actually implement the above

## References
  - [DIY Fully working Alpine Linux for Allwinner and Other ARM SOCs](https://wiki.alpinelinux.org/wiki/DIY_Fully_working_Alpine_Linux_for_Allwinner_and_Other_ARM_SOCs)
  - [armbian/build](https://github.com/armbian/build)
  - [How to compile Linux kernel for Orange Pi Zero](https://blog.brichacek.net/how-to-compile-linux-kernel-for-orange-pi-zero/)
  - [hyphop/miZy-uboot](https://github.com/hyphop/miZy-uboot)
  - [Building u-boot, script.bin and linux-kernel](http://www.orangepi.org/Docs/Building.html)
  - [https://github.com/asxtree/CompileKernelandAlpineLinuxforOrangePi](https://github.com/asxtree/CompileKernelandAlpineLinuxforOrangePi)
