#!/bin/bash

set -e

lsb_release -a

USER="$(whoami)"
if [ "${USER}" != "root" ]; then
    echo "ERROR: This script requires root privilege"
    exit 1
fi

apt update
apt install -y vim curl wget qemu-user-static qemu-system-arm debootstrap binfmt-support

UBUNTU_IMAGE_PATH="custom_ubuntu.img"
UBUNTU_ROOT_PATH="/mnt/ubuntu-boot"
UBUNTU_ROOTFS_PATH="/mnt/ubuntu-rootfs"

function start_custom() {

    if [ ! -f ${UBUNTU_IMAGE_PATH} ]; then
        echo "ERROR: custom_ubuntu.img file not found"
        exit 1
    fi

    rm -rf ${UBUNTU_ROOT_PATH} ${UBUNTU_ROOTFS_PATH}
    mkdir ${UBUNTU_ROOT_PATH} ${UBUNTU_ROOTFS_PATH}

    echo "$(fdisk -l ${UBUNTU_IMAGE_PATH})"

    OFFSET1=$(fdisk -l ${UBUNTU_IMAGE_PATH} | grep "${UBUNTU_IMAGE_PATH}1" | tr -s ' ' | cut -d' ' -f2)
    if [[ ! $OFFSET1 =~ ^[0-9]+$ ]]; then
        echo "Error: OFFSET1 is not a valid number."
        exit 1
    fi
    # shellcheck disable=SC2004
    LOOP_DEV1=$(losetup --find --show --offset $(($OFFSET1 * 512)) ${UBUNTU_IMAGE_PATH})

    OFFSET2=$(fdisk -l ${UBUNTU_IMAGE_PATH} | grep "${UBUNTU_IMAGE_PATH}2 " | tr -s ' ' | cut -d' ' -f2)
    if [[ ! $OFFSET2 =~ ^[0-9]+$ ]]; then
        echo "Error: OFFSET2 is not a valid number."
        exit 1
    fi
    # shellcheck disable=SC2004
    LOOP_DEV2=$(losetup --find --show --offset $(($OFFSET2 * 512)) ${UBUNTU_IMAGE_PATH})

    echo "OFFSET1: $OFFSET1"
    echo "OFFSET2: $OFFSET2"

    exit 0

    mount "$LOOP_DEV1" ${UBUNTU_ROOT_PATH}
    mount "$LOOP_DEV2" ${UBUNTU_ROOTFS_PATH}

    sleep 2

    mount --bind /dev ${UBUNTU_ROOTFS_PATH}/dev
    mount --bind /dev/pts ${UBUNTU_ROOTFS_PATH}/dev/pts
    mount -t proc proc ${UBUNTU_ROOTFS_PATH}/proc
    mount -t sysfs sys ${UBUNTU_ROOTFS_PATH}/sys

    sleep 2

    source ./script/init_service.sh
    init_service ${UBUNTU_ROOT_PATH} ${UBUNTU_ROOTFS_PATH}

    sleep 2
    umount ${UBUNTU_ROOTFS_PATH}/dev/pts
    umount ${UBUNTU_ROOTFS_PATH}/dev
    umount ${UBUNTU_ROOTFS_PATH}/proc
    umount ${UBUNTU_ROOTFS_PATH}/sys
    sleep 5
    umount ${UBUNTU_ROOTFS_PATH}
    umount ${UBUNTU_ROOT_PATH}
    sleep 2

    echo "Ubuntu Custom Done!"
    exit 0
}

start_custom