#!/usr/bin/env python3
"""Capture source-only namespace and static-use controls in a new local directory."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def digest(data):
    return hashlib.sha256(data).hexdigest()


root = Path.cwd().resolve()
destination = Path(sys.argv[1])
if destination.is_absolute() or ".." in destination.parts:
    raise SystemExit("output must be repository-relative")
destination.resolve().relative_to(root)
destination.mkdir(parents=True, exist_ok=False)


def run(argv, stdin=None):
    try:
        result = subprocess.run(argv, input=stdin, capture_output=True, timeout=60)
        status, streams = result.returncode, (result.stdout, result.stderr)
    except subprocess.TimeoutExpired as error:
        status, streams = "timeout", (error.stdout or b"", error.stderr or b"")
    return {"argv": argv, "exit": status, **{
        name: {"raw_bytes": len(raw), "raw_sha256": digest(raw),
               "text": raw.decode().replace(str(root), "<repo>")}
        for name, raw in zip(("stdout", "stderr"), streams)
    }}


direct = """(?fsm:namespace_width
  (+types (type word_t (bits 8)))
  (+params (word_t 16))
  (+interface (output data))
  (+size (data WIDTH_TOKEN))
  (idle (= (data 0))))
"""
coupled = """(actor coupled_widths
  (clock clk) (reset rst_n) (watchdog WATCHDOG)
  (params (W 2))
  (interface (input start) (input ready) (output data (width W)))
  (storage (bank mem (width W) (depth DEPTH)))
  (transaction main (on start) (await ready) (set data 0)))
"""
cases = {
    "namespace_actor.isf": """(actor namespace_width
  (clock clk) (reset rst_n)
  (types (type word_t (bits 8))) (params (word_t 16))
  (interface (input start) (output data (width word_t)))
  (transaction main (on start) (set data 0)))
""",
    "namespace_bare.fsm": direct.replace("WIDTH_TOKEN", "word_t"),
    "namespace_expression.fsm": direct.replace("WIDTH_TOKEN", "(+ word_t 0)"),
    "namespace_literal.fsm": direct.replace("WIDTH_TOKEN", "16"),
    "coupled_named.isf": coupled.replace("WATCHDOG", "W").replace("DEPTH", "W"),
    "coupled_literal.isf": coupled.replace("WATCHDOG", "2").replace("DEPTH", "2"),
    "static_precedence.isf": """(actor static_precedence
  (clock clk) (reset rst_n) (watchdog W)
  (params (W 4)) (constants (W 2))
  (interface (input start) (input ready) (output data (width W)))
  (storage (bank mem (width W) (depth W)))
  (transaction main (on start) (await ready) (set data 0)))
""",
}

probe = r'''
use strict; use warnings; use JSON::PP; use Storable qw(dclone);
use FSM::Adapter::ISF; use FSM::Scheduler::ISF;
my $json = JSON::PP->new->canonical;
open my $fh, '<:raw', $ARGV[0] or die $!;
my $text = do {local $/; <$fh>}; close $fh or die $!;
# An identical explicit source label makes source-use loss observable without
# deleting or normalizing arbitrary actor fields after parsing.
my $actor = FSM::Adapter::ISF->new->parse_source($text, 'source-use-peer.isf');
my $before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $module = $scheduler->{ir}->build_module($actor);
my @keys = qw(actor_name ports declared_storage signal_widths params constants reset_values
              counters states storage_roles);
my %ir = map {exists($module->{$_}) ? ($_ => dclone($module->{$_})) : ()}
    grep {ref($module->{$_})} @keys;
$ir{actor_name} = $module->{actor_name};
my $files = $scheduler->lower($actor)->{files};
print $json->encode({actor=>$json->decode($before), ir=>\%ir, files=>$files,
    caller_unchanged=>$json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false}), "\n";
'''

receipt = {
    "schema_version": 1, "owner": "ISF-REDUCTION-DELIVERY.2.3.1.1",
    "revision": run(["git", "rev-parse", "HEAD"])["stdout"]["text"].strip(),
    "status_at_capture": run(["git", "status", "--short"]),
    "scope": "Native check/semantic and private parser/selected-IR/carrier products only; no HDL tool execution.",
    "normalization": "Only exact checkout roots become <repo>; raw streams are not retained.",
    "producer": {"path": str(Path(__file__).resolve().relative_to(root)), "sha256": digest(Path(__file__).read_bytes())},
    "private_probe": probe, "cases": {},
}
for name, source in cases.items():
    path = destination / name
    path.write_text(source)
    row = {"source": source, "sha256": digest(source.encode()), "queries": {}}
    if path.suffix == ".isf":
        row["private"] = run(["perl", "-Iperl", "-e", probe, str(path)])
    for kind, flags in (("check", ["--check", "--json"]),
                        ("semantic", ["--emit-semantic-json"])):
        row["queries"][kind] = run(["perl", "bin/fsmgen", "--quiet", "--strict", *flags, str(path)])
        # Keep every completed query before another one can fail or time out.
        (destination / (name + "." + kind + ".json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    receipt["cases"][name] = row
    print(name, {kind: result["exit"] for kind, result in row["queries"].items()}, flush=True)
receipt["selected_inputs"] = {}
for path in ("perl/FSM/Adapter/ISF/Parser.pm", "perl/FSM/Adapter/FSMGenFull/Parser.pm",
             "perl/FSM/Adapter/FSMGenFull/SignalManager.pm", "perl/FSM/Scheduler/ISF/LoweringIR.pm"):
    data = Path(path).read_bytes()
    receipt["selected_inputs"][path] = {"bytes": len(data), "sha256": digest(data)}
output = destination / "receipt.json.gz"
with output.open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
print(output)
