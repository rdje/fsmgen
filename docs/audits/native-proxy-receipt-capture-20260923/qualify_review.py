#!/usr/bin/env python3
"""Falsify saved-capture review with local copies; never run the compiler."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("compiler_receipt_review", HERE / "review.py")
review = importlib.util.module_from_spec(spec)
spec.loader.exec_module(review)


class SavedReview(unittest.TestCase):
    def test_saved_capture(self):
        self.assertEqual(review.verify(review.SAVED)["compiler_pid"],
                         review.read(review.SAVED / "first-state.json")[1]["private_state"]["pid"])

    def test_archived_bytes(self):
        review.verify_archive(review.SAVED)
        with tempfile.TemporaryDirectory(prefix="compiler-receipt-archive-",
                                         dir=review.ROOT / ".artifacts/tmp") as tmp:
            path = Path(tmp)
            for name in ("artifacts.json", "attempt.json", "preparation.json"):
                shutil.copyfile(review.SAVED / name, path / name)
            packet = json.loads((path / "artifacts.json").read_text())
            image = next(node for node in packet["nodes"] if node["kind"] == "file")
            image["bytes_base64"] = "AAAA" + image["bytes_base64"][4:]
            (path / "artifacts.json").write_text(json.dumps(packet))
            with self.assertRaises(AssertionError):
                review.verify_archive(path)

    def test_independent_mutations(self):
        cases = (
            ("first-state.json", lambda x: x["result"].update(exit_code=9)),
            ("first-state.json", lambda x: x["private_state"].update(pid=0)),
            ("first-state.json", lambda x: x["private_state"].update(birth_usec=1_000_000)),
            ("first-state.json", lambda x: x["observation"]["cleanup"].update(group_gone=0)),
            ("launch.json", lambda x: x["request"].update(argv=["substituted-program"])),
            ("preflight.json", lambda x: x.update(git_status_porcelain=" M unexpected")),
            ("attempt.json", lambda x: x["source_files"].update({next(iter(x["source_files"])): "0" * 64})),
        )
        for filename, mutate in cases:
            with self.subTest(filename=filename), tempfile.TemporaryDirectory(
                    prefix="compiler-receipt-review-", dir=review.ROOT / ".artifacts/tmp") as tmp:
                path = Path(tmp)
                for name in review.RECORDS:
                    shutil.copyfile(review.SAVED / name, path / name)
                review.verify(path)  # A fresh valid control precedes each mutation.
                record = json.loads((path / filename).read_text())
                mutate(record)
                (path / filename).write_text(json.dumps(record))
                with self.assertRaises(AssertionError):
                    review.verify(path)


if __name__ == "__main__":
    unittest.main()
