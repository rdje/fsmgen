"""Offline policy attribution controls with independent retained-record oracles."""

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("fixture_policy_analysis", ROOT / "scripts/analyze_fixture_policy.py")
analysis = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(analysis)


class OfflineAttribution(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="policy-analysis-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        # Captured roots are data. This path never needs to exist or be read.
        self.capture_root = str(self.root / "previous location")
        self.calibration = ".artifacts/logs/calibration"
        self.target = ".artifacts/logs/target"
        self.paths = [analysis.FIXTURE_PREFIX + "held/producer-" + str(i) for i in range(4)]
        self.tokens = [str(i) * 16 for i in range(1, 5)]
        self.mapping = {self.capture_root + "/" + path: token for path, token in zip(self.paths, self.tokens)}
        self.calibration_records = [self.event(
            "PST: (path: " + token + ") file://" + self.capture_root.replace(" ", "%20") + "/" + path)
            for path, token in zip(self.paths[:2], self.tokens[:2])]
        self.target_records = [self.event("queueing up scan for code: PST: (path: " + token + ")")
                               for token in self.tokens[2:]]
        self.target_records += [self.event("queueing up scan for code: PST: (path: " + "a" * 16 + ")"),
                                self.event("independent unrelated event")]
        self.make_run(self.calibration, self.paths[:2], self.calibration_records)
        self.make_run(self.target, self.paths[2:], self.target_records)

    @staticmethod
    def event(message):
        return dict(eventType="logEvent", eventMessage=message, processID=677,
                    subsystem="com.apple.syspolicy.exec", timestamp="retained control timestamp")

    def make_run(self, relative, paths, records):
        directory = self.root / relative
        directory.mkdir(parents=True, exist_ok=True)
        sources = []
        for index, path in enumerate(paths):
            body = ("independent source for " + path + "\n").encode()
            digest = hashlib.sha256(body).hexdigest()
            (directory / (digest + ".source")).write_bytes(body)
            sources.append(dict(path=path, sha256=digest, size_bytes=len(body),
                                device=self.root.stat().st_dev, inode=index + 1))
        (directory / "observations.jsonl").write_text(json.dumps(
            dict(event="candidate", evidence=dict(sources=sources))) + "\n")
        header = 'Filtering the log data using "process == "syspolicyd" AND (composedMessage CONTAINS '
        header += (json.dumps(self.capture_root + "/" + analysis.FIXTURE_PREFIX)
                   + ' OR subsystem == "com.apple.syspolicy.exec")"\n')
        (directory / "policy.stdout").write_text(header + "\n".join(map(json.dumps, records)) + "\n"
                                                + json.dumps(dict(count=len(records), finished=1)) + "\n")
        policy = (directory / "policy.stdout").read_bytes()
        command = ["/usr/bin/log", "stream", "--style", "ndjson", "--level", "debug",
                   "--timeout", "240", "--predicate",
                   'process == "syspolicyd" AND (eventMessage CONTAINS '
                   '"<repo>/.artifacts/tmp/process-supervisor-tests/" '
                   'OR subsystem == "com.apple.syspolicy.exec")']
        (directory / "policy-result.json").write_text(json.dumps(dict(
            schema="fsmgen.fixture_policy_log.v1", scope="execution_context", command=command,
            returncode=0, failures={}, outputs=dict(stdout=dict(path=relative + "/policy.stdout",
            bytes=len(policy), sha256=hashlib.sha256(policy).hexdigest(),
            hash_complete=True, path_identity_matches=True)))))
        (directory / "test-result.json").write_text(json.dumps(dict(returncode=2, timeout=False)))

    def run_analysis(self, path_hash=None):
        return analysis.analyze(self.target, [self.calibration], self.root,
                                self.mapping.__getitem__ if path_hash is None else path_hash)

    def assert_complete_context(self, result):
        self.assertEqual(result["records"], self.target_records)
        self.assertEqual(result["metadata"], [dict(count=4, finished=1)])
        self.assertEqual(result["original_result"], dict(returncode=2, timeout=False))
        by_token = {row["token"]: row for row in result["tokens"]}
        self.assertEqual(set(by_token), set(self.tokens[2:] + ["a" * 16]))
        for index, token in enumerate(self.tokens[2:]):
            row = by_token[token]
            self.assertEqual(row["source"]["path"], self.paths[index + 2])
            self.assertEqual(row["attribution"], "calibrated_observed_path_hash")
            self.assertEqual((row["queued"], row["started"], row["wakeups"]), (1, 0, 0))
            self.assertEqual(row["record_indices"], [index])
        self.assertIsNone(by_token["a" * 16]["source"])
        self.assertEqual(by_token["a" * 16]["attribution"], "unattributed")
        self.assertEqual(result["missing_records"], "unknown")
        self.assertEqual(result["complete_coverage"], "unproved")

    def test_queued_only_context_uses_capture_root_and_keeps_unjoined_records(self):
        with patch.object(analysis.os, "kill", side_effect=AssertionError("process signalled")), \
                patch.object(subprocess, "Popen", side_effect=AssertionError("process launched")):
            self.assert_complete_context(self.run_analysis())
        moved = self.root / "moved repository"
        moved.mkdir()
        shutil.copytree(self.root / ".artifacts", moved / ".artifacts")
        result = analysis.analyze(self.target, [self.calibration], moved, self.mapping.__getitem__)
        self.assert_complete_context(result)

    def test_incorrect_or_unavailable_calibration_cannot_publish_attribution(self):
        with self.assertRaisesRegex(ValueError, "disagrees with literal"):
            self.run_analysis(lambda _: "f" * 16)
        with self.assertRaisesRegex(ValueError, "separate retained run"):
            analysis.analyze(self.target, [self.target], self.root, self.mapping.__getitem__)
        with self.assertRaisesRegex(ValueError, "bounded distinct"):
            analysis.analyze(self.target, [], self.root, self.mapping.__getitem__)
        self.make_run(self.calibration, self.paths[:2], self.calibration_records[:1])
        with self.assertRaisesRegex(ValueError, "distinct independently linked"):
            self.run_analysis()

    def test_collector_command_and_scope_are_required_for_target_and_calibration(self):
        for relative in (self.target, self.calibration):
            path = self.root / relative / "policy-result.json"
            original = json.loads(path.read_text())
            variants = {}
            for field in ("schema", "scope", "command"):
                changed = copy.deepcopy(original)
                del changed[field]
                variants["missing " + field] = changed
                changed = copy.deepcopy(original)
                changed[field] = "unreviewed"
                variants["changed " + field] = changed
            for index, value in ((0, "/usr/bin/true"), (1, "show"), (3, "json"),
                                 (5, "info"), (7, "241"), (8, "--other")):
                changed = copy.deepcopy(original)
                changed["command"][index] = value
                variants["argv " + str(index)] = changed
            for label, predicate in (
                    ("wrong process", original["command"][-1].replace("syspolicyd", "other")),
                    ("widened predicate", original["command"][-1] + " OR TRUEPREDICATE"),
                    ("narrowed predicate", 'process == "syspolicyd"'),
                    ("wrong root", original["command"][-1].replace("<repo>", "<other>"))):
                changed = copy.deepcopy(original)
                changed["command"][-1] = predicate
                variants[label] = changed
            try:
                for label, changed in variants.items():
                    with self.subTest(run=relative, variant=label):
                        path.write_text(json.dumps(changed))
                        with self.assertRaisesRegex(ValueError, "collector command"):
                            self.run_analysis()
            finally:
                path.write_text(json.dumps(original))
        self.assert_complete_context(self.run_analysis())

    def test_header_predicate_must_agree_even_when_manifest_hash_is_updated(self):
        for relative in (self.target, self.calibration):
            directory = self.root / relative
            output = directory / "policy.stdout"
            manifest = directory / "policy-result.json"
            original_bytes, original_manifest = output.read_bytes(), manifest.read_bytes()
            header, records = original_bytes.split(b"\n", 1)
            variants = {
                "wrong process": header.replace(b"syspolicyd", b"other"),
                "widened predicate": header[:-1] + b' OR TRUEPREDICATE"',
                "changed conjunction": header.replace(b" AND ", b" OR "),
                "changed subsystem": header.replace(b"com.apple.syspolicy.exec", b"other"),
            }
            try:
                for label, changed_header in variants.items():
                    with self.subTest(run=relative, variant=label):
                        data = changed_header + b"\n" + records
                        output.write_bytes(data)
                        changed = json.loads(original_manifest)
                        changed["outputs"]["stdout"].update(
                            bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
                        manifest.write_text(json.dumps(changed))
                        with self.assertRaisesRegex(ValueError, "header predicate"):
                            self.run_analysis()
            finally:
                output.write_bytes(original_bytes)
                manifest.write_bytes(original_manifest)
        self.assert_complete_context(self.run_analysis())

    def test_verified_command_does_not_discard_collector_failure_evidence(self):
        path = self.root / self.target / "policy-result.json"
        manifest = json.loads(path.read_text())
        manifest.update(returncode=1, failures={"finish": "retained cleanup failure"})
        path.write_text(json.dumps(manifest))
        result = self.run_analysis()
        self.assert_complete_context(result)
        self.assertEqual(result["collector_result"], manifest)

    def test_hash_collisions_and_literal_disagreement_fail_closed(self):
        values = dict(self.mapping)
        values[self.capture_root + "/" + self.paths[3]] = self.tokens[2]
        with self.assertRaisesRegex(ValueError, "ambiguous native hash"):
            self.run_analysis(values.__getitem__)
        contradiction = self.event("PST: (path: " + "f" * 16 + ") file://"
                                   + self.capture_root.replace(" ", "%20") + "/" + self.paths[2])
        self.make_run(self.target, self.paths[2:], self.target_records + [contradiction])
        with self.assertRaisesRegex(ValueError, "contradicts calibrated"):
            self.run_analysis()

    def test_archive_identity_and_local_file_admission_are_independent(self):
        directory = self.root / self.target
        archive = next(directory.glob("*.source"))
        archive.write_bytes(b"changed archive")
        with self.assertRaisesRegex(ValueError, "byte identity"):
            self.run_analysis()
        self.make_run(self.target, self.paths[2:], self.target_records)
        archive = next(directory.glob("*.source"))
        body = archive.read_bytes()
        separate = self.root / "indirect-source"
        separate.write_bytes(body)
        archive.unlink()
        archive.symlink_to(separate)
        with self.assertRaisesRegex(ValueError, "indirect"):
            self.run_analysis()
        for path in ("/outside", ".artifacts/logs/../target", ".artifacts/logs/target//duplicate"):
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, "repository-relative"):
                analysis.load_run(path, self.root)
        with self.assertRaisesRegex(ValueError, "byte bound"):
            analysis.read_local(separate, self.root, limit=1)

    def test_context_oracle_rejects_a_return_to_path_seeded_selection(self):
        result = self.run_analysis()
        broken = copy.deepcopy(result)
        broken["records"] = [row for row in broken["records"] if "file://" in row["eventMessage"]]
        with self.assertRaises(AssertionError):
            self.assert_complete_context(broken)

    def test_replaced_input_descriptor_is_rejected_before_any_bytes_are_read(self):
        expected = self.root / self.target / "policy.stdout"
        replacement = self.root / "replacement"
        replacement.write_bytes(b"must not be consumed")
        with replacement.open("rb") as stream:
            observed = MagicMock(wraps=stream)
            observed.__enter__.return_value = observed
            with patch.object(analysis.os, "open", return_value=stream.fileno()), \
                    patch.object(analysis.os, "fdopen", return_value=observed), \
                    self.assertRaisesRegex(ValueError, "changed before reading"):
                analysis.read_local(expected, self.root)
            observed.read.assert_not_called()

    def test_changed_policy_and_nonfinite_or_duplicate_json_fail_closed(self):
        policy = self.root / self.target / "policy.stdout"
        policy.write_bytes(policy.read_bytes() + b"\n")
        with self.assertRaisesRegex(ValueError, "collector manifest"):
            self.run_analysis()
        for value in ('{"duplicate":1,"duplicate":2}', '{"number":NaN}'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                analysis.decode_json(value)

    def test_selected_native_oracle_deadline_failure_stays_failed(self):
        timeout = subprocess.TimeoutExpired(["independent native ABI worker"], 5)
        compiled = subprocess.CompletedProcess([], 0, b"", b"")
        with patch.object(subprocess, "run", side_effect=[compiled, timeout]) as run, \
                self.assertRaises(subprocess.TimeoutExpired) as caught:
            # Directly exercise the separately selected control's boundary;
            # neither the compiler nor the native worker runs in this test.
            selected = type(self).test_native_hash_matches_independent_c_abi_oracle
            getattr(selected, "__wrapped__", selected)(self)
        self.assertIs(caught.exception, timeout)
        self.assertEqual(run.call_count, 2)
        self.assertEqual(run.call_args.kwargs["timeout"], 5)

    @unittest.skipUnless(sys.platform == "darwin" and os.environ.get("FSMGEN_NATIVE_POLICY_ABI_ORACLE") == "1",
                         "separately selected native build/load qualification")
    def test_native_hash_matches_independent_c_abi_oracle(self):
        source = self.root / "hash-oracle.c"
        library = self.root / "hash-oracle.dylib"
        source.write_text(r'''
#include <CoreFoundation/CoreFoundation.h>
#include <stdint.h>
int oracle_hash(const char *text, uint64_t *result) {
    CFStringRef value = CFStringCreateWithCString(kCFAllocatorDefault, text, kCFStringEncodingUTF8);
    if (!value) return 2;
    *result = CFHash(value);
    CFRelease(value);
    return 0;
}
''')
        environment = dict(os.environ, TMPDIR=str(self.root), TMP=str(self.root), TEMP=str(self.root),
                           CLANG_MODULE_CACHE_PATH=str(self.root / "clang-cache"))
        compiled = subprocess.run(["/usr/bin/clang", "-fno-modules", "-dynamiclib", str(source),
                                   "-framework", "CoreFoundation", "-o", str(library)],
                                  cwd=ROOT, env=environment, capture_output=True, timeout=30)
        self.assertEqual(compiled.returncode, 0, compiled.stderr.decode())
        paths = [self.capture_root + "/" + path for path in self.paths]
        paths += [self.capture_root + "/non-ASCII-é", self.capture_root + "/" + "x" * 300]
        # New code mapping itself can stall on this host. Keep it outside the
        # test process and under an external deadline; never turn a timeout
        # into successful ABI qualification. The ordinary offline gate does
        # not implicitly start this separately owned native experiment.
        worker = r'''
import ctypes, json, sys
oracle = ctypes.CDLL(sys.argv[1])
oracle.oracle_hash.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_uint64)]
oracle.oracle_hash.restype = ctypes.c_int
values = []
for path in sys.argv[2:]:
    value = ctypes.c_uint64()
    if oracle.oracle_hash(path.encode(), ctypes.byref(value)) != 0:
        raise RuntimeError("native C oracle failed")
    values.append(f"{value.value:016x}")
print(json.dumps(values))
'''
        result = subprocess.run([sys.executable, "-B", "-c", worker, str(library), *paths],
                                cwd=ROOT, env=environment, capture_output=True, timeout=5)
        self.assertEqual((result.returncode, result.stderr), (0, b""))
        expected = json.loads(result.stdout)
        self.assertEqual(len(expected), len(paths))
        native = analysis.NativePathHash()
        self.assertEqual([native(path) for path in paths], expected)
        with self.assertRaisesRegex(ValueError, "NUL-free"):
            native("truncated\0path")


if __name__ == "__main__":
    unittest.main()
