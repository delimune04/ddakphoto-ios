#!/usr/bin/env python3
"""Offline checks for DdakPhoto's App Store metadata (no account/network access).

Default mode validates the draft; --submission also rejects incomplete local
submission fields. Neither mode establishes Apple account or release readiness.
Apple field limits were checked on 2026-10-04; see docs/submission-requirements.md.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import struct
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent.parent
LIMITS = {"name": 30, "subtitle": 30, "description": 4000, "promotional_text": 170, "keywords": 100}
SCREENSHOT_SIZES = {(1260, 2736), (1290, 2796), (1320, 2868), (1284, 2778), (1242, 2688)}


def image_header(path: Path) -> tuple[int, int, bool]:
    """Read PNG/JPEG dimensions and transparency, not a full pixel-decoding QA."""
    data = path.read_bytes()
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        offset, dimensions, alpha = 8, None, False
        while offset + 12 <= len(data):
            size = struct.unpack(">I", data[offset:offset + 4])[0]
            kind = data[offset + 4:offset + 8]
            body = data[offset + 8:offset + 8 + size]
            if offset + size + 12 > len(data):
                raise ValueError("Truncated PNG chunk")
            if kind == b"IHDR":
                if size != 13:
                    raise ValueError("Invalid PNG header")
                width, height, _, color, *_ = struct.unpack(">IIBBBBB", body)
                dimensions = width, height
                alpha = color in (4, 6)
            elif kind == b"tRNS":
                alpha = True
            elif kind == b"IEND":
                if dimensions and min(dimensions) > 0:
                    return *dimensions, alpha
                break
            offset += size + 12
        raise ValueError("Incomplete PNG")
    if data.startswith(b"\xff\xd8") and data.endswith(b"\xff\xd9"):
        offset = 2
        while offset + 4 <= len(data):
            if data[offset] != 0xFF:
                raise ValueError("Invalid JPEG segment")
            while offset < len(data) and data[offset] == 0xFF:
                offset += 1
            if offset >= len(data):
                break
            marker = data[offset]
            offset += 1
            if marker in (0xD9, 0xDA):
                break
            if marker == 0x01 or 0xD0 <= marker <= 0xD7:
                continue
            if offset + 2 > len(data):
                break
            size = struct.unpack(">H", data[offset:offset + 2])[0]
            if size < 2 or offset + size > len(data):
                raise ValueError("Truncated JPEG segment")
            if marker in (0xC0, 0xC1, 0xC2):
                if size < 8:
                    raise ValueError("Invalid JPEG frame")
                height, width = struct.unpack(">HH", data[offset + 3:offset + 7])
                if width and height:
                    return width, height, False
                break
            offset += size
    raise ValueError("Expected a complete PNG or JPEG image header")


def validate(root: Path, submission: bool = False) -> dict:
    errors, pending, checks = [], [], []
    metadata = root / "release/metadata"
    try:
        app = json.loads((metadata / "app.json").read_text())
        if not isinstance(app, dict):
            raise ValueError("Expected an object")
    except (OSError, ValueError) as error:
        return {"errors": [f"app.json: {error}"], "pending": [], "checks": []}

    locales = app.get("localizations")
    if not isinstance(locales, list) or not locales:
        errors.append("localizations must be a nonempty list")
        locales = []
    if app.get("primary_language") not in locales:
        errors.append("primary_language must be included in localizations")
    seen = set()
    for locale in locales:
        if not isinstance(locale, str) or not re.fullmatch(r"[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*", locale):
            errors.append("Invalid localization directory name")
            continue
        if locale in seen:
            errors.append(f"Duplicate localization: {locale}")
            continue
        seen.add(locale)
        for field, limit in LIMITS.items():
            try:
                value = (metadata / locale / f"{field}.txt").read_text().strip()
            except (OSError, UnicodeError):
                errors.append(f"{locale}/{field}: missing or unreadable UTF-8 text")
                continue
            length = len(value.encode("utf-8")) if field == "keywords" else len(value)
            unit = "bytes" if field == "keywords" else "characters"
            if not value and field in ("name", "description", "keywords"):
                errors.append(f"{locale}/{field}: required value is empty")
            if field == "name" and len(value) < 2:
                errors.append(f"{locale}/name: minimum 2 characters")
            if length > limit:
                errors.append(f"{locale}/{field}: {length}/{limit} {unit}")
            checks.append(f"{locale}/{field}: {length}/{limit} {unit}")

    for field in ("support_url", "privacy_policy_url"):
        value = app.get(field)
        try:
            url = urlparse(value) if isinstance(value, str) else None
            valid = bool(url and url.scheme == "https" and url.hostname and not url.username and not url.password)
        except ValueError:
            valid = False
        if not valid:
            errors.append(f"{field}: expected a public HTTPS URL without credentials")
    if not isinstance(app.get("bundle_id"), str) or not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", app["bundle_id"]):
        errors.append("bundle_id must be a reverse-DNS identifier")

    try:
        notes = (metadata / "review_information/review_notes.txt").read_text().strip()
        if not notes or len(notes.encode("utf-8")) > 4000:
            errors.append("Review notes must contain 1–4000 UTF-8 bytes")
        if "this note is a draft" in notes.lower():
            pending.append("Replace draft-only review-note instructions after final review")
    except (OSError, UnicodeError):
        errors.append("Review notes are missing or unreadable")

    icon = root / "DdakPhoto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    try:
        if image_header(icon) != (1024, 1024, False):
            errors.append("App icon must be 1024 × 1024 without transparency")
        else:
            checks.append("App icon: 1024 × 1024, no transparency")
    except (OSError, ValueError) as error:
        errors.append(f"App icon: {error}")

    screenshots = sorted(p for p in (root / "release/screenshots").glob("*") if p.suffix.lower() in (".png", ".jpg", ".jpeg"))
    if not screenshots:
        pending.append("Restore native screenshots from the verified commit's CI artifact")
    elif len(screenshots) > 10:
        errors.append("This single screenshot set must contain no more than 10 images")
    for path in screenshots:
        try:
            width, height, alpha = image_header(path)
            if (width, height) not in SCREENSHOT_SIZES or alpha:
                errors.append(f"{path.name}: unsupported portrait size or transparency")
            checks.append(f"{path.name}: {width} × {height}, alpha={alpha}")
        except (OSError, ValueError) as error:
            errors.append(f"{path.name}: {error}")

    for field in ("copyright", "age_rating"):
        if not app.get(field):
            pending.append(f"Complete verified {field}")
    contact = app.get("review_contact")
    if not isinstance(contact, dict) or not all(isinstance(contact.get(k), str) and contact[k].strip() for k in ("first_name", "last_name", "email", "phone_number")):
        pending.append("Complete real App Review contact privately in App Store Connect")
    price = app.get("target_price")
    if not isinstance(price, dict) or price.get("user_approved") is not True:
        pending.append("Confirm the proposed price with the owner")
    if not isinstance(price, dict) or price.get("verified_in_app_store_connect") is not True:
        pending.append("Verify and select the actual price in App Store Connect")
    if app.get("bundle_id_requires_registration") is not False:
        pending.append("Verify the Bundle ID registration and matching App Store Connect app record")
    if app.get("screenshots_verified") is not True:
        pending.append("Review the native screenshots and confirm the sample-image rights")

    return {"errors": errors + (pending if submission else []), "pending": pending, "checks": checks}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--submission", action="store_true", help="also fail on incomplete local submission fields")
    parser.add_argument("--json", action="store_true", help="print machine-readable results")
    args = parser.parse_args()
    result = validate(args.root, args.submission)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for check in result["checks"]:
            print(f"CHECK {check}")
        for pending in result["pending"]:
            print(f"PENDING {pending}")
        for error in result["errors"]:
            print(f"ERROR {error}")
        print("Local metadata checks failed." if result["errors"] else "Local metadata checks passed.")
        print("This does not verify signing, Apple account status, device testing, upload, or approval.")
    return 1 if result["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
