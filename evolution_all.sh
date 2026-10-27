#!/bin/bash

# ============================================================
# Crave Multi-Device Automated Build Script - Realme SM7125
# Builds: Realme 7 Pro (RMX2170), Realme 6 Pro (RMX2061),
#         Realme 8 Pro (RMX3081)
# ============================================================
#
# Build Order:
#   1. Realme 7 Pro (RMX2170)
#   2. Realme 6 Pro (RMX2061)
#   3. Realme 8 Pro (RMX3081)
#
# Note:
#   If any build fails, the script continues to build the
#   remaining devices and displays a full summary report at the end.
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

# Track build results across devices
SUCCESS_BUILDS=()
FAILED_BUILDS=()

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
    --depth=1 || true

echo "Repo initialized."

# Helper function to clean, sync source and apply patches
sync_source() {
    echo "=============================="
    echo " Cleaning and syncing source..."
    echo "=============================="
    curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/clean.py | python3 || true
    if [ -f "/opt/crave/resync.sh" ]; then
        /opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags || true
    else
        repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags || true
    fi
    curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/patch.py | python3 || true
    echo "Source sync and patches complete."
}

# ============================================================
# 1. REALME 7 PRO (RMX2170)
# ============================================================

echo ""
echo "============================================================"
echo " [1/3] Building $ROM_NAME - Realme 7 Pro (RMX2170)"
echo "============================================================"

cd "$ROM_WORK_DIR"
rm -rf .repo/local_manifests
if git clone -b evox-bka https://github.com/realme-atoll/RMX2170-manifest .repo/local_manifests; then
    sync_source
    source build/envsetup.sh
    if lunch "lineage_RMX2170-${BUILD_VARIANT}"; then
        echo "Starting build: m $BUILD_TARGET for RMX2170..."
        if m "$BUILD_TARGET"; then
            echo ">>> [SUCCESS] Realme 7 Pro (RMX2170) build succeeded!"
            SUCCESS_BUILDS+=("Realme 7 Pro (RMX2170)")
        else
            echo ">>> [ERROR] Realme 7 Pro (RMX2170) build compilation failed!"
            FAILED_BUILDS+=("Realme 7 Pro (RMX2170)")
        fi
    else
        echo ">>> [ERROR] lunch failed for Realme 7 Pro (RMX2170)!"
        FAILED_BUILDS+=("Realme 7 Pro (RMX2170) [lunch failed]")
    fi
else
    echo ">>> [ERROR] Failed to clone local manifest for Realme 7 Pro (RMX2170)!"
    FAILED_BUILDS+=("Realme 7 Pro (RMX2170) [manifest clone failed]")
fi

# ============================================================
# 2. REALME 6 PRO (RMX2061)
# ============================================================

echo ""
echo "============================================================"
echo " [2/3] Building $ROM_NAME - Realme 6 Pro (RMX2061)"
echo "============================================================"

cd "$ROM_WORK_DIR"
rm -rf .repo/local_manifests
if git clone -b evox-bka https://github.com/realme-atoll/RMX2061-manifest .repo/local_manifests; then
    sync_source
    source build/envsetup.sh
    if lunch "lineage_RMX2061-${BUILD_VARIANT}"; then
        echo "Starting build: m $BUILD_TARGET for RMX2061..."
        if m "$BUILD_TARGET"; then
            echo ">>> [SUCCESS] Realme 6 Pro (RMX2061) build succeeded!"
            SUCCESS_BUILDS+=("Realme 6 Pro (RMX2061)")
        else
            echo ">>> [ERROR] Realme 6 Pro (RMX2061) build compilation failed!"
            FAILED_BUILDS+=("Realme 6 Pro (RMX2061)")
        fi
    else
        echo ">>> [ERROR] lunch failed for Realme 6 Pro (RMX2061)!"
        FAILED_BUILDS+=("Realme 6 Pro (RMX2061) [lunch failed]")
    fi
else
    echo ">>> [ERROR] Failed to clone local manifest for Realme 6 Pro (RMX2061)!"
    FAILED_BUILDS+=("Realme 6 Pro (RMX2061) [manifest clone failed]")
fi

# ============================================================
# 3. REALME 8 PRO (RMX3081)
# ============================================================

echo ""
echo "============================================================"
echo " [3/3] Building $ROM_NAME - Realme 8 Pro (RMX3081)"
echo "============================================================"

cd "$ROM_WORK_DIR"
rm -rf .repo/local_manifests
if git clone -b evox-bka https://github.com/realme-atoll/RMX3081-manifest .repo/local_manifests; then
    sync_source
    source build/envsetup.sh
    if lunch "lineage_RMX3081-${BUILD_VARIANT}"; then
        echo "Starting build: m $BUILD_TARGET for RMX3081..."
        if m "$BUILD_TARGET"; then
            echo ">>> [SUCCESS] Realme 8 Pro (RMX3081) build succeeded!"
            SUCCESS_BUILDS+=("Realme 8 Pro (RMX3081)")
        else
            echo ">>> [ERROR] Realme 8 Pro (RMX3081) build compilation failed!"
            FAILED_BUILDS+=("Realme 8 Pro (RMX3081)")
        fi
    else
        echo ">>> [ERROR] lunch failed for Realme 8 Pro (RMX3081)!"
        FAILED_BUILDS+=("Realme 8 Pro (RMX3081) [lunch failed]")
    fi
else
    echo ">>> [ERROR] Failed to clone local manifest for Realme 8 Pro (RMX3081)!"
    FAILED_BUILDS+=("Realme 8 Pro (RMX3081) [manifest clone failed]")
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
    echo " All builds completed successfully!"
    echo "============================================================"
    exit 0
fi
