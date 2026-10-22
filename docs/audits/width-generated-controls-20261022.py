#!/usr/bin/env python3
"""Qualify a connected generated fixture and retained activation source values."""
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
baseline_path = Path("docs/audits/width-physical-sources-first-20261022.json.gz")
baseline = json.loads(gzip.decompress(baseline_path.read_bytes()))
original = baseline["cases"]["generated.isf"]["source"]
require_count = original.count(" (set actor_result data)")
if require_count != 1:
    raise ValueError("expected exact unconnected inherited-output source slot")
literal = original.replace(" (set actor_result data)", "").replace(
    "(params (W 8) (ALIAS W))", "(params (W 8) (ALIAS W) (ACTIVATION 4))")
cases = {"generated_literal.isf": literal,
         "generated_named.isf": literal.replace("(spawn child as first (params (W 4))",
                                              "(spawn child as first (params (W ACTIVATION))")}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def run(argv):
    result = subprocess.run(argv, capture_output=True, timeout=60)
    return {"argv": argv, "exit": result.returncode, **{
        name: {"raw_bytes": len(raw), "raw_sha256": sha(raw),
               "text": raw.decode().replace(str(root), "<repo>")}
        for name, raw in (("stdout", result.stdout), ("stderr", result.stderr))}}


producer = Path(__file__).resolve().relative_to(root)
receipt = {"owner": "ISF-REDUCTION-DELIVERY.2.3.1.2", "schema_version": 1,
           "revision": subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip(),
           "producer": {"path": str(producer), "sha256": sha(producer.read_bytes())},
           "baseline": {"path": str(baseline_path), "sha256": sha(baseline_path.read_bytes())},
           "scope": "Correct only unconnected inherited output, then vary one activation value; actual source/preparation/IR/carriers and native queries, no HDL tools.",
           "cases": {}}
for name, source in cases.items():
    path = destination / name
    path.write_text(source)
    row = {"source": source, "sha256": sha(source.encode()), "queries": {}}
    row["private"] = run(["perl", "-Iperl", "-e", baseline["private_probe"], str(path)])
    (destination / (name + ".private.json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    for kind, flags in (("check", ["--check", "--json"]),
                        ("semantic", ["--emit-semantic-json"]), ("schedule", ["--emit-schedule-json"])):
        row["queries"][kind] = run(["perl", "bin/fsmgen", "--quiet", "--strict", *flags, str(path)])
        (destination / (name + "." + kind + ".json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    receipt["cases"][name] = row
    print(name, row["private"]["exit"], {key: value["exit"] for key, value in row["queries"].items()}, flush=True)
with (destination / "receipt.json.gz").open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
