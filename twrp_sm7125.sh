#!/bin/bash
# =============================================================================
# TeamWin Recovery Project (TWRP) - Realme Atoll (sm7125)
# Unified: Realme 6 Pro (RMX2061), Realme 7 Pro (RMX2170), Realme 8 Pro (RMX3081)
#
# Examples:
#   crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/twrp_sm7125.sh | bash"
#   crave run --no-patch -- "SF_KEY='<b64_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/twrp_sm7125.sh | bash"
# =============================================================================

set -e -o pipefail

# =============================================================================
# CONFIGURATION - MODIFY ONLY THIS SECTION
# =============================================================================

# Device & Recovery Settings
DEVICE="sm7125"
RECOVERY_NAME="TWRP"
MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"
MANIFEST_BRANCH="twrp-14.1"
DEVICE_MANIFEST_URL="https://github.com/realme-atoll/recovery-manifest"
DEVICE_MANIFEST_BRANCH="twrp"

# Build Settings
BUILD_TARGET="recoveryimage"
LUNCH_TARGET="twrp_${DEVICE}-trunk_staging-eng"
WORK_DIR="/tmp/src/android"

# Cloud Upload Destination
UPLOAD_SUBDIR="Recovery/${DEVICE}/TWRP"

# Helper Scripts URLs
SCRIPT_BRANCH="${SCRIPT_BRANCH:-aosp-16}"
UPLOAD_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/upload.py"

# =============================================================================
# SCRIPT LOGIC - DO NOT MODIFY BELOW THIS LINE
# =============================================================================

# Workspace Setup (Uses Crave's stock cached directory)
if [ -d "$WORK_DIR" ]; then
    cd "$WORK_DIR"
fi
echo "============================================================"
echo " Building $RECOVERY_NAME for $DEVICE"
echo " Working Directory: $(pwd)"
echo "============================================================"

# 1. Initialize repo
echo ""
echo "=============================="
echo " [1/5] Initializing $RECOVERY_NAME repo ($MANIFEST_BRANCH)..."
echo "=============================="
repo init -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH" --depth=1

# 2. Setup device manifest
echo ""
echo "=============================="
echo " [2/5] Setting up device manifest..."
echo "=============================="
rm -rf .repo/local_manifests
git clone -b "$DEVICE_MANIFEST_BRANCH" "$DEVICE_MANIFEST_URL" .repo/local_manifests

# 3. Sync source
echo ""
echo "=============================="
echo " [3/5] Syncing source via crave resync..."
echo "=============================="
/opt/crave/resync.sh

# 4. Setup build environment and lunch
echo ""
echo "=============================="
echo " [4/5] Setting up environment & lunching $LUNCH_TARGET..."
echo "=============================="
export ALLOW_MISSING_DEPENDENCIES=true
export TW_DEVICE_VERSION="12.1"
export LC_ALL="C.UTF-8"
source build/envsetup.sh
[ -f "device/realme/${DEVICE}/vendorsetup.sh" ] && source "device/realme/${DEVICE}/vendorsetup.sh" "${DEVICE}"
lunch "$LUNCH_TARGET"

# 5. Compile recovery
echo ""
echo "=============================="
echo " [5/5] Compiling $RECOVERY_NAME ($BUILD_TARGET)..."
echo "=============================="
m "$BUILD_TARGET" 2>&1 | tee /tmp/build_${DEVICE}.log

# 6. Prepare branded image & upload
echo ""
echo "=============================="
echo " Uploading recovery artifacts..."
echo "=============================="
OUT_DIR="out/target/product/${DEVICE}"
[ -f "$OUT_DIR/recovery.img" ] && cp -v "$OUT_DIR/recovery.img" "$OUT_DIR/TWRP-realme-${DEVICE}.img"
COOKED_FILES=($(ls -t "$OUT_DIR"/TWRP*.img "$OUT_DIR"/TWRP*.zip "$OUT_DIR"/twrp*.zip 2>/dev/null | head -n 2))
curl -sLf "$UPLOAD_SCRIPT_URL" | python3 - "${UPLOAD_SUBDIR}" "${COOKED_FILES[@]}"

echo ""
echo "============================================================"
echo " $RECOVERY_NAME build process completed successfully!"
echo "============================================================"
