FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Berlin

ARG USER=root

WORKDIR /root/

RUN sed -i 's/archive.ubuntu.com/de.archive.ubuntu.com/' /etc/apt/sources.list \
    && apt-get update \
    && apt-get -y --no-install-recommends --fix-missing install \
	gcc-arm-linux-gnueabihf gcc automake make kmod bison flex swig musl bc tar xz-utils cpio \
	u-boot-tools dosfstools device-tree-compiler \
	libncurses5-dev squashfs-tools \
	git git-core git-lfs wget pv nano \
	python3 python3-pip python3-distutils python3-dev python-dev-is-python3 \
	ca-certificates openssl libssl-dev \
	locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8 \
    && pip3 install setuptools lastversion

COPY build.sh /root/

CMD ["./build.sh"]
