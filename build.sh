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
mkdir $workdir/clang
if [[ $USE_AOSP_CLANG == "true" ]]; then
    wget -qO $workdir/clang.tar.gz https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-$AOSP_CLANG_VERSION.tar.gz
    tar -xf $workdir/clang.tar.gz -C $workdir/clang/
    rm -f $workdir/clang.tar.gz
elif [[ $USE_CUSTOM_CLANG == "true" ]]; then
    if [[ $CUSTOM_CLANG_SOURCE =~ git ]]; then
        if [[ $CUSTOM_CLANG_SOURCE == *'.tar.'* ]]; then
            wget -qO $workdir/clang.tar.gz $CUSTOM_CLANG_SOURCE
			tar -xf $workdir/clang.tar.gz -C $workdir/clang/
            rm -f $workdir/*.tar.*
        else
            rm -rf $workdir/clang
            git clone $CUSTOM_CLANG_SOURCE -b $CUSTOM_CLANG_BRANCH $workdir/clang --depth=1
        fi
	elif [[ $CUSTOM_CLANG_SOURCE == *'.tar.'* ]]; then
            wget -qO $workdir/clang.tar.gz $CUSTOM_CLANG_SOURCE
			tar -xf $workdir/clang.tar.gz -C $workdir/clang/
            rm -f $workdir/*.tar.*
    else
        echo "Clang source other than git or tar file is not supported."
        exit 1
    fi
elif [[ $USE_AOSP_CLANG == "true" ]] && [[ $USE_CUSTOM_CLANG == "true" ]]; then
    echo "You have to choose one, AOSP Clang or Custom Clang!"
    exit 1
else
    echo "stfu."
    exit 1
fi

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

$ONLY_DEFCONFIG && exit

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
