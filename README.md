# Crave Build Scripts for Realme Atoll (SM7125)

Collection of automated Crave.io build scripts for compiling custom ROMs and recoveries for Realme Atoll devices (Realme 6 Pro, 7 Pro, and 8 Pro).

Every script includes built-in post-build automation:
- **Instant Direct Download Link**: Automatically uploads output artifacts to `https://temp.sh/` and prints a direct HTTPS download link (valid for 3 days) in the build console.
- **SourceForge Direct Upload (Optional)**: Automatically uploads build artifacts directly to SourceForge via `rsync` over SSH if `SF_KEY` is provided.
- **Stock Workspace Integration**: All scripts run within Crave's stock cached workspace (`/tmp/src/android`), fully utilizing Crave's fast resync and prebuilt dependencies without redundant downloads.
- **Centralized Configuration**: Every script has a dedicated top-level `CONFIGURATION` block for URLs, branches, lunch targets, and upload paths. The script body is 100% parameter-driven.

---

## 🔑 SourceForge Direct Upload Setup (Optional)

If you wish to upload compiled builds directly to SourceForge upon completion:

1. **Add your SSH Public Key to SourceForge**:
   - Go to [SourceForge SSH Settings](https://sourceforge.net/account/user-permissions).
   - Paste your SSH public key (`~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`) on a new line and click **Save**.

2. **Encode your SSH Private Key to Base64**:
   - **Linux**:
     ```bash
     SF_KEY=$(base64 -w0 ~/.ssh/id_ed25519)
     ```
   - **macOS**:
     ```bash
     SF_KEY=$(base64 -i ~/.ssh/id_ed25519 | tr -d '\n')
     ```

3. **Pass `SF_KEY` to Crave**:
   Prefix your build command with `SF_KEY="$SF_KEY"` (or inline `SF_KEY='...'`) as shown in the examples below.

> **Note:** If `SF_KEY` is omitted, the script automatically skips SourceForge upload and prints only the `temp.sh` direct download link.

---

## 1. Multi-Target Batch Scripts

### Build All ROMs (`evolution_all.sh`)
Sequentially builds Evolution X for Realme 7 Pro (`RMX2170`), Realme 6 Pro (`RMX2061`), and Realme 8 Pro (`RMX3081`) in a single Crave run. The script continues building subsequent devices even if one fails and provides a consolidated summary report at the end. Each device artifact is uploaded immediately upon completion:

```bash
# Standard Build:
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_all.sh | bash"

# With Automatic SourceForge Upload:
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_all.sh | bash"
```

### Build All Recoveries (`recovery_all.sh`)
Sequentially builds both OrangeFox and TWRP recoveries for unified `sm7125` directly in `/tmp/src/android` in a single Crave run with failure resilience and instant artifact upload:

```bash
# Standard Build:
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/recovery_all.sh | bash"

# With Automatic SourceForge Upload:
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/recovery_all.sh | bash"
```

---

## 2. Standalone ROM Scripts

### Realme 7 Pro (`RMX2170`)
```bash
# Standard Build:
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_rmx2170.sh | bash"

# With SourceForge Upload:
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_rmx2170.sh | bash"
```

### Realme 6 Pro (`RMX2061`)
```bash
# Standard Build:
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_rmx2061.sh | bash"

# With SourceForge Upload:
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_rmx2061.sh | bash"
```

### Realme 8 Pro (`RMX3081`)
```bash
# Standard Build:
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_rmx3081.sh | bash"

# With SourceForge Upload:
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_rmx3081.sh | bash"
```

#### Custom Build Variant (Optional):
To compile a variant other than the default `userdebug` (e.g. `user` or `eng`), pass `BUILD_VARIANT`:
```bash
crave run --no-patch -- "BUILD_VARIANT=user curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/evolution_rmx2170.sh | bash"
```

---

## 3. Standalone Recovery Scripts

### OrangeFox Recovery (Unified `sm7125`)
```bash
# Standard Build:
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/ofrp_sm7125.sh | bash"

# With SourceForge Upload:
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/ofrp_sm7125.sh | bash"
```

### TeamWin Recovery Project - TWRP (Unified `sm7125`)
```bash
# Standard Build:
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/twrp_sm7125.sh | bash"

# With SourceForge Upload:
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/<branch>/twrp_sm7125.sh | bash"
```

---

## 4. Maintenance & Modular Cloud Helpers

- `upload.py`: Modular Python artifact uploader supporting SourceForge direct upload and instant direct web links. Auto-detects and uploads artifacts (`.zip`, `.img`) and build-generated companion files (MD5 `.md5sum`/`.md5`, SHA256 `.sha256sum`/`.sha256`, `.json` OTA metadata, and changelog `.txt` files), skipping any that were not generated. To add or change cloud destinations in the future, only this script needs modification!
- `clean.py`: Resets modified repositories and removes dirty build patches before repo sync.
- `patch.py`: Applies upstream bugfixes and local manifest patches after repo sync.
