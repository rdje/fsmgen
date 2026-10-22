#!/usr/bin/env python3
"""Capture or independently verify this private static-source preservation slice.

Run captures under the repository RAM guard. Verification reads retained data
and Git only; it never reruns historical source or external HDL workloads.
"""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path.cwd().resolve()
PARSER = "perl/FSM/Adapter/ISF/Parser.pm"
TEST = "t/2096-isf-authored-static-references.t"
BASE = "7fce9eb2b834db8f6479ebe4ab9966b9a8e8a7b4"
PREFIX = "docs/audits/static-references-"
PROBE = r'''
use strict; use warnings; use JSON::PP; use Digest::SHA qw(sha256_hex); use B;
use FSM::Adapter::ISF; use FSM::Scheduler::ISF;
my $json = JSON::PP->new->canonical;
my $path = $INC{'FSM/Adapter/ISF/Parser.pm'};
open my $p, '<:raw', $path or die $!;
my $bytes = do { local $/; <$p> }; close $p or die $!;
my %methods = map { $_ => B::svref_2object(FSM::Adapter::ISF::Parser->can($_))->GV->FILE }
    qw(_finalize_actor_storage_depths _finalize_actor_watchdog_limit);
open my $fh, '<:raw', $ARGV[0] or die $!;
my $text = do { local $/; <$fh> }; close $fh or die $!;
my $actor = FSM::Adapter::ISF->new->parse_source($text, 'source-use-peer.isf');
my $before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $files = $scheduler->lower($actor)->{files};
my $report = $json->decode($scheduler->report($actor));
print $json->encode({actor => $json->decode($before), files => $files, report => $report,
    caller_unchanged => $json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false,
    loaded => {path => $path, sha256 => sha256_hex($bytes), methods => \%methods}}), "\n";
'''


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(ok, message):
    if not ok:
        raise ValueError(message)


def unpack(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def run(argv):
    result = subprocess.run(argv, capture_output=True, timeout=60)
    return {"argv": argv, "exit": result.returncode, **{
        key: {"text": data.decode().replace(str(ROOT), "<repo>"),
              "raw_bytes": len(data), "raw_sha256": sha(data)}
        for key, data in (("stdout", result.stdout), ("stderr", result.stderr))}}


def capture(epoch):
    require(epoch in ("before", "after"), "unknown capture epoch")
    work = Path(".artifacts/static-references-native-20261022")
    work.mkdir(exist_ok=True)
    first_path = "docs/audits/width-carrier-contract-first-20261022.json.gz"
    peers_path = "docs/audits/width-static-use-controls-20261022.json.gz"
    first, peers = unpack(first_path), unpack(peers_path)
    sources = {"literal": first["cases"]["coupled_literal.isf"]["source"],
               **{k.removesuffix("_only.isf"): v["source"] for k, v in peers["cases"].items()}}
    require(set(sources) == {"literal", "depth", "watchdog"}, "original peer membership")
    record = {"schema_version": 1, "owner": "ISF-REDUCTION-DELIVERY.2.3.2.1.1",
              "epoch": epoch, "baseline_revision": BASE, "probe": PROBE,
              "revision": subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip(),
              "inputs": {p: {"sha256": sha(Path(p).read_bytes()), "text": Path(p).read_text()}
                         for p in (PARSER, TEST, __file__)},
              "originals": {p: sha(Path(p).read_bytes()) for p in (first_path, peers_path)},
              "source_diff": subprocess.check_output(["git", "diff", BASE, "--", PARSER]).decode(),
              "normalization": "Only the exact checkout prefix becomes <repo>. Original stream hashes/lengths retained; raw absolute-root bytes are not reconstructed.",
              "cases": {}}
    for name, source in sources.items():
        path = work / (name + ".isf")
        path.write_text(source)
        row = {"source": source, "source_sha256": sha(source.encode()), "queries": {}}
        row["private"] = run(["perl", "-Iperl", "-e", PROBE, str(path)])
        for kind, flags in (("check", ["--check", "--json"]),
                            ("semantic", ["--emit-semantic-json"]),
                            ("schedule", ["--emit-schedule-json"])):
            row["queries"][kind] = run(["perl", "bin/fsmgen", "--quiet", "--strict", *flags, str(path)])
        record["cases"][name] = row
        require(all(r["exit"] == 0 for r in [row["private"], *row["queries"].values()]),
                "capture query refused: " + name)
    log = Path(".artifacts/static-references-" + ("red" if epoch == "before" else "green") + "-20261022.log")
    record["regression"] = {"path": str(log), "text": log.read_text().replace(str(ROOT), "<repo>"),
                            "sha256": sha(log.read_bytes())}
    output = Path(PREFIX + epoch + "-20261022.json.gz")
    with output.open("xb") as stream:
        with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
            packed.write((json.dumps(record, sort_keys=True, indent=2) + "\n").encode())
    print(output)


def validate(before, after):
    old_parser = subprocess.check_output(["git", "show", BASE + ":" + PARSER])
    require(before["inputs"][PARSER]["sha256"] == sha(old_parser), "original parser differs from Git")
    require(before["inputs"][TEST] == after["inputs"][TEST], "RED/GREEN regression changed")
    for epoch in (before, after):
        require(set(epoch["cases"]) == {"literal", "depth", "watchdog"}, "peer membership")
        for path, data in epoch["inputs"].items():
            require(sha(data["text"].encode()) == data["sha256"], "stored input identity: " + path)
        for path, digest in epoch["originals"].items():
            require(sha(Path(path).read_bytes()) == digest, "original receipt identity")
    for name in ("literal", "depth", "watchdog"):
        old, new = before["cases"][name], after["cases"][name]
        for row in (old, new):
            require(row["private"]["exit"] == 0, "private query refused")
            require(set(row["queries"]) == {"check", "semantic", "schedule"}, "query membership")
            require(all(r["exit"] == 0 for r in row["queries"].values()), "native query refused")
            for kind in ("check", "semantic"):
                require(json.loads(row["queries"][kind]["stdout"]["text"])["success"] is True,
                        "native product is not successful")
        require(old["source"] == new["source"], "source changed")
        require(sha(old["source"].encode()) == old["source_sha256"] == new["source_sha256"], "source digest")
        a, b = [json.loads(row["private"]["stdout"]["text"]) for row in (old, new)]
        for product, epoch in ((a, before), (b, after)):
            require(product["loaded"] == {"path": PARSER, "sha256": epoch["inputs"][PARSER]["sha256"],
                    "methods": {m: PARSER for m in ("_finalize_actor_storage_depths", "_finalize_actor_watchdog_limit")}},
                    "actual loaded method identity")
            require(product["caller_unchanged"] is True, "caller changed")
        expected = {"token": "W", "kind": "actor_parameter", "owner": "coupled_widths"}
        if name == "depth":
            require(b["actor"]["storage"][0].pop("_depth_declaration") == expected, "wrong depth association")
        if name == "watchdog":
            require(b["actor"].pop("_watchdog_declaration") == expected, "wrong watchdog association")
        del a["loaded"], b["loaded"]
        require(json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True),
                "complete private products or primitive kinds changed outside owned metadata")
        for kind in ("check", "semantic", "schedule"):
            require(old["queries"][kind] == new["queries"][kind], "native product changed: " + kind)
    require("Result: FAIL" in before["regression"]["text"], "original regression did not fail")
    require(re.search(r"Failed tests:\s+1,\s*3\b", before["regression"]["text"]) is not None,
            "missing original semantic RED summary")
    require("All tests successful." in after["regression"]["text"] and
            "Result: PASS" in after["regression"]["text"], "current regression not green")


