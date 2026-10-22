#!/usr/bin/env python3
"""Read the immutable source-only audit using independently literal oracles."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def require(condition, message):
    if not condition:
        raise ValueError(message)


def products(receipt, name):
    row = receipt["cases"][name]
    require(row["private"]["exit"] == 0, name + " private admission")
    value = json.loads(row["private"]["stdout"]["text"])
    require(value["caller_unchanged"] is True, name + " caller preservation")
    for kind, query in row["queries"].items():
        require(query["exit"] == 0, name + " native " + kind)
        json.loads(query["stdout"]["text"])
    return value


def oracle(receipt):
    require(set(receipt["cases"]) == {
        "equal_defaults", "transaction_scope", "library_scope", "derived_refusal"
    }, "complete declared cohort")
    equal = products(receipt, "equal_defaults")
    ports = equal["actor_before"]["interface"]["inputs"]
    require([(p["name"], p["width"]) for p in ports] == [
        ("start", 1), ("data", 8), ("alias_data", 8), ("other_data", 8),
        ("literal_data", "8"), ("constant_data", 8), ("typed_data", 8),
    ], "independent complete source width/kind oracle")
    require(equal["actor_before"]["params"] == [
        {"name": "WIDTH", "value": "8"},
        {"name": "ALIAS", "value": "WIDTH", "resolved_value": "8"},
        {"name": "OTHER", "value": "8"},
    ], "authored alias declaration survives independently of port widths")
    require(all(set(p) == {"name", "width"} for p in ports[1:6]),
            "baseline symbolic port declaration loss")
    require(ports[6]["type"] == "byte_t", "named type survives baseline")
    fsm = equal["files"]["width_origins.fsm"]
    for token in ("(data 8)", "(alias_data 8)", "(other_data 8)",
                  "(literal_data 8)", "(constant_data 8)", "(typed_data byte_t)",
                  "(saved 8 (reset 3))"):
        require(token in fsm, "actual carrier " + token)
    tx = products(receipt, "transaction_scope")
    child = tx["actor_before"]["transactions"][0]
    require(child["ports"] == {
        "inputs": [{"name": "payload", "width": 8}],
        "outputs": [{"name": "response", "width": 8}],
    }, "transaction association loss despite resolved widths")
    require(child["_transaction_param_port_widths"] == {"ALIAS": 1, "WIDTH": 1},
            "existing transaction parameter-use set")
    library = products(receipt, "library_scope")
    use = library["actor_before"]["library_uses"][0]
    require(use["parameter_overrides"] == [{"name": "WIDTH", "value": "16"}],
            "actual library override")
    require(use["actor"]["interface"]["inputs"] == [{"name": "data", "width": 8}],
            "existing library default-only shape remains explicit")
    require("(data 8)" in library["files"]["library_width_origins__first.fsm"],
            "actual library carrier stays fixed")
    failed = receipt["cases"]["derived_refusal"]
    require(failed["private"]["exit"] == 255, "derived private refusal")
    for kind, status in (("check", 1), ("semantic", 1), ("schedule", 255)):
        query = failed["queries"][kind]
        require(query["exit"] == status, "derived " + kind + " refusal status")
        require("unsupported aggregate/list parameter leaf '/'" in
                query["stdout"]["text"] + query["stderr"]["text"],
                "derived " + kind + " complete source cause")
    require(receipt["claim_template_review"]["matches_reviewed_template"] is True,
            "external policy source unchanged since reviewed template")


path = Path(sys.argv[1] if len(sys.argv) > 1 else
            "docs/audits/scalar-width-foundation-20261022.json.gz")
receipt = json.loads(gzip.decompress(path.read_bytes()))
oracle(receipt)
producer = receipt["producer"]
require(hashlib.sha256(Path(producer["path"]).read_bytes()).hexdigest() == producer["sha256"],
        "retained exact audit producer identity")
revision = receipt["revision"]
for name, identity in receipt["inputs"].items():
    data = subprocess.run(["git", "show", revision + ":" + name],
                          check=True, capture_output=True).stdout
    require(len(data) == identity["bytes"] and
            hashlib.sha256(data).hexdigest() == identity["sha256"],
            "exact source revision identity: " + name)

# Deliberately break named allocation/association facts, rather than totals.
mutations = [
    ("equal_defaults", lambda value: value["actor_before"]["interface"]["inputs"][1].update(width=16)),
    ("equal_defaults", lambda value: value["actor_before"]["params"][1].update(value="OTHER")),
    ("transaction_scope", lambda value: value["actor_before"]["transactions"][0]["ports"]["inputs"][0].update(name="response")),
    ("library_scope", lambda value: value["actor_before"]["library_uses"][0]["actor"]["interface"]["inputs"][0].update(width=16)),
]
for name, mutate in mutations:
    hostile = copy.deepcopy(receipt)
    stream = hostile["cases"][name]["private"]["stdout"]
    value = json.loads(stream["text"])
    mutate(value)
    stream["text"] = json.dumps(value)
    try:
        oracle(hostile)
    except ValueError:
        pass
    else:
        raise ValueError("hostile source association accepted: " + name)
print("scalar-width audit: exact source identities, literal allocation and hostile controls pass")
