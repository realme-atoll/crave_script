# Crave Build Script for Android 17 (aosp-17)

This branch contains automated Crave build scripts for **Android 17**.

## Supported ROM & Target
- **ROM**: Evolution X (Android 17, branch `cnb`)
- **Device**: Realme 7 Pro (`RMX2170`)

---

## Usage

### Standard Build
```bash
crave run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-17/evolution_rmx2170.sh | bash"
```

### With SourceForge Direct Upload
```bash
crave run --no-patch -- "SF_KEY='<base64_encoded_ssh_key>' curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-17/evolution_rmx2170.sh | bash"
```

### Custom Build Variant (e.g. user / eng)
```bash
crave run --no-patch -- "BUILD_VARIANT=user curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-17/evolution_rmx2170.sh | bash"
```

---

## ⚡ Features
- Automatically pulls `clean.py`, `patch.py`, and `upload.py` from the `aosp-17` branch.
- Instant direct temporary link on `https://temp.sh/`.
- Uploads to SourceForge path: `RMX2170/EvolutionX/17`.
