#!/bin/bash

# ============================================================
# Android 16 - RMX2170 (Realme 7 Pro)
# ============================================================
#
# Usage:
#   Default (userdebug):
#     crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2170.sh | bash"
#
#   Custom build variant (e.g. user, userdebug, eng):
#     crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2170.sh | bash -s -- user"
#     OR
#     crave -n run --no-patch -- "BUILD_VARIANT=user curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2170.sh | bash"
#
# ============================================================

set -e

# ============================================================
# CONFIG - CHANGE ONLY THESE VALUES FOR A DIFFERENT ROM
# ============================================================

ROM_NAME="Android 16"

ROM_MANIFEST_URL="https://github.com/Evolution-X/manifest"
ROM_MANIFEST_BRANCH="bka"

DEVICE_MANIFEST_URL="https://github.com/realme-atoll/RMX2170-manifest"
DEVICE_MANIFEST_BRANCH="evox-bka"

DEVICE="RMX2170"

# Build variant: user, userdebug, or eng (passed via $1 or BUILD_VARIANT env var; defaults to userdebug)
BUILD_VARIANT="${1:-${BUILD_VARIANT:-userdebug}}"
BUILD_TARGET="evolution"

LUNCH_PRODUCT="lineage_${DEVICE}"
LUNCH_TARGET="${LUNCH_PRODUCT}-${BUILD_VARIANT}"

SOURCE_DIR="/tmp/src/android"

# ============================================================
# DO NOT MODIFY BELOW THIS LINE
# ============================================================

echo "=============================="
echo " $ROM_NAME Build - $DEVICE ($BUILD_VARIANT)"
echo "=============================="

# Use SOURCE_DIR only if it exists, otherwise build in current workspace
if [ -d "$SOURCE_DIR" ]; then
    cd "$SOURCE_DIR"
fi
echo "Working directory: $(pwd)"

# ============================================================
# Initialize ROM repo
# ============================================================

echo "=============================="
echo " Initializing $ROM_NAME ($ROM_MANIFEST_BRANCH)..."
echo "=============================="

repo init \
    -u "$ROM_MANIFEST_URL" \
    -b "$ROM_MANIFEST_BRANCH" \
    --git-lfs \
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

# Clean previous patches and dirty state
curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/clean.py | python3

/opt/crave/resync.sh

echo "=============================="
echo " Sync complete"
echo "=============================="

# ============================================================
# Apply Upstream Fixes
# ============================================================

curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/patch.py | python3

# ============================================================
# Build environment
# ============================================================

echo "=============================="
echo " Setting up build environment..."
echo "=============================="

source build/envsetup.sh

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
echo " Building $ROM_NAME ($BUILD_TARGET)..."
echo "=============================="

m "$BUILD_TARGET"

echo "=============================="
echo " Build complete successfully"
echo "=============================="
