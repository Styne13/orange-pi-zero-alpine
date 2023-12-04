# Docker
Image to build orangepi zero alpine linux images in a ubuntu docker container

## Build
Execute the following command to build the container:
```
docker build -t orange-pi-zero-alpine-build:22.04 ./docker
```

## Run
Execute the following command form the main _orange-pi-zero-alpine_ directory:
```
docker run -ti -e CORES=$(grep -c processor /proc/cpuinfo) -v $PWD:/root/orange-pi-zero-alpine/ orange-pi-zero-alpine-build:22.04
```

This issues a build with default configuration including uboot, linux kernel, xradio driver and alpine image.

### Environment Variables
These can be handed over to the container via _-e_ option as in the example _run_ command.

_CORES_: Set number of cores to build faster

_LINUX_TAG_: Tag used for ```make get-linux```. If not set script tries to get latest and longest supported lts version.

_UBOOT_TAG_: Tag used for ```make get-uboot```. If not set script tries to get latest version

_ALPINE_VERSION_: Alpine version used for to download alpine image
