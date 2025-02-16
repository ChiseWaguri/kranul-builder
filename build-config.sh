# GKI Version
export GKI_VERSION="android12-5.10"

# Build variables
export TZ="Asia/Jakarta"
export KBUILD_BUILD_USER="chise"
export KBUILD_BUILD_HOST="ubuntu24"
export KBUILD_BUILD_TIMESTAMP=$(date)


# Melt KSU Manual Hook
export MELT_KSU_USE_MANUAL_HOOK= # set to yes to activate, else off

# LTO
export LTO_CONFIG="default" 
# default, THIN, FULL, NONE

# AOSP Clang
export USE_AOSP_CLANG="true"
export AOSP_CLANG_VERSION="r547379"

# Custom clang
export USE_CUSTOM_CLANG="false"
export CUSTOM_CLANG_SOURCE="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/30af425ee5c159ed7b9b2ac895344858396686eb/clang-r547379.tar.gz" # git repo or tar file
export CUSTOM_CLANG_BRANCH="" # if from git

