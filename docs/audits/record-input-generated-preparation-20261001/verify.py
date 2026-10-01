#!/usr/bin/env python3
"""Authenticate saved preparation receipts; never execute HDL."""
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def validate(red, focused, final, verbose):
    assert "not ok 22 - domains explicit output binding is completion-guarded" in red
    assert "Expected child source file: 'packed_input_generated_domains__domain_idle.fsm'" in red
    assert "Files=1, Tests=1," in red and "Result: FAIL" in red
    assert "All tests successful." in focused and "Files=5, Tests=23," in focused
    assert "All tests successful." in final and "Files=2, Tests=6," in final
    assert "Result: PASS" in focused and "Result: PASS" in final
    assert "All tests successful." in verbose and "Files=1, Tests=4," in verbose
    assert "# SKIP fixed generated observer and explicit runtime admission required" in verbose
    assert "not ok" not in verbose


def main():
    manifest = json.loads((HERE / "manifest.json").read_bytes())
    assert manifest["schema"] == "fsmgen.generated_record_input_witness_preparation.v1"
    assert manifest["feature_runtime"] == "not_executed"
    actual = {str(p.relative_to(HERE)) for p in HERE.rglob("*") if p.is_file() and p.name != "manifest.json"}
    assert set(manifest["sha256"]) == actual
    for name, expected in manifest["sha256"].items():
        assert digest((HERE / name).read_bytes()) == expected
    for name, record in manifest["inputs"].items():
        path = ROOT / name
        data = path.read_bytes() if path.is_file() else b""
        if digest(data) != record["sha256"]:
            data = subprocess.check_output(["git", "cat-file", "blob", record["git_blob"]], cwd=ROOT)
        assert digest(data) == record["sha256"], name
    args = tuple((HERE / name).read_text() for name in ("first-red.txt", "focused.txt", "final.txt", "verbose-final.txt"))
    validate(*args)
    for index in range(4):
        bad = list(args)
        bad[index] = "unrelated result"
        try:
            validate(*bad)
        except AssertionError:
            continue
        raise AssertionError("unrelated preparation receipt accepted")
    print("Initial draft scope/path errors and final complete static preparation receipts authenticated; corrupt saved receipts reject. Feature HDL runtime remains unqualified.")


if __name__ == "__main__":
    main()
