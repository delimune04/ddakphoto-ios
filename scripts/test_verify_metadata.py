"""Portable regression tests. Run: python3 -m unittest discover -s scripts -p 'test_*.py'."""

import importlib.util
import json
from pathlib import Path
import shutil
import struct
import tempfile
import unittest
import zlib


SPEC = importlib.util.spec_from_file_location("verify_metadata", Path(__file__).with_name("verify-metadata.py"))
VERIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFY)


def png(width, height, alpha=False):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    # Header fixture only: production validation deliberately does not claim to
    # decode pixels. Actual app screenshots receive a separate visual review.
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6 if alpha else 2, 0, 0, 0)) + chunk(b"IEND", b"")


class MetadataTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        shutil.copytree(VERIFY.ROOT / "release/metadata", self.root / "release/metadata")
        self.icon = self.root / "DdakPhoto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        self.icon.parent.mkdir(parents=True)
        self.icon.write_bytes(png(1024, 1024))
        self.app_path = self.root / "release/metadata/app.json"

    def tearDown(self):
        self.tmp.cleanup()

    def change_app(self, **changes):
        app = json.loads(self.app_path.read_text())
        app.update(changes)
        self.app_path.write_text(json.dumps(app))

    def write_field(self, field, value, locale="ko"):
        (self.root / f"release/metadata/{locale}/{field}.txt").write_text(value)

    def errors(self, submission=False):
        return VERIFY.validate(self.root, submission)["errors"]

    def test_current_draft_is_valid_but_not_submission_ready(self):
        self.assertEqual(self.errors(), [])
        self.assertTrue(self.errors(submission=True))

    def test_korean_keyword_limit_is_bytes_not_characters(self):
        self.write_field("keywords", "가" * 34)
        self.assertTrue(any("102/100 bytes" in e for e in self.errors()))

    def test_exact_100_keyword_bytes_allowed(self):
        self.write_field("keywords", "가" * 33 + "a\n")
        self.assertEqual(self.errors(), [])

    def test_name_character_limit(self):
        self.write_field("name", "가" * 30)
        self.assertEqual(self.errors(), [])
        self.write_field("name", "가" * 31)
        self.assertTrue(any("31/30" in e for e in self.errors()))

    def test_one_character_name_rejected(self):
        self.write_field("name", "가")
        self.assertTrue(any("minimum 2" in e for e in self.errors()))

    def test_missing_description_rejected(self):
        (self.root / "release/metadata/ko/description.txt").unlink()
        self.assertTrue(any("ko/description" in e for e in self.errors()))

    def test_empty_required_field_rejected(self):
        self.write_field("description", " \n")
        self.assertTrue(any("required value is empty" in e for e in self.errors()))

    def test_non_https_or_credential_url_rejected(self):
        for value in (None, "http://example.com", "https://example:secret@example.com", "https://[", 123):
            with self.subTest(value=value):
                self.change_app(support_url=value)
                self.assertTrue(any("support_url" in e for e in self.errors()))

    def test_empty_localizations_rejected(self):
        self.change_app(localizations=[])
        self.assertTrue(any("nonempty list" in e for e in self.errors()))

    def test_localization_path_traversal_rejected(self):
        self.change_app(localizations=["../elsewhere"])
        self.assertTrue(any("Invalid localization" in e for e in self.errors()))

    def test_duplicate_localizations_rejected(self):
        self.change_app(localizations=["ko", "ko"])
        self.assertTrue(any("Duplicate localization" in e for e in self.errors()))

    def test_bad_json_is_reported(self):
        self.app_path.write_text("{")
        self.assertTrue(any("app.json" in e for e in self.errors()))

    def test_wrong_json_shape_is_reported(self):
        self.app_path.write_text("[]")
        self.assertTrue(any("Expected an object" in e for e in self.errors()))

    def test_bundle_id_required(self):
        self.change_app(bundle_id="not a bundle")
        self.assertTrue(any("bundle_id" in e for e in self.errors()))

    def test_icon_transparency_rejected(self):
        self.icon.write_bytes(png(1024, 1024, alpha=True))
        self.assertTrue(any("App icon must" in e for e in self.errors()))

    def test_invalid_screenshot_rejected(self):
        directory = self.root / "release/screenshots"
        directory.mkdir()
        (directory / "sample.png").write_bytes(png(100, 100))
        self.assertTrue(any("unsupported portrait size" in e for e in self.errors()))

    def test_verified_price_does_not_imply_owner_approval(self):
        self.change_app(target_price={"verified_in_app_store_connect": True})
        self.assertTrue(any("Confirm the proposed price" in e for e in self.errors(True)))

    def test_complete_local_fields_pass_without_claiming_account_readiness(self):
        self.change_app(copyright="2026 Example Owner", age_rating="4+",
                        review_contact={"first_name": "Example", "last_name": "Tester", "email": "test@example.com", "phone_number": "+1 555 0100"},
                        target_price={"user_approved": True, "verified_in_app_store_connect": True},
                        bundle_id_requires_registration=False, screenshots_verified=True)
        (self.root / "release/metadata/review_information/review_notes.txt").write_text("Verified local review notes fixture.")
        screenshots = self.root / "release/screenshots"
        screenshots.mkdir()
        (screenshots / "sample.png").write_bytes(png(1320, 2868))
        self.assertEqual(self.errors(True), [])


class ImageHeaderTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "image"

    def tearDown(self):
        self.tmp.cleanup()

    def test_png_header(self):
        self.path.write_bytes(png(1320, 2868))
        self.assertEqual(VERIFY.image_header(self.path), (1320, 2868, False))

    def test_truncated_image_rejected(self):
        for data in (b"not an image", png(1024, 1024)[:-4], b"\xff\xd8\xff\xc0\x00\x11\xff\xd9"):
            with self.subTest(data=data[:8]):
                self.path.write_bytes(data)
                with self.assertRaises(ValueError):
                    VERIFY.image_header(self.path)

    def test_jpeg_header(self):
        self.path.write_bytes(b"\xff\xd8\xff\xc0\x00\x08\x08" + struct.pack(">HH", 2868, 1320) + b"\x03\xff\xd9")
        self.assertEqual(VERIFY.image_header(self.path), (1320, 2868, False))


if __name__ == "__main__":
    unittest.main()
