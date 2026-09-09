"""Exclusive publication under observed directory, inode and I/O failures."""

import hashlib
import os
from pathlib import Path
import stat
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
try:
    import fixture_policy_associations as associations
finally:
    sys.path.pop(0)


class PublicationWriter(unittest.TestCase):
    def setUp(self):
        fixture = tempfile.TemporaryDirectory(prefix="policy-writer-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name)
        self.relative = ".artifacts/logs/run/evidence.json"
        self.output = self.root / self.relative
        self.parent = self.output.parent
        self.parent.mkdir(parents=True)
        self.raw = b"expected complete evidence\n"

    def publish(self, raw=None):
        return associations.publish_bytes(self.raw if raw is None else raw, self.relative, self.root)

    def pending(self, parent=None):
        return list((self.parent if parent is None else parent).glob("*.pending"))

    def test_complete_bytes_digest_private_mode_and_exact_bound(self):
        for raw in (b"", self.raw, b"x" * associations.MAX_MANIFEST_BYTES):
            with self.subTest(size=len(raw)):
                self.assertEqual(self.publish(raw), hashlib.sha256(raw).hexdigest())
                self.assertEqual(self.output.read_bytes(), raw)
                self.assertEqual(stat.S_IMODE(self.output.stat().st_mode), 0o600)
                self.assertEqual(self.output.stat().st_nlink, 1)
                self.assertEqual(self.pending(), [])
                self.output.unlink()
        with patch.object(associations.os, "open") as opened:
            for raw in (b"x" * (associations.MAX_MANIFEST_BYTES + 1), bytearray(b"x")):
                with self.assertRaises(ValueError):
                    self.publish(raw)
            opened.assert_not_called()

    def test_existing_file_directory_and_broken_symlink_are_untouched(self):
        self.output.write_bytes(b"existing")
        with self.assertRaises(FileExistsError):
            self.publish()
        self.assertEqual(self.output.read_bytes(), b"existing")
        self.output.unlink()
        self.output.mkdir()
        with self.assertRaises(FileExistsError):
            self.publish()
        self.assertEqual(list(self.output.iterdir()), [])
        self.output.rmdir()
        self.output.symlink_to("absent")
        with self.assertRaises(FileExistsError):
            self.publish()
        self.assertEqual(os.readlink(self.output), "absent")
        self.assertEqual(self.pending(), [])

    def test_existing_pending_name_is_not_owned_or_removed(self):
        class FixedId:
            hex = "fixed"
        pending = self.parent / "associations-fixed.pending"
        pending.write_bytes(b"foreign")
        with patch.object(associations.uuid, "uuid4", return_value=FixedId()), self.assertRaises(FileExistsError):
            self.publish()
        self.assertEqual(pending.read_bytes(), b"foreign")
        self.assertFalse(self.output.exists())

    def test_directory_swap_keeps_writes_and_cleanup_in_original_directory(self):
        link = os.link
        saved = self.root / "saved-run"
        def replace(source, destination, **kwargs):
            self.parent.rename(saved)
            self.parent.mkdir()
            (self.parent / Path(source).name).write_bytes(b"foreign")
            return link(source, destination, **kwargs)
        with patch.object(associations.os, "link", side_effect=replace), self.assertRaises(ValueError):
            self.publish()
        self.assertFalse(self.output.exists())
        self.assertEqual([p.read_bytes() for p in self.pending()], [b"foreign"])
        self.assertEqual(self.pending(saved), [])
        self.assertEqual((saved / self.output.name).read_bytes(), self.raw)

    def test_ancestor_swap_does_not_redirect_publication_or_cleanup(self):
        link = os.link
        saved = self.root / "saved-artifacts"
        def replace(source, destination, **kwargs):
            (self.root / ".artifacts").rename(saved)
            self.parent.mkdir(parents=True)
            (self.parent / Path(source).name).write_bytes(b"foreign")
            return link(source, destination, **kwargs)
        with patch.object(associations.os, "link", side_effect=replace), self.assertRaises(ValueError):
            self.publish()
        self.assertFalse(self.output.exists())
        self.assertEqual([p.read_bytes() for p in self.pending()], [b"foreign"])
        self.assertEqual(self.pending(saved / "logs/run"), [])
        self.assertEqual((saved / "logs/run/evidence.json").read_bytes(), self.raw)

    def test_indirect_parent_and_foreign_volume_reject_before_temporary_creation(self):
        saved = self.root / "saved-run"
        self.parent.rename(saved)
        self.parent.symlink_to(saved)
        with self.assertRaises(OSError):
            self.publish()
        self.assertEqual(list(saved.iterdir()), [])
        self.parent.unlink()
        saved.rename(self.parent)
        fstat = os.fstat
        def foreign(descriptor):
            info = fstat(descriptor)
            values = list(info)
            values[2] = info.st_dev + 1
            return os.stat_result(values)
        with patch.object(associations.os, "fstat", side_effect=foreign), self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(list(self.parent.iterdir()), [])

    def test_replaced_temporary_inode_is_rejected_and_not_removed(self):
        link = os.link
        def replace(source, destination, **kwargs):
            path = self.parent / Path(source).name
            path.unlink()
            path.write_bytes(b"foreign")
            return link(source, destination, **kwargs)
        with patch.object(associations.os, "link", side_effect=replace), self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(self.output.read_bytes(), b"foreign")
        self.assertEqual([p.read_bytes() for p in self.pending()], [b"foreign"])

    def test_same_inode_changed_bytes_do_not_return_an_expected_digest(self):
        link = os.link
        def change(source, destination, **kwargs):
            (self.parent / Path(source).name).write_bytes(b"x" * len(self.raw))
            return link(source, destination, **kwargs)
        with patch.object(associations.os, "link", side_effect=change), self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(self.output.read_bytes(), b"x" * len(self.raw))
        self.assertEqual(self.pending(), [])

    def test_destination_replaced_after_link_is_not_removed_or_accepted(self):
        link = os.link
        def change(source, destination, **kwargs):
            link(source, destination, **kwargs)
            self.output.unlink()
            self.output.write_bytes(b"foreign")
        with patch.object(associations.os, "link", side_effect=change), self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(self.output.read_bytes(), b"foreign")
        self.assertEqual(self.pending(), [])

    def test_sync_failure_cleans_owned_temporary_and_publishes_nothing(self):
        error = OSError("controlled fsync failure")
        with patch.object(associations.os, "fsync", side_effect=error), self.assertRaises(OSError) as caught:
            self.publish()
        self.assertIs(caught.exception, error)
        self.assertFalse(self.output.exists())
        self.assertEqual(self.pending(), [])

    def test_link_failure_preserves_primary_error_when_cleanup_also_fails(self):
        primary = OSError("controlled link failure")
        with patch.object(associations.os, "link", side_effect=primary), \
                patch.object(associations.os, "unlink", side_effect=OSError("controlled cleanup failure")), \
                self.assertRaises(OSError) as caught:
            self.publish()
        self.assertIs(caught.exception, primary)
        self.assertFalse(self.output.exists())
        self.assertEqual([p.read_bytes() for p in self.pending()], [self.raw])

    def test_cleanup_failure_after_valid_publication_remains_failed(self):
        error = OSError("controlled cleanup failure")
        with patch.object(associations.os, "unlink", side_effect=error), self.assertRaises(OSError) as caught:
            self.publish()
        self.assertIs(caught.exception, error)
        self.assertEqual(self.output.read_bytes(), self.raw)
        self.assertEqual([p.read_bytes() for p in self.pending()], [self.raw])


if __name__ == "__main__":
    unittest.main()
