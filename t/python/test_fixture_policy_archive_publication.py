"""Index-last archive publication, retained failures and actual-file verification."""

import copy
import os
import shutil
import subprocess
import unittest
from unittest.mock import patch

import test_fixture_policy_archive_builder as builder_fixture

archive, encode, digest = builder_fixture.archive, builder_fixture.encode, builder_fixture.digest


class ArchivePublication(unittest.TestCase):
    event = staticmethod(builder_fixture.ArchiveBuilder.event)
    make_run = builder_fixture.ArchiveBuilder.make_run
    save = builder_fixture.ArchiveBuilder.save
    write_rows = builder_fixture.ArchiveBuilder.write_rows
    file_inventory = builder_fixture.ArchiveBuilder.file_inventory

    def setUp(self):
        builder_fixture.ArchiveBuilder.setUp(self)
        self.admitted = archive.associations.calibration_snapshot(
            [self.calibration], self.root, self.mapping.__getitem__)
        self.index_path = self.directory / archive.INDEX_FILE

    def publish(self):
        return archive.publish(self.target, [self.calibration], self.admitted,
                               self.root, self.mapping.__getitem__)

    def large_capture(self):
        rows = [self.event("context " + str(i)) for i in range(4095)]
        rows += [{"metadata": "private"}, self.event("starting work for scan: PST: (path: " + self.tokens[2] + ")")]
        self.write_rows(rows)
        return rows

    def test_all_pages_are_consumed_before_index_and_failure_flags_survive(self):
        rows = self.large_capture()
        self.collector.update(returncode=-9, failures={"error": "private failure"})
        self.save()
        before = self.file_inventory()
        writes, reads = [], []
        writer, consumer = archive.associations.publish_bytes, archive.consume
        def publish(raw, relative, root):
            self.assertFalse(self.index_path.exists())
            if relative.endswith("/" + archive.INDEX_FILE):
                self.assertEqual(len(reads), 1)
                self.assertEqual(len(writes), 2)
            else:
                self.assertEqual(reads, [])
            result = writer(raw, relative, root)
            writes.append(relative)
            return result
        def consume(raw, pin, root):
            result = consumer(raw, pin, root)
            reads.append(result)
            return result
        with patch.object(archive.associations, "publish_bytes", side_effect=publish), \
                patch.object(archive, "consume", side_effect=consume), \
                patch.object(subprocess, "Popen", side_effect=AssertionError("no process launches")):
            result = self.publish()
        index = result["index"]
        self.assertEqual(set(result), {"index", "sha256"})
        self.assertEqual(result["sha256"], digest(self.index_path.read_bytes()))
        self.assertEqual(len(reads), 2)
        self.assertEqual(reads[0], reads[1])
        self.assertEqual(index["context"]["original"]["returncode"], 2)
        self.assertEqual(index["context"]["collector"]["returncode"], -9)
        self.assertTrue(index["context"]["collector"]["reported_failure"])
        entries = [entry for page in reads[-1]["pages"] for entry in page["records"]]
        self.assertEqual([entry["sha256"] for entry in entries], [digest(encode(row)) for row in rows])
        self.assertEqual(entries[-1]["phase"], "started")
        self.assertEqual(entries[-2]["kind"], "metadata")
        self.assertEqual(writes, [d["path"] for d in index["pages"]] + [self.target + "/" + archive.INDEX_FILE])
        for name, identity in before.items():
            self.assertEqual(self.file_inventory()[name], identity)
        for relative in writes:
            self.assertEqual((self.root / relative).stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(self.directory.glob("*.pending")), [])
        self.assertFalse((self.directory / "policy-publication.json").exists())

    def test_portable_receiver_consumes_only_pinned_index_and_public_pages(self):
        self.large_capture()
        result = self.publish()
        raw = self.index_path.read_bytes()
        expected = archive.consume(raw, result["sha256"], self.root)
        moved = self.root / "receiver"
        for relative in [d["path"] for d in result["index"]["pages"]] + [self.target + "/" + archive.INDEX_FILE]:
            path = moved / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(self.root / relative, path)
        shutil.rmtree(self.root / ".artifacts")
        with patch.object(archive.analysis, "_load_capture_inputs", side_effect=AssertionError("no private reads")), \
                patch.object(archive.analysis, "NativePathHash", side_effect=AssertionError("no native reads")), \
                patch.object(subprocess, "Popen", side_effect=AssertionError("no launches")):
            self.assertEqual(archive.consume(raw, result["sha256"], moved), expected)

    def test_changed_admission_and_malformed_build_fail_before_any_publication(self):
        original = copy.deepcopy(self.admitted)
        self.admitted[0]["run"] += "-changed"
        with patch.object(archive.associations, "publish_bytes") as writer, self.assertRaises(ValueError):
            self.publish()
        writer.assert_not_called()
        self.admitted = original
        built = archive.build(self.target, [self.calibration], self.root, self.mapping.__getitem__)
        for change in (lambda b: b["page_bytes"].clear(),
                       lambda b: b["page_bytes"].append(b["page_bytes"][0]),
                       lambda b: b["page_bytes"].__setitem__(0, b["page_bytes"][0] + b" ")):
            candidate = copy.deepcopy(built)
            change(candidate)
            with patch.object(archive, "build", return_value=candidate), \
                    patch.object(archive.associations, "publish_bytes") as writer, self.assertRaises(ValueError):
                self.publish()
            writer.assert_not_called()
        self.assertFalse(self.index_path.exists())

    def test_all_fixed_existing_destinations_reject_including_unreferenced_pages(self):
        for name in [archive.INDEX_FILE, "policy-archive-0001.json", "policy-archive-0016.json"]:
            path = self.directory / name
            path.write_bytes(b"previous evidence")
            with self.subTest(name=name), patch.object(archive.associations, "publish_bytes", side_effect=AssertionError("existing evidence reached writer")) as writer, \
                    self.assertRaises(FileExistsError):
                self.publish()
            writer.assert_not_called()
            self.assertEqual(path.read_bytes(), b"previous evidence")
            path.unlink()
        self.index_path.symlink_to("absent")
        with patch.object(archive.associations, "publish_bytes", side_effect=AssertionError("existing evidence reached writer")) as writer, self.assertRaises(FileExistsError):
            self.publish()
        writer.assert_not_called()
        self.assertEqual(os.readlink(self.index_path), "absent")

    def test_second_page_failure_retains_first_page_without_index_or_retry(self):
        self.large_capture()
        writer = archive.associations.publish_bytes
        calls = []
        error = OSError("controlled second page failure")
        def fail(raw, relative, root):
            calls.append(relative)
            if len(calls) == 2:
                raise error
            return writer(raw, relative, root)
        with patch.object(archive.associations, "publish_bytes", side_effect=fail), self.assertRaises(OSError) as caught:
            self.publish()
        self.assertIs(caught.exception, error)
        self.assertEqual(len(calls), 2)
        self.assertTrue((self.root / calls[0]).is_file())
        self.assertFalse((self.root / calls[1]).exists())
        self.assertFalse(self.index_path.exists())
        with self.assertRaises(FileExistsError):
            self.publish()
        self.assertEqual(list(self.directory.glob("*.pending")), [])

    def test_replaced_directory_between_pages_stops_before_writing_into_replacement(self):
        self.large_capture()
        writer = archive.associations.publish_bytes
        saved = self.root / "saved-target"
        writes = []
        def replace(raw, relative, root):
            self.assertEqual(writes, [], "replacement must stop before another write")
            result = writer(raw, relative, root)
            writes.append(relative)
            self.directory.rename(saved)
            self.directory.mkdir()
            (self.directory / "foreign").write_bytes(b"unrelated")
            return result
        with patch.object(archive.associations, "publish_bytes", side_effect=replace), self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(len(writes), 1)
        self.assertEqual(list(p.name for p in self.directory.iterdir()), ["foreign"])
        self.assertEqual((self.directory / "foreign").read_bytes(), b"unrelated")
        self.assertTrue((saved / "policy-archive-0001.json").is_file())
        self.assertFalse((saved / archive.INDEX_FILE).exists())

    def test_corrupted_page_is_detected_before_index_publication(self):
        writer = archive.associations.publish_bytes
        def corrupt(raw, relative, root):
            result = writer(raw, relative, root)
            (root / relative).write_bytes(raw + b" ")
            return result
        with patch.object(archive.associations, "publish_bytes", side_effect=corrupt), self.assertRaises(ValueError):
            self.publish()
        self.assertFalse(self.index_path.exists())
        self.assertTrue((self.directory / "policy-archive-0001.json").exists())

    def test_false_writer_digest_rejects_page_or_index_without_deleting_complete_files(self):
        writer = archive.associations.publish_bytes
        for at_index in (False, True):
            with self.subTest(at_index=at_index):
                def wrong(raw, relative, root):
                    actual = writer(raw, relative, root)
                    return "0" * 64 if relative.endswith("/" + archive.INDEX_FILE) == at_index else actual
                try:
                    with patch.object(archive.associations, "publish_bytes", side_effect=wrong), self.assertRaises(ValueError):
                        self.publish()
                    self.assertTrue((self.directory / "policy-archive-0001.json").exists())
                    self.assertEqual(self.index_path.exists(), at_index)
                finally:
                    for path in self.directory.glob("policy-archive*.json"):
                        path.unlink()

    def test_index_write_failure_preserves_pages_and_primary_exception(self):
        writer = archive.associations.publish_bytes
        error = OSError("controlled index failure")
        def fail(raw, relative, root):
            if relative.endswith("/" + archive.INDEX_FILE):
                raise error
            return writer(raw, relative, root)
        with patch.object(archive.associations, "publish_bytes", side_effect=fail), self.assertRaises(OSError) as caught:
            self.publish()
        self.assertIs(caught.exception, error)
        self.assertTrue((self.directory / "policy-archive-0001.json").exists())
        self.assertFalse(self.index_path.exists())

    def test_index_or_page_tampering_during_final_write_is_detected_by_final_consumption(self):
        writer = archive.associations.publish_bytes
        for filename in (archive.INDEX_FILE, "policy-archive-0001.json"):
            with self.subTest(filename=filename):
                def corrupt(raw, relative, root):
                    result = writer(raw, relative, root)
                    if relative.endswith("/" + archive.INDEX_FILE):
                        with (self.directory / filename).open("ab") as stream:
                            stream.write(b" ")
                    return result
                try:
                    with patch.object(archive.associations, "publish_bytes", side_effect=corrupt), self.assertRaises(ValueError):
                        self.publish()
                    self.assertTrue(self.index_path.exists())
                finally:
                    for path in self.directory.glob("policy-archive*.json"):
                        path.unlink()



if __name__ == "__main__":
    unittest.main()
