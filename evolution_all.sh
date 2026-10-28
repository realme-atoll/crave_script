#!/bin/bash
# =============================================================================
# Evolution X (Android 16) - Multi-Device Batch Build
# Devices: Realme 7 Pro (RMX2170), Realme 6 Pro (RMX2061), Realme 8 Pro (RMX3081)
#
# Examples:
#   crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_all.sh | bash"
#   crave run --no-patch -- "SF_KEY='<b64_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_all.sh | bash"
# =============================================================================

# Enable pipefail so pipeline failure (m ... | tee) is accurately detected
# Note: set -e is deliberately omitted so a failure on one device does not abort remaining devices
set -o pipefail

# =============================================================================
# CONFIGURATION - MODIFY ONLY THIS SECTION
# =============================================================================

# ROM Source Repository
ROM_NAME="Evolution X"
ROM_MANIFEST_URL="https://github.com/Evolution-X/manifest"
ROM_MANIFEST_BRANCH="bka"

# Device Local Manifests (Configured independently per device)
RMX2170_MANIFEST_URL="https://github.com/realme-atoll/RMX2170-manifest"
RMX2170_MANIFEST_BRANCH="evox-bka"

RMX2061_MANIFEST_URL="https://github.com/realme-atoll/RMX2061-manifest"
RMX2061_MANIFEST_BRANCH="evox-bka"

RMX3081_MANIFEST_URL="https://github.com/realme-atoll/RMX3081-manifest"
RMX3081_MANIFEST_BRANCH="evox-bka"

# Build Settings
BUILD_VARIANT="${1:-${BUILD_VARIANT:-userdebug}}"
BUILD_TARGET="evolution"
WORK_DIR="/tmp/src/android"

# Cloud Upload Destination (Destination path: <DEVICE>/<UPLOAD_SUBDIR_SUFFIX>)
UPLOAD_SUBDIR_SUFFIX="EvolutionX/16"

# Helper Scripts URLs
SCRIPT_BRANCH="${SCRIPT_BRANCH:-aosp-16}"
CLEAN_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/clean.py"
PATCH_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/patch.py"
UPLOAD_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/upload.py"

# =============================================================================
# SCRIPT LOGIC - DO NOT MODIFY BELOW THIS LINE
# =============================================================================

SUCCESS_BUILDS=()
FAILED_BUILDS=()

# Setup workspace
if [ -d "$WORK_DIR" ]; then
    cd "$WORK_DIR"
else
    WORK_DIR="$(pwd)"
fi

echo "============================================================"
echo " Starting $ROM_NAME Batch Build ($BUILD_VARIANT)"
echo " Workspace: $WORK_DIR"
echo "============================================================"

# Initialize ROM repo (shared base)
echo ""
echo "=============================="
echo " Initializing $ROM_NAME base repo..."
echo "=============================="
repo init -u "$ROM_MANIFEST_URL" -b "$ROM_MANIFEST_BRANCH" --git-lfs --depth=1 || true

# Helper: Build single device
build_device() {
    local dev="$1"
    local manifest_url="$2"
    local manifest_branch="$3"

    echo ""
    echo "============================================================"
    echo ">>> Starting Build for $dev ($BUILD_VARIANT)..."
    echo "============================================================"

    cd "$WORK_DIR"
    
    # 1. Setup device manifest
    echo ""
    echo "=============================="
    echo " [$dev] Setting up device manifest..."
    echo "=============================="
    rm -rf .repo/local_manifests
    if git clone -b "$manifest_branch" "$manifest_url" .repo/local_manifests; then
        
        # 2. Clean and sync source
        echo ""
        echo "=============================="
        echo " [$dev] Syncing source and applying patches..."
        echo "=============================="
        curl -sLf "$CLEAN_SCRIPT_URL" | python3 || true
        /opt/crave/resync.sh || true
        curl -sLf "$PATCH_SCRIPT_URL" | python3 || true
        
        # 3. Setup build environment and lunch
        echo ""
        echo "=============================="
        echo " [$dev] Setting up environment & lunching lineage_${dev}-${BUILD_VARIANT}..."
        echo "=============================="
        source build/envsetup.sh

        if lunch "lineage_${dev}-${BUILD_VARIANT}"; then
            
            # 4. Compile ROM
            echo ""
            echo "=============================="
            echo " [$dev] Compiling $ROM_NAME ($BUILD_TARGET)..."
            echo "=============================="
            if m "$BUILD_TARGET" 2>&1 | tee "/tmp/build_${dev}.log"; then
                echo ">>> [SUCCESS] $dev build succeeded!"
                SUCCESS_BUILDS+=("$dev")

                # 5. Extract cooked package and upload
                echo ""
                echo "=============================="
                echo " [$dev] Uploading build artifacts..."
                echo "=============================="
                local build_zip
                build_zip=$(grep "Package Complete:" "/tmp/build_${dev}.log" | awk '{print $NF}' | tail -n 1)
                build_zip="${build_zip:-$(ls -t "out/target/product/${dev}/"*.zip 2>/dev/null | grep -v -E "target_files|symbols|ota_update" | head -n 1)}"

                curl -sLf "$UPLOAD_SCRIPT_URL" | python3 - "${dev}/${UPLOAD_SUBDIR_SUFFIX}" "$build_zip" || true
            else
                echo ">>> [FAILED] $dev build compilation failed!"
                FAILED_BUILDS+=("$dev")
            fi
        else
            echo ">>> [FAILED] $dev lunch failed!"
            FAILED_BUILDS+=("$dev [lunch failed]")
        fi
    else
        echo ">>> [FAILED] $dev local manifest clone failed!"
        FAILED_BUILDS+=("$dev [manifest clone failed]")
    fi
}

# Build all devices sequentially
build_device "RMX2170" "$RMX2170_MANIFEST_URL" "$RMX2170_MANIFEST_BRANCH"
build_device "RMX2061" "$RMX2061_MANIFEST_URL" "$RMX2061_MANIFEST_BRANCH"
build_device "RMX3081" "$RMX3081_MANIFEST_URL" "$RMX3081_MANIFEST_BRANCH"

# Final Summary Report
echo ""
echo "============================================================"
echo "                   BUILD SUMMARY REPORT                     "
echo "============================================================"
[ ${#SUCCESS_BUILDS[@]} -gt 0 ] && echo " Successful Builds: ${SUCCESS_BUILDS[*]}"
[ ${#FAILED_BUILDS[@]} -gt 0 ] && echo " Failed Builds:     ${FAILED_BUILDS[*]}"
echo "============================================================"

if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
    exit 1
fi
exit 0
