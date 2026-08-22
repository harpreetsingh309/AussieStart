#!/usr/bin/env python3
"""Capture live simulator screenshots of AussieStart, then compose App Store assets."""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path("/Users/harpreetsingh/Desktop/AussieStart")
RAW = ROOT / "AppStore" / "raw"
BUNDLE = "com.aussiestart.app"
SCENES = ["home", "journey", "guide", "languages", "paywall", "topics", "explore"]

IPHONE = {"name": "iPhone 16 Plus", "os": "18.6", "prefix": "iphone"}
IPAD = {"name": "iPad Pro 13-inch (M4)", "os": "18.6", "prefix": "ipad"}


def run(cmd: list[str], check: bool = True, timeout: int = 180, capture: bool = True) -> subprocess.CompletedProcess:
    print("+", " ".join(cmd), flush=True)
    result = subprocess.run(cmd, check=False, timeout=timeout, text=True, capture_output=capture)
    if check and result.returncode != 0:
        if capture:
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print(result.stderr)
        raise SystemExit(f"Command failed ({result.returncode}): {' '.join(cmd)}")
    return result


def udid_for(name: str, os_version: str) -> str:
    listing = run(["xcrun", "simctl", "list", "devices", "available"]).stdout
    in_runtime = False
    wanted = f"iOS {os_version}"
    uuid_re = re.compile(r"\(([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})\)", re.I)
    for line in listing.splitlines():
        if line.startswith("--"):
            in_runtime = wanted in line
            continue
        if not in_runtime or f"{name} (" not in line:
            continue
        match = uuid_re.search(line)
        if match:
            return match.group(1)
    raise SystemExit(f"No simulator named {name!r} on iOS {os_version}")


def ensure_booted(udid: str) -> None:
    run(["open", "-a", "Simulator", "--args", "-CurrentDeviceUDID", udid], check=False)
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=180)


def build(udid: str) -> Path:
    result = run(
        [
            "xcodebuild",
            "-project",
            str(ROOT / "AussieStart.xcodeproj"),
            "-scheme",
            "AussieStart",
            "-configuration",
            "Debug",
            "-destination",
            f"platform=iOS Simulator,id={udid}",
            "-derivedDataPath",
            str(ROOT / ".derived-screenshots"),
            "build",
        ],
        timeout=360,
        capture=False,
    )
    app = ROOT / ".derived-screenshots/Build/Products/Debug-iphonesimulator/AussieStart.app"
    if not app.exists():
        raise SystemExit(f"Missing built app at {app}")
    return app


def install(udid: str, app: Path) -> None:
    run(["xcrun", "simctl", "terminate", udid, BUNDLE], check=False)
    run(["xcrun", "simctl", "install", udid, str(app)], timeout=120)


def capture_scene(udid: str, prefix: str, scene: str) -> Path:
    run(["xcrun", "simctl", "terminate", udid, BUNDLE], check=False)
    run(
        [
            "xcrun",
            "simctl",
            "launch",
            "--terminate-running-process",
            udid,
            BUNDLE,
            "-AppStoreScreenshot",
            scene,
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_AU",
        ]
    )
    time.sleep(5.5 if scene == "paywall" else 4.0 if scene == "explore" else 3.2)
    names = {
        "home": f"{prefix}-01-home.png",
        "journey": f"{prefix}-02-journey.png",
        "guide": f"{prefix}-03-guide.png",
        "languages": f"{prefix}-04-languages.png",
        "paywall": f"{prefix}-05-paywall.png",
        "topics": f"{prefix}-06-topics.png",
        "explore": f"{prefix}-07-explore.png",
    }
    dest = RAW / names[scene]
    dest.parent.mkdir(parents=True, exist_ok=True)
    run(["xcrun", "simctl", "io", udid, "screenshot", str(dest)])
    print("captured", dest)
    return dest


