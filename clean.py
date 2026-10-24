#!/usr/bin/env python3
"""
Clean and reset script for realme-atoll ROM builds.
"""

import os
import shutil
import subprocess

TARGETS = [
    "packages/apps/Settings",
    "packages/apps/Evolver",
]

def clean():
    print("=== Cleaning Patched Repositories ===")

    for repo in TARGETS:
        if os.path.isdir(repo):
            symlink = os.path.join(repo, "Evolver")
            if os.path.islink(symlink):
                try:
                    os.unlink(symlink)
                except Exception:
                    pass
            subprocess.run(["git", "-C", repo, "reset", "--hard", "HEAD"], check=False)
            subprocess.run(["git", "-C", repo, "clean", "-fd"], check=False)
            print(f"Cleaned {repo}")

    # Remove stale GCC so LineageOS kernel makefiles use host compiler
    shutil.rmtree("prebuilts/gcc", ignore_errors=True)

    print("=== Cleanup Complete ===")

if __name__ == "__main__":
    clean()
