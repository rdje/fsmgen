#!/usr/bin/env python3
"""Compare complete retained public products and literal private associations."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import re


def require(value, message):
    if not value:
        raise ValueError(message)


def load(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def canonical(value):
    # Encoding equality keeps primitive kinds distinct, including bool/int.
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def normalize(value, directory):
    if isinstance(value, str):
        return value.replace(directory, "<fixture-root>")
    if isinstance(value, list):
        return [normalize(item, directory) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item, directory) for key, item in value.items()}
    return value


def declarations(value, path=()):
    result = {}
    if isinstance(value, dict):
        if "_width_declaration" in value:
            result[path] = value["_width_declaration"]
        for key, item in value.items():
            result.update(declarations(item, (*path, key)))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            result.update(declarations(item, (*path, index)))
    return result


def strip_declarations(value):
    if isinstance(value, dict):
        return {key: strip_declarations(item) for key, item in value.items()
                if key != "_width_declaration"}
    if isinstance(value, list):
        return [strip_declarations(item) for item in value]
    return value


def declaration(token, kind, owner):
    return {"token": token, "kind": kind, "owner": owner}


actor = ("actor_before",)
EXPECTED = {
    "equal_defaults": {
        (*actor, "interface", "inputs", 1): declaration("WIDTH", "actor_parameter", "width_origins"),
        (*actor, "interface", "inputs", 2): declaration("ALIAS", "actor_parameter", "width_origins"),
        (*actor, "interface", "inputs", 3): declaration("OTHER", "actor_parameter", "width_origins"),
        (*actor, "interface", "inputs", 5): declaration("FIXED", "actor_constant", "width_origins"),
        (*actor, "interface", "outputs", 0): declaration("WIDTH", "actor_parameter", "width_origins"),
        (*actor, "storage", 0): declaration("ALIAS", "actor_parameter", "width_origins"),
    },
    "transaction_scope": {
        (*actor, "interface", "inputs", 1): declaration("WIDTH", "actor_parameter", "tx_width_origins"),
        (*actor, "interface", "outputs", 0): declaration("WIDTH", "actor_parameter", "tx_width_origins"),
        (*actor, "transactions", 0, "ports", "inputs", 0): declaration("ALIAS", "transaction_parameter", "child"),
        (*actor, "transactions", 0, "ports", "outputs", 0): declaration("WIDTH", "transaction_parameter", "child"),
    },
    "library_scope": {
        (*actor, "library_uses", 0, "actor", "interface", "inputs", 0): declaration("WIDTH", "actor_parameter", "child"),
        (*actor, "library_uses", 0, "actor", "interface", "outputs", 0): declaration("WIDTH", "actor_parameter", "child"),
    },
}


def compare(before, after):
    require(set(before["cases"]) == set(after["cases"]), "complete source cohort")
    for name in before["cases"]:
        old, new = before["cases"][name], after["cases"][name]
        require(old["source"] == new["source"] and old["source_sha256"] == new["source_sha256"],
                name + " exact source bytes")
        directories = [receipt["queries"]["check"]["argv"][-1].rsplit("/", 1)[0]
                       for receipt in (old, new)]
        require(old["private"]["exit"] == new["private"]["exit"], name + " private status")
        if name in EXPECTED:
            values = [normalize(json.loads(row["private"]["stdout"]["text"]), directory)
                      for row, directory in zip((old, new), directories)]
            actual = declarations(values[1])
            require(canonical({str(key): val for key, val in actual.items()}) ==
                    canonical({str(key): val for key, val in EXPECTED[name].items()}),
                    name + " exact literal declaration allocation")
            require(canonical(values[0]) == canonical(strip_declarations(values[1])),
                    name + " complete original actor/IR/carrier/caller preservation")
        for kind in ("check", "semantic", "schedule"):
            queries = [row["queries"][kind] for row in (old, new)]
            require(queries[0]["exit"] == queries[1]["exit"], name + " " + kind + " status")
            if name == "derived_refusal" and kind == "schedule":
                for query in queries:
                    require("unsupported aggregate/list parameter leaf '/'" in
                            query["stdout"]["text"] + query["stderr"]["text"],
                            "existing derived schedule refusal cause")
                continue  # Complete Perl stacks are retained, not claimed byte-identical.
            reports = [normalize(json.loads(query["stdout"]["text"]), directory)
                       for query, directory in zip(queries, directories)]
            require(canonical(reports[0]) == canonical(reports[1]),
                    name + " complete native " + kind + " product")


baseline_path = "docs/audits/scalar-width-foundation-20261022.json.gz"
before = load(baseline_path)
after = load(sys.argv[1] if len(sys.argv) > 1 else
             "docs/audits/scalar-width-declarations-native-20261022.json.gz")
baseline_revision = "ca3889c79fd498e1e6aa11cf22794b072dcb344e"
require(after["revision"] == baseline_revision, "declared pre-change source revision")
require(Path(baseline_path).read_bytes() == subprocess.check_output(
    ["git", "show", baseline_revision + ":" + baseline_path]),
    "independent committed baseline receipt identity")
compare(before, after)


def verify_private_proof(proof):
    parser_path = "perl/FSM/Adapter/ISF/Parser.pm"
    require(proof["baseline_revision"] == baseline_revision, "private proof baseline")
    parser = proof["parser"]
    require(parser["path"] == parser_path, "private parser source path")
    require(hashlib.sha256(parser["text"].encode()).hexdigest() == parser["sha256"] ==
            after["inputs"][parser_path]["sha256"], "complete changed parser identity")
    require(hashlib.sha256(proof["test"]["text"].encode()).hexdigest() == proof["test"]["sha256"],
            "complete final regression identity")
    prior = subprocess.check_output(["git", "show", baseline_revision + ":" + parser_path])
    old = proof["predecessor"]["observations"]
    require(canonical(old["before"]) == canonical(old["after"]), "old load changed during regression")
    methods = {"_finalize_actor_interface_widths", "_finalize_actor_storage_widths",
               "_finalize_actor_transaction_port_widths"}
    require(old["before"]["sha256"] == hashlib.sha256(prior).hexdigest(), "old loaded payload Git join")
    require(old["before"]["new_helper_present"] is False, "old helper Boolean domain")
    require(set(old["before"]["methods"]) == methods and
            set(old["before"]["methods"].values()) == {old["before"]["path"]},
            "complete actual old compiled-method census")
    current = proof["current_passive_load_observation"]
    require(current["path"] == parser_path and current["sha256"] == parser["sha256"],
            "passive current load/source join")
    require(set(current["methods"]) == methods | {"_preserve_symbolic_width_declaration"} and
            set(current["methods"].values()) == {parser_path}, "current compiled-method census")
    require(proof["initial_epochs"]["test"] == proof["initial_epochs"]["first_green_test"],
            "unchanged initial regression reversal")
    require(proof["native_receipt"]["sha256"] == hashlib.sha256(Path(
        proof["native_receipt"]["path"]).read_bytes()).hexdigest(), "complete native receipt join")


proof = load("docs/audits/scalar-width-declarations-private-qualification-20261022.json.gz")
verify_private_proof(proof)
complete_path = Path("docs/audits/scalar-width-declarations-qualification-20261022.json.gz")
if complete_path.exists():
    complete = load(complete_path)
    verify_private_proof(complete)
    require(complete["pending_public_confirmation"] is False, "complete capture still pending")
    public = complete["streams"][".artifacts/scalar-width-declarations-public-20261022.log"]["text"]
    require(re.search(r"^t/1985-isf-interface-port-public-qualification[.]t +[.]+ ok$", public, re.M),
            "all-interface file did not pass before selector failure")
    require("Cannot detect source of 't/2076-isf-unary-reduction-source.t'" in public,
            "original selector error lost or misclassified")
    corrected = complete["streams"][".artifacts/scalar-width-declarations-public-corrected-20261022.log"]["text"]
    require("All tests successful." in corrected and "Files=3, Tests=15" in corrected,
            "corrected public programme missing its separate successful outcome")
for family in ("missing_method", "numeric_boolean"):
    hostile = copy.deepcopy(proof)
    for epoch in ("before", "after"):
        old = hostile["predecessor"]["observations"][epoch]
        if family == "missing_method":
            del old["methods"]["_finalize_actor_storage_widths"]
        else:
            old["new_helper_present"] = 0
    try:
        verify_private_proof(hostile)
    except ValueError:
        pass
    else:
        raise ValueError("hostile loaded-source proof accepted: " + family)

for case in EXPECTED:
    hostile = copy.deepcopy(after)
    stream = hostile["cases"][case]["private"]["stdout"]
    value = json.loads(stream["text"])
    node = value
    for component in next(iter(EXPECTED[case])):
        node = node[component]
    node["_width_declaration"]["token"] = "UNRELATED_EQUAL_DEFAULT"
    stream["text"] = json.dumps(value)
    try:
        compare(before, hostile)
    except ValueError:
        pass
    else:
        raise ValueError("hostile declaration association accepted: " + case)
print("scalar-width declarations: exact private allocation, complete public/carrier preservation and hostile controls pass")
