#!/usr/bin/env python3
"""Capture actual private source/physical products and native source queries."""
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


def sha(data):
    return hashlib.sha256(data).hexdigest()


def run(argv):
    try:
        result = subprocess.run(argv, capture_output=True, timeout=60)
        status, streams = result.returncode, (result.stdout, result.stderr)
    except subprocess.TimeoutExpired as error:
        status, streams = "timeout", (error.stdout or b"", error.stderr or b"")
    return {"argv": argv, "exit": status, **{
        name: {"raw_bytes": len(raw), "raw_sha256": sha(raw),
               "text": raw.decode().replace(str(root), "<repo>")}
        for name, raw in zip(("stdout", "stderr"), streams)}}


library = """(library widths (exports (actor child))
  (actor child (clock clk) (params (W 8) (ALIAS W))
    (interface (input data (width ALIAS)) (output result (width W)))
    (rule copy 1 (result data))))
(actor library_widths (clock clk) (params (LIMIT 16))
  (imports (library widths as lib))
  (interface (input data (width 8)) (output first_result (width 8)) (output second_result (width 8)))
  (use lib.child as first (params (W OVERRIDE_TOKEN))
    (bind (clock clk) (input data data) (output result first_result)))
  (use lib.child as second
    (bind (clock clk) (input data data) (output result second_result))))
"""
cases = {
    "direct.isf": """(actor direct_widths (clock clk) (reset rst_n)
  (params (W 8) (ALIAS W) (OTHER 8)) (constants (FIXED 8))
  (types (type byte_t (bits 8)))
  (interface (input start) (input other) (input payload (width W))
    (input literal (width 8)) (input typed (type byte_t))
    (output result (width W)) (output done))
  (storage (var saved (width ALIAS) (reset 3)) (bank mem (width W) (depth 2)))
  (transaction left (params (W 4) (ALIAS W))
    (ports (input payload (width ALIAS)) (output response (width W)))
    (on start) (update response payload) (complete done))
  (transaction right (params (W 6))
    (ports (input payload (width W))) (on other) (wait payload) (set result saved)))
""",
    "generated.isf": """(actor generated_widths (clock clk) (reset rst_n)
  (params (W 8) (ALIAS W))
  (interface (input start) (input data (width W))
    (output actor_result (width W)) (output result (width 4)) (output done))
  (storage (var saved (width ALIAS)))
  (transaction child (params (W 4) (ALIAS W))
    (ports (input payload (width ALIAS)) (output response (width W)))
    (update response payload) (set actor_result data) (complete done))
  (transaction parent (on start)
    (spawn child as first (params (W 4)) (bind (input payload 0) (output response result)))
    (await_all first) (complete done)))
""",
    "library_named.isf": library.replace("OVERRIDE_TOKEN", "LIMIT"),
    "library_literal.isf": library.replace("OVERRIDE_TOKEN", "16"),
    "atl.isf": """(actor atl_widths (clock clk) (reset rst_n)
  (interface (input start) (input payload (width 8)) (output done))
  (imports (library widths as lib)) (instance worker of lib.child)
  (drive feed (worker.payload pins.payload))
  (transaction run (on start) (drive feed) (trigger worker.process)
    (await worker.done) (complete done)))
(library widths (exports (actor child))
  (actor child (clock clk) (reset rst_n) (params (W 8) (ALIAS W))
    (interface (input process_start) (input payload (width ALIAS)) (output done))
    (transaction process (on process_start) (complete done))))
""",
    "domains.isf": """(actor domain_widths
  (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
  (params (W 8) (ALIAS W))
  (interface (input start) (input aux_start (domain aux))
    (input data (width W)) (input aux_data (width ALIAS) (domain aux))
    (output result (width W)) (output aux_result (width W) (domain aux)))
  (storage (var saved (width W)) (var aux_saved (width ALIAS) (domain aux)))
  (transaction core_tx (params (W 4)) (ports (input payload (width W)))
    (on start) (set result data))
  (transaction aux_tx (domain aux) (params (W 6)) (ports (input payload (width W)))
    (on aux_start) (set aux_result aux_data)))
""",
}
probe = r'''
use strict; use warnings; use JSON::PP; use Storable qw(dclone);
use FSM::Adapter::ISF; use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
my $json = JSON::PP->new->canonical;
open my $in, '<:raw', $ARGV[0] or die $!;
my $source = do {local $/; <$in>}; close $in or die $!;
my $actor = FSM::Adapter::ISF->new->parse_source($source, 'width-source-peer.isf');
my $before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $prepared = $scheduler->{ir}->prepare_formal_source($actor);
my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
my $physical = $context ? $context->{actor} : $actor;
my $ir = $scheduler->{ir}->build_module($physical);
my (@modules, @domains, $realizations);
my $build = \&FSM::Scheduler::ISF::LoweringIR::build_module;
my $domain = \&FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact;
my $realize = \&FSM::Scheduler::ISF::_multi_domain_realizations;
no warnings 'redefine';
local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {
    my $result = $build->(@_); push @modules, dclone($result); return $result;
};
local *FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact = sub {
    my $result = $domain->(@_); push @domains, dclone($result); return $result;
};
local *FSM::Scheduler::ISF::_multi_domain_realizations = sub {
    my $result = $realize->(@_); $realizations = dclone($result); return $result;
};
my $files = $scheduler->lower($actor)->{files};
print $json->encode({actor=>$json->decode($before), prepared=>$prepared,
    formal_context=>$context, physical=>$physical, ir=>$ir, files=>$files,
    executed_modules=>\@modules, domain_sources=>\@domains, realizations=>$realizations,
    caller_unchanged=>$json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false}), "\n";
'''
producer = Path(__file__).resolve().relative_to(root)
receipt = {"owner": "ISF-REDUCTION-DELIVERY.2.3.1.2", "schema_version": 1,
           "revision": subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip(),
           "producer": {"path": str(producer), "sha256": sha(producer.read_bytes())},
           "private_probe": probe, "cases": {},
           "production_diff": subprocess.check_output(["git", "diff", "HEAD", "--", "bin", "perl"]).decode(),
           "scope": "Actual source/preparation/formal/IR/domain/realization/carrier captures and native source queries. No HDL tool execution or external dependency footprint reconstruction.",
           "normalization": "Exact checkout roots in streams become <repo>; no arbitrary field removal. Raw bytes are represented by counts and SHA256, not reconstructed."}
