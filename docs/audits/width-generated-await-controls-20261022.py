#!/usr/bin/env python3
"""Use an await predicate for the live-input width audit; retain wait defect peers."""
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
paths = [Path("docs/audits/width-generated-live-controls-20261022.json.gz"),
         Path("docs/audits/width-physical-observer-20261022.json.gz")]
prior, observed = [json.loads(gzip.decompress(path.read_bytes())) for path in paths]


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
           "scope": "Only wait becomes await in each live-input source. This avoids the separately owned leading runtime-wait defect; actual first-touch private products and native queries, no HDL tools.",
           "cases": {}}
for name, original in prior["cases"].items():
    if original["source"].count("(wait (== data 0))") != 1:
        raise ValueError("one exact leading wait source slot required")
    source = original["source"].replace("(wait (== data 0))", "(await (== data 0))")
    name = name.replace("_live", "_await")
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