def verify():
    before = unpack(PREFIX + "before-20261022.json.gz")
    after = unpack(PREFIX + "after-20261022.json.gz")
    validate(before, after)
    # Independent literal oracle and real saved counterfactuals distinguish
    # correct association from equal-default, stale-identity and kind agreement.
    for mutation in ("token", "owner", "kind", "primitive", "missing-peer", "loaded"):
        bad = copy.deepcopy(after)
        row = bad["cases"]["depth"]["private"]["stdout"]
        value = json.loads(row["text"])
        if mutation in ("token", "owner", "kind"):
            value["actor"]["storage"][0]["_depth_declaration"][mutation] = "wrong"
        elif mutation == "primitive":
            value["actor"]["storage"][0]["depth"] = True
        elif mutation == "loaded":
            value["loaded"]["sha256"] = "0" * 64
        else:
            del bad["cases"]["watchdog"]
        row["text"] = json.dumps(value)
        try:
            validate(before, bad)
        except (ValueError, KeyError):
            continue
        raise ValueError("hostile control accepted: " + mutation)
    print("static-reference saved verification: PASS; hostile controls rejected")


def seal():
    verify()
    paths = [".artifacts/static-references-" + name + "-20261022.log" for name in
             ("focused", "doc-tests", "mdbook", "verifier-refusal", "doctrines")]
    streams = {path: {"raw_sha256": sha(Path(path).read_bytes()),
                      "text": Path(path).read_text().replace(str(ROOT), "<repo>")}
               for path in paths}
    for path in paths[:2]:
        require("All tests successful." in streams[path]["text"], "qualification stream incomplete")
    require("HTML book written" in streams[paths[2]]["text"], "book did not build")
    require("missing original semantic RED" in streams[paths[3]]["text"], "lost draft verifier refusal")
    require("all doctrine checks passed" in streams[paths[4]]["text"], "doctrines incomplete")
    record = {"owner": "ISF-REDUCTION-DELIVERY.2.3.2.1.1", "schema_version": 1,
              "baseline_revision": BASE,
              "inputs": {p: sha(Path(p).read_bytes()) for p in (PARSER, TEST, __file__)},
              "producer": {"path": __file__, "text": Path(__file__).read_text()},
              "streams": streams,
              "oracle_correction": "The initial saved verifier expected verbose TAP from nonverbose prove. Its source remains in both original capture inputs. The first interactive refusal was followed by the retained identical saved-only refusal. Corrected validation reads the actual failed-test summary; no source/native replay or product change.",
              "legs": {"rederive": "Actual independent source peers, parsed actors, loaded-method hashes, complete carriers and native products.",
                       "falsify": "Unchanged genuine original RED/current GREEN, literal identities, alias/package/equal-default scopes and hostile saved association/kind/loaded/membership mutations.",
                       "durability": "Tracked test, capture/verifier, original/current products, this qualification receipt, decision0119 and Git."},
              "limits": "Private parser retention only. Complete transitive process/environment footprints and original absolute-root stream reconstruction are not retained; API/MCP-specific inventory, IR/carrier propagation, specialization and actual generic HDL stay owned by successor leaves. No HDL tool executes in this slice."}
    output = Path(PREFIX + "qualification-20261022.json.gz")
    with output.open("xb") as stream:
        with gzip.GzipFile(fileobj=stream, mode="wb", mtime=0) as packed:
            packed.write((json.dumps(record, sort_keys=True, indent=2) + "\n").encode())
    print(output)


if __name__ == "__main__":
    if sys.argv[1:] == ["verify"]:
        verify()
    elif sys.argv[1:] == ["seal"]:
        seal()
    elif len(sys.argv) == 3 and sys.argv[1] == "capture":
        capture(sys.argv[2])
    else:
        raise SystemExit("usage: static-references-20261022.py capture before|after OR verify OR seal")
