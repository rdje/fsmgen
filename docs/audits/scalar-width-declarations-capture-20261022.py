#!/usr/bin/env python3
"""Seal the completed parser-width qualification without starting any workload.

Inputs are the explicitly named repository-local captures from this task. Run
only after consuming their process results. Existing evidence is never replaced.
"""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(["git", *args])


def require(condition, message):
    if not condition:
        raise ValueError(message)


root = Path.cwd()
private_only = sys.argv[1:] == ["--private-only"]
require(not sys.argv[1:] or private_only, "only --private-only is supported")
revision = "ca3889c79fd498e1e6aa11cf22794b072dcb344e"
parser_path = "perl/FSM/Adapter/ISF/Parser.pm"
parser = Path(parser_path).read_bytes()
test_path = "t/2094-isf-authored-width-declarations.t"
test = Path(test_path).read_bytes()
old = Path(".artifacts/scalar-width-declarations-predecessor-20261022")
identities = json.loads((old / "identity.json").read_text())
prior = git("show", revision + ":" + parser_path)
require(identities["before"] == identities["after"], "predecessor load changed during test")
identity = identities["before"]
methods = {"_finalize_actor_interface_widths", "_finalize_actor_storage_widths",
           "_finalize_actor_transaction_port_widths"}
require(identity["sha256"] == sha(prior), "loaded predecessor differs from Git")
require(identity["new_helper_present"] is False, "predecessor unexpectedly has new helper")
require(set(identity["methods"]) == methods, "incomplete predecessor method census")
require(set(identity["methods"].values()) == {identity["path"]}, "wrong compiled predecessor methods")
current = json.loads(Path(".artifacts/scalar-width-declarations-current-identity-20261022.json").read_text())
require(current["sha256"] == sha(parser), "current loaded parser identity drift")
require(current["path"] == parser_path, "current parser loaded from another root")
require(set(current["methods"]) == methods | {"_preserve_symbolic_width_declaration"},
        "incomplete current method census")
require(set(current["methods"].values()) == {parser_path}, "wrong current compiled methods")
changed = git("diff", "--name-only", revision, "--", "bin", "perl").decode().splitlines()
require(changed == [parser_path], "unexpected additional implementation changes")
native_path = Path("docs/audits/scalar-width-declarations-native-20261022.json.gz")
native = json.loads(gzip.decompress(native_path.read_bytes()))
require(native["inputs"][parser_path]["sha256"] == sha(parser), "native capture source identity drift")

logs = [
    ".artifacts/scalar-width-declarations-focused-20261022.log",
    ".artifacts/scalar-width-declarations-final-20261022.log",
    ".artifacts/scalar-width-declarations-public-20261022.log",
    ".artifacts/scalar-width-declarations-public-corrected-20261022.log",
    ".artifacts/scalar-width-declarations-docs-20261022.log",
    str(old / "result.log"),
]
streams = {}
for path in logs:
    if private_only and path == logs[2]:
        continue
    raw = Path(path).read_bytes()
    streams[path] = {"raw_bytes": len(raw), "raw_sha256": sha(raw),
                     "text": raw.decode().replace(str(root), "<repo>")}
for path in (logs[0], logs[1], logs[3], logs[4]):
    require("All tests successful." in streams[path]["text"] and
            "Result: PASS" in streams[path]["text"], "incomplete successful stream: " + path)
if not private_only:
    require("t/1985-isf-interface-port-public-qualification.t" in streams[logs[2]]["text"] and
            "Cannot detect source" in streams[logs[2]]["text"],
            "first public programme has not reached its recorded selector error")
for index in (1, 2, 3):
    require("not ok " + str(index) in streams[logs[-1]]["text"], "missing predecessor semantic RED")

receipt = {
    "schema_version": 1, "owner": "ISF-REDUCTION-DELIVERY.2.2",
    "baseline_revision": revision,
    "source_scope": "Only the named own-repository parser changes from the baseline; complete external dependency footprints are not reconstructed.",
    "parser": {"path": parser_path, "sha256": sha(parser), "text": parser.decode()},
    "source_diff": git("diff", revision, "--", parser_path).decode(),
    "test": {"path": test_path, "sha256": sha(test), "text": test.decode()},
    "initial_epochs": json.loads(Path(".artifacts/scalar-width-declarations-initial-20261022.json").read_text()),
    "predecessor": {"observations": identities, "probe": (old / "probe.pl").read_text(),
                    "parser_sha256": sha(prior), "observed_exit": 3,
                    "invocation": ["scripts/run_with_ram_guard.sh", "--", "perl", str(old / "probe.pl")]},
    "current_passive_load_observation": current,
    "native_receipt": {"path": str(native_path), "sha256": sha(native_path.read_bytes())},
    "normalization": "Only exact checkout roots become <repo>; native comparison separately normalizes each exact fixture directory. Raw stream bytes are not retained.",
    "streams": streams,
    "pending_public_confirmation": private_only,
    "producer": {"path": __file__, "sha256": sha(Path(__file__).read_bytes())},
}
suffix = "private-qualification" if private_only else "qualification"
output = Path("docs/audits/scalar-width-declarations-" + suffix + "-20261022.json.gz")
with output.open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
print(output)
