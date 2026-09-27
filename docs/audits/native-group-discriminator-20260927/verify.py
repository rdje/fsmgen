#!/usr/bin/env python3
"""Verify retained native observations and reject controlled evidence corruption."""
import copy
import errno
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def validate(rows):
    expected = [(mode, 0) for mode in (
        "child_only", "parent_first", "child_first", "session_leader"
    )] + [("simultaneous", index) for index in range(64)]
    assert [(row["mode"], row["trial"]) for row in rows] == expected
    identities = set()
    for row in rows:
        before, after = row["before"], row["after"]
        pid = before["pid"]
        assert pid > 0 and pid not in identities
        identities.add(pid)
        assert before["ppid"] == after["ppid"] > 0
        for phase in ("before", "after"):
            child, parent = row[phase], row["parent_" + phase]
            assert child["pid"] == parent["pid"] == pid
            for field in ("pgid", "sid"):
                assert child[field] == parent[field] > 0
                assert child[field + "_errno"] == parent[field + "_errno"] == 0
        assert before["sid"] == after["sid"]
        assert after["pgid"] == pid
        if row["mode"] == "session_leader":
            assert before["sid"] == before["pgid"] == pid
            assert row["child_result"] == -1 and row["child_errno"] == errno.EPERM
        else:
            assert before["sid"] != pid and before["pgid"] != pid
            assert row["child_result"] == 0 and row["child_errno"] == 0
        called = row["mode"] in ("parent_first", "child_first", "simultaneous")
        assert row["parent_called"] == int(called)
        assert row["parent_result"] == row["parent_errno"] == 0
        assert row["wait_status"] == 0
        assert row["post_wait_kill_result"] == -1
        assert row["post_wait_kill_errno"] == errno.ESRCH


def main():
    manifest = json.loads((ROOT / "manifest.json").read_text())
    for name, expected in manifest["sha256"].items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == expected, name
    rows = [json.loads(line) for line in (ROOT / "result.jsonl").read_text().splitlines()]
    validate(rows)
    mutations = []
    missing = copy.deepcopy(rows)
    missing.pop()
    mutations.append(missing)
    wrong_session = copy.deepcopy(rows)
    wrong_session[3]["parent_after"]["sid"] += 1
    mutations.append(wrong_session)
    admitted_failure = copy.deepcopy(rows)
    admitted_failure[3]["child_result"] = 0
    mutations.append(admitted_failure)
    stale_errno = copy.deepcopy(rows)
    stale_errno[0]["child_errno"] = errno.EPERM
    mutations.append(stale_errno)
    unreaped = copy.deepcopy(rows)
    unreaped[0]["wait_status"] = 256
    mutations.append(unreaped)
    alive = copy.deepcopy(rows)
    alive[0]["post_wait_kill_result"] = 0
    mutations.append(alive)
    for mutation in mutations:
        try:
            validate(mutation)
        except AssertionError:
            continue
        raise AssertionError("corrupt native evidence was accepted")
    print("Native timing evidence verified; corruption controls rejected.")
    print("Original T1972 cause remains unproved; no repair or runtime qualification follows.")


if __name__ == "__main__":
    main()
