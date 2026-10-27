#!/bin/bash

# ============================================================
# Crave Automated Build Script - All Recoveries (Realme SM7125)
# Builds:
#   1. OrangeFox Recovery Project - OFRP (sm7125)
#   2. TeamWin Recovery Project - TWRP (sm7125)
# ============================================================
#
# Note:
#   If any build fails, the script continues to build the
#   remaining recovery and displays a full summary report at the end.
#
# Usage:
#   crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/recovery_all.sh | bash"
#
# ============================================================

SUCCESS_BUILDS=()
FAILED_BUILDS=()

BASE_DIR="/tmp/src"
if [ ! -d "$BASE_DIR" ]; then
    BASE_DIR="$(pwd)"
fi

# ============================================================
# 1. ORANGEFOX RECOVERY PROJECT (sm7125)
# ============================================================

echo ""
echo "============================================================"
echo " [1/2] Building OrangeFox Recovery Project (sm7125)"
echo "============================================================"

OFRP_DIR="${BASE_DIR}/ofrp"
mkdir -p "$OFRP_DIR"
cd "$OFRP_DIR"

echo "Initializing OrangeFox repo..."
repo init \
    -u "https://gitlab.com/OrangeFox/Manifest.git" \
    -b "fox_16.0" \
    --depth=1 || true

rm -rf .repo/local_manifests
if git clone -b ofrp https://github.com/realme-atoll/recovery-manifest .repo/local_manifests; then
    echo "Syncing source..."
    if [ -f "/opt/crave/resync.sh" ]; then
        /opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags || true
    else
        repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags || true
    fi
    cd "$OFRP_DIR"

    export ALLOW_MISSING_DEPENDENCIES=true
    export FOX_BUILD_DEVICE="sm7125"
    export LC_ALL="C.UTF-8"

    source build/envsetup.sh
    if [ -f "device/realme/sm7125/vendorsetup.sh" ]; then
        source "device/realme/sm7125/vendorsetup.sh" "sm7125"
    fi

    if lunch twrp_sm7125-trunk_staging-eng; then
        echo "Starting build: m recoveryimage for OrangeFox sm7125..."
        if m recoveryimage; then
            echo ">>> [SUCCESS] OrangeFox Recovery (sm7125) build succeeded!"
            SUCCESS_BUILDS+=("OrangeFox Recovery (sm7125)")
        else
            echo ">>> [ERROR] OrangeFox Recovery (sm7125) build compilation failed!"
            FAILED_BUILDS+=("OrangeFox Recovery (sm7125)")
        fi
    else
        echo ">>> [ERROR] lunch failed for OrangeFox Recovery (sm7125)!"
        FAILED_BUILDS+=("OrangeFox Recovery (sm7125) [lunch failed]")
    fi
else
    echo ">>> [ERROR] Failed to clone local manifest for OrangeFox Recovery!"
    FAILED_BUILDS+=("OrangeFox Recovery (sm7125) [manifest clone failed]")
fi

# ============================================================
# 2. TEAMWIN RECOVERY PROJECT - TWRP (sm7125)
# ============================================================

echo ""
echo "============================================================"
echo " [2/2] Building TeamWin Recovery Project - TWRP (sm7125)"
echo "============================================================"

TWRP_DIR="${BASE_DIR}/twrp"
mkdir -p "$TWRP_DIR"
cd "$TWRP_DIR"

echo "Initializing TWRP repo..."
repo init \
    -u "https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git" \
    -b "twrp-14.1" \
    --depth=1 || true

rm -rf .repo/local_manifests
if git clone -b twrp https://github.com/realme-atoll/recovery-manifest .repo/local_manifests; then
    echo "Syncing source..."
    if [ -f "/opt/crave/resync.sh" ]; then
        /opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags || true
    else
        repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags || true
    fi
    cd "$TWRP_DIR"

    export ALLOW_MISSING_DEPENDENCIES=true
    export TW_DEVICE_VERSION="12.1"
    export LC_ALL="C.UTF-8"

    source build/envsetup.sh
    if [ -f "device/realme/sm7125/vendorsetup.sh" ]; then
        source "device/realme/sm7125/vendorsetup.sh" "sm7125"
    fi

    if lunch twrp_sm7125-trunk_staging-eng; then
        echo "Starting build: m recoveryimage for TWRP sm7125..."
        if m recoveryimage; then
            echo ">>> [SUCCESS] TWRP (sm7125) build succeeded!"
            SUCCESS_BUILDS+=("TWRP Recovery (sm7125)")
        else
            echo ">>> [ERROR] TWRP (sm7125) build compilation failed!"
            FAILED_BUILDS+=("TWRP Recovery (sm7125)")
        fi
    else
        echo ">>> [ERROR] lunch failed for TWRP (sm7125)!"
        FAILED_BUILDS+=("TWRP Recovery (sm7125) [lunch failed]")
    fi
else
    echo ">>> [ERROR] Failed to clone local manifest for TWRP Recovery!"
    FAILED_BUILDS+=("TWRP Recovery (sm7125) [manifest clone failed]")
fi

# ============================================================
# FINAL SUMMARY REPORT
# ============================================================

echo ""
echo "============================================================"
echo "                   BUILD SUMMARY REPORT                     "
echo "============================================================"

if [ ${#SUCCESS_BUILDS[@]} -gt 0 ]; then
    echo " Successful Builds (${#SUCCESS_BUILDS[@]}):"
    for item in "${SUCCESS_BUILDS[@]}"; do
        echo "   [✓] $item"
    done
fi

if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
    echo ""
    echo " Failed Builds (${#FAILED_BUILDS[@]}):"
    for item in "${FAILED_BUILDS[@]}"; do
        echo "   [✗] $item"
    done
    echo "============================================================"
    echo " Some builds encountered errors. Check the logs above."
    echo "============================================================"
    exit 1
else
    echo ""
    echo " All recovery builds completed successfully!"
    echo "============================================================"
    exit 0
fi
