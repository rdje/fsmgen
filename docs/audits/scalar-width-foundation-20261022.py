#!/usr/bin/env python3
"""Capture the source-only width frontier; never invoke an HDL tool.

Run from the repository root under scripts/run_with_ram_guard.sh. Supply a new
repository-relative output directory. The immutable receipt is written there;
copy it into docs/audits only after reviewing its complete observations.
"""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def digest(data):
    return hashlib.sha256(data).hexdigest()


ROOT = Path.cwd().resolve()
destination = Path(sys.argv[1])
if destination.is_absolute() or ".." in destination.parts:
    raise SystemExit("output must be repository-relative")
destination.resolve().relative_to(ROOT)
destination.mkdir(parents=True, exist_ok=False)


def run(argv, stdin=None):
    result = subprocess.run(argv, input=stdin, capture_output=True, timeout=60)
    streams = {}
    for name in ("stdout", "stderr"):
        raw = getattr(result, name)
        streams[name] = {
            "raw_bytes": len(raw), "raw_sha256": digest(raw),
            "text": raw.decode().replace(str(ROOT), "<repo>"),
        }
    return {"argv": argv, "exit": result.returncode, **streams}


PERL = r'''
use strict; use warnings; use JSON::PP;
use FSM::Adapter::ISF; use FSM::Scheduler::ISF;
my $json = JSON::PP->new->canonical;
my $actor = FSM::Adapter::ISF->new->parse_file($ARGV[0]);
my $before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $ir = $scheduler->{ir}->build_module($actor);
my @keys = qw(actor_name ports declared_storage signal_widths signal_type_refs
              params constants reset_values library_uses);
my %projection = map {exists($ir->{$_}) ? ($_ => $ir->{$_}) : ()} @keys;
my $files = $scheduler->lower($actor)->{files};
print $json->encode({actor_before => $json->decode($before),
    caller_unchanged => $json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false,
    ir => \%projection, files => $files}), "\n";
'''

CASES = {
    "equal_defaults": """(actor width_origins
  (clock clk) (reset rst_n)
  (params (WIDTH 8) (ALIAS WIDTH) (OTHER 8))
  (constants (FIXED 8))
  (types (type byte_t (bits 8)))
  (interface (input start) (input data (width WIDTH))
    (input alias_data (width ALIAS)) (input other_data (width OTHER))
    (input literal_data (width 8)) (input constant_data (width FIXED))
    (input typed_data (type byte_t)) (output result (width WIDTH)))
  (storage (var saved (width ALIAS) (reset 3)))
  (transaction main (on start) (update saved data) (set result saved)))
""",
    "transaction_scope": """(actor tx_width_origins
  (clock clk) (params (WIDTH 8))
  (interface (input start) (input data (width WIDTH))
    (output result (width WIDTH)) (output done))
  (transaction child (params (WIDTH 8) (ALIAS WIDTH))
    (ports (input payload (width ALIAS)) (output response (width WIDTH)))
    (update response payload) (complete done))
  (transaction parent (on start)
    (spawn child as first (bind (input payload data) (output response result)))
    (await_all first) (complete done)))
""",
    "library_scope": """(library widths (exports (actor child))
  (actor child (clock clk) (params (WIDTH 8))
    (interface (input data (width WIDTH)) (output result (width WIDTH)))
    (rule copy 1 (result data))))
(actor library_width_origins (clock clk)
  (interface (input data (width 8)) (output result (width 8)))
  (imports (library widths as lib))
  (use lib.child as first (params (WIDTH 16))
    (bind (clock clk) (input data data) (output result result))))
""",
    "derived_refusal": """(actor derived_width
  (clock clk) (params (WIDTH 32) (BYTES (/ WIDTH 8)))
  (interface (output result (width BYTES))))
""",
}

receipt = {
    "schema_version": 1,
    "scope": "source/parser/private IR/carrier/native reports only; no HDL execution",
    "revision": run(["git", "rev-parse", "HEAD"])["stdout"]["text"].strip(),
    "initial_status": run(["git", "status", "--short"]),
    "normalization": "replace exact checkout root with <repo>; raw streams are not retained",
    "producer": {"path": __file__, "sha256": digest(Path(__file__).read_bytes())},
    "perl_probe": PERL,
    "cases": {},
}
for name, source in CASES.items():
    path = destination / (name + ".isf")
    path.write_text(source)
    row = {"source": source, "source_sha256": digest(source.encode()), "queries": {}}
    row["private"] = run(["perl", "-Iperl", "-e", PERL, str(path)])
    for query, flags in (
        ("check", ["--strict", "--check", "--json"]),
        ("semantic", ["--strict", "--emit-semantic-json"]),
        ("schedule", ["--emit-schedule-json"]),
    ):
        row["queries"][query] = run(["perl", "bin/fsmgen", "--quiet", *flags, str(path)])
    receipt["cases"][name] = row

files = [
    "perl/FSM/Adapter/ISF/Parser.pm", "perl/FSM/Adapter/FSMGenFull/Parser.pm",
    "perl/FSM/Scheduler/ISF/LoweringIR.pm", "perl/FSM/Scheduler/ISF/FormalLowering.pm",
    "perl/FSM/Scheduler/ISF/Emitter/FSM.pm", "perl/FSM/Support/ISFReductions.pm",
    "docs/ARTIFACT_CLEANUP.md", "docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md",
    "CLAIM_VERIFICATION.md", "docs/audits/claim-template-review-20260923/template.txt",
]
receipt["inputs"] = {
    path: {"bytes": len(Path(path).read_bytes()), "sha256": digest(Path(path).read_bytes())}
    for path in files
}
for name in ("sf-isf-generic-port-widths", "sf-isf-derived-width-parameter"):
    path = Path("../specforge/docs/upstream/fsmgen") / name / "README.md"
    receipt.setdefault("read_only_requests", {})[name] = {
        "logical_path": str(path), "sha256": digest(path.read_bytes()), "text": path.read_text(),
    }
source = Path("../pgen/docs/CLAIM_VERIFICATION.md").read_bytes()
receipt["claim_template_review"] = {
    "source_sha256": digest(source),
    "matches_reviewed_template": source == Path(files[-1]).read_bytes(),
}
output = destination / "receipt.json.gz"
with output.open("wb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
for name, row in receipt["cases"].items():
    print(name, "private", row["private"]["exit"], "queries",
          {key: value["exit"] for key, value in row["queries"].items()})
print(output)
