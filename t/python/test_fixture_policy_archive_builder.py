"""Complete retained-input reconstruction and hostile calibrated archive builds."""

import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

import test_fixture_daemon_associations as fixtures
from test_fixture_policy_archive import encode, digest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
try:
    import fixture_policy_archive as archive
finally:
    sys.path.pop(0)


class ArchiveBuilder(unittest.TestCase):
    event = staticmethod(fixtures.DaemonAssociations.event)
    make_run = fixtures.DaemonAssociations.make_run
    save = fixtures.DaemonAssociations.save

    def setUp(self):
        fixtures.DaemonAssociations.setUp(self)

    def write_rows(self, rows):
        path = self.directory / "policy.stdout"
        path.write_bytes(b'Filtering the log data using "process == "syspolicyd""\n'
                         + b"\n".join(encode(row).rstrip(b"\n") for row in rows) + b"\n")
        self.save()

    def build(self, mapping=None):
        return archive.build(self.target, [self.calibration], self.root,
                             self.mapping.__getitem__ if mapping is None else mapping)

    def file_inventory(self):
        return {str(p.relative_to(self.root)): (p.stat().st_size, digest(p.read_bytes()))
                for p in self.root.rglob("*") if p.is_file()}

    def checked_entries(self, built):
        raw = encode(built["index"])
        index = archive.read_index(raw, digest(raw))
        pages = [archive.read_page(raw, descriptor, index["context_sha256"])
                 for raw, descriptor in zip(built["page_bytes"], index["pages"])]
        return [entry for page in pages for entry in page["records"]]

    def test_large_ordered_capture_preserves_late_progress_metadata_and_failed_original(self):
        queued = self.event("queueing up scan: PST: (path: " + self.tokens[2] + ")")
        started = self.event("starting work for scan: PST: (path: " + self.tokens[2] + ")")
        wakeup = self.event("scan finished, waking: PST: (path: " + self.tokens[2] + ")")
        started.update(threadID=991, timestamp="2026-09-09 20:54:41.603439+0200")
        rows = [queued, {"private_metadata": "secret", "ordinal": 1}]
        rows += [self.event("unrelated daemon context " + str(i)) for i in range(5000)]
        rows += [started, {"metadata_after_start": True}, wakeup]
        self.write_rows(rows)
        before = self.file_inventory()
        with patch.object(subprocess, "Popen", side_effect=AssertionError("no launches")), \
                patch.object(archive.associations, "publish_bytes", side_effect=AssertionError("no publication")):
            built = self.build()
        entries = self.checked_entries(built)
        self.assertEqual(len(entries), len(rows))
        self.assertEqual([entry["sha256"] for entry in entries], [digest(encode(row)) for row in rows])
        self.assertEqual([entry["kind"] for entry in entries],
                         ["log_event" if row.get("eventType") == "logEvent" else "metadata" for row in rows])
        self.assertEqual(entries[1], dict(kind="metadata", sha256=digest(encode(rows[1]))))
        self.assertEqual([(i, entry["phase"]) for i, entry in enumerate(entries)
                          if entry.get("tokens") == [self.tokens[2]]],
                         [(0, "queued"), (5002, "started"), (5004, "wakeups")])
        self.assertEqual(entries[5002]["context"]["thread_id"], 991)
        self.assertEqual([d["record_count"] for d in built["index"]["pages"]], [4096, 909])
        self.assertEqual(built["index"]["context"]["original"]["returncode"], 2)
        self.assertEqual(built["index"]["metadata_count"], 2)
        public = encode(built["index"]) + b"".join(built["page_bytes"])
        for private in (b"secret", b"unrelated daemon context", str(self.root).encode(), b"eventMessage"):
            self.assertNotIn(private, public)
        self.assertEqual(self.file_inventory(), before)
        # The separate frozen contract still rejects this larger stream.
        with self.assertRaisesRegex(ValueError, "retained policy exceeds its event bound"):
            archive.analysis.load_daemon_capture(self.target, self.root)

    def test_small_projection_matches_frozen_v1_without_changing_its_schema(self):
        legacy = archive.associations.seal_daemon_capture(
            self.target, [self.calibration], self.root, self.mapping.__getitem__)
        legacy_raw = encode(legacy)
        report = archive.diagnostics.export(legacy_raw, digest(legacy_raw), self.target, self.root)
        built = self.build()
        entries = self.checked_entries(built)
        self.assertEqual([{k: entry[k] for k in ("sha256", "tokens", "phase", "context")}
                          for entry in entries if entry["kind"] == "log_event"], report["records"])
        self.assertEqual(built["index"]["context"]["inputs"], legacy["target"]["inputs"])
        self.assertEqual(built["index"]["context"]["sources"], legacy["target"]["sources"])
        self.assertEqual(built["index"]["context"]["calibrations"], legacy["calibrations"])
        self.assertEqual(legacy["schema"], "fsmgen.fixture_policy_associations.v1")
        self.assertEqual(archive.analysis.MAX_EVENTS, 4096)
        self.assertEqual(self.build(), built)

    def test_packing_splits_on_bytes_before_the_record_boundary(self):
        tokens = ["%016x" % number for number in range(16)]
        message = " ".join("PST: (path: " + token + ")" for token in tokens)
        event = self.event(message)
        event.update(threadID=(1 << 64) - 1, machTimestamp=(1 << 64) - 1,
                     activityIdentifier=(1 << 64) - 1, processID=(1 << 31) - 1,
                     timestamp="2026-09-09 20:54:41.603439+0200")
        rows = [event] * 4096
        self.write_rows(rows)
        built = self.build()
        self.assertGreater(len(built["page_bytes"]), 1)
        self.assertLess(built["index"]["pages"][0]["record_count"], 4096)
        first = json.loads(built["page_bytes"][0])
        self.assertLessEqual(len(encode(first)), 2097152)
        first["records"].append(self.checked_entries(built)[-1])
        self.assertGreater(len(encode(first)), 2097152)
        self.assertEqual([entry["sha256"] for entry in self.checked_entries(built)],
                         [digest(encode(event))] * 4096)

    def test_exact_combined_record_envelope_and_adjacent_excess(self):
        metadata = {"counted_metadata": True}
        self.write_rows([metadata] * 65536)
        built = self.build()
        self.assertEqual(len(built["page_bytes"]), 16)
        self.assertEqual(built["index"]["record_count"], 65536)
        self.assertEqual(built["index"]["metadata_count"], 65536)
        self.assertEqual(built["index"]["log_event_count"], 0)
        self.write_rows([metadata] * 65537)
        with self.assertRaisesRegex(ValueError, "combined record bound"):
            self.build()
        self.assertFalse(list(self.directory.glob("policy-archive*")))

    def test_packer_rejects_page_envelope_exhaustion_without_returning_partial_data(self):
        # A producer-private packing oracle isolates the page limit from the
        # separate raw byte/cardinality deciders; no public bound is widened.
        from test_fixture_policy_archive import ArchiveReader
        entry = ArchiveReader.event("queued", b"full page")
        entry["tokens"] = ["%016x" % number for number in range(16)]
        with self.assertRaisesRegex(ValueError, "page-count bound"):
            archive._pack_pages([entry] * 65536, "1" * 64, self.target)

    def test_invalid_raw_rows_tokens_and_outcome_shapes_reject(self):
        for rows in ([], [None], [dict(eventType="logEvent")],
                     [self.event("PST: (path: +1)")],
                     [self.event(" ".join("PST: (path: %x)" % i for i in range(17)))]):
            self.write_rows(rows)
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                self.build()
        self.write_rows(self.target_records)
        result = self.directory / "test-result.json"
        for original in ([], {"returncode": True, "timeout": False}, {"returncode": 0, "timeout": 0}):
            result.write_bytes(encode(original))
            with self.subTest(original=original), self.assertRaises(ValueError):
                self.build()

    def test_native_calibration_collisions_and_literal_contradictions_reject(self):
        changed = dict(self.mapping)
        changed[self.capture_root + "/" + self.paths[0]] = "f" * 16
        with self.assertRaisesRegex(ValueError, "literal policy calibration"):
            self.build(changed.__getitem__)
        changed = dict(self.mapping)
        changed[self.capture_root + "/" + self.paths[3]] = self.tokens[2]
        with self.assertRaisesRegex(ValueError, "colliding tokens"):
            self.build(changed.__getitem__)
        self.write_rows([self.event("PST: (path: " + "f" * 16 + ") file://"
                                   + self.capture_root + "/" + self.paths[2])])
        with self.assertRaisesRegex(ValueError, "contradicts calibrated attribution"):
            self.build()

    def test_source_capture_and_calibration_mutations_are_detected_before_return(self):
        original_result = (self.directory / "test-result.json").read_bytes()
        def change_original(path):
            if path == self.capture_root + "/" + self.paths[-1]:
                (self.directory / "test-result.json").write_bytes(encode(dict(returncode=0, timeout=False)))
            return self.mapping[path]
        with self.assertRaisesRegex(ValueError, "private capture changed"):
            self.build(change_original)
        (self.directory / "test-result.json").write_bytes(original_result)
        calibration_result = self.root / self.calibration / "test-result.json"
        def change_calibration(path):
            if path == self.capture_root + "/" + self.paths[-1]:
                calibration_result.write_bytes(encode(dict(returncode=0, timeout=False)))
            return self.mapping[path]
        with self.assertRaisesRegex(ValueError, "calibration changed"):
            self.build(change_calibration)
        source = next(self.directory.glob("*.source"))
        source.write_bytes(b"changed archive")
        with self.assertRaisesRegex(ValueError, "source archive"):
            self.build()

    def test_final_calibration_callback_and_producer_byte_changes_cannot_escape_recheck(self):
        calls = 0
        original = (self.directory / "test-result.json").read_bytes()

        def late_change(path):
            nonlocal calls
            if path == self.capture_root + "/" + self.paths[0]:
                calls += 1
                if calls == 2:
                    (self.directory / "test-result.json").write_bytes(encode(dict(returncode=0, timeout=False)))
            return self.mapping[path]

        with self.assertRaisesRegex(ValueError, "private capture changed"):
            self.build(late_change)
        self.assertEqual(calls, 2)
        (self.directory / "test-result.json").write_bytes(original)
        read = archive.analysis.read_local
        producer = archive.ROOT / "scripts/fixture_policy_archive.py"
        before = producer.read_bytes()
        reads = 0

        def changed_producer(path, *args, **kwargs):
            nonlocal reads
            raw = read(path, *args, **kwargs)
            if path == producer:
                reads += 1
                if reads == 2:
                    return raw + b"# changed producer bytes\n"
            return raw

        with patch.object(archive.analysis, "read_local", side_effect=changed_producer), \
                self.assertRaisesRegex(ValueError, "producer changed"):
            self.build()
        self.assertEqual(reads, 2)
        self.assertEqual(producer.read_bytes(), before)

    def test_whole_page_serialization_work_is_linear_in_retained_rows(self):
        rows = [self.event("bounded whole-page encoding work")] * 8200
        self.write_rows(rows)
        canonical = archive.associations.canonical
        whole_page_rows = []

        def count_pages(value):
            if type(value) is dict and value.get("schema") == "fsmgen.fixture_policy_archive_page.v1":
                whole_page_rows.append(len(value["records"]))
            return canonical(value)

        with patch.object(archive.associations, "canonical", side_effect=count_pages):
            built = self.build()
        self.assertEqual(built["index"]["record_count"], len(rows))
        # Repeated whole-page encoding after every append would exceed this
        # linear allowance by orders of magnitude. Constant revalidation fits.
        self.assertLessEqual(sum(whole_page_rows), 4 * len(rows))
        self.assertEqual(self.checked_entries(built)[-1]["sha256"], digest(encode(rows[-1])))

    def test_scope_header_and_retained_byte_hash_stay_required(self):
        original = copy.deepcopy(self.collector)
        for fields in ({"scope": "execution_context"}, {"capture_root_sha256": "f" * 64},
                       {"command": original["command"][:-1] + ["TRUEPREDICATE"]}):
            self.collector = original | fields
            self.save()
            with self.subTest(fields=fields), self.assertRaises(ValueError):
                self.build()
        self.collector = original
        path = self.directory / "policy.stdout"
        raw = path.read_bytes()
        path.write_bytes(raw.replace(b'process == "syspolicyd"', b'TRUEPREDICATE', 1))
        self.save()
        with self.assertRaisesRegex(ValueError, "header"):
            self.build()
        path.write_bytes(raw)
        self.save()
        path.write_bytes(raw + b" ")
        with self.assertRaisesRegex(ValueError, "collector manifest"):
            self.build()


if __name__ == "__main__":
    unittest.main()
