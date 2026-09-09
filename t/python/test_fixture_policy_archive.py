"""Independent archive fixtures, ordered reconstruction and hostile readers."""

import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
try:
    import fixture_policy_archive as archive
finally:
    sys.path.pop(0)


def encode(value):
    return (json.dumps(value, sort_keys=True, ensure_ascii=True,
                       separators=(",", ":"), allow_nan=False) + "\n").encode("ascii")


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


class ArchiveReader(unittest.TestCase):
    def setUp(self):
        temporary = ROOT / ".artifacts/tmp/policy-archive-tests"
        temporary.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=temporary)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.run = ".artifacts/logs/target"
        identity = dict(bytes=7, sha256=digest(b"fixture"))
        inputs = {name: dict(identity) for name in (
            "observations.jsonl", "policy.stdout", "policy-result.json", "test-result.json")}

        def source(name, token):
            return dict(path=".artifacts/tmp/process-supervisor-tests/f/" + name,
                        sha256=digest(name.encode()), size_bytes=len(name), token=token)

        self.context = dict(run=self.run, inputs=inputs,
            sources=[source("target", "3" * 16)],
            calibrations=[dict(run=".artifacts/logs/calibration", inputs=copy.deepcopy(inputs),
                pairs=[source("calibration-a", "1" * 16), source("calibration-b", "2" * 16)])],
            producers={name: dict(identity) for name in (
                "scripts/analyze_fixture_policy.py", "scripts/fixture_policy_associations.py",
                "scripts/fixture_policy_diagnostics.py", "scripts/fixture_policy_archive.py")},
            scope="daemon_context",
            original=dict(returncode=1, timeout=False, released=True, leader_reaped=True),
            collector=dict(returncode=-2, reported_failure=False, leader_reaped=True, forced_kill=False))
        self.entries = [self.event("queued", b"first"), self.metadata(b"metadata"),
                        self.event("started", b"second"), self.event("wakeups", b"third")]
        self.index, self.pages = self.bundle([self.entries[:2], self.entries[2:]])

    @staticmethod
    def metadata(raw):
        return dict(kind="metadata", sha256=digest(raw))

    @staticmethod
    def event(phase, raw):
        return dict(kind="log_event", sha256=digest(raw), tokens=["3" * 16], phase=phase,
            context=dict(process_id=677, thread_id=991, activity_id=None, mach_timestamp=123456,
                         timestamp="2026-09-09 20:54:41.603439+0200", subsystem="execution_policy"))

    def bundle(self, chunks):
        context = copy.deepcopy(self.context)
        binding = digest(encode(context))
        descriptors, pages = [], []
        first = logs = metadata = 0
        for number, chunk in enumerate(chunks, 1):
            page = dict(schema="fsmgen.fixture_policy_archive_page.v1", context_sha256=binding,
                        first_record=first, records=copy.deepcopy(chunk))
            raw = encode(page)
            count = sum(record["kind"] == "log_event" for record in chunk)
            descriptors.append(dict(path=self.run + "/policy-archive-%04d.json" % number,
                bytes=len(raw), sha256=digest(raw), first_record=first,
                record_count=len(chunk), log_event_count=count, metadata_count=len(chunk) - count))
            first += len(chunk)
            logs += count
            metadata += len(chunk) - count
            pages.append(raw)
        index = dict(schema="fsmgen.fixture_policy_archive.v1", context=context,
            context_sha256=binding, pages=descriptors, record_count=first, log_event_count=logs,
            metadata_count=metadata, limits=dict(archive.LIMITS))
        return index, pages

    def write_pages(self, index=None, pages=None, root=None):
        index = self.index if index is None else index
        pages = self.pages if pages is None else pages
        root = self.root if root is None else root
        for descriptor, raw in zip(index["pages"], pages):
            path = root / descriptor["path"]
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(raw)

    def consume(self, index=None, root=None):
        index = self.index if index is None else index
        raw = encode(index)
        return archive.consume(raw, digest(raw), self.root if root is None else root)

    def test_relocated_consumer_reconstructs_exact_order_without_private_or_native_reads(self):
        destination = self.root / "moved"
        self.write_pages(root=destination)
        self.assertFalse((destination / "scripts").exists())
        reads = []
        read = archive.analysis.read_local
        allowed = {destination / item["path"] for item in self.index["pages"]}

        def public_only(path, root, maximum):
            self.assertIn(path, allowed)
            self.assertEqual(maximum, 2097152)
            reads.append(path)
            return read(path, root, maximum)

        with patch.object(archive.analysis, "read_local", side_effect=public_only), \
                patch.object(archive.analysis, "NativePathHash", side_effect=AssertionError("native read")), \
                patch.object(subprocess, "Popen", side_effect=AssertionError("process launch")):
            result = self.consume(root=destination)
        actual = [entry for page in result["pages"] for entry in page["records"]]
        self.assertEqual(actual, self.entries)
        self.assertEqual([entry["sha256"] for entry in actual],
                         [digest(value) for value in (b"first", b"metadata", b"second", b"third")])
        self.assertEqual(result["index"]["context"]["original"]["returncode"], 1)
        self.assertEqual(reads, [destination / item["path"] for item in self.index["pages"]])
        self.assertEqual(result["index"]["limits"]["authority"], "separately_pinned_index_not_authentication")
        self.assertEqual(result["index"]["limits"]["complete_coverage"], "unproved")

    def test_index_order_counts_paths_and_unknown_fields_reject_even_with_new_anchor(self):
        variants = []
        for mutate in (
            lambda x: x["pages"].reverse(),
            lambda x: x["pages"].pop(),
            lambda x: x["pages"].append(copy.deepcopy(x["pages"][0])),
            lambda x: x["pages"][1].update(first_record=1),
            lambda x: x["pages"][1].update(first_record=3),
            lambda x: x["pages"][1].update(path=self.run + "/policy-archive-0001.json"),
            lambda x: x["pages"][0].update(path=".artifacts/logs/foreign/policy-archive-0001.json"),
            lambda x: x["pages"][0].update(path=".artifacts/logs/../outside"),
            lambda x: x.update(record_count=True),
            lambda x: x.update(metadata_count=0),
            lambda x: x["pages"][0].update(record_count=0, log_event_count=0, metadata_count=0),
            lambda x: x["pages"][0].update(record_count=1.0),
            lambda x: x.update(private="unadmitted"),
            lambda x: x["limits"].update(complete_coverage="proved"),
        ):
            changed = copy.deepcopy(self.index)
            mutate(changed)
            variants.append(changed)
        with patch.object(archive.analysis, "read_local", side_effect=AssertionError("invalid index read a page")):
            for number, changed in enumerate(variants):
                with self.subTest(number=number), self.assertRaises(ValueError):
                    self.consume(changed)

    def test_context_domains_calibration_and_binding_reject(self):
        mutations = (
            lambda x: x.update(scope="execution_context"),
            lambda x: x["original"].update(returncode=True),
            lambda x: x["original"].update(timeout=0),
            lambda x: x["collector"].update(reported_failure=1),
            lambda x: x["collector"].update(leader_reaped="yes"),
            lambda x: x["sources"].append(copy.deepcopy(x["sources"][0])),
            lambda x: x["calibrations"].append(copy.deepcopy(x["calibrations"][0])),
            lambda x: x["calibrations"][0].update(run=self.run),
            lambda x: x["calibrations"][0]["pairs"].reverse(),
            lambda x: x["calibrations"][0]["pairs"][0].update(token="3"),
            lambda x: x["producers"].pop("scripts/fixture_policy_archive.py"),
            lambda x: x["inputs"]["policy.stdout"].update(bytes=16777217),
        )
        for number, mutate in enumerate(mutations):
            changed = copy.deepcopy(self.index)
            mutate(changed["context"])
            changed["context_sha256"] = digest(encode(changed["context"]))
            with self.subTest(number=number), self.assertRaises(ValueError):
                archive.read_index(encode(changed), digest(encode(changed)))
        changed = copy.deepcopy(self.index)
        changed["context"]["original"]["returncode"] = 0
        with self.assertRaisesRegex(ValueError, "context disagrees"):
            archive.read_index(encode(changed), digest(encode(changed)))

    def test_page_shape_context_range_and_entry_domains_reject_after_rehash(self):
        original = json.loads(self.pages[0])
        mutations = (
            lambda p: p.update(context_sha256="f" * 64),
            lambda p: p.update(first_record=True),
            lambda p: p.update(first_record=1),
            lambda p: p.update(extra="private"),
            lambda p: p["records"][1].update(raw="private metadata"),
            lambda p: p["records"][1].update(kind="other"),
            lambda p: p["records"][0].update(tokens=["f" * 16, "3" * 16]),
            lambda p: p["records"][0].update(tokens=["3" * 16] * 2),
            lambda p: p["records"][0].update(tokens=["abc"]),
            lambda p: p["records"][0].update(phase="completed"),
            lambda p: p["records"][0]["context"].update(thread_id=True),
            lambda p: p["records"][0]["context"].update(thread_id=1 << 64),
            lambda p: p["records"][0]["context"].update(process_id=-1),
            lambda p: p["records"][0]["context"].update(timestamp="2026-02-30 01:00:00.000000+0000"),
            lambda p: p["records"][0]["context"].update(subsystem="private"),
            lambda p: p["records"].pop(),
        )
        for number, mutate in enumerate(mutations):
            page = copy.deepcopy(original)
            mutate(page)
            raw = encode(page)
            descriptor = self.index["pages"][0] | dict(bytes=len(raw), sha256=digest(raw))
            with self.subTest(number=number), self.assertRaises(ValueError):
                archive.read_page(raw, descriptor, self.index["context_sha256"])

    def test_missing_changed_and_foreign_pages_fail_against_the_separate_anchor(self):
        self.write_pages()
        first = self.root / self.index["pages"][0]["path"]
        first.unlink()
        with self.assertRaises(FileNotFoundError):
            self.consume()
        first.write_bytes(self.pages[1])
        with self.assertRaisesRegex(ValueError, "pinned digest"):
            self.consume()
        page = json.loads(self.pages[0])
        page["records"].reverse()
        first.write_bytes(encode(page))
        with self.assertRaisesRegex(ValueError, "pinned digest"):
            self.consume()
        changed = copy.deepcopy(self.index)
        changed["pages"][0]["sha256"] = digest(first.read_bytes())
        anchor = digest(encode(self.index))
        with self.assertRaisesRegex(ValueError, "pinned digest"):
            archive.consume(encode(changed), anchor, self.root)

    def test_reanchored_descriptor_kind_counts_must_match_actual_entries(self):
        self.write_pages()
        changed = copy.deepcopy(self.index)
        changed["pages"][0].update(log_event_count=2, metadata_count=0)
        changed.update(log_event_count=4, metadata_count=0)
        with self.assertRaisesRegex(ValueError, "descriptor counts"):
            self.consume(changed)

    def test_page_paths_reject_indirection_and_wrong_regular_file_type(self):
        self.write_pages()
        path = self.root / self.index["pages"][0]["path"]
        saved = self.root / "saved-page.json"
        path.rename(saved)
        path.symlink_to(saved)
        with self.assertRaisesRegex(ValueError, "indirect"):
            self.consume()
        path.unlink()
        path.mkdir()
        with self.assertRaisesRegex(ValueError, "regular file"):
            self.consume()

    def test_foreign_volume_rejects_before_reading_a_page(self):
        stat = Path.stat
        device = self.root.stat().st_dev

        def other_volume(path, *args, **kwargs):
            if path == self.root:
                return SimpleNamespace(st_dev=device + 1)
            return stat(path, *args, **kwargs)

        with patch.object(Path, "stat", autospec=True, side_effect=other_volume), \
                patch.object(archive.analysis, "read_local", side_effect=AssertionError("foreign read")):
            with self.assertRaisesRegex(ValueError, "repository volume"):
                self.consume()

    def test_exact_record_and_page_cardinality_boundaries(self):
        chunk = [self.metadata(b"same metadata") for _ in range(4096)]
        index, pages = self.bundle([chunk] * 16)
        self.write_pages(index, pages)
        result = self.consume(index)
        self.assertEqual(sum(len(p["records"]) for p in result["pages"]), 65536)
        self.assertEqual(len(result["pages"]), 16)
        self.assertEqual(result["index"]["metadata_count"], 65536)
        excess_index, _ = self.bundle([chunk] * 17)
        with self.assertRaisesRegex(ValueError, "cardinality"):
            archive.read_index(encode(excess_index), digest(encode(excess_index)))
        excess_index, excess_pages = self.bundle([chunk + chunk[:1]])
        with self.assertRaises(ValueError):
            archive.read_page(excess_pages[0], excess_index["pages"][0], excess_index["context_sha256"])

    def test_raw_byte_caps_precede_decode_and_valid_large_page_rejects(self):
        oversized = b" " * 2097153
        with patch.object(archive.analysis, "decode_json", side_effect=AssertionError("oversized decode")):
            with self.assertRaisesRegex(ValueError, "byte bound"):
                archive.read_index(oversized, digest(oversized))
            descriptor = self.index["pages"][0] | dict(bytes=2097152, sha256=digest(oversized))
            with self.assertRaisesRegex(ValueError, "byte bound"):
                archive.read_page(oversized, descriptor, self.index["context_sha256"])
        large = self.event("queued", b"full")
        large["tokens"] = ["%016x" % i for i in range(16)]
        index, pages = self.bundle([[large] * 4096])
        self.assertGreater(len(pages[0]), 2097152)
        with self.assertRaises(ValueError):
            archive.validate_page(json.loads(pages[0]), index["pages"][0], index["context_sha256"])

    def test_exact_canonical_page_byte_boundary_and_adjacent_excess(self):
        # Independently size valid entries; variable integer spellings bridge
        # token-list length steps without introducing padding or unknown keys.
        choices = {}
        for tokens in range(17):
            for digits in range(1, 20):
                entry = self.event("queued", b"byte boundary")
                entry["tokens"] = ["%016x" % number for number in range(tokens)]
                entry["context"]["thread_id"] = 10 ** digits - 1
                choices[len(encode(entry)) - 1] = entry
        maximum = max(choices)
        _, empty_pages = self.bundle([[]])
        overhead = len(empty_pages[0])
        full_count = (2097152 - overhead) // (maximum + 1) - 2
        remaining = 2097152 - (overhead + full_count * (maximum + 1) - 1)
        metadata = self.metadata(b"byte accounting")
        metadata_cost = len(encode(metadata))
        match = next((count, remaining - count * metadata_cost - 1)
                     for count in range(20)
                     if remaining - count * metadata_cost - 1 in choices)
        entries = [choices[maximum]] * full_count + [metadata] * match[0] + [choices[match[1]]]
        index, pages = self.bundle([entries])
        self.assertLessEqual(len(entries), 4096)
        self.assertEqual(len(pages[0]), 2097152)
        self.write_pages(index, pages)
        self.assertEqual(self.consume(index)["pages"][0]["records"], entries)
        page = json.loads(pages[0])
        page["first_record"] = 10  # One extra canonical byte, still an admitted integer.
        excess = encode(page)
        self.assertEqual(len(excess), 2097153)
        descriptor = index["pages"][0] | dict(first_record=10, bytes=len(excess), sha256=digest(excess))
        with self.assertRaises(ValueError):
            archive.read_page(excess, descriptor, index["context_sha256"])

    def test_duplicate_json_noncanonical_encoding_and_nonfinite_numbers_reject(self):
        raw = encode(self.index)
        variants = [raw.replace(b'"schema":', b'"schema":"duplicate","schema":', 1),
                    json.dumps(self.index, indent=2).encode(), raw + b" ",
                    raw.replace(b'"record_count":4', b'"record_count":NaN', 1)]
        for altered in variants:
            self.assertNotEqual(altered, raw)
            with self.subTest(altered=altered[:60]), self.assertRaises(ValueError):
                archive.read_index(altered, digest(altered))


if __name__ == "__main__":
    unittest.main()
