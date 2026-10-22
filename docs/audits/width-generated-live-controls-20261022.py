#!/usr/bin/env python3
"""Keep the inherited actor-width input live in connected generated controls."""
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
paths = [Path("docs/audits/width-generated-controls-first-20261022.json.gz"),
         Path("docs/audits/width-physical-observer-20261022.json.gz")]
generated, observed = [json.loads(gzip.decompress(path.read_bytes())) for path in paths]


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
           "baselines": {str(path): sha(path.read_bytes()) for path in paths},
           "scope": "Connected generated sources additionally read inherited data in a wait predicate so input pruning cannot remove the actor/transaction width-scope control. First-touch private snapshots and native queries; no HDL tools.",
           "cases": {}}
for name, original in generated["cases"].items():
    if original["source"].count("(update response payload)") != 1:
        raise ValueError("one exact generated body slot required")
    source = original["source"].replace("(update response payload)",
                                      "(wait (== data 0)) (update response payload)")
    name = name.replace(".isf", "_live.isf")
    path = destination / name
    path.write_text(source)
    row = {"source": source, "sha256": sha(source.encode()), "queries": {}}
    row["private"] = run(["perl", "-Iperl", "-e", observed["private_probe"], str(path)])
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
