"""Private daemon origin binding, calibration and portable disclosure controls."""

import copy
import hashlib
import json
from pathlib import Path
import shutil
import sys
import unittest
from unittest.mock import patch

import test_fixture_policy_associations as fixtures

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
try:
    import fixture_policy_diagnostics as diagnostics
finally:
    sys.path.pop(0)
associations = diagnostics.associations
analysis = associations.analysis


class DaemonAssociations(unittest.TestCase):
    event = staticmethod(fixtures.PortableAssociations.event)
    make_run = fixtures.PortableAssociations.make_run

    def setUp(self):
        fixtures.PortableAssociations.setUp(self)
        self.directory = self.root / self.target
        path = self.directory / "policy.stdout"
        lines = path.read_text().splitlines()
        lines[0] = 'Filtering the log data using "process == "syspolicyd""'
        path.write_text("\n".join(lines) + "\n")
        self.collector = json.loads((self.directory / "policy-result.json").read_text())
        self.collector.update(scope="daemon_context", capture_root_sha256=hashlib.sha256(str(self.root).encode()).hexdigest())
        self.collector["command"][-1] = 'process == "syspolicyd"'
        self.save()

    def save(self):
        raw = (self.directory / "policy.stdout").read_bytes()
        self.collector["outputs"]["stdout"].update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        (self.directory / "policy-result.json").write_text(json.dumps(self.collector))

    def seal(self, mapping=None):
        return associations.seal_daemon_capture(self.target, [self.calibration], self.root,
                                                self.mapping.__getitem__ if mapping is None else mapping)

    def test_native_origin_binding_is_required_before_daemon_sealing(self):
        original = copy.deepcopy(self.collector)
        for digest in (None, True, "", "0" * 64, "f" * 63):
            self.collector["capture_root_sha256"] = digest
            self.save()
            with self.subTest(digest=digest), self.assertRaisesRegex(ValueError, "current checkout"):
                self.seal()
        self.collector.pop("capture_root_sha256")
        self.save()
        with self.assertRaisesRegex(ValueError, "current checkout"):
            self.seal()
        self.collector = original
        self.save()
        moved = self.root / "moved checkout"
        shutil.copytree(self.root / ".artifacts", moved / ".artifacts")
        with self.assertRaisesRegex(ValueError, "current checkout"):
            analysis.load_daemon_capture(self.target, moved)

    def test_closed_daemon_contract_rejects_rehashed_command_and_header_drift(self):
        original = copy.deepcopy(self.collector)
        for change in ({"scope": "execution_context"}, {"schema": "unknown"}, {"command": []},
                       {"command": original["command"][:-1] + ['process == "other_process"']},
                       {"command": original["command"][:-1] + ['TRUEPREDICATE']}):
            self.collector = dict(original, **change)
            self.save()
            with self.subTest(change=change), self.assertRaisesRegex(ValueError, "reviewed contract"):
                self.seal()
        self.collector = original
        path = self.directory / "policy.stdout"
        raw = path.read_text()
        for predicate in ('process == "other_process"', 'TRUEPREDICATE'):
            path.write_text(raw.replace('process == "syspolicyd"', predicate, 1))
            self.save()
            with self.subTest(predicate=predicate), self.assertRaisesRegex(ValueError, "header"):
                self.seal()

    def test_calibration_and_source_archive_remain_required(self):
        with self.assertRaises(ValueError):
            associations.seal_daemon_capture(self.target, [], self.root, self.mapping.__getitem__)
        with self.assertRaisesRegex(ValueError, "distinct separate runs"):
            associations.seal_daemon_capture(self.target, [self.target], self.root, self.mapping.__getitem__)
        altered = dict(self.mapping)
        altered[self.capture_root + "/" + self.paths[0]] = "f" * 16
        with self.assertRaisesRegex(ValueError, "literal policy calibration"):
            self.seal(altered.__getitem__)
        path = next(self.directory.glob("*.source"))
        path.write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "source archive"):
            self.seal()

    def test_capture_snapshot_mutation_cannot_publish_a_seal(self):
        def changed(path):
            if path == self.capture_root + "/" + self.paths[-1]:
                result = self.directory / "test-result.json"
                result.write_text(json.dumps(dict(returncode=0, timeout=False)))
            return self.mapping[path]
        with self.assertRaisesRegex(ValueError, "changed during association sealing"):
            self.seal(changed)

    def test_daemon_seal_replays_and_discloses_after_private_machine_inputs_are_deleted(self):
        self.collector.update(returncode=-9, failures={"private": "/unrelated/private/account"})
        self.save()
        manifest = self.seal()
        raw = associations.canonical(manifest)
        report = diagnostics.export(raw, hashlib.sha256(raw).hexdigest(), self.target, self.root)
        self.assertEqual(report["scope"], "daemon_context")
        self.assertEqual(report["original"]["returncode"], 2)
        self.assertTrue(report["collector"]["reported_failure"])
        self.assertEqual(report["qualification"], "not_claimed")
        for encoded in (raw, associations.canonical(report)):
            self.assertNotIn(str(self.root).encode(), encoded)
            self.assertNotIn(self.collector["capture_root_sha256"].encode(), encoded)
            self.assertNotIn(b"/unrelated/private/account", encoded)
        moved = self.root / "receiver"
        archives = moved / ".artifacts/logs/archives"
        archives.mkdir(parents=True)
        for source in self.directory.glob("*.source"):
            shutil.copyfile(source, archives / source.name)
        shutil.rmtree(self.root / ".artifacts")
        with patch.object(analysis, "NativePathHash", side_effect=AssertionError("native access")), \
                patch.object(analysis, "load_run", side_effect=AssertionError("private access")), \
                patch.object(analysis, "load_daemon_capture", side_effect=AssertionError("capture access")):
            replay = associations.replay(raw, hashlib.sha256(raw).hexdigest(), ".artifacts/logs/archives", moved)
            report_raw = associations.canonical(report)
            self.assertEqual(diagnostics.read_report(report_raw, hashlib.sha256(report_raw).hexdigest()), report)
        self.assertEqual([row["token"] for row in replay["tokens"]], [self.tokens[2], self.tokens[3], "a" * 16])
        self.assertEqual([row["record_indices"] for row in replay["tokens"]], [[0], [1], [2]])
        self.assertIsNone(replay["tokens"][-1]["source"])

    def test_existing_loader_and_standalone_sealer_still_reject_daemon_scope(self):
        with self.assertRaisesRegex(ValueError, "execution-context"):
            analysis.load_run(self.target, self.root)
        with self.assertRaisesRegex(ValueError, "execution-context"):
            associations.seal(self.target, [self.calibration], self.root, self.mapping.__getitem__)


if __name__ == "__main__":
    unittest.main()
