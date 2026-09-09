"""Independent native-token spellings across calibration, joins and disclosure."""

import copy
import hashlib
import json
import subprocess
import unittest
from unittest.mock import patch

import test_fixture_policy_associations as fixtures
import test_fixture_policy_diagnostics as diagnostic_tests


diagnostics = diagnostic_tests.diagnostics
associations = diagnostics.associations
analysis = associations.analysis


class NativeTokenSpellings(unittest.TestCase):
    event = staticmethod(fixtures.PortableAssociations.event)
    make_run = fixtures.PortableAssociations.make_run

    def setUp(self):
        fixtures.PortableAssociations.setUp(self)
        self.tokens = ["0000000000000000", "0000000000000001",
                       "0499990c7f2beab5", "ffffffffffffffff"]
        self.mapping = {self.capture_root + "/" + path: token
                        for path, token in zip(self.paths, self.tokens)}
        self.calibration_records = [self.literal("0", self.paths[0]),
                                    self.literal("0000000000000001", self.paths[1])]
        self.target_records = [
            self.event("queueing up scan for code: PST: (path: 499990c7f2beab5)"),
            self.event("starting work for scan: PST: (path: 0499990c7f2beab5)"),
            self.event("scan finished, waking: PST: (path: 499990c7f2beab5)"),
            self.literal("499990c7f2beab5", self.paths[2]),
            self.literal("0499990c7f2beab5", self.paths[2]),
            self.event("PST: (path: ffffffffffffffff) PST: (path: 000000000000000a) PST: (path: a)"),
            self.event("unrelated context"),
        ]
        self.make_run(self.calibration, self.paths[:2], self.calibration_records)
        self.make_run(self.target, self.paths[2:], self.target_records)

    def literal(self, token, path):
        return self.event("PST: (path: " + token + ") file://" + self.capture_root + "/" + path)

    def test_all_native_widths_and_zero_keep_one_canonical_literal_value(self):
        path = self.capture_root + "/" + self.paths[2]
        for width in range(1, 17):
            raw = "f" * width
            expected = "0" * (16 - width) + raw
            run = dict(capture_root=self.capture_root, sources={self.paths[2]: {}},
                       records=[self.literal(raw, self.paths[2]), self.literal(expected, self.paths[2])])
            with self.subTest(width=width):
                self.assertEqual(analysis.literal_pairs(run), {path: expected})
        run["records"] = [self.literal("0", self.paths[2]), self.literal("0" * 16, self.paths[2])]
        self.assertEqual(analysis.literal_pairs(run), {path: "0" * 16})

    def test_analysis_joins_mixed_spellings_without_changing_raw_evidence(self):
        before = copy.deepcopy(self.target_records)
        with patch.object(subprocess, "Popen", side_effect=AssertionError("offline test launched")):
            result = analysis.analyze(self.target, [self.calibration], self.root, self.mapping.__getitem__)
        self.assertEqual(result["records"], before)
        self.assertEqual(result["original_result"], {"returncode": 2, "timeout": False})
        rows = {row["token"]: row for row in result["tokens"]}
        self.assertEqual(set(rows), {"0499990c7f2beab5", "ffffffffffffffff", "000000000000000a"})
        matched = rows["0499990c7f2beab5"]
        self.assertEqual(matched["record_indices"], [0, 1, 2, 3, 4])
        self.assertEqual((matched["queued"], matched["started"], matched["wakeups"]), (1, 1, 1))
        self.assertEqual(matched["source"]["path"], self.paths[2])
        self.assertEqual(rows["000000000000000a"]["record_indices"], [5])
        self.assertIsNone(rows["000000000000000a"]["source"])

    def test_manifest_replay_and_diagnostics_keep_canonical_tokens_for_both_scopes(self):
        expected = [["0499990c7f2beab5"]] * 5 + [["000000000000000a", "ffffffffffffffff"], []]
        for scope in ("execution_context", "daemon_context"):
            directory = self.root / self.target
            if scope == "daemon_context":
                output = directory / "policy.stdout"
                _, records = output.read_bytes().split(b"\n", 1)
                raw = b'Filtering the log data using "process == "syspolicyd""\n' + records
                output.write_bytes(raw)
                path = directory / "policy-result.json"
                collector = json.loads(path.read_bytes())
                collector.update(scope=scope, capture_root_sha256=hashlib.sha256(str(self.root).encode()).hexdigest())
                collector["command"][-1] = 'process == "syspolicyd"'
                collector["outputs"]["stdout"].update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
                path.write_text(json.dumps(collector))
            seal = associations.seal if scope == "execution_context" else associations.seal_daemon_capture
            with self.subTest(scope=scope):
                manifest = seal(self.target, [self.calibration], self.root, self.mapping.__getitem__)
                raw = associations.canonical(manifest)
                anchor = hashlib.sha256(raw).hexdigest()
                self.assertEqual([row["tokens"] for row in manifest["target"]["records"]], expected)
                replay = associations.replay(raw, anchor, self.target, self.root)
                matched = next(row for row in replay["tokens"] if row["token"] == "0499990c7f2beab5")
                self.assertEqual(matched["record_indices"], [0, 1, 2, 3, 4])
                report = diagnostics.export(raw, anchor, self.target, self.root)
                self.assertEqual([row["tokens"] for row in report["records"]], expected)
                self.assertEqual(report["original"]["returncode"], 2)
                self.assertNotIn(str(self.root).encode(), associations.canonical(report))
                for original, projected in zip(self.target_records, report["records"]):
                    encoded = (json.dumps(original, sort_keys=True, separators=(",", ":")) + "\n").encode()
                    self.assertEqual(projected["sha256"], hashlib.sha256(encoded).hexdigest())

    def test_invalid_native_spellings_cannot_hide_beside_valid_tokens(self):
        invalid = ["", "1" * 17, "A", "g", "-1", "+1", "0x1", "1 ", " 1", "１"]
        for token in invalid:
            # A valid token elsewhere must not conceal malformed native syntax.
            message = "PST: (path: 0000000000000001) PST: (path: " + token + ")"
            with self.subTest(token=token), self.assertRaisesRegex(ValueError, "invalid.*token|token.*invalid"):
                analysis.policy_tokens(message)
        with self.assertRaisesRegex(ValueError, "invalid.*token|token.*invalid"):
            analysis.policy_tokens("PST: (path: 1")
        self.assertEqual(analysis.policy_tokens("ordinary unrelated context"), set())

    def test_literal_ambiguity_and_contradictions_survive_normalization(self):
        absolute = self.capture_root + "/" + self.paths[2]
        run = dict(capture_root=self.capture_root, sources={self.paths[2]: {}}, records=[])
        run["records"] = [self.event("PST: (path: 1) PST: (path: 2) file://" + absolute)]
        with self.assertRaisesRegex(ValueError, "unambiguous"):
            analysis.literal_pairs(run)
        run["records"] = [self.literal("1", self.paths[2]), self.literal("2", self.paths[2])]
        with self.assertRaisesRegex(ValueError, "disagree on their token"):
            analysis.literal_pairs(run)
        self.target_records.append(self.literal("499990c7f2beab6", self.paths[2]))
        self.make_run(self.target, self.paths[2:], self.target_records)
        with self.assertRaisesRegex(ValueError, "disagree on their token"):
            associations.seal(self.target, [self.calibration], self.root, self.mapping.__getitem__)
        self.make_run(self.target, self.paths[2:], [self.literal("499990c7f2beab6", self.paths[2])])
        with self.assertRaisesRegex(ValueError, "contradicts calibrated"):
            associations.seal(self.target, [self.calibration], self.root, self.mapping.__getitem__)


if __name__ == "__main__":
    unittest.main()
