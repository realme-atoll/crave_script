#!/bin/bash
# =============================================================================
# Multi-Recovery Batch Build - Realme Atoll (sm7125)
# Recoveries: OrangeFox Recovery Project & TeamWin Recovery Project (TWRP)
#
# Examples:
#   crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/recovery_all.sh | bash"
#   crave run --no-patch -- "SF_KEY='<b64_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/recovery_all.sh | bash"
# =============================================================================

# Note: set -e is deliberately omitted so a failure on one recovery does not abort the other

# =============================================================================
# CONFIGURATION
# =============================================================================

DEVICE="sm7125"
LUNCH_TARGET="twrp_${DEVICE}-eng"

# Base Minimal TWRP Manifest for Android 12.1 (shared base for TWRP 12.1 & OrangeFox 12.1)
BASE_MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"
BASE_MANIFEST_BRANCH="twrp-12.1"

# Shared Recovery Manifest (local_manifests containing device trees)
RECOVERY_MANIFEST_URL="https://github.com/realme-atoll/recovery-manifest"
OFRP_DEVICE_BRANCH="ofrp"
TWRP_DEVICE_BRANCH="twrp"

# Workspace & Cloud Upload
WORK_DIR="/tmp/src/android"
UPLOAD_SUBDIR_BASE="Recovery/${DEVICE}"

# Helper Scripts URLs
SCRIPT_BRANCH="${SCRIPT_BRANCH:-aosp-16}"
UPLOAD_SCRIPT_URL="https://raw.githubusercontent.com/realme-atoll/crave_script/${SCRIPT_BRANCH}/upload.py"

# =============================================================================
# SCRIPT LOGIC
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
echo " Starting Multi-Recovery Batch Build for Realme Atoll ($DEVICE)"
echo " Workspace: $WORK_DIR"
echo "============================================================"

# Helper: Ensure Qualcomm recovery dependencies are present
ensure_qcom_dependencies() {
    echo ">> Checking Qualcomm common recovery dependencies..."
    if [ ! -d "device/qcom/common" ]; then
        echo ">> Cloning device/qcom/common (android-12.1)..."
        git clone --depth=1 https://github.com/TeamWin/android_device_qcom_common.git -b android-12.1 device/qcom/common
    fi
    if [ ! -d "device/qcom/twrp-common" ]; then
        echo ">> Cloning device/qcom/twrp-common (android-12.1)..."
        git clone --depth=1 https://github.com/TeamWin/android_device_qcom_twrp-common.git -b android-12.1 device/qcom/twrp-common
    fi
}

# -----------------------------------------------------------------------------
# 1. OrangeFox Recovery Build
# -----------------------------------------------------------------------------
build_orangefox() {
    echo ""
    echo "============================================================"
    echo ">>> Starting Build for OrangeFox Recovery ($DEVICE)..."
    echo "============================================================"
    cd "$WORK_DIR"

    # Clean intermediate files to conserve disk space
    rm -rf out/target/product/"${DEVICE}" out/soong
    rm -rf .repo/local_manifests device/realme/"${DEVICE}"

    # Initialize standard minimal manifest
    echo "=============================="
    echo " [OrangeFox] Initializing minimal manifest ($BASE_MANIFEST_BRANCH)..."
    echo "=============================="
    repo init -u "$BASE_MANIFEST_URL" -b "$BASE_MANIFEST_BRANCH"

    # Setup device manifest for OrangeFox
    echo "=============================="
    echo " [OrangeFox] Setting up device manifest (branch: $OFRP_DEVICE_BRANCH)..."
    echo "=============================="
    if ! git clone -b "$OFRP_DEVICE_BRANCH" "$RECOVERY_MANIFEST_URL" .repo/local_manifests; then
        echo ">>> [FAILED] OrangeFox local manifest clone failed!"
        FAILED_BUILDS+=("OrangeFox [manifest clone failed]")
        return 1
    fi

    # Sync source
    echo "=============================="
    echo " [OrangeFox] Syncing source via crave resync..."
    echo "=============================="
    /opt/crave/resync.sh

    # Official OrangeFox source setup (fox_12.1)
    echo "=============================="
    echo " [OrangeFox] Fetching OrangeFox Recovery GUI & Vendor trees..."
    echo "=============================="
    rm -rf bootable/recovery vendor/recovery
    git clone https://gitlab.com/OrangeFox/bootable/Recovery.git -b fox_12.1 bootable/recovery
    git clone https://gitlab.com/OrangeFox/vendor/recovery.git -b main vendor/recovery

    # Qualcomm dependencies
    ensure_qcom_dependencies

    # Setup environment & lunch
    echo "=============================="
    echo " [OrangeFox] Setting up environment & lunching $LUNCH_TARGET..."
    echo "=============================="
    export ALLOW_MISSING_DEPENDENCIES=true
    export FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1
    export LC_ALL="C.UTF-8"

    source build/envsetup.sh
    [ -f "device/realme/${DEVICE}/vendorsetup.sh" ] && source "device/realme/${DEVICE}/vendorsetup.sh" "${DEVICE}"

    if lunch "$LUNCH_TARGET"; then
        echo "=============================="
        echo " [OrangeFox] Compiling recovery image..."
        echo "=============================="
        if m recoveryimage; then
            echo ">>> [SUCCESS] OrangeFox Recovery build succeeded!"
            SUCCESS_BUILDS+=("OrangeFox")

            # Prepare branded artifacts and upload
            local out_dir="${WORK_DIR}/out/target/product/${DEVICE}"
            [ -f "$out_dir/recovery.img" ] && cp -v "$out_dir/recovery.img" "$out_dir/OrangeFox-R12.0-realme-${DEVICE}.img"
            local UPLOAD_SUBDIR="${UPLOAD_SUBDIR_BASE}/OrangeFox"
            curl -sLf "$UPLOAD_SCRIPT_URL" | python3 - "${UPLOAD_SUBDIR}" "${DEVICE}" "recovery"
        else
            echo ">>> [FAILED] OrangeFox Recovery compilation failed!"
            FAILED_BUILDS+=("OrangeFox [compilation failed]")
        fi
    else
        echo ">>> [FAILED] OrangeFox lunch failed!"
        FAILED_BUILDS+=("OrangeFox [lunch failed]")
    fi
}

