#!/usr/bin/env python3
"""Read retained source/native products; never replay historical workloads."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess


def require(value, message):
    if not value:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    # JSON encoding distinguishes numeric, string and Boolean primitives.
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def load(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


BASE = "docs/audits/width-carrier-contract-first-20261022.json.gz"
CONTROL = "docs/audits/width-static-use-controls-20261022.json.gz"
REVISION = "7d9d3a6827ec3d0922317e2d8dbf7bd363db2500"


def identity(first, controls):
    for packet in (first, controls):
        require(packet["revision"] == REVISION, "selected Git revision")
        producer = packet["producer"]
        require(not Path(producer["path"]).is_absolute(), "relative producer path")
        require(sha(producer["text"].encode()) == producer["sha256"],
                "complete captured producer identity")
        for row in packet["cases"].values():
            require(sha(row["source"].encode()) == row["sha256"], "complete source identity")
    require(controls["baseline"]["sha256"] == sha(Path(BASE).read_bytes()),
            "sealed baseline receipt join")
    require(controls["baseline"]["raw_capture_sha256"] == first["seal"]["raw_capture_sha256"],
            "original capture baseline join")
    for path, declared in first["selected_inputs"].items():
        data = subprocess.check_output(["git", "show", REVISION + ":" + path])
        require(len(data) == declared["bytes"] and sha(data) == declared["sha256"],
                "exact selected implementation Git join: " + path)


def product(row):
    require(row["private"]["exit"] == 0, "successful private source probe")
    result = json.loads(row["private"]["stdout"]["text"])
    require(result["caller_unchanged"] is True, "actual caller Boolean and isolation")
    return result


def positive(row):
    for query in row["queries"].values():
        require(query["exit"] == 0, "successful native source query")
        require(json.loads(query["stdout"]["text"])["success"] is True,
                "native success Boolean")


def qualify(first, controls):
    cases = first["cases"]
    require(set(cases) == {"namespace_actor.isf", "namespace_bare.fsm",
            "namespace_expression.fsm", "namespace_literal.fsm", "coupled_named.isf",
            "coupled_literal.isf", "static_precedence.isf"}, "complete first source cohort")
    expected = {"namespace_actor.isf": 16, "namespace_bare.fsm": 8,
                "namespace_expression.fsm": 16, "namespace_literal.fsm": 16}
    for name, width in expected.items():
        row = cases[name]
        positive(row)
        report = json.loads(row["queries"]["semantic"]["stdout"]["text"])
        outputs = report["semantic"]["signal_analysis"]["outputs"]
        require(len(outputs) == 1 and outputs[0]["name"] == "data", "actual output identity")
        signal = outputs[0]
        require(canonical(signal["width"]) == canonical(width), name + " literal width oracle")
        if name == "namespace_bare.fsm":
            require(signal["declared_type_name"] == "word_t" and
                    canonical(signal["declared_type_spec"]) == canonical(
                        {"kind": "bits", "signed": 0, "width": 8}), "bare token selects named type")
        else:
            require("declared_type_name" not in signal and "declared_type_spec" not in signal,
                    name + " scalar declaration remains independent of named type")
    actor = product(cases["namespace_actor.isf"])
    require(canonical(actor["actor"]["interface"]["outputs"][0]["_width_declaration"]) ==
            canonical({"token": "word_t", "kind": "actor_parameter", "owner": "namespace_width"}),
            "ISF canonical parameter branch and original owner")
    require("(data 16)" in "\n".join(actor["files"].values()), "actual current numeric carrier")
    # Direct peers differ only in the authored size token, with both namespaces fixed.
    bare = cases["namespace_bare.fsm"]["source"]
    require(bare.replace("(+size (data word_t))", "(+size (data (+ word_t 0)))") ==
            cases["namespace_expression.fsm"]["source"], "exact expression source control")
    require(bare.replace("(+size (data word_t))", "(+size (data 16))") ==
            cases["namespace_literal.fsm"]["source"], "exact literal source control")

    literal = cases["coupled_literal.isf"]
    baseline = product(literal)
    positive(literal)
    require(type(baseline["actor"]["watchdog"]) is str and baseline["actor"]["watchdog"] == "2",
            "watchdog resolved primitive and value")
    storage = baseline["actor"]["storage"][0]
    require(type(storage["depth"]) is int and storage["depth"] == 2,
            "depth resolved primitive and value")
    require([item["name"] for item in storage["signals"]] == ["mem_0", "mem_1"],
            "actual static bank expansion")
    require(set(controls["cases"]) == {"watchdog_only.isf", "depth_only.isf"},
            "complete independently varied source slots")
    peers = {"coupled_named.isf": (cases["coupled_named.isf"],
             literal["source"].replace("(watchdog 2)", "(watchdog W)").replace("(depth 2)", "(depth W)"))}
    for name, old, new in (("watchdog_only.isf", "(watchdog 2)", "(watchdog W)"),
                           ("depth_only.isf", "(depth 2)", "(depth W)")):
        require(literal["source"].count(old) == 1, "independent single source slot")
        peers[name] = (controls["cases"][name], literal["source"].replace(old, new))
    for name, (row, source) in peers.items():
        require(row["source"] == source and row["source"] != literal["source"],
                name + " exact authored difference")
        positive(row)
        require(canonical(product(row)) == canonical(baseline),
                name + " complete actor/selected-IR/carrier equality without field removal")
    refusal = cases["static_precedence.isf"]
    cause = "Error: actor 'static_precedence' constant 'W' conflicts with actor parameter 'W'"
    require(refusal["private"]["exit"] == 255 and cause in refusal["private"]["stderr"]["text"],
            "duplicate declaration private refusal, not successful precedence")
    for query in refusal["queries"].values():
        report = json.loads(query["stdout"]["text"])
        require(query["exit"] == 1 and report["success"] is False and
                report["diagnostics"][0]["message"] == cause, "native duplicate refusal")


first, controls = load(BASE), load(CONTROL)
identity(first, controls)
qualify(first, controls)
for family in ("wrong_width", "numeric_boolean", "retained_watchdog", "retained_depth"):
    bad_first, bad_controls = copy.deepcopy(first), copy.deepcopy(controls)
    if family == "wrong_width":
        stream = bad_first["cases"]["namespace_bare.fsm"]["queries"]["semantic"]["stdout"]
        value = json.loads(stream["text"])
        value["semantic"]["signal_analysis"]["outputs"][0]["width"] = 16
    else:
        row = bad_controls["cases"]["watchdog_only.isf" if family != "retained_depth" else "depth_only.isf"]
        stream = row["private"]["stdout"]
        value = json.loads(stream["text"])
        if family == "numeric_boolean":
            value["caller_unchanged"] = 1
        else:
            value["actor"]["_invented_retained_source"] = "W"
    stream["text"] = json.dumps(value)
    try:
        qualify(bad_first, bad_controls)
    except ValueError:
        pass
    else:
        raise ValueError("hostile product accepted: " + family)
print("width carrier contracts: namespace, exact single-slot erasure, caller kinds and hostile controls pass")
