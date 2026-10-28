#!/bin/bash
# =============================================================================
# Multi-Recovery Batch Build - Realme Atoll (sm7125)
# Recoveries: OrangeFox Recovery Project & TeamWin Recovery Project (TWRP)
#
# Examples:
#   crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/recovery_all.sh | bash"
#   crave run --no-patch -- "SF_KEY='<b64_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/recovery_all.sh | bash"
# =============================================================================

# Enable pipefail so pipeline failure (m ... | tee) is accurately detected
# Note: set -e is deliberately omitted so a failure on one recovery does not abort remaining builds
set -o pipefail

# =============================================================================
# CONFIGURATION - MODIFY ONLY THIS SECTION
# =============================================================================

# Target Device & Shared Recovery Manifest
DEVICE="sm7125"
RECOVERY_MANIFEST_URL="https://github.com/realme-atoll/recovery-manifest"

# OrangeFox Configuration
OFRP_MANIFEST_URL="https://gitlab.com/orangefox/manifest.git"
OFRP_MANIFEST_BRANCH="fox_12.1"
OFRP_DEVICE_BRANCH="ofrp"
OFRP_LUNCH_TARGET="tw_${DEVICE}-eng"

# TWRP Configuration
TWRP_MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"
TWRP_MANIFEST_BRANCH="twrp-14.1"
TWRP_DEVICE_BRANCH="twrp"
TWRP_LUNCH_TARGET="twrp_${DEVICE}-trunk_staging-eng"

# Workspace & Cloud Upload (Uses Crave's stock cached directory)
WORK_DIR="/tmp/src/android"
UPLOAD_SUBDIR_BASE="Recovery/${DEVICE}"

# Helper Scripts URLs
SCRIPT_BRANCH="${SCRIPT_BRANCH:-aosp-16}"
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
echo " Starting Multi-Recovery Batch Build for Realme Atoll ($DEVICE)"
echo " Workspace: $WORK_DIR"
echo "============================================================"

# Helper: Build single recovery
build_recovery() {
    local name="$1"                     # "OrangeFox" or "TWRP"
    local manifest_url="$2"
    local manifest_branch="$3"
    local device_manifest_url="$4"
    local device_manifest_branch="$5"
    local lunch_target="$6"

    echo ""
    echo "============================================================"
    echo ">>> Starting Build for $name Recovery ($DEVICE)..."
    echo "============================================================"

    cd "$WORK_DIR"
    
    # 1. Initialize repo
    echo ""
    echo "=============================="
    echo " [$name] Initializing repo ($manifest_branch)..."
    echo "=============================="
    repo init -u "$manifest_url" -b "$manifest_branch" --depth=1 || true

    # 2. Setup device manifest
    echo ""
    echo "=============================="
    echo " [$name] Setting up device manifest..."
    echo "=============================="
    rm -rf .repo/local_manifests
    if git clone -b "$device_manifest_branch" "$device_manifest_url" .repo/local_manifests; then
        
        # 3. Sync source via Crave resync
        echo ""
        echo "=============================="
        echo " [$name] Syncing source via crave resync..."
        echo "=============================="
        /opt/crave/resync.sh || true

        # 4. Setup build environment and lunch
        echo ""
        echo "=============================="
        echo " [$name] Setting up environment & lunching $lunch_target..."
        echo "=============================="
        export ALLOW_MISSING_DEPENDENCIES=true
        export LC_ALL="C.UTF-8"
        if [ "$name" = "OrangeFox" ]; then
            export FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1
        else
            export TW_DEVICE_VERSION="12.1"
        fi

        source build/envsetup.sh
        [ -f "device/realme/${DEVICE}/vendorsetup.sh" ] && source "device/realme/${DEVICE}/vendorsetup.sh" "${DEVICE}"

        if lunch "$lunch_target"; then
            
            # 5. Compile recovery
            echo ""
            echo "=============================="
            echo " [$name] Compiling recovery ($lunch_target)..."
            echo "=============================="
            if m recoveryimage 2>&1 | tee "/tmp/build_${name}.log"; then
                echo ">>> [SUCCESS] $name Recovery build succeeded!"
                SUCCESS_BUILDS+=("$name")

                # 6. Prepare branded image and upload
                echo ""
                echo "=============================="
                echo " [$name] Uploading recovery artifacts..."
                echo "=============================="
                local out_dir="${WORK_DIR}/out/target/product/${DEVICE}"
                [ -f "$out_dir/recovery.img" ] && cp -v "$out_dir/recovery.img" "$out_dir/${name}-realme-${DEVICE}.img"
                local cooked_files=($(ls -t "$out_dir"/${name}*.img "$out_dir"/${name}*.zip "$out_dir"/${name,,}*.zip 2>/dev/null | head -n 2))
                curl -sLf "$UPLOAD_SCRIPT_URL" | python3 - "${UPLOAD_SUBDIR_BASE}/${name}" "${cooked_files[@]}" || true
            else
                echo ">>> [FAILED] $name Recovery compilation failed!"
                FAILED_BUILDS+=("$name")
            fi
        else
            echo ">>> [FAILED] $name lunch failed!"
            FAILED_BUILDS+=("$name [lunch failed]")
        fi
    else
        echo ">>> [FAILED] $name local manifest clone failed!"
        FAILED_BUILDS+=("$name [manifest clone failed]")
    fi
}

# Build both recoveries sequentially
build_recovery "OrangeFox" "$OFRP_MANIFEST_URL" "$OFRP_MANIFEST_BRANCH" "$RECOVERY_MANIFEST_URL" "$OFRP_DEVICE_BRANCH" "$OFRP_LUNCH_TARGET"
build_recovery "TWRP" "$TWRP_MANIFEST_URL" "$TWRP_MANIFEST_BRANCH" "$RECOVERY_MANIFEST_URL" "$TWRP_DEVICE_BRANCH" "$TWRP_LUNCH_TARGET"

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
