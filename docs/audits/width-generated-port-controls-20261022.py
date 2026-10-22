#!/usr/bin/env python3
"""Qualify the documented scalar await-port spelling in connected width sources."""
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
paths = [Path("docs/audits/width-generated-connected-20261022.json.gz"),
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
           "scope": "Connected width sources use documented (await port), changing only the malformed list operand. First-touch source/preparation/IR/carrier and native products; no HDL tools.",
           "cases": {}}
for name, original in prior["cases"].items():
    if not name.endswith("_await.isf"):
        continue
    if original["source"].count("(await (== data 0))") != 1:
        raise ValueError("one exact malformed await operand required")
    source = original["source"].replace("(await (== data 0))", "(await data)")
    label = name.replace("_connected_await", "_port")
    path = destination / label
    path.write_text(source)
    row = {"source": source, "sha256": sha(source.encode()), "queries": {}}
    row["private"] = run(["perl", "-Iperl", "-e", observed["private_probe"], str(path)])
    (destination / (label + ".private.json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    for kind, flags in (("check", ["--check", "--json"]),
                        ("semantic", ["--emit-semantic-json"]), ("schedule", ["--emit-schedule-json"])):
        row["queries"][kind] = run(["perl", "bin/fsmgen", "--quiet", "--strict", *flags, str(path)])
        (destination / (label + "." + kind + ".json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    receipt["cases"][label] = row
    print(label, row["private"]["exit"], {key: value["exit"] for key, value in row["queries"].items()}, flush=True)
with (destination / "receipt.json.gz").open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
