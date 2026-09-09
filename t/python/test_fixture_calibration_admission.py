"""Calibration admission before target creation, plus independent change controls."""

import hashlib
import json
import shutil
import subprocess
import unittest
from unittest.mock import patch

import test_fixture_policy_associations as fixtures

associations = fixtures.associations
analysis = associations.analysis


class CalibrationAdmission(unittest.TestCase):
    event = staticmethod(fixtures.PortableAssociations.event)
    make_run = fixtures.PortableAssociations.make_run

    def setUp(self):
        fixtures.PortableAssociations.setUp(self)

    def preflight(self, calibrations=None, path_hash=None):
        return associations.calibration_snapshot([self.calibration] if calibrations is None else calibrations,
            self.root, self.mapping.__getitem__ if path_hash is None else path_hash)

    def test_admission_needs_no_target_and_exposes_only_checked_relative_identities(self):
        shutil.rmtree(self.root / self.target)
        with patch.object(subprocess, "Popen", side_effect=AssertionError("process launched")), \
                patch.object(associations, "seal", side_effect=AssertionError("target sealing requested")), \
                patch.object(analysis, "NativePathHash", side_effect=AssertionError("unexpected ABI request")):
            ready = self.preflight()
        self.assertEqual(len(ready), 1)
        self.assertEqual(ready[0]["run"], self.calibration)
        self.assertEqual([row["path"] for row in ready[0]["pairs"]], self.paths[:2])
        self.assertEqual([row["token"] for row in ready[0]["pairs"]], self.tokens[:2])
        for name, identity in ready[0]["inputs"].items():
            raw = (self.root / self.calibration / name).read_bytes()
            self.assertEqual(identity, dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
        self.assertNotIn(str(self.root).encode(), associations.canonical(ready))
        self.assertNotIn(b"file://", associations.canonical(ready))

    def test_run_set_is_bounded_distinct_and_deterministically_ordered(self):
        for runs in ([], [self.calibration] * 2, [self.calibration] * (analysis.MAX_CALIBRATIONS + 1)):
            with self.subTest(runs=runs), self.assertRaises(ValueError):
                self.preflight(runs)
        other = ".artifacts/logs/second-calibration"
        self.make_run(other, self.paths[:2], self.calibration_records)
        self.assertEqual(self.preflight([other, self.calibration]), self.preflight([self.calibration, other]))
        self.assertEqual([row["run"] for row in self.preflight([other, self.calibration])],
                         [self.calibration, other])

    def test_native_mismatch_and_corrupt_source_cannot_be_preflighted(self):
        altered = dict(self.mapping)
        altered[self.capture_root + "/" + self.paths[0]] = "f" * 16
        with self.assertRaisesRegex(ValueError, "literal policy calibration"):
            self.preflight(path_hash=altered.__getitem__)
        archive = next((self.root / self.calibration).glob("*.source"))
        archive.write_bytes(b"changed calibration source")
        with self.assertRaisesRegex(ValueError, "source archive"):
            self.preflight()

    def test_snapshot_change_during_preflight_is_rejected(self):
        def changing(path):
            if path == self.capture_root + "/" + self.paths[1]:
                result = self.root / self.calibration / "test-result.json"
                result.write_text(json.dumps(dict(returncode=0, timeout=False)))
            return self.mapping[path]
        with self.assertRaisesRegex(ValueError, "changed during preflight"):
            self.preflight(path_hash=changing)

    def test_later_seal_matches_only_unchanged_admitted_calibration(self):
        ready = self.preflight()
        sealed = associations.seal(self.target, [self.calibration], self.root, self.mapping.__getitem__)
        self.assertEqual(ready, sealed["calibrations"])
        result = self.root / self.calibration / "test-result.json"
        result.write_text(json.dumps(dict(returncode=0, timeout=False)))
        changed = associations.seal(self.target, [self.calibration], self.root, self.mapping.__getitem__)
        self.assertNotEqual(ready, changed["calibrations"], "preflight must not confer trust on later bytes")
        self.assertEqual(ready[0]["pairs"], changed["calibrations"][0]["pairs"])

    def test_preflight_uses_the_same_closed_identity_domain_as_portable_sealing(self):
        run = analysis.load_run(self.calibration, self.root)
        for spelling in ("/unrelated/private/path", ".artifacts/logs/back\\slash", ".artifacts/logs/" + "x" * 1024):
            with self.subTest(spelling=spelling), patch.object(analysis, "load_run", return_value=dict(run, directory=spelling)), \
                    self.assertRaises(ValueError):
                self.preflight()


if __name__ == "__main__":
    unittest.main()
