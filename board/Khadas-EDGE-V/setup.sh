#
KERNCONF=EXPERT
TARGET=aarch64
TARGET_ARCH=aarch64
UBOOT_DIR="u-boot-khadas-edge-v"
UBOOT_PATH="/usr/local/share/u-boot/${UBOOT_DIR}"
UBOOT_BIN="u-boot.itb"
IMAGE_SIZE=$((1000 * 1000 * 1000))

khadas_edge_v_check_uboot ( ) {
	uboot_port_test ${UBOOT_DIR} ${UBOOT_BIN}
}
strategy_add $PHASE_CHECK khadas_edge_v_check_uboot

#
# Khadas EDGE-V uses EFI, so the first partition will be a FAT partition.
#
khadas_edge_v_partition_image ( ) {
	echo "Installing Partitions on ${DISK_MD}"
	dd if=${UBOOT_PATH}/idbloader.img of=/dev/${DISK_MD} conv=sync bs=512 seek=64
	dd if=${UBOOT_PATH}/${UBOOT_BIN}  of=/dev/${DISK_MD} conv=sync bs=512 seek=16384
	disk_partition_mbr
	disk_fat_create 16m 16 1m
	disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW khadas_edge_v_partition_image

khadas_edge_v_populate_boot_partition ( ) {
	mkdir -p efi/boot
	echo bootaa64 > startup.nsh
}
strategy_add $PHASE_BOOT_INSTALL khadas_edge_v_populate_boot_partition

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER  freebsd_loader_efi_build
strategy_add $PHASE_BOOT_INSTALL mkdir -p efi efi/boot
strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy efi/boot/bootaa64.efi

# Khadas EDGE-V puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos

fix_dtb_path () {
	echo "Fix DTB path to ${BOARD_FREEBSD_MOUNTPOINT}/boot/dtb"
	DTBFILE="${BOARD_FREEBSD_MOUNTPOINT}/boot/dtb/rockchip/rk3399-khadas-edge-v.dtb"
	if [ -f ${DTBFILE} ] ; then
		cp ${DTBFILE} ${BOARD_FREEBSD_MOUNTPOINT}/boot/dtb
	fi
}

PRIORITY=200 strategy_add $PHASE_FREEBSD_OPTION_INSTALL fix_dtb_path

