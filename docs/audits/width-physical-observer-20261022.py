#!/usr/bin/env python3
"""Repair lossy audit snapshots; preserve all original products and native epochs."""
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
paths = [Path("docs/audits/width-physical-sources-first-20261022.json.gz"),
         Path("docs/audits/width-generated-controls-first-20261022.json.gz")]
packets = [json.loads(gzip.decompress(path.read_bytes())) for path in paths]
probe = packets[0]["private_probe"]
edits = {
    "my $before = $json->encode($actor);": "my $before = $json->encode($actor);\nsub snapshot { $json->decode($json->encode($_[0])) }",
    "my $context = FSM::Scheduler": "my $prepared_observation = snapshot($prepared);\nmy $context = FSM::Scheduler",
    "my $physical = $context": "my $formal_observation = snapshot($context);\nmy $physical = $context",
    "my $ir = $scheduler": "my $physical_observation = snapshot($physical);\nmy $ir = $scheduler",
    "my (@modules, @domains, $realizations);": """my $ir_observation = snapshot($ir);
my $before_clone = $json->encode($ir);
my $clone_observation = snapshot(dclone($ir));
my $clone_caller_unchanged = $json->encode($ir) eq $before_clone ? JSON::PP::true : JSON::PP::false;
my (@modules, @domains, $realizations);""",
    "prepared=>$prepared,": "prepared=>$prepared_observation,",
    "formal_context=>$context, physical=>$physical, ir=>$ir, files=>$files,":
        "formal_context=>$formal_observation, physical=>$physical_observation, ir=>$ir_observation, files=>$files,\n    clone_counterfactual=>{ir=>$clone_observation, caller_unchanged=>$clone_caller_unchanged},",
}
for old, new in edits.items():
    if probe.count(old) != 1:
        raise ValueError("exact observer replacement absent or ambiguous: " + old)
    probe = probe.replace(old, new)
if probe.count("dclone($result)") != 3:
    raise ValueError("actual three observer copy sites changed")
probe = probe.replace("dclone($result)", "snapshot($result)")


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
           "private_probe": probe, "cases": {},
           "scope": "Fresh private first-touch JSON snapshots only, with explicit Storable copy counterfactual. Production inputs and calls stay unchanged. Original native queries are not rerun or relabeled; no HDL tools.",
           "normalization": "Only exact checkout roots become <repo>; raw stream byte counts/hashes retained without raw-root reconstruction."}
for packet in packets:
    for name, original in packet["cases"].items():
        path = destination / name
        path.write_text(original["source"])
        row = {"source": original["source"], "sha256": original["sha256"],
               "private": run(["perl", "-Iperl", "-e", probe, str(path)])}
        receipt["cases"][name] = row
        (destination / (name + ".json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
        print(name, row["private"]["exit"], flush=True)
with (destination / "receipt.json.gz").open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
