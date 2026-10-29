#!/usr/bin/env python3
"""
Crave Artifact Uploader (upload.py)
Uploads cooked ROM/recovery builds and companions (.md5sum, .sha256sum, .json, .txt)
to SourceForge and temp.sh (direct links).

Usage:
  upload.py <remote_subdir> <device_or_path> [build_type] [extra_files...]
"""

import os
import sys
import re
import base64
import subprocess
from pathlib import Path

# SourceForge configuration
SF_PROJECT = "realme-atoll"
SF_USER = "nikhilpal2705"
SF_HOST = "frs.sourceforge.net"


def get_sf_key() -> Path | None:
    """Resolve SourceForge SSH private key from ~/.ssh/, /tmp/, or SF_KEY env variable."""
    sf_upload_env = os.environ.get("SF_UPLOAD", "").strip().lower()
    sf_key_b64 = os.environ.get("SF_KEY", "").strip()

    # Skip SourceForge if SF_UPLOAD is explicitly disabled (0) or if neither SF_UPLOAD=1 nor SF_KEY is set
    if sf_upload_env in ("0", "false", "no", "disable", "disabled") or (sf_upload_env != "1" and not sf_key_b64):
        print(">>> [INFO] SourceForge upload disabled (SF_UPLOAD not enabled). Skipping SourceForge.")
        return None

    sf_mode = os.environ.get("SF_MODE", "").strip().lower()

    ssh_dir = Path.home() / ".ssh"
    ssh_dir.mkdir(mode=0o700, exist_ok=True)

    # If legacy mode explicitly requested, prefer SF_KEY
    if sf_mode == "legacy":
        sf_key_b64 = os.environ.get("SF_KEY", "").strip()
        if sf_key_b64:
            key_file = ssh_dir / "sf_key"
            try:
                key_file.write_bytes(base64.b64decode(sf_key_b64))
                key_file.chmod(0o600)
                print(">>> [SF KEY] Using SF_KEY from environment (Legacy CLI)")
                return key_file
            except Exception as e:
                print(f">>> [WARN] Failed to decode SF_KEY: {e}")

    # 1. Devspace local SSH key candidates (Safe & Private: no key exposed on CLI or logs)
    candidates = [
        ssh_dir / "crave_sf",
        Path("/tmp/crave_sf"),
        Path("/tmp/.ssh/crave_sf"),
        Path("/tmp/src/android/.ssh/crave_sf"),
        ssh_dir / "id_ed25519",
        ssh_dir / "id_rsa",
    ]

    for cand in candidates:
        if cand.is_file() and cand.stat().st_size > 0:
            dest_key = ssh_dir / "crave_sf"
            if cand.resolve() != dest_key.resolve():
                try:
                    import shutil
                    shutil.copy2(cand, dest_key)
                except Exception as e:
                    print(f">>> [WARN] Could not copy {cand} to ~/.ssh: {e}")
                    dest_key = cand
            try:
                dest_key.chmod(0o600)
            except Exception:
                pass
            print(f">>> [SF KEY] Using local SSH key in devspace: {dest_key}")
            return dest_key

    # 2. Base64 encoded key passed via Crave run (Fallback)
    sf_key_b64 = os.environ.get("SF_KEY", "").strip()
    if sf_key_b64:
        key_file = ssh_dir / "sf_key"
        try:
            key_file.write_bytes(base64.b64decode(sf_key_b64))
            key_file.chmod(0o600)
            print(">>> [SF KEY] Using SF_KEY from environment (Fallback)")
            return key_file
        except Exception as e:
            print(f">>> [WARN] Failed to decode SF_KEY: {e}")

    return None


def get_build_sort_key(file_path: Path) -> tuple:
    """
    Sort key to identify the latest build:
    1. 8-digit date in filename YYYYMMDD (e.g. 20261028 > 20261025 > 20261020)
    2. File modification time (st_mtime) for builds with same date
    """
    date_match = re.search(r'(20\d{6})', file_path.name)
    date_str = date_match.group(1) if date_match else "00000000"
    return (date_str, file_path.stat().st_mtime)


def find_companions(artifact: Path) -> list[Path]:
    """Finds companion files (.md5, .sha256, .json, .txt) using switch-case pattern matching."""
    companions: list[Path] = []
    parent, stem = artifact.parent, artifact.stem

    for cand in sorted(parent.iterdir()):
        if not cand.is_file() or cand.stat().st_size == 0 or cand == artifact:
            continue
        if not (cand.name.startswith(stem) or "changelog" in cand.name.lower()):
            continue

        match cand.suffix.lower():
            case ".sha256sum" | ".sha256":
                if cand not in companions:
                    companions.append(cand)
            case ".md5sum" | ".md5":
                if cand not in companions:
                    companions.append(cand)
            case ".json":
                if cand not in companions:
                    companions.append(cand)
            case ".txt" if "changelog" in cand.name.lower() or cand.stem == stem:
                if cand not in companions:
                    companions.append(cand)
            case _:
                pass

    return companions


def resolve_target_path(item: str) -> Path:
    """Resolves an input item to a Path, checking direct path, device codename, or out/target/product."""
    p = Path(item)
    if p.exists():
        return p

    # Check if item is a device codename under out/target/product/
    base = Path("out/target/product")
    for cand in [base / item, base / item.lower(), base / item.upper()]:
        if cand.is_dir():
            return cand

    return p


