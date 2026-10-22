#!/usr/bin/env python3
"""Bind the actor-sized formal explicitly; qualify scope and wait-defect peers."""
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
paths = [Path("docs/audits/width-generated-await-controls-20261022.json.gz"),
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
           "scope": "Explicit bound data formal uses actor alias ACTOR_W -> W8 alongside local W4. Await peers qualify width scopes; wait peers retain entry defect with all child ports connected. Actual first-touch private and native products; no HDL tools.",
           "cases": {}}
for name, original in prior["cases"].items():
    source = original["source"]
    for old, new in (("(ACTIVATION 4))", "(ACTIVATION 4) (ACTOR_W W))"),
                     ("(ports (input payload", "(ports (input data (width ACTOR_W)) (input payload"),
                     ("(bind (input payload", "(bind (input data data) (input payload")):
        if source.count(old) != 1:
            raise ValueError("one exact source-edit slot required: " + old)
        source = source.replace(old, new)
    for mode in ("await", "wait"):
        chosen = source if mode == "await" else source.replace("(await (== data 0))", "(wait (== data 0))")
        label = name.replace("_await", "_connected_" + mode)
        path = destination / label
        path.write_text(chosen)
        row = {"source": chosen, "sha256": sha(chosen.encode()), "queries": {}}
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
