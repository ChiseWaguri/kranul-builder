#!/bin/bash

set -x

# source config
source ./build-config.sh

SECONDS=0 # start timer
workdir=$(realpath ..)
kernel_root=$(pwd)

ONLY_DEFCONFIG=false
DISABLE_LTO=false


while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -d | --disable-lto )
                DISABLE_LTO=true
                ;;
        -c | --gen-config )
                ONLY_DEFCONFIG=true
                ;;
        * )
                ONE="${1}"
                ;;
    esac
    shift
done


KERNEL_COPY_TO="$workdir/files"
mkdir $KERNEL_COPY_TO

DEFCONFIG="marble_defconfig"

# DEFCONFIGS="vendor/waipio_GKI.config \
# vendor/xiaomi_GKI.config \
# vendor/personal.config \
# vendor/debugfs.config"
DEFCONFIGS="vendor/custom.config"


# Download Toolchains
[[ ! -d $workdir/clang ]] || exit 1

# Clone binutils if they don't exist
if ! ls $workdir/clang/bin | grep -q 'aarch64-linux-gnu'; then
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gas/linux-x86 -b main $workdir/gas
    export PATH="$workdir/clang/bin:$workdir/gas:$PATH"
else
    export PATH="$workdir/clang/bin:$PATH"
fi


function m() {
    make -j27 ARCH=arm64 LLVM=1 LLVM_IAS=1 O=out CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- $@ || exit 0
}


echo -e "Generating config...\n"
$DISABLE_LTO && (
    sed -i 's/CONFIG_LTO=y/CONFIG_LTO=n/' "$workdir/common/arch/arm64/configs/$DEFCONFIG"
    sed -i 's/CONFIG_LTO_CLANG_FULL=y/CONFIG_LTO_CLANG_FULL=n/' "$workdir/common/arch/arm64/configs/$DEFCONFIG"
    sed -i 's/CONFIG_LTO_CLANG_THIN=y/CONFIG_LTO_CLANG_THIN=n/' "$workdir/common/arch/arm64/configs/$DEFCONFIG"
    sed -i 's/CONFIG_THINLTO=y/CONFIG_THINLTO=n/' "$workdir/common/arch/arm64/configs/$DEFCONFIG"
    echo "CONFIG_LTO_CLANG_NONE=y" >> "$workdir/common/arch/arm64/configs/$DEFCONFIG"
    echo "CONFIG_LTO_NONE=y" >> "$workdir/common/arch/arm64/configs/$DEFCONFIG"
)
mkdir -p out
m $DEFCONFIG
m ./scripts/kconfig/merge_config.sh $DEFCONFIGS
scripts/config --file out/.config \
    --set-str LOCALVERSION "-Melt-Chise"

$ONLY_DEFCONFIG && (
	cp out/.config $KERNEL_COPY_TO
)

echo -e "\nBuilding kernel...\n"
m

echo -e "\nKernel compiled succesfully!...\n"

# rm -rf AnyKernel3
# if [ -d "$AK3_DIR" ]; then
# 	cp -r $AK3_DIR AnyKernel3
# 	git -C AnyKernel3 checkout marble &> /dev/null
# elif ! git clone -q https://github.com/ghostrider-reborn/AnyKernel3 -b marble; then
# 	echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
# 	exit 1
# fi
# KERNEL_COPY_TO="AnyKernel3"
# DTB_COPY_TO="AnyKernel3/dtb"
# DTBO_COPY_TO="AnyKernel3/dtbo.img"
# VBOOT_DIR="AnyKernel3/vendor_boot_modules"
# VDLKM_DIR="AnyKernel3/vendor_dlkm_modules"

cp $workdir/common/out/arch/arm64/boot/Image $KERNEL_COPY_TO
echo "Copied kernel to $KERNEL_COPY_TO."

# cd AnyKernel3
# zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
# cd ..
# rm -rf AnyKernel3

echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
# echo "$(realpath $ZIPNAME)"
