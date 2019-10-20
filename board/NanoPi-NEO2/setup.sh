#
KERNCONF=NANOPI
SUNXI_UBOOT_DIR="u-boot-nanopi-neo2"
SUNXI_UBOOT_BIN="u-boot-sunxi-with-spl.bin "
UBOOT_PATH="/usr/local/share/u-boot/${SUNXI_UBOOT_DIR}"
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=aarch64
TARGET=aarch64

nanopi_k1_plus_check_uboot ( ) {
    uboot_port_test ${SUNXI_UBOOT_DIR} ${SUNXI_UBOOT_BIN}
}
strategy_add $PHASE_CHECK nanopi_k1_plus_check_uboot

#
# NanoPi K1 Plus uses EFI, so the first partition will be a FAT partition.
#
nanopi_k1_plus_partition_image ( ) {
    echo "Installing Partitions on ${DISK_MD}"
    dd if=${UBOOT_PATH}/${SUNXI_UBOOT_BIN} conv=sync of=/dev/${DISK_MD} bs=1024 seek=8
    disk_partition_mbr
    disk_fat_create 16m 16 1m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW nanopi_k1_plus_partition_image

nanopi_k1_plus_populate_boot_partition ( ) {
    mkdir -p efi/boot
    echo bootaa64 > startup.nsh
    cp ${UBOOT_PATH}/${SUNXI_UBOOT_BIN} .
    cp ${UBOOT_PATH}/README .
}
strategy_add $PHASE_BOOT_INSTALL nanopi_k1_plus_populate_boot_partition

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER  freebsd_loader_efi_build
strategy_add $PHASE_BOOT_INSTALL mkdir -p efi efi/boot
strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy efi/boot/bootaa64.efi

# NanoPi K1 Plus puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos

