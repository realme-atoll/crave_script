#!/bin/bash

# ============================================================
# Crave Multi-Device Automated Build Script - Realme SM7125
# Builds: Realme 7 Pro (RMX2170), Realme 6 Pro (RMX2061),
#         Realme 8 Pro (RMX3081), & OrangeFox Recovery (sm7125)
# ============================================================
#
# Build Order:
#   1. Realme 7 Pro (RMX2170)
#   2. Realme 6 Pro (RMX2061)
#   3. Realme 8 Pro (RMX3081)
#   4. OrangeFox Recovery Project (sm7125)
#
# Usage:
#   Default (userdebug):
#     crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_all.sh | bash"
#
#   Custom build variant (e.g. user, userdebug, eng):
#     crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_all.sh | bash -s -- user"
#     OR
#     crave -n run --no-patch -- "BUILD_VARIANT=user curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_all.sh | bash"
#
# ============================================================

set -e

# ============================================================
# CONFIGURATION
# ============================================================

ROM_NAME="Android 16"
ROM_MANIFEST_URL="https://github.com/Evolution-X/manifest"
ROM_MANIFEST_BRANCH="bka"
BUILD_TARGET="evolution"

BUILD_VARIANT="${1:-${BUILD_VARIANT:-userdebug}}"

SOURCE_DIR="/tmp/src/android"

if [ -d "$SOURCE_DIR" ]; then
    cd "$SOURCE_DIR"
fi
ROM_WORK_DIR="$(pwd)"
echo "Working directory: $ROM_WORK_DIR"
echo "Build variant:     $BUILD_VARIANT"

# ============================================================
# INITIALIZE ROM REPOSITORY
# ============================================================

echo "============================================================"
echo " Initializing $ROM_NAME ($ROM_MANIFEST_BRANCH)..."
echo "============================================================"

repo init \
    -u "$ROM_MANIFEST_URL" \
    -b "$ROM_MANIFEST_BRANCH" \
    --git-lfs \
    --depth=1

echo "Repo initialized successfully."

# Helper function to clean, sync source and apply patches
sync_source() {
    echo "=============================="
    echo " Cleaning and syncing source..."
    echo "=============================="
    curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/clean.py | python3 || true
    if [ -f "/opt/crave/resync.sh" ]; then
        /opt/crave/resync.sh
    else
        repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
    fi
    curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/patch.py | python3 || true
    echo "Source sync and patches complete."
}

# ============================================================
# 1. REALME 7 PRO (RMX2170)
# ============================================================

echo ""
echo "============================================================"
echo " [1/4] Building $ROM_NAME - Realme 7 Pro (RMX2170)"
echo "============================================================"

cd "$ROM_WORK_DIR"
rm -rf .repo/local_manifests
git clone -b evox-bka https://github.com/realme-atoll/RMX2170-manifest .repo/local_manifests

sync_source

source build/envsetup.sh
lunch "lineage_RMX2170-${BUILD_VARIANT}"
m "$BUILD_TARGET"

# ============================================================
# 2. REALME 6 PRO (RMX2061)
# ============================================================

echo ""
echo "============================================================"
echo " [2/4] Building $ROM_NAME - Realme 6 Pro (RMX2061)"
echo "============================================================"

cd "$ROM_WORK_DIR"
rm -rf .repo/local_manifests
git clone -b evox-bka https://github.com/realme-atoll/RMX2061-manifest .repo/local_manifests

sync_source

source build/envsetup.sh
lunch "lineage_RMX2061-${BUILD_VARIANT}"
m "$BUILD_TARGET"

# ============================================================
# 3. REALME 8 PRO (RMX3081)
# ============================================================

echo ""
echo "============================================================"
echo " [3/4] Building $ROM_NAME - Realme 8 Pro (RMX3081)"
echo "============================================================"

cd "$ROM_WORK_DIR"
rm -rf .repo/local_manifests
git clone -b evox-bka https://github.com/realme-atoll/RMX3081-manifest .repo/local_manifests

sync_source

source build/envsetup.sh
lunch "lineage_RMX3081-${BUILD_VARIANT}"
m "$BUILD_TARGET"

# ============================================================
# 4. ORANGEFOX RECOVERY PROJECT (sm7125)
# ============================================================

echo ""
echo "============================================================"
echo " [4/4] Building OrangeFox Recovery Project (sm7125)"
echo "============================================================"

if [ -d "/tmp/src" ]; then
    OFRP_DIR="/tmp/src/ofrp"
else
    OFRP_DIR="${ROM_WORK_DIR}/ofrp"
fi

mkdir -p "$OFRP_DIR"
cd "$OFRP_DIR"

repo init -u "https://gitlab.com/OrangeFox/Manifest.git" -b "fox_16.0" --depth=1

rm -rf .repo/local_manifests
git clone -b fox_16.0 https://github.com/realme-atoll/sm7125-manifest .repo/local_manifests

if [ -f "/opt/crave/resync.sh" ]; then
    /opt/crave/resync.sh
else
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi
cd "$OFRP_DIR"

export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE="sm7125"
export LC_ALL="C.UTF-8"

source build/envsetup.sh
if [ -f "device/realme/sm7125/vendorsetup.sh" ]; then
    source "device/realme/sm7125/vendorsetup.sh" "sm7125"
fi

lunch twrp_sm7125-eng
m recoveryimage

echo ""
echo "============================================================"
echo " All builds completed successfully!"
echo "============================================================"
