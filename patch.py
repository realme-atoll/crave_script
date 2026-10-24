#!/usr/bin/env python3
"""
Upstream and tree patches for realme-atoll ROM builds.
"""

import os
import re

SETTINGS_DIR = "packages/apps/Settings"
EVOLVER_DIR = "packages/apps/Evolver"

def patch_settings():
    if not os.path.isdir(SETTINGS_DIR):
        return

    print("=== Applying Upstream Patches ===")

    # 1. Symlink Evolver inside Settings
    evolver_link = os.path.join(SETTINGS_DIR, "Evolver")
    if not os.path.lexists(evolver_link) and os.path.isdir(EVOLVER_DIR):
        try:
            os.symlink("../Evolver", evolver_link)
            print("Linked Evolver -> ../Evolver")
        except Exception as e:
            print(f"Note on Evolver symlink: {e}")

    # 2. Remove unused Scrollbar.kt (fixes kapt ScrollIndicatorState build error)
    scrollbar = os.path.join(SETTINGS_DIR, "src/com/android/settings/widget/Scrollbar.kt")
    if os.path.exists(scrollbar):
        try:
            os.remove(scrollbar)
            print("Removed unused Scrollbar.kt")
        except Exception as e:
            print(f"Note removing Scrollbar.kt: {e}")

    # 3. Replace PixelPropsUtils.isCustomForkBuild() with false
    for repo in [SETTINGS_DIR, EVOLVER_DIR]:
        src = os.path.join(repo, "src")
        if os.path.isdir(src):
            for root, _, files in os.walk(src):
                for f in files:
                    if f.endswith((".java", ".kt")):
                        path = os.path.join(root, f)
                        try:
                            with open(path, "r", encoding="utf-8", errors="ignore") as fp:
                                content = fp.read()
                            if "PixelPropsUtils.isCustomForkBuild()" in content:
                                content = content.replace("PixelPropsUtils.isCustomForkBuild()", "false")
                                with open(path, "w", encoding="utf-8") as fp:
                                    fp.write(content)
                                print(f"Patched PixelPropsUtils in {f}")
                        except Exception as e:
                            print(f"Note patching {f}: {e}")

    # 4. Fix screen resolution display string in ModelPageController
    ctrl = os.path.join(SETTINGS_DIR, "src/com/android/settings/deviceinfo/hardwareinfo/ModelPageController.java")
    if os.path.exists(ctrl):
        try:
            with open(ctrl, "r", encoding="utf-8", errors="ignore") as fp:
                content = fp.read()
            if "screen_resolution_refresh_rate_combined_displayed_text" in content:
                content = re.sub(
                    r"mContext\.getString\(\s*R\.string\.screen_resolution_refresh_rate_combined_displayed_text\s*,[\s\S]*?\)",
                    r'String.format("%s × %s, %s Hz", String.valueOf(Math.max(w, h)), String.valueOf(Math.min(w, h)), String.valueOf(Math.round(hz)))',
                    content
                )
                with open(ctrl, "w", encoding="utf-8") as fp:
                    fp.write(content)
                print("Patched ModelPageController.java")
        except Exception as e:
            print(f"Note patching ModelPageController.java: {e}")

    # 5. Add string resource to evolution_strings.xml
    strings = os.path.join(SETTINGS_DIR, "res/values/evolution_strings.xml")
    if os.path.exists(strings):
        try:
            with open(strings, "r", encoding="utf-8", errors="ignore") as fp:
                content = fp.read()
            if "screen_resolution_refresh_rate_combined_displayed_text" not in content:
                content = content.replace(
                    "</resources>",
                    '    <string name="screen_resolution_refresh_rate_combined_displayed_text" translatable="false">%1$s × %2$s, %3$s Hz</string>\n</resources>'
                )
                with open(strings, "w", encoding="utf-8") as fp:
                    fp.write(content)
                print("Added screen_resolution_refresh_rate_combined_displayed_text to evolution_strings.xml")
        except Exception as e:
            print(f"Note updating evolution_strings.xml: {e}")

    print("=== Upstream Patches Applied ===")

if __name__ == "__main__":
    patch_settings()
