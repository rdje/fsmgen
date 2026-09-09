"""Portable archive admission and compact sequence journal anchors."""

import copy
import contextlib
import io
import json
import subprocess
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import test_fixture_policy_archive as public_fixtures
import run_fixture_startup_sequence as sequence

archive = public_fixtures.archive
daemon, launcher = sequence.daemon, sequence.launcher
encode, digest = public_fixtures.encode, public_fixtures.digest


class DaemonArchiveControls(unittest.TestCase):
    event = staticmethod(public_fixtures.ArchiveReader.event)
    metadata = staticmethod(public_fixtures.ArchiveReader.metadata)
    bundle = public_fixtures.ArchiveReader.bundle
    write_pages = public_fixtures.ArchiveReader.write_pages

    def setUp(self):
        public_fixtures.ArchiveReader.setUp(self)
        self.context["original"]["returncode"] = 0
        self.admitted = copy.deepcopy(self.context["calibrations"])
        self.evidence = SimpleNamespace(root=self.root, directory=self.root / self.run, stream=Mock())
        self.install()

    def install(self):
        self.index, self.pages = self.bundle([self.entries[:2], self.entries[2:]])
        self.write_pages()
        raw = encode(self.index)
        (self.evidence.directory / archive.INDEX_FILE).write_bytes(raw)
        self.published = dict(index=copy.deepcopy(self.index), sha256=digest(raw))
        return raw

    def retained(self, result=None):
        return sequence.retained_daemon_publication(
            self.evidence, self.published, self.admitted,
            dict(self.context["original"]) if result is None else result)

    def test_legacy_transport_rejects_without_compatibility_fallback(self):
        legacy = dict(receipt={}, sha256="0" * 64)
        with patch.object(archive, "consume", side_effect=AssertionError("legacy transport reached consumer")), \
                self.assertRaises(ValueError):
            daemon._checked_publication(legacy)
        with patch.object(archive.analysis, "read_local", side_effect=AssertionError("legacy transport read input")), \
                self.assertRaises(ValueError):
            sequence.retained_daemon_publication(self.evidence, legacy, self.admitted, self.context["original"])

    def test_actual_index_context_and_returned_object_must_match_the_iteration(self):
        self.assertEqual(self.retained(), self.published)
        for field, value in (("returncode", 7), ("timeout", True), ("released", False), ("leader_reaped", False)):
            result = dict(self.context["original"])
            result[field] = value
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "admitted sequence iteration"):
                self.retained(result)
        self.published["index"]["context"]["original"]["returncode"] = 7
        with self.assertRaisesRegex(ValueError, "admitted sequence iteration"):
            self.retained()
        self.install()
        self.context["calibrations"][0]["run"] += "-different"
        self.install()
        with self.assertRaisesRegex(ValueError, "admitted sequence iteration"):
            self.retained()

    def test_rehashed_failed_or_unknown_context_never_qualifies_a_completed_iteration(self):
        original = copy.deepcopy(self.context)
        changes = [("original", "returncode", 7), ("original", "timeout", True),
                   ("original", "released", None), ("original", "leader_reaped", False),
                   ("collector", "returncode", 1), ("collector", "reported_failure", True),
                   ("collector", "leader_reaped", None), ("collector", "forced_kill", True)]
        for group, field, value in changes:
            self.context = copy.deepcopy(original)
            self.context[group][field] = value
            self.install()
            with self.subTest(group=group, field=field), patch.object(daemon, "ROOT", self.root):
                # Failed evidence is still a valid standalone archive.
                self.assertEqual(daemon._checked_publication(self.published), self.published)
                with self.assertRaisesRegex(ValueError, "unsuccessful original or collector"):
                    daemon._checked_publication(self.published, successful_iteration=True)
                with self.assertRaisesRegex(ValueError, "unsuccessful original or collector"):
                    self.retained()

    def test_public_output_rejects_changed_calibration_between_individually_valid_indexes(self):
        first = copy.deepcopy(self.published)
        self.run += "-next"
        self.context["run"] = self.run
        self.context["calibrations"][0]["run"] += "-different"
        self.evidence.directory = self.root / self.run
        self.install()
        outcome = dict(reason="invocation_limit", completed_invocations=2, capture_received=False,
                       qualification="not_claimed", unobserved_descendants="unknown",
                       publications=[first, self.published])
        output = io.StringIO()
        with patch.object(daemon, "ROOT", self.root), contextlib.redirect_stdout(output), \
                self.assertRaisesRegex(ValueError, "change calibration"):
            daemon._emit_sequence(outcome, 2)
        self.assertEqual(output.getvalue(), "")

    def test_large_valid_index_keeps_the_existing_journal_event_bound(self):
        self.context["sources"] = [dict(
            path=".artifacts/tmp/process-supervisor-tests/" + "%02d" % number + "/" + "p" * 240,
            sha256=digest(str(number).encode()), size_bytes=1, token="%016x" % (number + 1))
            for number in range(64)]
        raw = self.install()
        archive.read_index(raw, self.published["sha256"])
        self.assertGreater(len(raw), 16384)
        self.assertLessEqual(len(raw), archive.MAX_INDEX_BYTES)
        self.assertEqual(launcher.observer.MAX_EVENT_BYTES, 16384)
        journal = launcher.observer.Evidence(self.root)
        self.addCleanup(journal.stream.close)
        with self.assertRaisesRegex(ValueError, "fixed storage bound"):
            journal.record("counterfactual_embedded_index", **self.published)
        session = SimpleNamespace(helper={"pid": 1}, directory=self.root / ".artifacts/logs/helper", submitted=False)
        result = dict(self.context["original"])
        with patch.object(archive.associations, "calibration_snapshot", return_value=self.admitted), \
                patch.object(launcher, "require_ready"), patch.object(launcher, "stop_helper") as stop, \
                patch.object(launcher.observer, "Evidence", return_value=self.evidence), \
                patch.object(sequence, "settled_iteration"), patch.object(sequence, "MAX_INVOCATIONS", 1), \
                patch.object(daemon, "run", return_value=dict(original=result, publication=self.published)), \
                patch.object(subprocess, "Popen", side_effect=AssertionError("portable journal test launched a process")):
            try:
                outcome = sequence.run_sequence(session, object(), journal, self.root,
                                                 target_family="rust", calibrations=[self.admitted[0]["run"]])
            except ValueError as error:
                self.fail("valid large archive must retain a bounded journal anchor: " + str(error))
        stop.assert_called_once_with(session)
        self.assertEqual(outcome["publications"], [self.published])
        journal.stream.flush()
        lines = (journal.directory / "observations.jsonl").read_bytes().splitlines(keepends=True)
        self.assertTrue(all(len(line) <= 16384 for line in lines))
        anchors = [json.loads(line) for line in lines if json.loads(line)["event"] == "iteration_publication"]
        self.assertEqual(len(anchors), 1)
        anchor = anchors[0]
        self.assertEqual(set(anchor), {"event", "monotonic_ns", "number", "schema", "index_path", "sha256"})
        self.assertEqual(anchor["schema"], "fsmgen.fixture_policy_archive.v1")
        self.assertEqual(anchor["index_path"], self.run + "/policy-archive.json")
        self.assertEqual(anchor["sha256"], digest(raw))
        self.assertEqual(archive.consume((self.root / anchor["index_path"]).read_bytes(), anchor["sha256"], self.root)["index"], self.index)


if __name__ == "__main__":
    unittest.main()
