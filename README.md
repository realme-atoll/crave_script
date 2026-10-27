# Crave Build Scripts for Realme Atoll (SM7125)

Automated build scripts for compiling custom ROMs and recoveries on [Crave.io](https://crave.io).

---

## 1. Multi-Target Batch Scripts

### Build All ROMs (`evolution_all.sh`)
Sequentially builds Evolution X for all three devices (Realme 7 Pro, 6 Pro, and 8 Pro) in a single Crave run, continuing even if one build encounters an error:
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_all.sh | bash"
```

### Build All Recoveries (`recovery_all.sh`)
Sequentially builds both OrangeFox and TWRP recoveries for unified `sm7125` in a single Crave run:
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/recovery_all.sh | bash"
```

---

## 2. Standalone ROM Scripts

### Realme 7 Pro (`RMX2170`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2170.sh | bash"
```

### Realme 6 Pro (`RMX2061`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2061.sh | bash"
```

### Realme 8 Pro (`RMX3081`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx3081.sh | bash"
```

---

## 3. Standalone Recovery Scripts

### OrangeFox Recovery R12.0 (Unified `sm7125`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/ofrp_sm7125.sh | bash"
```

### TeamWin Recovery Project - TWRP (Unified `sm7125`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/twrp_sm7125.sh | bash"
```

---

## 4. Maintenance & Patch Helpers

- `clean.py`: Cleans dirty patches and resets modified repositories prior to source resync.
- `patch.py`: Applies upstream source or device tree patches after resync.