def prepare_status_bar(udid: str) -> None:
    run(
        [
            "xcrun",
            "simctl",
            "status_bar",
            udid,
            "override",
            "--time",
            "9:41",
            "--batteryState",
            "charged",
            "--batteryLevel",
            "100",
            "--cellularMode",
            "active",
            "--cellularBars",
            "4",
            "--wifiMode",
            "active",
            "--wifiBars",
            "3",
            "--dataNetwork",
            "wifi",
        ],
        check=False,
    )
    run(["xcrun", "simctl", "ui", udid, "appearance", "light"], check=False)


def capture_device(spec: dict[str, str], app: Path, scenes: list[str] | None = None) -> None:
    udid = udid_for(spec["name"], spec["os"])
    print(f"Using {spec['name']} {udid}")
    ensure_booted(udid)
    install(udid, app)
    prepare_status_bar(udid)
    for scene in scenes or SCENES:
        capture_scene(udid, spec["prefix"], scene)
    run(["xcrun", "simctl", "status_bar", udid, "clear"], check=False)
    run(["xcrun", "simctl", "terminate", udid, BUNDLE], check=False)


def export_iap_review() -> None:
    subprocess.run(["python3", str(ROOT / "scripts/compose_app_store_screenshots.py"), "--iap-only"], check=True)


def parse_only() -> list[str] | None:
    if "--only" not in sys.argv:
        return None
    index = sys.argv.index("--only")
    if index + 1 >= len(sys.argv):
        raise SystemExit("Usage: --only home,journey,guide,languages,paywall,topics,explore")
    scenes = [item.strip() for item in sys.argv[index + 1].split(",") if item.strip()]
    unknown = [scene for scene in scenes if scene not in SCENES]
    if unknown:
        raise SystemExit(f"Unknown scenes: {unknown}. Valid: {SCENES}")
    return scenes


def main() -> None:
    iap_only = "--iap-only" in sys.argv
    resume = "--resume" in sys.argv
    only = parse_only()
    app = ROOT / ".derived-screenshots/Build/Products/Debug-iphonesimulator/AussieStart.app"

    if iap_only:
        iphone_udid = udid_for(IPHONE["name"], IPHONE["os"])
        ensure_booted(iphone_udid)
        if not app.exists():
            app = build(iphone_udid)
            install(iphone_udid, app)
        prepare_status_bar(iphone_udid)
        capture_scene(iphone_udid, "iphone", "paywall")
        export_iap_review()
        return

    if only:
        RAW.mkdir(parents=True, exist_ok=True)
        subprocess.run(["python3", str(ROOT / "scripts/generate_xcodeproj.py")], check=True)
        iphone_udid = udid_for(IPHONE["name"], IPHONE["os"])
        ensure_booted(iphone_udid)
        app = build(iphone_udid)
        capture_device(IPHONE, app, only)
        capture_device(IPAD, app, only)
        subprocess.run(["python3", str(ROOT / "scripts/compose_app_store_screenshots.py")], check=True)
        return

    if not resume:
        for folder in (ROOT / "AppStore" / "screenshots", ROOT / "AppStore" / "source-ui", RAW):
            if folder.exists():
                shutil.rmtree(folder)
        RAW.mkdir(parents=True, exist_ok=True)
        subprocess.run(["python3", str(ROOT / "scripts/generate_xcodeproj.py")], check=True)
        iphone_udid = udid_for(IPHONE["name"], IPHONE["os"])
        ensure_booted(iphone_udid)
        app = build(iphone_udid)
        capture_device(IPHONE, app)
    elif not app.exists():
        raise SystemExit("No built app for --resume. Run without --resume first.")
    else:
        iphone_udid = udid_for(IPHONE["name"], IPHONE["os"])
        ensure_booted(iphone_udid)
        prepare_status_bar(iphone_udid)
        capture_scene(iphone_udid, "iphone", "paywall")

    capture_device(IPAD, app)
    subprocess.run(["python3", str(ROOT / "scripts/compose_app_store_screenshots.py")], check=True)


if __name__ == "__main__":
    main()