for name, source in cases.items():
    path = destination / name
    path.write_text(source)
    row = {"source": source, "sha256": sha(source.encode()), "queries": {}}
    row["private"] = run(["perl", "-Iperl", "-e", probe, str(path)])
    (destination / (name + ".private.json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    for kind, flags in (("check", ["--check", "--json"]),
                        ("semantic", ["--emit-semantic-json"]), ("schedule", ["--emit-schedule-json"])):
        row["queries"][kind] = run(["perl", "bin/fsmgen", "--quiet", "--strict", *flags, str(path)])
        (destination / (name + "." + kind + ".json")).write_text(json.dumps(row, sort_keys=True, indent=2) + "\n")
    receipt["cases"][name] = row
    print(name, row["private"]["exit"], {key: value["exit"] for key, value in row["queries"].items()}, flush=True)
receipt["selected_inputs"] = {}
for name in ("perl/FSM/Adapter/ISF/Parser.pm", "perl/FSM/Scheduler/ISF.pm",
             *["perl/FSM/Scheduler/ISF/" + name + ".pm" for name in
               ("LoweringIR", "FormalLowering", "FormalIdentityPlan", "FormalClauseResolver", "DomainSource")]):
    data = Path(name).read_bytes()
    receipt["selected_inputs"][name] = {"bytes": len(data), "sha256": sha(data)}
with (destination / "receipt.json.gz").open("xb") as stream:
    with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
        packed.write((json.dumps(receipt, sort_keys=True, indent=2) + "\n").encode())
