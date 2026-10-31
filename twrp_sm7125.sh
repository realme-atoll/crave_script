#!/bin/bash
# =============================================================================
# TeamWin Recovery Project (TWRP) - Realme Atoll (sm7125)
# Unified: Realme 6 Pro (RMX2061), Realme 7 Pro (RMX2170), Realme 8 Pro (RMX3081)
#
# Examples:
#   Standard Build:
#     crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/twrp_sm7125.sh | bash"
#   With SourceForge Upload (Devspace Key /tmp/crave_sf):
#     crave run --no-patch -- "export SF_UPLOAD=true; curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/twrp_sm7125.sh | bash"
#   With SourceForge Upload (Base64 SF_KEY):
#     crave run --no-patch -- "export SF_KEY='<b64_key>'; curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/twrp_sm7125.sh | bash"
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

DEVICE="sm7125"
RECOVERY_NAME="TWRP"
BASE_MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"
BASE_MANIFEST_BRANCH="twrp-12.1"
DEVICE_MANIFEST_URL="https://github.com/realme-atoll/recovery-manifest"
DEVICE_MANIFEST_BRANCH="twrp"

BUILD_TARGET="recoveryimage"
BUILD_VARIANT="${BUILD_VARIANT:-eng}"
LUNCH_TARGET="twrp_${DEVICE}-${BUILD_VARIANT}"
WORK_DIR="/tmp/src/android"

UPLOAD_SUBDIR="Recovery/${DEVICE}/TWRP"

SCRIPT_BRANCH="${SCRIPT_BRANCH:-aosp-16}"
UPLOAD_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/upload.py"

# =============================================================================
# SCRIPT LOGIC
# =============================================================================

if [ -d "$WORK_DIR" ]; then
    cd "$WORK_DIR"
fi
echo "============================================================"
echo " Building $RECOVERY_NAME for $DEVICE"
echo " Working Directory: $(pwd)"
echo "============================================================"

# Clean previous build tree to prevent disk space exhaustion
rm -rf out/target/product/"${DEVICE}" out/soong
rm -rf .repo/local_manifests device/realme/"${DEVICE}"

# 1. Initialize repo
echo "=============================="
echo " [1/5] Initializing $RECOVERY_NAME base repo ($BASE_MANIFEST_BRANCH)..."
echo "=============================="
repo init -u "$BASE_MANIFEST_URL" -b "$BASE_MANIFEST_BRANCH"

# 2. Setup device manifest
echo "=============================="
echo " [2/5] Setting up device manifest ($DEVICE_MANIFEST_BRANCH)..."
echo "=============================="
git clone -b "$DEVICE_MANIFEST_BRANCH" "$DEVICE_MANIFEST_URL" .repo/local_manifests

# 3. Sync source via crave resync
echo "=============================="
echo " [3/5] Syncing source via crave resync..."
echo "=============================="
/opt/crave/resync.sh

# Qualcomm common dependencies
if [ ! -d "device/qcom/common" ]; then
    git clone --depth=1 https://github.com/TeamWin/android_device_qcom_common.git -b android-12.1 device/qcom/common
fi
if [ ! -d "device/qcom/twrp-common" ]; then
    git clone --depth=1 https://github.com/TeamWin/android_device_qcom_twrp-common.git -b android-12.1 device/qcom/twrp-common
fi

# 4. Setup build environment and lunch
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
echo "=============================="
echo " [5/5] Compiling $RECOVERY_NAME ($BUILD_TARGET)..."
echo "=============================="
m "$BUILD_TARGET"

# 6. Prepare branded image & upload
echo "=============================="
echo " Uploading recovery artifacts..."
echo "=============================="
[ -f "out/target/product/${DEVICE}/recovery.img" ] && cp -v "out/target/product/${DEVICE}/recovery.img" "out/target/product/${DEVICE}/TWRP-realme-${DEVICE}.img"
curl -sLf "$UPLOAD_SCRIPT_URL" | python3 - "${UPLOAD_SUBDIR}" "${DEVICE}" "recovery"

echo ""
echo "============================================================"
echo " $RECOVERY_NAME build process completed successfully!"
echo "============================================================"
