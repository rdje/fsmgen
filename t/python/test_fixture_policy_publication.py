"""Closed publication receipts, partial writes, tampering and private-input loss."""

import copy
import hashlib
import json
from pathlib import Path
import shutil
import sys
import unittest
from unittest.mock import patch

import test_fixture_daemon_associations as fixtures

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
try:
    import fixture_policy_publication as publication
finally:
    sys.path.pop(0)
associations, analysis = publication.associations, publication.analysis


class PublicationControls(unittest.TestCase):
    event = staticmethod(fixtures.DaemonAssociations.event)
    make_run = fixtures.DaemonAssociations.make_run
    save = fixtures.DaemonAssociations.save

    def setUp(self):
        fixtures.DaemonAssociations.setUp(self)
        self.admitted = associations.calibration_snapshot([self.calibration], self.root, self.mapping.__getitem__)

    def publish(self):
        return publication.publish(self.target, [self.calibration], self.admitted, self.root, self.mapping.__getitem__)

    def receipt_bytes(self):
        return (self.directory / publication.RECEIPT).read_bytes()

    def test_receipt_binds_exclusive_artifacts_without_promoting_original_failure(self):
        self.collector.update(returncode=-9, failures={"private": "/unrelated/private/account"})
        self.save()
        result = self.publish()
        raw = self.receipt_bytes()
        self.assertEqual(result["sha256"], hashlib.sha256(raw).hexdigest())
        loaded = publication.consume(raw, result["sha256"], self.root)
        self.assertEqual(loaded["receipt"], result["receipt"])
        self.assertEqual(loaded["diagnostic"]["original"]["returncode"], 2)
        self.assertTrue(loaded["diagnostic"]["collector"]["reported_failure"])
        self.assertEqual(loaded["diagnostic"]["qualification"], "not_claimed")
        self.assertEqual(loaded["receipt"]["admission_sha256"],
                         hashlib.sha256(associations.canonical(self.admitted)).hexdigest())
        for filename in (*publication.FILES.values(), publication.RECEIPT):
            path = self.directory / filename
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertNotIn(str(self.root).encode(), path.read_bytes())
            self.assertNotIn(b"/unrelated/private/account", path.read_bytes())
        self.assertEqual(list(self.directory.glob("*.pending")), [])

    def test_receiver_needs_only_pinned_receipt_and_public_pair(self):
        published = self.publish()
        raw = self.receipt_bytes()
        expected = publication.consume(raw, published["sha256"], self.root)
        moved = self.root / "receiver"
        destination = moved / self.target
        destination.mkdir(parents=True)
        for filename in (*publication.FILES.values(), publication.RECEIPT):
            shutil.copyfile(self.directory / filename, destination / filename)
        shutil.rmtree(self.root / ".artifacts")
        with patch.object(analysis, "load_run", side_effect=AssertionError("private access")), \
                patch.object(analysis, "load_daemon_capture", side_effect=AssertionError("capture access")), \
                patch.object(analysis, "NativePathHash", side_effect=AssertionError("native access")):
            self.assertEqual(publication.consume(raw, published["sha256"], moved), expected)
        self.assertEqual(expected["receipt"]["limits"]["source_bodies"], "not_rehashed_or_included_by_receipt_consumer")

    def test_changed_calibration_rejects_before_any_publication(self):
        path = self.root / self.calibration / "test-result.json"
        path.write_text(json.dumps(dict(returncode=0, timeout=False)))
        with patch.object(associations, "publish_bytes") as publish, \
                self.assertRaisesRegex(ValueError, "changed after prospective admission"):
            self.publish()
        publish.assert_not_called()
        self.assertFalse((self.directory / publication.RECEIPT).exists())

    def test_existing_destinations_are_preserved_before_any_write(self):
        for filename in (*publication.FILES.values(), publication.RECEIPT):
            path = self.directory / filename
            path.write_bytes(b"existing evidence\n")
            with self.subTest(filename=filename), patch.object(associations, "publish_bytes") as publish, \
                    self.assertRaises(FileExistsError):
                self.publish()
            publish.assert_not_called()
            self.assertEqual(path.read_bytes(), b"existing evidence\n")
            path.unlink()

    def test_second_write_failure_preserves_valid_partial_manifest_without_receipt(self):
        publish = associations.publish_bytes
        def fail_report(raw, relative, root):
            if relative.endswith("/" + publication.FILES["diagnostic"]):
                raise OSError("controlled report publication failure")
            return publish(raw, relative, root)
        with patch.object(associations, "publish_bytes", side_effect=fail_report), self.assertRaises(OSError):
            self.publish()
        raw = (self.directory / publication.FILES["manifest"]).read_bytes()
        associations.read_manifest(raw, hashlib.sha256(raw).hexdigest())
        self.assertFalse((self.directory / publication.FILES["diagnostic"]).exists())
        self.assertFalse((self.directory / publication.RECEIPT).exists())
        self.assertEqual(list(self.directory.glob("*.pending")), [])

    def test_tampered_artifact_is_detected_before_receipt_publication(self):
        publish = associations.publish_bytes
        def corrupt(raw, relative, root):
            result = publish(raw, relative, root)
            if relative.endswith("/" + publication.FILES["diagnostic"]):
                with (self.directory / publication.FILES["manifest"]).open("ab") as stream:
                    stream.write(b" ")
            return result
        with patch.object(associations, "publish_bytes", side_effect=corrupt), \
                self.assertRaisesRegex(ValueError, "pinned identity"):
            self.publish()
        self.assertFalse((self.directory / publication.RECEIPT).exists())

    def test_receipt_anchor_and_closed_fields_reject_before_file_reads(self):
        published = self.publish()
        raw = self.receipt_bytes()
        with patch.object(analysis, "read_local", side_effect=AssertionError("file accessed")), \
                self.assertRaisesRegex(ValueError, "retained digest"):
            publication.consume(raw, "0" * 64, self.root)
        changes = [lambda r: r.update(private="/unrelated/private/account"),
            lambda r: r.update(run="/unrelated/private/account"),
            lambda r: r["artifacts"]["manifest"].update(bytes=True),
            lambda r: r["artifacts"]["diagnostic"].update(path=r["artifacts"]["manifest"]["path"]),
            lambda r: r["limits"].update(original_qualification="passed")]
        for index, change in enumerate(changes):
            receipt = copy.deepcopy(published["receipt"])
            change(receipt)
            changed = associations.canonical(receipt)
            with self.subTest(index=index), self.assertRaises(ValueError):
                publication.read_receipt(changed, hashlib.sha256(changed).hexdigest())
        for changed in (raw + b" ", b"x" * (associations.MAX_MANIFEST_BYTES + 1)):
            with self.assertRaises(ValueError):
                publication.read_receipt(changed, hashlib.sha256(changed).hexdigest())

    def test_rehashed_public_artifacts_still_require_exact_calibrated_linkage(self):
        published = self.publish()
        path = self.directory / publication.FILES["diagnostic"]
        original = json.loads(path.read_bytes())
        changes = [lambda r: r.update(manifest_sha256="0" * 64),
                   lambda r: r["records"][0].update(sha256="0" * 64),
                   lambda r: r["sources"][0].update(sha256="0" * 64)]
        for index, change in enumerate(changes):
            report = copy.deepcopy(original)
            change(report)
            data = associations.canonical(report)
            path.write_bytes(data)
            receipt = copy.deepcopy(published["receipt"])
            receipt["artifacts"]["diagnostic"].update(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
            raw = associations.canonical(receipt)
            with self.subTest(index=index), self.assertRaisesRegex(ValueError, "calibrated linkage"):
                publication.consume(raw, hashlib.sha256(raw).hexdigest(), self.root)
        path.write_bytes(associations.canonical(original))
        receipt = copy.deepcopy(published["receipt"])
        receipt["admission_sha256"] = "0" * 64
        raw = associations.canonical(receipt)
        with self.assertRaisesRegex(ValueError, "calibrated linkage"):
            publication.consume(raw, hashlib.sha256(raw).hexdigest(), self.root)


if __name__ == "__main__":
    unittest.main()
