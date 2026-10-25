# Crave Build Scripts for Realme Atoll (SM7125)

Automated build scripts for compiling custom ROMs and recoveries on [Crave.io](https://crave.io).

## Individual Build Scripts

### 1. Realme 7 Pro (`RMX2170`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2170.sh | bash"
```

### 2. Realme 6 Pro (`RMX2061`)
```bash
crave -n run --no-patch -- "curl -sLf https://raw.githubusercontent.com/realme-atoll/crave_script/aosp-16/evolution_rmx2061.sh | bash"
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

## Maintenance & Patch Helpers

- `clean.py`: Cleans dirty patches and resets modified repositories prior to source resync.
- `patch.py`: Applies upstream source or device tree patches after resync.
