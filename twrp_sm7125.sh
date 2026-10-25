#!/bin/bash

# ============================================================
# TeamWin Recovery Project (TWRP) - sm7125 (Realme 6 Pro, 7 Pro & 8 Pro)
# ============================================================
#
# Usage:
#   crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/twrp_sm7125.sh | bash"
#
# ============================================================

set -e

# ============================================================
# CONFIG - CHANGE ONLY THESE VALUES FOR A DIFFERENT RECOVERY/DEVICE
# ============================================================

RECOVERY_NAME="TeamWin Recovery Project"

RECOVERY_MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"
RECOVERY_MANIFEST_BRANCH="twrp-12.1"

DEVICE_MANIFEST_URL="https://github.com/realme-atoll/sm7125-manifest"
DEVICE_MANIFEST_BRANCH="twrp-12.1"

DEVICE="sm7125"
LUNCH_TARGET="twrp_${DEVICE}-eng"
BUILD_TARGET="recoveryimage"

SOURCE_DIR="/tmp/src/android"

# ============================================================
# DO NOT MODIFY BELOW THIS LINE
# ============================================================

echo "=============================="
echo " $RECOVERY_NAME Build - $DEVICE ($LUNCH_TARGET)"
echo "=============================="

# Use SOURCE_DIR only if it exists, otherwise build in current workspace
if [ -d "$SOURCE_DIR" ]; then
    cd "$SOURCE_DIR"
fi
echo "Working directory: $(pwd)"

# ============================================================
# Initialize Recovery repo
# ============================================================

echo "=============================="
echo " Initializing $RECOVERY_NAME ($RECOVERY_MANIFEST_BRANCH)..."
echo "=============================="

repo init \
    -u "$RECOVERY_MANIFEST_URL" \
    -b "$RECOVERY_MANIFEST_BRANCH" \
    --depth=1

echo "=============================="
echo " Repo initialized"
echo "=============================="

# ============================================================
# Setup device local manifest
# ============================================================

echo "=============================="
echo " Setting up device manifest..."
echo "=============================="

rm -rf .repo/local_manifests

git clone \
    -b "$DEVICE_MANIFEST_BRANCH" \
    "$DEVICE_MANIFEST_URL" \
    .repo/local_manifests

echo "=============================="
echo " Device manifest ready"
echo "=============================="

# ============================================================
# Sync source
# ============================================================

echo "=============================="
echo " Syncing source..."
echo "=============================="

if [ -f "/opt/crave/resync.sh" ]; then
    /opt/crave/resync.sh
else
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi

echo "=============================="
echo " Sync complete"
echo "=============================="

# ============================================================
# Build environment
# ============================================================

echo "=============================="
echo " Setting up build environment..."
echo "=============================="

export ALLOW_MISSING_DEPENDENCIES=true
export TW_DEVICE_VERSION="12.1"
export LC_ALL="C.UTF-8"

source build/envsetup.sh

# Source device-specific vendor setup if available
if [ -f "device/realme/${DEVICE}/vendorsetup.sh" ]; then
    source "device/realme/${DEVICE}/vendorsetup.sh" "$DEVICE"
fi

echo "=============================="
echo " Envsetup complete"
echo "=============================="

# ============================================================
# Lunch target
# ============================================================

echo "=============================="
echo " Running lunch $LUNCH_TARGET..."
echo "=============================="

lunch "$LUNCH_TARGET"

echo "=============================="
echo " Lunch complete"
echo "=============================="

# ============================================================
# Build
# ============================================================

echo "=============================="
echo " Building $RECOVERY_NAME ($BUILD_TARGET)..."
echo "=============================="

m "$BUILD_TARGET"

echo "=============================="
echo " Build complete successfully"
echo "=============================="

# ============================================================
# Post-Build Artifacts
# ============================================================

OUT_DIR="out/target/product/${DEVICE}"
if [ -d "$OUT_DIR" ]; then
    echo "=============================="
    echo " Processing build artifacts..."
    echo "=============================="

    # Find generated recovery image
    if [ -f "$OUT_DIR/recovery.img" ]; then
        cp -v "$OUT_DIR/recovery.img" "$OUT_DIR/TWRP-realme-${DEVICE}.img"
    fi

    # Find generated TWRP zip (if any)
    TWRP_ZIP=$(find "$OUT_DIR" -maxdepth 1 \( -name "twrp*.zip" -o -name "TWRP*.zip" \) | head -n 1)

    if [ -n "$TWRP_ZIP" ] && [ -f "$TWRP_ZIP" ]; then
        ZIP_BASENAME=$(basename "$TWRP_ZIP" .zip)

        # Ensure "realme" is included in the name
        if [[ "$ZIP_BASENAME" =~ "realme" ]]; then
            TARGET_BASE="$ZIP_BASENAME"
        else
            if [[ "$ZIP_BASENAME" =~ "${DEVICE}" ]]; then
                TARGET_BASE="${ZIP_BASENAME//${DEVICE}/realme-${DEVICE}}"
            else
                TARGET_BASE="${ZIP_BASENAME}-realme-${DEVICE}"
            fi
        fi

        if [ "$TWRP_ZIP" != "$OUT_DIR/${TARGET_BASE}.zip" ]; then
            cp -v "$TWRP_ZIP" "$OUT_DIR/${TARGET_BASE}.zip"
        fi
    fi

    echo "=============================="
    echo " Final Artifacts:"
    echo "=============================="
    ls -lh "$OUT_DIR"/TWRP* "$OUT_DIR"/twrp* "$OUT_DIR"/recovery.img 2>/dev/null || true
fi