def discover_candidates(search_dir: Path, build_type: str) -> list[Path]:
    """Discovers target artifacts in product directory based on build type using pattern matching."""
    candidates: list[Path] = []

    match build_type.lower():
        case "recovery":
            # 1. Recovery installer ZIPs if present (OrangeFox, TWRP, recovery)
            zips = [
                z for z in search_dir.glob("*.zip")
                if any(k in z.name.lower() for k in ["orangefox", "twrp", "recovery"])
                and not any(ign in z.name.lower() for ign in ["target_files", "symbols", "ota_update"])
            ]
            if zips:
                zips.sort(key=get_build_sort_key, reverse=True)
                candidates.append(zips[0])

            # 2. Recovery images (prefer branded OrangeFox/TWRP, fallback to recovery.img)
            imgs = [
                i for i in search_dir.glob("*.img")
                if any(k in i.name.lower() for k in ["orangefox", "twrp", "recovery"])
            ]
            if imgs:
                branded = [i for i in imgs if any(k in i.name.lower() for k in ["orangefox", "twrp"])]
                chosen_imgs = branded if branded else imgs
                chosen_imgs.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                candidates.append(chosen_imgs[0])

        case "rom" | _:
            # Latest cooked ROM ZIP (exclude standalone recovery zips)
            zips = [
                z for z in search_dir.glob("*.zip")
                if not any(ign in z.name.lower() for ign in ["target_files", "symbols", "ota_update", "orangefox", "twrp"])
            ]
            if zips:
                zips.sort(key=get_build_sort_key, reverse=True)
                candidates.append(zips[0])

    return candidates


def resolve_artifacts(raw_inputs: list[str], build_type: str = "rom") -> list[Path]:
    """Resolves cooked artifacts and companions from device names, directories, or direct file paths."""
    targets: list[Path] = []

    for item in raw_inputs:
        if not item:
            continue

        p = resolve_target_path(item)

        # If a directory (or resolved device dir), discover cooked artifacts
        if p.is_dir():
            for cand in discover_candidates(p, build_type):
                if cand not in targets:
                    targets.append(cand)
                    for comp in find_companions(cand):
                        if comp not in targets:
                            targets.append(comp)
            continue

        if not p.is_file() or p.stat().st_size == 0 or p in targets:
            continue

        targets.append(p)
        for comp in find_companions(p):
            if comp not in targets:
                targets.append(comp)

    return targets


def upload_sf(files: list[Path], remote_subdir: str, key_file: Path | None):
    """Uploads artifacts to SourceForge via rsync over SSH."""
    if not key_file:
        print(">>> [INFO] SourceForge SSH key not found (~/.ssh/crave_sf, /tmp/crave_sf, or SF_KEY). Skipping SourceForge upload.")
        return

    dest = f"/home/frs/project/{SF_PROJECT}/{remote_subdir.strip('/')}/"
    print(f">>> [SF UPLOAD] Uploading to {dest}...")

    # Ensure remote directory exists on SourceForge via SFTP
    dirs = remote_subdir.strip("/").split("/")
    curr = f"/home/frs/project/{SF_PROJECT}"
    sftp_cmds = "\n".join([f"mkdir {curr}/{'/'.join(dirs[:i+1])}" for i in range(len(dirs))]) + "\n"
    subprocess.run(
        ["sftp", "-i", str(key_file), "-o", "StrictHostKeyChecking=no", f"{SF_USER}@{SF_HOST}"],
        input=sftp_cmds,
        text=True,
        capture_output=True,
        timeout=30,
    )

    # Cache host key
    subprocess.run(["ssh-keyscan", "-H", SF_HOST], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)

    # Rsync transfer
    cmd = [
        "rsync", "-avP",
        "-e", f"ssh -i {key_file} -o StrictHostKeyChecking=no",
        *[str(f) for f in files],
        f"{SF_USER}@{SF_HOST}:{dest}",
    ]
    subprocess.run(cmd)


def upload_temp(files: list[Path]):
    """Uploads artifacts to temp.sh for instant direct download link."""
    print("\nGenerating direct download links (temp.sh)...")
    for f in files:
        try:
            res = subprocess.run(
                ["curl", "-s", "-F", f"file=@{f}", "https://temp.sh/upload"],
                capture_output=True,
                text=True,
                timeout=180,
            )
            print(f"Direct link ({f.name}): {res.stdout.strip()}")
        except Exception as e:
            print(f">>> [WARN] temp.sh upload failed for {f.name}: {e}")


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <remote_subdir> <device_or_path> [build_type] [extra_files...]")
        sys.exit(1)

    remote_subdir = sys.argv[1].strip("/")
    target_arg = sys.argv[2]

    # Optional explicit build_type ('rom' or 'recovery')
    explicit_type = ""
    extra_start = 3
    if len(sys.argv) > 3 and sys.argv[3].lower() in ["rom", "recovery"]:
        explicit_type = sys.argv[3].lower()
        extra_start = 4

    build_type = explicit_type or ("recovery" if any(k in remote_subdir.lower() for k in ["recovery", "twrp", "orangefox", "ofrp"]) else "rom")
    raw_inputs = [target_arg] + sys.argv[extra_start:]

    files = resolve_artifacts(raw_inputs, build_type=build_type)
    if not files:
        print(f">>> [ERROR] No valid build artifacts found for target '{target_arg}' (build_type: {build_type}).")
        sys.exit(1)

    print(f"\nArtifacts to upload ({len(files)}):")
    for f in files:
        print(f" - {f.name} ({f.stat().st_size / (1024 * 1024):.2f} MB)")

    key_file = get_sf_key()
    upload_sf(files, remote_subdir, key_file)
    upload_temp(files)
    print("\nUpload complete.")


if __name__ == "__main__":
    main()
