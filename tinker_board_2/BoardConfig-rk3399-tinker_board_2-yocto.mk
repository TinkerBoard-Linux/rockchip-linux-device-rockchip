#!/bin/bash

# Target arch
export RK_KERNEL_ARCH=arm64
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=tinker_board_2
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=tinker_board_2_defconfig
# Kernel dts
export RK_KERNEL_DTS=rk3399-tinker_board_2
# boot image type
export RK_BOOT_IMG=boot.img
# kernel image path
export RK_KERNEL_IMG=kernel/arch/arm64/boot/Image
# parameter for GPT table
export RK_PARAMETER=parameter.txt
# Buildroot config
export RK_CFG_BUILDROOT=rockchip_rk3399
# Build Debian by default
export RK_ROOTFS_SYSTEM=yocto
# Recovery config
export RK_CFG_RECOVERY=rockchip_rk3399_recovery
# Pcba config
export RK_CFG_PCBA=rockchip_rk3399_pcba
# target chip
export RK_CHIP=rk3399
# Set rootfs type, including ext2 ext4 squashfs
export RK_ROOTFS_TYPE=ext4
# Set debian version (debian10: buster, debian11: bullseye)
export RK_DEBIAN_VERSION=bullseye
# yocto machine
export RK_YOCTO_MACHINE=rockchip-rk3399-tinker_board_2
#misc image
export RK_MISC=blank-misc.img
# Define WiFi BT chip
# Compatible with Realtek and AP6XXX WiFi : RK_WIFIBT_CHIP=ALL_AP
# Compatible with Realtek and CYWXXX WiFi : RK_WIFIBT_CHIP=ALL_CY
# Single WiFi configuration: AP6256 or CYW43455: RK_WIFIBT_CHIP=AP6256
export RK_WIFIBT_CHIP=ALL_AP
# Define BT ttySX
export RK_WIFIBT_TTY=ttyS0
# <dev>:<mount point>:<fs type>:<mount flags>:<source dir>:<image size(M|K|auto)>:[options]
export RK_EXTRA_PARTITIONS="userdata:/userdata:ext2:defaults:userdata_normal:auto:resize"
# Define package-file for update.img
export RK_PACKAGE_FILE=tinker_board_2-package-file
