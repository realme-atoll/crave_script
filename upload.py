#!/usr/bin/env python3
"""
Crave Artifact Uploader (upload.py)
Uploads cooked ROM/recovery builds and companions (.md5sum, .sha256sum, .json, .txt)
to SourceForge and temp.sh (direct links).

Usage:
  upload.py <remote_subdir> <file_or_dir> [extra_files...]
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
    """Resolve SourceForge SSH private key from SF_KEY env variable or ~/.ssh/."""
    ssh_dir = Path.home() / ".ssh"
    ssh_dir.mkdir(mode=0o700, exist_ok=True)

    # Base64 encoded key passed via Crave run
    sf_key_b64 = os.environ.get("SF_KEY", "").strip()
    if sf_key_b64:
        key_file = ssh_dir / "sf_key"
        try:
            key_file.write_bytes(base64.b64decode(sf_key_b64))
            key_file.chmod(0o600)
            return key_file
        except Exception as e:
            print(f">>> [WARN] Failed to decode SF_KEY: {e}")

    # Local SSH key files
    for name in ["crave_sf", "id_ed25519", "id_rsa"]:
        cand = ssh_dir / name
        if cand.is_file():
            return cand
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


def resolve_artifacts(raw_inputs: list[str]) -> list[Path]:
    """
    Resolves cooked artifacts and finds companion files (.md5sum, .sha256sum, .json, .txt)
    by replacing or appending extensions. If a directory is passed, selects the latest
    cooked build by date and modification time.
    """
    targets: list[Path] = []

    for item in raw_inputs:
        if not item:
            continue
        p = Path(item)

        # Fallback if directory was passed instead of file: pick latest cooked build
        if p.is_dir():
            zips = [
                z for z in p.glob("*.zip")
                if not any(ign in z.name.lower() for ign in ["target_files", "symbols", "ota_update"])
            ]
            if zips:
                zips.sort(key=get_build_sort_key, reverse=True)
                p = zips[0]
            else:
                imgs = [i for i in p.glob("*.img") if "boot" not in i.name.lower()]
                if imgs:
                    imgs.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                    p = imgs[0]

        if not p.is_file() or p.stat().st_size == 0 or p in targets:
            continue

        targets.append(p)
        parent, stem = p.parent, p.stem

        # Check for MD5 checksum (.md5sum or .md5)
        for ext in [".md5sum", ".md5"]:
            for cand in [parent / f"{p.name}{ext}", parent / f"{stem}{ext}"]:
                if cand.is_file() and cand not in targets:
                    targets.append(cand)
                    break

        # Check for SHA256 checksum (.sha256sum or .sha256)
        for ext in [".sha256sum", ".sha256"]:
            for cand in [parent / f"{p.name}{ext}", parent / f"{stem}{ext}"]:
                if cand.is_file() and cand not in targets:
                    targets.append(cand)
                    break

        # Check for OTA updater metadata (.json)
        for cand in [parent / f"{stem}.json", *parent.glob(f"{stem}*.json")]:
            if cand.is_file() and cand not in targets:
                targets.append(cand)
                break

        # Check for Changelog (.txt)
        for cand in [parent / f"{stem}.txt", *parent.glob("*changelog*.txt"), *parent.glob("*Changelog*.txt")]:
            if cand.is_file() and cand not in targets:
                targets.append(cand)
                break

    return targets


def upload_sf(files: list[Path], remote_subdir: str, key_file: Path | None):
    """Uploads artifacts to SourceForge via rsync over SSH."""
    if not key_file:
        print(">>> [INFO] SF_KEY not provided. Skipping SourceForge upload.")
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
        print(f"Usage: {sys.argv[0]} <remote_subdir> <file_or_dir> [extra_files...]")
        sys.exit(1)

    remote_subdir = sys.argv[1].strip("/")
    raw_inputs = sys.argv[2:]

    files = resolve_artifacts(raw_inputs)
    if not files:
        print(">>> [ERROR] No valid build artifacts found to upload.")
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
