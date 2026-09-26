#!/usr/bin/env python3
"""Replay retained public inputs into a fresh repository-local directory.

This captures current outcomes, including intended refusals. It is not feature
signoff: implementation tests decide which changed outcomes are correct.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def main():
    root = Path(__file__).resolve().parents[2]
    if len(sys.argv) not in (2, 3) or (len(sys.argv) == 3 and sys.argv[2] != "--storage-access"):
        raise SystemExit("usage: replay-specforge-feature-intake.py RELATIVE_NEW_DIRECTORY [--storage-access]")
    requested = Path(sys.argv[1])
    destination = (root / requested).resolve()
    if requested.is_absolute() or not destination.is_relative_to(root) or destination == root:
        raise SystemExit("output must be a repository-relative directory inside the repository")
    if destination.exists():
        raise SystemExit("output directory must not already exist")
    ancestor = destination.parent
    while not ancestor.exists():
        ancestor = ancestor.parent
    if ancestor.stat().st_dev != root.stat().st_dev:
        raise SystemExit("output directory must be on the repository volume")
    storage_access = len(sys.argv) == 3
    audit_name = ("specforge-storage-register-access-intake-20260926.json" if storage_access
                  else "specforge-feature-intake-20260926.json")
    audit = json.loads((root / "docs/audits" / audit_name).read_text())
    tickets = ([dict(ticket="sf-isf-storage-register-access", cases=[
        dict(source=case["source"], check=case["runs"]["check_strict"])
        for case in audit["cases"]
    ])] if storage_access else audit["tickets"])
    destination.mkdir(parents=True)

    def capture(argv):
        run = subprocess.run(argv, cwd=root, capture_output=True, text=True, timeout=90)
        return dict(argv=argv, exit_code=run.returncode,
                    stdout=run.stdout.replace(str(root) + "/", ""),
                    stderr=run.stderr.replace(str(root) + "/", ""))

    results = []
    for ticket in tickets:
        directory = destination / ticket["ticket"]
        directory.mkdir()
        for case in ticket["cases"]:
            source = directory / Path(case["source"]["path"]).name
            data = case["source"]["text"].encode("utf-8")
            if hashlib.sha256(data).hexdigest() != case["source"]["sha256"]:
                raise SystemExit("retained source hash mismatch: " + case["source"]["path"])
            source.write_bytes(data)
            relative = str(source.relative_to(root))
            check = capture(["perl", "bin/fsmgen", "--strict", "--check", "--json", relative])
            check["report"] = json.loads(check.pop("stdout"))
            if check["exit_code"] not in (0, 1):
                raise SystemExit("check process did not return an ordinary source result: " + relative)
            row = dict(ticket=ticket["ticket"], source=relative, check=check,
                       intake_check_exit=case["check"]["exit_code"])
            if check["exit_code"] == 0:
                output = source.with_suffix(".sv")
                row["generation"] = capture(["perl", "bin/fsmgen", "--strict", "--quiet",
                                             "--output", str(output.relative_to(root)), relative])
                if row["generation"]["exit_code"] == 0:
                    row["generation"]["text"] = output.read_text()
            results.append(row)
    changed = sum(row["check"]["exit_code"] != row["intake_check_exit"] for row in results)
    record = dict(revision=subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
                  cases=results, changed_check_outcomes=changed,
                  boundary="Current native capture only; changed feature behavior requires its owning acceptance tests.")
    (destination / "results.json").write_text(json.dumps(record, indent=2) + "\n")
    print(f"Captured {len(results)} sources; {changed} check outcomes differ from intake.")


if __name__ == "__main__":
    main()
