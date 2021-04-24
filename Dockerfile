FROM debian:bullseye
RUN adduser --disabled-password --gecos "" notroot
RUN apt-get -qq update
RUN apt-get -qq install \
	build-essential \
	file \
	wget \
	cpio \
	python3 \
	python3-ply \
	python3-pip \
	unzip \
	rsync \
	flex \
	bison \
	bc \
	git \
	pkg-config \
	libssl-dev \
	libyaml-dev \
	gcc-arm-linux-gnueabihf
USER notroot
