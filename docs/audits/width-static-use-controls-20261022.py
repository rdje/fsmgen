#!/usr/bin/env python3
"""Add one-field-at-a-time controls to the immutable first width-use capture."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path.cwd().resolve()
destination = Path(sys.argv[1])
if destination.is_absolute() or ".." in destination.parts:
    raise SystemExit("output must be repository-relative")
destination.resolve().relative_to(root)
destination.mkdir(parents=True, exist_ok=False)
baseline_path = Path("docs/audits/width-carrier-contract-first-20261022.json.gz")
baseline = json.loads(gzip.decompress(baseline_path.read_bytes()))
literal = baseline["cases"]["coupled_literal.isf"]["source"]
if literal.count("(watchdog 2)") != 1 or literal.count("(depth 2)") != 1:
    raise ValueError("baseline no longer has the exact independent source slots")
cases = {
    "watchdog_only.isf": literal.replace("(watchdog 2)", "(watchdog W)"),
    "depth_only.isf": literal.replace("(depth 2)", "(depth W)"),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def run(argv):
    result = subprocess.run(argv, capture_output=True, timeout=60)
    return {"argv": argv, "exit": result.returncode, **{
        key: {"raw_bytes": len(raw), "raw_sha256": sha(raw),
              "text": raw.decode().replace(str(root), "<repo>")}
        for key, raw in (("stdout", result.stdout), ("stderr", result.stderr))
    }}


receipt = {
    "owner": "ISF-REDUCTION-DELIVERY.2.3.1.1", "schema_version": 1,
    "baseline": {"path": str(baseline_path), "sha256": sha(baseline_path.read_bytes())},
    "revision": subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip(),
    "producer": {"path": str(Path(__file__).resolve().relative_to(root)), "sha256": sha(Path(__file__).read_bytes())},
    "scope": "Each peer changes exactly one source token; same private source label and existing probe. No HDL tool execution.",
    "cases": {},
}
for name, source in cases.items():
    path = destination / name
    path.write_text(source)
    row = {"source": source, "sha256": sha(source.encode()), "queries": {}}
    row["private"] = run(["perl", "-Iperl", "-e", baseline["private_probe"], str(path)])
    (destination / (name + ".private.json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    for kind, flags in (("check", ["--check", "--json"]), ("semantic", ["--emit-semantic-json"])):
        row["queries"][kind] = run(["perl", "bin/fsmgen", "--quiet", "--strict", *flags, str(path)])
        (destination / (name + "." + kind + ".json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    receipt["cases"][name] = row
    print(name, row["private"]["exit"], {k: v["exit"] for k, v in row["queries"].items()}, flush=True)
with (destination / "receipt.json.gz").open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
