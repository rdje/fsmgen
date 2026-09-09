"""Portable replay, independent record joins, and hostile association controls."""

import copy
import hashlib
import io
import json
from pathlib import Path
import shutil
import sys
import unittest
from unittest.mock import patch

import test_fixture_policy_analysis as retained_tests


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
try:
    import fixture_policy_associations as associations
finally:
    sys.path.pop(0)


class PortableAssociations(unittest.TestCase):
    event = staticmethod(retained_tests.OfflineAttribution.event)
    make_run = retained_tests.OfflineAttribution.make_run

    def setUp(self):
        retained_tests.OfflineAttribution.setUp(self)
        old_root = self.capture_root
        self.capture_root = str(self.root)
        self.mapping = {key.replace(old_root, self.capture_root): value for key, value in self.mapping.items()}
        self.calibration_records = [self.event(
            "PST: (path: " + token + ") file://" + self.capture_root + "/" + path)
            for path, token in zip(self.paths[:2], self.tokens[:2])]
        self.make_run(self.calibration, self.paths[:2], self.calibration_records)
        self.make_run(self.target, self.paths[2:], self.target_records)

    def seal(self):
        return associations.seal(self.target, [self.calibration], self.root, self.mapping.__getitem__)

    def replay(self, manifest, root=None, archives=None):
        raw = associations.canonical(manifest)
        return associations.replay(raw, hashlib.sha256(raw).hexdigest(),
                                   archives or self.target, root or self.root)

    def test_relocated_replay_needs_only_manifest_anchor_and_archives(self):
        manifest = self.seal()
        old = retained_tests.OfflineAttribution.run_analysis(self)
        destination = self.root / "relocated-checkout"
        archives = destination / ".artifacts/logs/source-archives"
        archives.mkdir(parents=True)
        for source in (self.root / self.target).glob("*.source"):
            shutil.copyfile(source, archives / source.name)
        # Delete all capture/calibration records, headers and original archives.
        # The relocated repository is now the sole source of replay input.
        shutil.rmtree(self.root / ".artifacts")
        with patch.object(associations.analysis, "NativePathHash", side_effect=AssertionError("native ABI accessed")), \
                patch.object(associations.analysis, "load_run", side_effect=AssertionError("raw run loaded")), \
                patch.object(associations.sys, "platform", "linux"):
            result = self.replay(manifest, destination, ".artifacts/logs/source-archives")
        actual = [{key: row[key] for key in ("token", "record_indices", "queued", "started", "wakeups")}
                  | {"path": row["source"]["path"] if row["source"] else None} for row in result["tokens"]]
        expected = [{key: row[key] for key in ("token", "record_indices", "queued", "started", "wakeups")}
                    | {"path": row["source"]["path"] if row["source"] else None} for row in old["tokens"]]
        self.assertEqual(actual, expected)
        # Independent authored-record oracle, beyond agreement with the old analyzer.
        self.assertEqual([row["token"] for row in result["tokens"]], [self.tokens[2], self.tokens[3], "a" * 16])
        self.assertEqual([row["record_indices"] for row in result["tokens"]], [[0], [1], [2]])
        self.assertEqual([row["queued"] for row in result["tokens"]], [1, 1, 1])
        self.assertEqual([row["started"] + row["wakeups"] for row in result["tokens"]], [0, 0, 0])
        self.assertIsNone(result["tokens"][-1]["source"])
        self.assertEqual(result["limits"]["native_hash_rederivation"],
                         "unavailable_without_private_capture_root_and_native_abi")
        self.assertEqual(result["limits"]["complete_coverage"], "unproved")

    def test_manifest_is_deterministic_and_contains_no_raw_root_or_messages(self):
        first = self.seal()
        self.assertEqual(first, self.seal())
        raw = associations.canonical(first)
        self.assertNotIn(str(self.root).encode(), raw)
        self.assertNotIn(b"file://", raw)
        self.assertNotIn(b"independent unrelated event", raw)
        self.assertNotIn(b'"capture_root":', raw)
        self.assertEqual(len(first["target"]["records"]), len(self.target_records))
        for captured, projected in zip(self.target_records, first["target"]["records"]):
            independent = (json.dumps(captured, sort_keys=True, separators=(",", ":"), ensure_ascii=True) + "\n").encode()
            self.assertEqual(projected["sha256"], hashlib.sha256(independent).hexdigest())
        for name, value in first["target"]["inputs"].items():
            original = (self.root / self.target / name).read_bytes()
            self.assertEqual(value, dict(bytes=len(original), sha256=hashlib.sha256(original).hexdigest()))

    def test_altered_mappings_and_record_allocation_fail_against_retained_anchor(self):
        original = self.seal()
        anchor = hashlib.sha256(associations.canonical(original)).hexdigest()
        variants = []
        changed = copy.deepcopy(original)
        changed["target"]["sources"][0]["token"], changed["target"]["sources"][1]["token"] = \
            changed["target"]["sources"][1]["token"], changed["target"]["sources"][0]["token"]
        variants.append(changed)
        changed = copy.deepcopy(original)
        changed["target"]["records"].reverse()
        variants.append(changed)
        changed = copy.deepcopy(original)
        changed["calibrations"][0]["pairs"][0]["token"] = "f" * 16
        variants.append(changed)
        for variant in variants:
            with self.subTest(variant=variants.index(variant)), self.assertRaisesRegex(ValueError, "retained digest"):
                associations.replay(associations.canonical(variant), anchor, self.target, self.root)
        # Replacing the trust anchor is a different claim, not a signature check.
        self.assertEqual(original["limits"]["digest_authority"], "caller_retained_anchor_not_authentication")

    def test_schema_and_bounds_reject_even_rehashed_hostile_manifests(self):
        original = self.seal()
        mutations = [
            lambda m: m.update(extra="private"),
            lambda m: m.update(schema="unknown"),
            lambda m: m["limits"].update(native_hash_rederivation="proved"),
            lambda m: m["target"].update(run="/private/capture"),
            lambda m: m["target"]["inputs"].pop("observations.jsonl"),
            lambda m: m["target"]["inputs"]["policy.stdout"].update(bytes=True),
            lambda m: m["target"]["sources"][0].update(path=associations.analysis.FIXTURE_PREFIX + "../escape"),
            lambda m: m["target"]["sources"][0].update(path=associations.analysis.FIXTURE_PREFIX + "x" * 1024),
            lambda m: m["target"]["sources"][0].update(token="not-a-token"),
            lambda m: m["target"]["sources"][0].update(size_bytes=65537),
            lambda m: m["target"]["sources"][1].update(token=m["target"]["sources"][0]["token"]),
            lambda m: m["target"]["sources"].reverse(),
            lambda m: m["target"].update(sources=m["target"]["sources"] * 33),
            lambda m: m["target"].update(records=m["target"]["records"] * 1025),
            lambda m: m["target"]["records"][0].update(tokens=["a" * 16] * 17),
            lambda m: m["target"]["records"][0].update(tokens=["a" * 16, "a" * 16]),
            lambda m: m["target"]["records"][0].update(phase="invented"),
            lambda m: m["target"]["records"][0].update(eventMessage="/private/message"),
            lambda m: m.update(calibrations=[]),
            lambda m: m.update(calibrations=m["calibrations"] * 5),
            lambda m: m["calibrations"][0].update(run=self.target),
            lambda m: m["calibrations"][0]["pairs"].pop(),
            lambda m: m["producers"]["scripts/analyze_fixture_policy.py"].update(sha256="z" * 64),
        ]
        for index, mutate in enumerate(mutations):
            modified = copy.deepcopy(original)
            mutate(modified)
            with self.subTest(mutation=index), self.assertRaises(ValueError):
                self.replay(modified)

    def test_encoding_bounds_and_duplicate_fields_cannot_hide_behind_new_anchor(self):
        manifest = self.seal()
        raw = associations.canonical(manifest)
        for value in (raw + b" ", b"{" + raw[1:-2] + b',"schema":"second"}\n',
                      b"x" * (associations.MAX_MANIFEST_BYTES + 1)):
            with self.subTest(bytes=len(value)), self.assertRaises(ValueError):
                associations.replay(value, hashlib.sha256(value).hexdigest(), self.target, self.root)

    def test_wrong_calibration_collision_and_changed_capture_fail_before_publication(self):
        with self.assertRaisesRegex(ValueError, "disagrees with literal"):
            associations.seal(self.target, [self.calibration], self.root, lambda _: "f" * 16)
        wrong = dict(self.mapping)
        wrong[self.capture_root + "/" + self.paths[3]] = self.tokens[2]
        with self.assertRaisesRegex(ValueError, "colliding tokens"):
            associations.seal(self.target, [self.calibration], self.root, wrong.__getitem__)
        original = associations.analysis.load_run
        calls = []

        def mutate_after_snapshot(relative, root):
            run = original(relative, root)
            calls.append(relative)
            if len(calls) == 2:
                path = root / self.target / "test-result.json"
                path.write_text('{"returncode":0}')
            return run

        with patch.object(associations.analysis, "load_run", side_effect=mutate_after_snapshot), \
                self.assertRaisesRegex(ValueError, "changed during"):
            self.seal()

    def test_target_literal_disagreement_and_foreign_capture_root_fail_closed(self):
        contradiction = self.event("PST: (path: " + "f" * 16 + ") file://" + self.capture_root + "/" + self.paths[2])
        self.make_run(self.target, self.paths[2:], self.target_records + [contradiction])
        with self.assertRaisesRegex(ValueError, "contradicts calibrated"):
            self.seal()
        self.capture_root += "/historical-checkout"
        self.make_run(self.target, self.paths[2:], self.target_records)
        with self.assertRaisesRegex(ValueError, "original capture checkout"):
            self.seal()

    def test_replay_rehashes_archives_and_rejects_symlinks(self):
        manifest = self.seal()
        archive = next((self.root / self.target).glob("*.source"))
        saved = archive.read_bytes()
        archive.write_bytes(b"wrong source")
        with self.assertRaisesRegex(ValueError, "sealed identity"):
            self.replay(manifest)
        replacement = self.root / "replacement"
        replacement.write_bytes(saved)
        archive.unlink()
        archive.symlink_to(replacement)
        with self.assertRaisesRegex(ValueError, "indirect"):
            self.replay(manifest)

    def test_publication_is_atomic_exclusive_and_leaves_no_pending_files(self):
        manifest = self.seal()
        relative = self.target + "/associations.json"
        anchor = associations.publish(manifest, relative, self.root)
        path = self.root / relative
        self.assertEqual(anchor, hashlib.sha256(path.read_bytes()).hexdigest())
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        with self.assertRaises(FileExistsError):
            associations.publish(manifest, relative, self.root)
        self.assertEqual(path.read_bytes(), associations.canonical(manifest))
        with patch.object(associations.os, "link", side_effect=OSError("publication failed")), \
                self.assertRaises(OSError):
            associations.publish(manifest, self.target + "/failed.json", self.root)
        self.assertFalse((path.parent / "failed.json").exists())
        self.assertEqual(list(path.parent.glob("*.pending")), [])

    def test_cli_failure_does_not_disclose_private_exception_or_source(self):
        stderr, stdout = io.StringIO(), io.StringIO()
        with patch.object(associations, "seal", side_effect=OSError("/private/unrelated/account")), \
                patch.object(sys, "stderr", stderr), patch.object(sys, "stdout", stdout):
            result = associations.main(["seal", self.target, "--calibration", self.calibration,
                                        "--output", self.target + "/manifest.json"])
        self.assertEqual(result, 1)
        self.assertEqual(stdout.getvalue(), "")
        self.assertEqual(stderr.getvalue(), "fixture policy association failed; no successful result\n")
        for arguments in (["/private/unrelated/account"], ["replay", "--unexpected=/private/input"]):
            stderr, stdout = io.StringIO(), io.StringIO()
            with patch.object(sys, "stderr", stderr), patch.object(sys, "stdout", stdout):
                result = associations.main(arguments)
            self.assertEqual(result, 1)
            self.assertEqual(stdout.getvalue(), "")
            self.assertEqual(stderr.getvalue(), "fixture policy association failed; no successful result\n")


if __name__ == "__main__":
    unittest.main()
