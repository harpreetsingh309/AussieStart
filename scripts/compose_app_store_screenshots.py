#!/usr/bin/env python3
"""Compose App Store screenshots with featured text at exact pixel sizes."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path("/Users/harpreetsingh/Desktop/AussieStart")
RAW = ROOT / "AppStore" / "raw"
OUT = ROOT / "AppStore" / "screenshots"

NAVY = (11, 31, 51, 255)
GREEN = (11, 110, 79, 255)
GOLD = (196, 163, 90, 255)
WHITE = (255, 255, 255, 255)
SAND = (245, 239, 228, 255)

IPHONE_65 = (1284, 2778)
IPHONE_69 = (1320, 2868)
IPAD_13 = (2064, 2752)
IAP = (640, 920)

SCENES = [
    {
        "file": "01-home",
        "sources": ["iphone-01-home.png"],
        "ipad_sources": ["ipad-01-home.png"],
        "kicker": "AUSSIESTART",
        "title": "Your Australia\nstarter guide",
        "sub": "Airport to TFN — offline on your phone",
    },
    {
        "file": "02-journey",
        "sources": ["iphone-02-journey.png"],
        "ipad_sources": ["ipad-02-journey.png"],
        "kicker": "ROADMAP",
        "title": "First 30 Days,\nmapped",
        "sub": "A week-by-week list for your state",
    },
    {
        "file": "03-guide",
        "sources": ["iphone-03-guide.png"],
        "ipad_sources": ["ipad-03-guide.png"],
        "kicker": "HOW-TO GUIDES",
        "title": "Clear steps.\nOfficial links.",
        "sub": "Open the real .gov.au page yourself",
    },
    {
        "file": "04-languages",
        "sources": ["iphone-04-languages.png"],
        "ipad_sources": ["ipad-04-languages.png"],
        "kicker": "LANGUAGES",
        "title": "English\nहिन्दी\nਪੰਜਾਬੀ",
        "sub": "UI and priority guides, on this device",
    },
    {
        "file": "05-paywall",
        "sources": ["iphone-05-paywall.png"],
        "ipad_sources": ["ipad-05-paywall.png"],
        "kicker": "ONE-TIME UNLOCK",
        "title": "Unlock\nAussieStart Pro",
        "sub": "$9.99 AUD · extra guides, no account",
    },
    {
        "file": "06-topics",
        "sources": ["iphone-06-topics.png"],
        "ipad_sources": ["ipad-06-topics.png"],
        "kicker": "BROWSE",
        "title": "Every topic,\nin one place",
        "sub": "SIM, bank, TFN, housing, and more",
    },
    {
        "file": "07-explore",
        "sources": ["iphone-07-explore.png"],
        "ipad_sources": ["ipad-07-explore.png"],
        "kicker": "EXPLORE",
        "title": "Weekends\nworth seeing",
        "sub": "Great Ocean Road and other day trips",
    },
]


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def pick_font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Avenir Next.ttc",
        "/Library/Fonts/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return font(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def pick_devanagari(size: int) -> ImageFont.FreeTypeFont:
    return font("/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc", size)


def pick_gurmukhi(size: int) -> ImageFont.FreeTypeFont:
    return font("/System/Library/Fonts/Supplemental/Gurmukhi Sangam MN.ttc", size)


def font_for_text(text: str, size: int) -> ImageFont.FreeTypeFont:
    if any("\u0A00" <= ch <= "\u0A7F" for ch in text):
        return pick_gurmukhi(size)
    if any("\u0900" <= ch <= "\u097F" for ch in text):
        return pick_devanagari(size)
    return pick_font(size, bold=True)


def first_existing(names: list[str]) -> Path:
    for name in names:
        path = RAW / name
        if path.exists():
            return path
    raise SystemExit(f"Missing simulator screenshot. Expected one of {names} in {RAW}")


def cover(src: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    scale = max(tw / src.width, th / src.height)
    resized = src.resize((max(1, int(src.width * scale)), max(1, int(src.height * scale))), Image.Resampling.LANCZOS)
    left = (resized.width - tw) // 2
    top = (resized.height - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size, NAVY[:3])
    overlay = Image.new("RGB", size, GREEN[:3])
    mask = Image.linear_gradient("L").resize((1, h)).resize((w, h))
    return Image.composite(overlay, img, mask).convert("RGBA")


def rounded_paste(base: Image.Image, overlay: Image.Image, box: tuple[int, int, int, int], radius: int) -> None:
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    fitted = cover(overlay.convert("RGBA"), (w, h))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    base.paste(fitted, (x0, y0), mask)


def draw_centered(draw: ImageDraw.ImageDraw, text: str, y: int, font_obj: ImageFont.FreeTypeFont, fill, width: int) -> int:
    bbox = draw.multiline_textbbox((0, 0), text, font=font_obj, align="center", spacing=8)
    tw = bbox[2] - bbox[0]
    draw.multiline_text(((width - tw) / 2, y), text, font=font_obj, fill=fill, align="center", spacing=8)
    return int(bbox[3] - bbox[1])


def draw_mixed_title(draw: ImageDraw.ImageDraw, text: str, y: int, size: int, fill, width: int) -> int:
    """Draw mixed Latin / Devanagari / Gurmukhi lines, each with a covering font."""
    lines = text.split("\n")
    total_h = 0
    line_gap = max(8, size // 8)
    for i, line in enumerate(lines):
        font_obj = font_for_text(line, size)
        bbox = draw.textbbox((0, 0), line, font=font_obj)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text(((width - tw) / 2, y + total_h), line, font=font_obj, fill=fill)
        total_h += th + (line_gap if i < len(lines) - 1 else 0)
    return total_h


def compose_phone_or_pad(scene: dict, canvas_size: tuple[int, int], sources: list[str], ui_radius: int) -> Image.Image:
    w, h = canvas_size
    banner_h = int(h * 0.28)
    canvas = gradient((w, h))
    draw = ImageDraw.Draw(canvas)

    kicker_font = pick_font(max(22, w // 28), bold=True)
    title_size = max(36, w // 14) if scene["file"] == "04-languages" else (
        max(44, w // 11) if any(ord(ch) > 127 for ch in scene["title"]) else max(48, w // 10)
    )
    sub_font = pick_font(max(22, w // 26), bold=False)

    y = int(h * 0.045)
    kicker_h = draw_centered(draw, scene["kicker"], y, kicker_font, GOLD, w)
    y += kicker_h + int(h * 0.012)
    title_h = draw_mixed_title(draw, scene["title"], y, title_size, WHITE, w)
    y += title_h + int(h * 0.012)
    draw_centered(draw, scene["sub"], y, sub_font, SAND, w)

    pad = int(w * 0.06)
    top = banner_h
    ui_box = (pad, top, w - pad, h - int(h * 0.035))
    src_path = first_existing(sources)
    with Image.open(src_path) as src:
        rounded_paste(canvas, src, ui_box, ui_radius)

    return canvas.convert("RGB")


def compose_iap() -> Image.Image:
    """Actual paywall UI at 640x920 for App Store Connect IAP review."""
    src = first_existing(["iphone-05-paywall.png"])
    with Image.open(src) as img:
        paywall = img.convert("RGB")
    target_w, target_h = IAP
    scale = min(target_w / paywall.width, target_h / paywall.height)
    fitted = paywall.resize(
        (max(1, int(paywall.width * scale)), max(1, int(paywall.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGB", IAP, (247, 247, 247))
    canvas.paste(fitted, ((target_w - fitted.width) // 2, (target_h - fitted.height) // 2))
    return canvas


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rgb = img.convert("RGB")
    rgb.save(path, format="PNG", optimize=True)
    print(f"Wrote {path.relative_to(ROOT)} ({rgb.size[0]}x{rgb.size[1]})")


def main() -> None:
    iap_only = "--iap-only" in sys.argv
    if iap_only:
        save(compose_iap(), OUT / "iap-640x920" / "aussiestart-pro.png")
        return
    for scene in SCENES:
        phone = compose_phone_or_pad(scene, IPHONE_65, scene["sources"], ui_radius=48)
        save(phone, OUT / "iphone-6.5" / f"{scene['file']}.png")
        save(phone.resize(IPHONE_69, Image.Resampling.LANCZOS), OUT / "iphone-6.9" / f"{scene['file']}.png")
        pad = compose_phone_or_pad(scene, IPAD_13, scene["ipad_sources"], ui_radius=36)
        save(pad, OUT / "ipad-13" / f"{scene['file']}.png")
    save(compose_iap(), OUT / "iap-640x920" / "aussiestart-pro.png")


if __name__ == "__main__":
    main()