# -----------------------------------------------------------------------------
# 2. TWRP Recovery Build
# -----------------------------------------------------------------------------
build_twrp() {
    echo ""
    echo "============================================================"
    echo ">>> Starting Build for TWRP Recovery ($DEVICE)..."
    echo "============================================================"
    cd "$WORK_DIR"

    # Clean intermediate files to conserve disk space
    rm -rf out/target/product/"${DEVICE}" out/soong
    rm -rf .repo/local_manifests device/realme/"${DEVICE}"

    # Initialize standard TWRP minimal manifest
    echo "=============================="
    echo " [TWRP] Initializing minimal manifest ($BASE_MANIFEST_BRANCH)..."
    echo "=============================="
    repo init -u "$BASE_MANIFEST_URL" -b "$BASE_MANIFEST_BRANCH"

    # Setup device manifest for TWRP
    echo "=============================="
    echo " [TWRP] Setting up device manifest (branch: $TWRP_DEVICE_BRANCH)..."
    echo "=============================="
    if ! git clone -b "$TWRP_DEVICE_BRANCH" "$RECOVERY_MANIFEST_URL" .repo/local_manifests; then
        echo ">>> [FAILED] TWRP local manifest clone failed!"
        FAILED_BUILDS+=("TWRP [manifest clone failed]")
        return 1
    fi

    # Reset recovery sources to standard TWRP
    rm -rf bootable/recovery vendor/recovery

    # Sync source
    echo "=============================="
    echo " [TWRP] Syncing source via crave resync..."
    echo "=============================="
    /opt/crave/resync.sh

    # Qualcomm dependencies
    ensure_qcom_dependencies

    # Setup environment & lunch
    echo "=============================="
    echo " [TWRP] Setting up environment & lunching $LUNCH_TARGET..."
    echo "=============================="
    export ALLOW_MISSING_DEPENDENCIES=true
    export TW_DEVICE_VERSION="12.1"
    export LC_ALL="C.UTF-8"

    source build/envsetup.sh
    [ -f "device/realme/${DEVICE}/vendorsetup.sh" ] && source "device/realme/${DEVICE}/vendorsetup.sh" "${DEVICE}"

    if lunch "$LUNCH_TARGET"; then
        echo "=============================="
        echo " [TWRP] Compiling recovery image..."
        echo "=============================="
        if m recoveryimage; then
            echo ">>> [SUCCESS] TWRP Recovery build succeeded!"
            SUCCESS_BUILDS+=("TWRP")

            # Prepare branded artifacts and upload
            local out_dir="${WORK_DIR}/out/target/product/${DEVICE}"
            [ -f "$out_dir/recovery.img" ] && cp -v "$out_dir/recovery.img" "$out_dir/TWRP-realme-${DEVICE}.img"
            local UPLOAD_SUBDIR="${UPLOAD_SUBDIR_BASE}/TWRP"
            curl -sLf "$UPLOAD_SCRIPT_URL" | python3 - "${UPLOAD_SUBDIR}" "${DEVICE}" "recovery"
        else
            echo ">>> [FAILED] TWRP Recovery compilation failed!"
            FAILED_BUILDS+=("TWRP [compilation failed]")
        fi
    else
        echo ">>> [FAILED] TWRP lunch failed!"
        FAILED_BUILDS+=("TWRP [lunch failed]")
    fi
}

# Execute builds
build_orangefox
build_twrp

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
