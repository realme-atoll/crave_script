#!/bin/bash
# =============================================================================
# Lunaris (Android 16) - Realme 7 Pro (RMX2170)
#
# Examples:
#   crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/lunaris_rmx2170.sh | bash"
#   crave run --no-patch -- "SF_KEY='<b64_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/lunaris_rmx2170.sh | bash"
# =============================================================================

set -e -o pipefail

# =============================================================================
# CONFIGURATION - MODIFY ONLY THIS SECTION
# =============================================================================

# Device & ROM Settings
DEVICE="RMX2170"
ROM_NAME="Lunaris"
ROM_MANIFEST_URL="https://github.com/Lunaris-AOSP/android.git"
ROM_MANIFEST_BRANCH="16"
DEVICE_MANIFEST_URL="https://github.com/realme-atoll/RMX2170-manifest"
DEVICE_MANIFEST_BRANCH="aosp-16"

# Build Settings
BUILD_VARIANT="${1:-${BUILD_VARIANT:-userdebug}}"
BUILD_TARGET="bacon"
LUNCH_TARGET="lineage_${DEVICE}-${BUILD_VARIANT}"
WORK_DIR="/tmp/src/android"

# Cloud Upload Destination
UPLOAD_SUBDIR="${DEVICE}/Lunaris/16"

# Helper Scripts URLs
SCRIPT_BRANCH="${SCRIPT_BRANCH:-aosp-16}"
CLEAN_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/clean.py"
PATCH_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/patch.py"
UPLOAD_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/upload.py"

# =============================================================================
# SCRIPT LOGIC - DO NOT MODIFY BELOW THIS LINE
# =============================================================================

# Workspace Setup
[ -d "$WORK_DIR" ] && cd "$WORK_DIR"
echo "============================================================"
echo " Building $ROM_NAME for $DEVICE ($BUILD_VARIANT)"
echo " Working Directory: $(pwd)"
echo "============================================================"

# 1. Initialize ROM repo
echo ""
echo "=============================="
echo " [1/6] Initializing $ROM_NAME ($ROM_MANIFEST_BRANCH)..."
echo "=============================="
repo init -u "$ROM_MANIFEST_URL" -b "$ROM_MANIFEST_BRANCH" --git-lfs --depth=1

# 2. Setup device manifest
echo ""
echo "=============================="
echo " [2/6] Setting up device manifest..."
echo "=============================="
rm -rf .repo/local_manifests
git clone -b "$DEVICE_MANIFEST_BRANCH" "$DEVICE_MANIFEST_URL" .repo/local_manifests

# 3. Clean and sync source
echo ""
echo "=============================="
echo " [3/6] Syncing source and applying patches..."
echo "=============================="
curl -sLf "$CLEAN_SCRIPT_URL" | python3
/opt/crave/resync.sh
curl -sLf "$PATCH_SCRIPT_URL" | python3

# 4. Setup build environment and lunch
echo ""
echo "=============================="
echo " [4/6] Setting up environment & lunching $LUNCH_TARGET..."
echo "=============================="
source build/envsetup.sh
lunch "$LUNCH_TARGET"

# 5. Compile ROM
echo ""
echo "=============================="
echo " [5/6] Building $ROM_NAME ($BUILD_TARGET)..."
echo "=============================="
m "$BUILD_TARGET" 2>&1 | tee /tmp/build_${DEVICE}.log

# 6. Extract cooked ROM package and upload
echo ""
echo "=============================="
echo " [6/6] Uploading build artifacts..."
echo "=============================="
BUILD_ZIP=$(grep "Package Complete:" /tmp/build_${DEVICE}.log | awk '{print $NF}' | tail -n 1)
BUILD_ZIP="${BUILD_ZIP:-$(ls -t "out/target/product/${DEVICE}/"*.zip 2>/dev/null | grep -v -E "target_files|symbols|ota_update" | head -n 1)}"

curl -sLf "$UPLOAD_SCRIPT_URL" | python3 - "${UPLOAD_SUBDIR}" "$BUILD_ZIP"

echo ""
echo "============================================================"
echo " Build process completed successfully!"
echo "============================================================"
