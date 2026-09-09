"""Pinned disclosure, private-path canaries, and independent snapshot controls."""

import copy
import hashlib
import io
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


class PrivateDiagnostics(unittest.TestCase):
    event = staticmethod(fixtures.PortableAssociations.event)
    make_run = fixtures.PortableAssociations.make_run
    seal = fixtures.PortableAssociations.seal

    def setUp(self):
        fixtures.PortableAssociations.setUp(self)
        self.secret = "/private/unrelated/person/project"
        self.target_records[0].update(processID=77, threadID=991, activityIdentifier=42,
            machTimestamp=123456, timestamp="2026-09-09 03:06:53.007132 +0200")
        self.target_records[1].update(processID=self.secret, threadID=True, machTimestamp=-1,
            activityIdentifier=1 << 64, subsystem=self.secret, timestamp=self.secret)
        # Exact timestamp spelling independently found in retained native output.
        self.target_records[2]["timestamp"] = "2026-09-09 03:06:44.616758+0200"
        for record in self.target_records:
            record["eventMessage"] += " " + self.secret
            record["private_extra"] = {self.secret: [self.secret]}
        self.make_run(self.target, self.paths[2:], self.target_records)
        self.directory = self.root / self.target
        journal = self.directory / "observations.jsonl"
        candidate = json.loads(journal.read_text())
        for source in candidate["evidence"]["sources"]:
            body = (self.directory / (source["sha256"] + ".source")).read_bytes() + self.secret.encode()
            source["sha256"] = hashlib.sha256(body).hexdigest()
            source["size_bytes"] = len(body)
            (self.directory / (source["sha256"] + ".source")).write_bytes(body)
        journal.write_text(json.dumps(candidate) + "\n" + json.dumps(dict(event="private", details=self.secret)) + "\n")
        path = self.directory / "policy.stdout"
        path.write_bytes(path.read_bytes() + json.dumps({self.secret: self.secret}).encode() + b"\n")
        self.collector = json.loads((self.directory / "policy-result.json").read_text())
        self.collector.update(returncode=-9, leader_reaped=True, forced_kill=True, failures={self.secret: self.secret})
        self.save_collector()
        (self.directory / "test-result.json").write_text(json.dumps(dict(returncode=2, timeout=False,
            released=True, leader_reaped=True, error=self.secret)))
        self.manifest = self.seal()

    def save_collector(self):
        raw = (self.directory / "policy.stdout").read_bytes()
        self.collector["outputs"]["stdout"].update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        (self.directory / "policy-result.json").write_text(json.dumps(self.collector))

    def repin_inputs(self, manifest):
        # Independently authored hypothetical capture inputs, not native sealing.
        for name in manifest["target"]["inputs"]:
            raw = (self.directory / name).read_bytes()
            manifest["target"]["inputs"][name] = dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())

    def export(self, manifest=None, private_directory=None, root=None):
        raw = associations.canonical(self.manifest if manifest is None else manifest)
        return diagnostics.export(raw, hashlib.sha256(raw).hexdigest(), private_directory or self.target,
                                  self.root if root is None else root)

    def test_projection_omits_private_data_and_keeps_independently_authored_context_and_failures(self):
        read = associations.analysis.read_local

        def no_source_body(path, *args, **kwargs):
            self.assertNotEqual(path.suffix, ".source", "export must not read source bodies")
            return read(path, *args, **kwargs)

        with patch.object(associations.analysis, "NativePathHash", side_effect=AssertionError("native accessed")), \
                patch.object(associations.analysis, "load_run", side_effect=AssertionError("raw analysis invoked")), \
                patch.object(associations.analysis, "read_local", side_effect=no_source_body):
            report = self.export()
        raw = associations.canonical(report)
        self.assertNotIn(self.secret.encode(), raw)
        self.assertNotIn(str(self.root).encode(), raw)
        self.assertNotIn(b"eventMessage", raw)
        self.assertNotIn(b"private_extra", raw)
        self.assertEqual(report["original"], dict(returncode=2, timeout=False, released=True, leader_reaped=True))
        self.assertEqual(report["collector"], dict(returncode=-9, reported_failure=True, leader_reaped=True, forced_kill=True))
        self.assertEqual(report["qualification"], "not_claimed")
        self.assertEqual(report["records"][0]["context"], dict(process_id=77, thread_id=991, activity_id=42,
            mach_timestamp=123456, timestamp="2026-09-09 03:06:53.007132 +0200", subsystem="execution_policy"))
        self.assertEqual(report["records"][1]["context"], dict(process_id=None, thread_id=None, activity_id=None,
            mach_timestamp=None, timestamp=None, subsystem="other"))
        self.assertEqual(report["metadata_records_omitted"], 2)
        self.assertEqual(report["records"][2]["context"]["timestamp"], "2026-09-09 03:06:44.616758+0200")
        self.assertEqual([row["tokens"] for row in report["records"]], [[self.tokens[2]], [self.tokens[3]], ["a" * 16], []])
        self.assertEqual([row["phase"] for row in report["records"]], ["queued", "queued", "queued", "other"])
        for index, record in enumerate(self.target_records):
            independent = (json.dumps(record, ensure_ascii=True, sort_keys=True, separators=(",", ":")) + "\n").encode()
            self.assertEqual(report["records"][index]["sha256"], hashlib.sha256(independent).hexdigest())
        self.assertEqual(report["limits"]["raw_record_equivalence"], "not_claimed")
        self.assertEqual(report["limits"]["observer_outcome"], "not_projected")
        self.assertEqual(report["omissions"]["source_bodies"], True)

    def test_report_consumption_survives_deletion_of_every_private_input_and_archive(self):
        report = self.export()
        raw = associations.canonical(report)
        anchor = hashlib.sha256(raw).hexdigest()
        moved = self.root / "receiver"
        destination = moved / ".artifacts/logs/report.json"
        destination.parent.mkdir(parents=True)
        destination.write_bytes(raw)
        shutil.rmtree(self.root / ".artifacts")
        with patch.object(associations.analysis, "NativePathHash", side_effect=AssertionError("native accessed")), \
                patch.object(associations.analysis, "load_run", side_effect=AssertionError("private run accessed")), \
                patch.object(diagnostics, "ROOT", moved), patch.object(sys, "stdout", io.StringIO()) as stdout:
            self.assertEqual(diagnostics.read_report(raw, anchor), report)
            self.assertEqual(diagnostics.main(["read", ".artifacts/logs/report.json", "--sha256", anchor]), 0)
        self.assertEqual(json.loads(stdout.getvalue()), report)

    def test_export_accepts_relocated_private_snapshot_without_old_root_or_source_bodies(self):
        destination = self.root / "moved/.artifacts/logs/private-snapshot"
        destination.mkdir(parents=True)
        for name in self.manifest["target"]["inputs"]:
            shutil.copyfile(self.directory / name, destination / name)
        expected = self.export()
        shutil.rmtree(self.root / ".artifacts")
        self.assertEqual(self.export(private_directory=".artifacts/logs/private-snapshot", root=self.root / "moved"), expected)

    def test_altered_private_bytes_or_event_associations_reject_before_disclosure(self):
        for name in self.manifest["target"]["inputs"]:
            path = self.directory / name
            original = path.read_bytes()
            path.write_bytes(original + b" ")
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, "pinned identity"):
                self.export()
            path.write_bytes(original)
        altered = copy.deepcopy(self.manifest)
        altered["target"]["records"][0]["phase"] = "started"
        with self.assertRaisesRegex(ValueError, "event projection"):
            self.export(altered)
        altered = copy.deepcopy(self.manifest)
        altered["target"]["records"].pop()
        with self.assertRaisesRegex(ValueError, "event projection"):
            self.export(altered)
        raw = associations.canonical(self.manifest)
        with self.assertRaisesRegex(ValueError, "retained digest"):
            diagnostics.export(raw, "0" * 64, self.target, self.root)

    def test_pinned_modeled_daemon_snapshot_has_closed_command_and_header(self):
        # Future daemon sealing/caller production is separately qualified. This
        # control authors a pinned snapshot to qualify only its disclosure reader.
        self.collector["scope"] = "daemon_context"
        self.collector["command"][-1] = 'process == "syspolicyd"'
        path = self.directory / "policy.stdout"
        lines = path.read_text().splitlines()
        lines[0] = 'Filtering the log data using "process == "syspolicyd""'
        original = "\n".join(lines) + "\n"
        path.write_text(original)
        self.save_collector()
        manifest = copy.deepcopy(self.manifest)
        self.repin_inputs(manifest)
        report = self.export(manifest)
        self.assertEqual(report["scope"], "daemon_context")
        self.assertEqual(report["records"][1]["context"]["subsystem"], "other")
        for header in ('Filtering the log data using TRUEPREDICATE',
                       'Filtering the log data using "process == "other_process""'):
            path.write_text(header + "\n" + "\n".join(lines[1:]) + "\n")
            self.save_collector()
            self.repin_inputs(manifest)
            with self.subTest(header=header), self.assertRaisesRegex(ValueError, "native header"):
                self.export(manifest)
        path.write_text(original)
        self.collector["command"][-1] = 'TRUEPREDICATE'
        self.save_collector()
        self.repin_inputs(manifest)
        with self.assertRaisesRegex(ValueError, "reviewed contract"):
            self.export(manifest)

    def test_snapshot_change_after_initial_reads_prevents_a_report(self):
        read = associations.analysis.read_local
        changed = False

        def replace_after_snapshot(path, *args, **kwargs):
            nonlocal changed
            raw = read(path, *args, **kwargs)
            if path.name == "fixture_policy_diagnostics.py" and not changed:
                changed = True
                result = self.directory / "test-result.json"
                result.write_bytes(result.read_bytes() + b"\n")
            return raw

        with patch.object(associations.analysis, "read_local", side_effect=replace_after_snapshot), \
                self.assertRaisesRegex(ValueError, "changed during projection"):
            self.export()
        self.assertTrue(changed)

    def test_record_and_output_bounds_reject_before_report_consumption(self):
        report = self.export()
        record = copy.deepcopy(report["records"][0])
        record["tokens"] = [f"{index:016x}" for index in range(16)]
        report["records"] = [record] * 4096
        report["metadata_records_omitted"] = 0
        raw = associations.canonical(report)
        self.assertGreater(len(raw), diagnostics.MAX_REPORT_BYTES)
        with self.assertRaisesRegex(ValueError, "byte bound"):
            diagnostics.validate(report)
        with self.assertRaisesRegex(ValueError, "byte bound"):
            diagnostics.read_report(raw, hashlib.sha256(raw).hexdigest())
        report["records"] = [record] * 4097
        with self.assertRaisesRegex(ValueError, "cardinality"):
            diagnostics.validate(report)

    def test_rehashed_execution_header_drift_and_typed_outcome_corruption_reject(self):
        path = self.directory / "policy.stdout"
        original = path.read_text()
        path.write_text(original.replace('process == "syspolicyd"', 'process == "other_process"', 1))
        self.save_collector()
        altered = copy.deepcopy(self.manifest)
        self.repin_inputs(altered)
        with self.assertRaisesRegex(ValueError, "header predicate"):
            self.export(altered)
        path.write_text(original)
        self.save_collector()
        result_path = self.directory / "test-result.json"
        for result in (dict(returncode=True, timeout=False), dict(returncode=0, timeout=self.secret)):
            result_path.write_text(json.dumps(result))
            self.repin_inputs(altered)
            with self.assertRaises(ValueError):
                self.export(altered)
        result_path.write_text(json.dumps(dict(returncode=0, timeout=True)))
        self.repin_inputs(altered)
        report = self.export(altered)
        self.assertTrue(report["original"]["timeout"])
        self.assertEqual(report["qualification"], "not_claimed")

    def test_report_anchor_and_rehashed_hostile_fields_cannot_disclose_arbitrary_content(self):
        report = self.export()
        raw = associations.canonical(report)
        with self.assertRaisesRegex(ValueError, "retained digest"):
            diagnostics.read_report(raw, "0" * 64)
        mutations = [lambda r: r.update(private=self.secret),
            lambda r: r.update(qualification="passed"),
            lambda r: r["sources"][0].update(path=self.secret),
            lambda r: r["records"][0].update(eventMessage=self.secret),
            lambda r: r["records"][0]["context"].update(subsystem=self.secret),
            lambda r: r["records"][0]["context"].update(timestamp=self.secret),
            lambda r: r["records"][0]["context"].update(process_id=True),
            lambda r: r["records"][0]["context"].update(thread_id=1 << 64),
            lambda r: r["records"][0]["context"].update(timestamp="2026-99-09 03:06:53.007132 +0200"),
            lambda r: r["original"].update(error=self.secret),
            lambda r: r["collector"].update(reported_failure="false"),
            lambda r: r["omissions"].update(raw_messages=1),
            lambda r: r["limits"].update(complete_coverage="proved")]
        for index, mutate in enumerate(mutations):
            changed = copy.deepcopy(report)
            mutate(changed)
            data = associations.canonical(changed)
            with self.subTest(index=index), self.assertRaises(ValueError):
                diagnostics.read_report(data, hashlib.sha256(data).hexdigest())
        for data in (raw + b" ", b"{" + raw[1:-2] + b',"schema":"duplicate"}\n',
                     b"x" * (diagnostics.MAX_REPORT_BYTES + 1)):
            with self.assertRaises(ValueError):
                diagnostics.read_report(data, hashlib.sha256(data).hexdigest())

    def test_cli_publishes_exclusively_and_never_prints_private_errors(self):
        raw = associations.canonical(self.manifest)
        (self.directory / "associations.json").write_bytes(raw)
        args = ["export", self.target + "/associations.json", "--sha256", hashlib.sha256(raw).hexdigest(),
                "--private-inputs", self.target, "--output", self.target + "/diagnostic.json"]
        with patch.object(diagnostics, "ROOT", self.root), \
                patch.object(sys, "stdout", io.StringIO()) as stdout, patch.object(sys, "stderr", io.StringIO()) as stderr:
            self.assertEqual(diagnostics.main(args), 0)
            self.assertEqual(stderr.getvalue(), "")
            report_path = self.directory / "diagnostic.json"
            saved = report_path.read_bytes()
            self.assertEqual(stdout.getvalue().strip(), hashlib.sha256(saved).hexdigest())
            self.assertEqual(report_path.stat().st_mode & 0o777, 0o600)
            stdout.truncate(0)
            stdout.seek(0)
            self.assertEqual(diagnostics.main(args), 1)
            self.assertEqual(stdout.getvalue(), "")
            self.assertEqual(report_path.read_bytes(), saved)
            self.assertEqual(list(self.directory.glob("*.pending")), [])
        for arguments in ([self.secret], ["read", self.secret, "--sha256", "0" * 64]):
            with patch.object(sys, "stdout", io.StringIO()) as stdout, patch.object(sys, "stderr", io.StringIO()) as stderr:
                self.assertEqual(diagnostics.main(arguments), 1)
                self.assertEqual(stdout.getvalue(), "")
                self.assertEqual(stderr.getvalue(), "fixture policy diagnostic failed; no successful result\n")
        with patch.object(associations.analysis, "read_local", side_effect=OSError(self.secret)), \
                patch.object(sys, "stdout", io.StringIO()) as stdout, patch.object(sys, "stderr", io.StringIO()) as stderr:
            self.assertEqual(diagnostics.main(args), 1)
            self.assertEqual(stdout.getvalue(), "")
            self.assertNotIn(self.secret, stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
