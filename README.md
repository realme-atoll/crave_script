# Crave Build Scripts for Realme Atoll (SM7125)

Automated build scripts and patch pipelines for compiling custom ROMs and recoveries on [Crave.io](https://crave.io).

## Available Build Scripts

### 1. Realme 6 Pro (`RMX2061`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2061.sh | bash"
```

### 2. Realme 7 Pro (`RMX2170`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2170.sh | bash"
```

### 3. Realme 8 Pro (`RMX3081`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx3081.sh | bash"
```

### 4. OrangeFox Recovery R12.0 (Unified `sm7125`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/ofrp_sm7125.sh | bash"
```

---

## Build Pipeline Helpers

- **`clean.py`**: Executes prior to `resync` to cleanly reset only the specific repositories and build artifacts modified by `patch.py`, preventing sync conflicts without disturbing unrelated repositories or toolchain binaries.
- **`patch.py`**: Executes after `resync` and prior to `lunch` to apply upstream compatibility fixes.

