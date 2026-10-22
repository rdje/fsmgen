#!/usr/bin/env python3
"""Seal completed source-only validation; execute no archived workload."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

root = Path.cwd().resolve()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def source(path):
    data = Path(path).read_bytes()
    blob = subprocess.check_output(["git", "hash-object", "--stdin"], input=data).decode().strip()
    return {"path": path, "bytes": len(data), "sha256": sha(data), "git_blob": blob, "text": data.decode()}


receipt = {
    "owner": "ISF-REDUCTION-DELIVERY.11.1",
    "baseline_revision": "b680e95ac3dad1bd36c4accc8381737e2b56d23d",
    "scope": "Completed source/IR/carrier and native/API/newline assertions. No HDL tool execution, full dependency footprint or raw-root reconstruction. Full API payloads are compared in T2095, not separately retained.",
    "before": json.loads(Path(".artifacts/generated-leading-wait-before-20261022.json").read_text()),
    "checkpoint": json.loads(Path(".artifacts/generated-leading-wait-replay-checkpoint-20261022.json").read_text()),
    "module": source("perl/FSM/Scheduler/ISF/LoweringIR.pm"),
    "test": source("t/2095-isf-generated-leading-runtime-wait.t"),
    "drafts": {
        name: source(".artifacts/generated-leading-wait-" + name + "-20261022.t")
        for name in ("first-test", "pre-clone-oracle-test")
    },
    "book_example": source(".artifacts/generated-leading-wait-book-example-20261022.isf"),
    "streams": {},
}
for name in (
    "red", "final-red", "green", "corrected-red", "corrected-green", "focused",
    "docs", "syntax", "book-example",
):
    path = Path(".artifacts/generated-leading-wait-" + name + "-20261022.log")
    data = path.read_bytes()
    receipt["streams"][str(path)] = {
        "raw_bytes": len(data), "raw_sha256": sha(data),
        "text": data.decode().replace(str(root), "<repo>"),
    }
producer = Path(__file__).resolve().relative_to(root)
receipt["producer"] = {"path": str(producer), "sha256": sha(producer.read_bytes())}
receipt["normalization"] = "Only exact checkout roots in log text become <repo>; source bytes and JSON primitive kinds are preserved."
path = Path("docs/audits/generated-leading-wait-20261022.json.gz")
with path.open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
print(path)
