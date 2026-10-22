#!/usr/bin/env python3
"""Independently join retained lexical declarations, physical products and scopes."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess


def require(value, message):
    if not value:
        raise ValueError(message)


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def same(left, right, message):
    require(canonical(left) == canonical(right), message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def load(name):
    return json.loads(gzip.decompress(Path(name).read_bytes()))


PREFIX = "docs/audits/"
FIRST = PREFIX + "width-physical-sources-first-20261022.json.gz"
GENERATED = PREFIX + "width-generated-controls-first-20261022.json.gz"
OBSERVER = PREFIX + "width-physical-observer-20261022.json.gz"
WAIT = PREFIX + "width-generated-live-controls-20261022.json.gz"
AWAIT = PREFIX + "width-generated-await-controls-20261022.json.gz"
CONNECTED = PREFIX + "width-generated-connected-20261022.json.gz"
LIVE = PREFIX + "width-generated-port-controls-20261022.json.gz"
REVISION = "8061449a36b54b512b949310cf883c8103859eab"


def private(row):
    require(row["private"]["exit"] == 0, "successful actual private call")
    value = json.loads(row["private"]["stdout"]["text"])
    require(value["caller_unchanged"] is True, "complete caller kinds preserved")
    return value


def named(rows, name):
    matches = [row for row in rows if row["name"] == name]
    require(len(matches) == 1, "unique declaration: " + name)
    return matches[0]


def declaration(row, token, kind, owner, width):
    same(row["_width_declaration"], {"token": token, "kind": kind, "owner": owner},
         "independent source token/kind/lexical owner")
    same(row["width"], width, "resolved declaration primitive and width")


def metadata_paths(value, path=()):
    result = []
    if isinstance(value, dict):
        if "_width_declaration" in value:
            result.append(path)
        for key, item in value.items():
            result.extend(metadata_paths(item, (*path, key)))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            result.extend(metadata_paths(item, (*path, index)))
    return result


def scopes(value):
    same(value["actor"], value["prepared"]["actor"], "full original preparation source")
    same(value["ir"], value["executed_modules"][0], "complete actual first-touch root IR")
    require(not metadata_paths(value["ir"]), "observed projection loss, not invented propagation")
    require(value["clone_counterfactual"]["caller_unchanged"] is True,
            "Storable counterfactual preserves original caller")


def formal(value, transaction, source_name, token, width):
    context = value["formal_context"]
    plan = context["plan"]["formals"][transaction][source_name]
    same(plan["identity"], ["transaction_port", value["actor"]["actor_name"], transaction, source_name],
         "actual full formal identity")
    declaration(plan["declaration"], token, "transaction_parameter", transaction, width)
    tx = named(value["physical"]["transactions"], transaction)
    ports = tx["ports"]["inputs"] + tx["ports"]["outputs"]
    port = named(ports, plan["physical_name"])
    declaration(port, token, "transaction_parameter", transaction, width)
    same(port["_isf_formal_identity"], {"source": plan["identity"], "physical_name": plan["physical_name"]},
         "physical source mark agrees with production plan")
    same(value["ir"]["signal_widths"][plan["physical_name"]], width, "real IR formal width")
    require(value["ir"]["storage_roles"][plan["physical_name"]] == "transaction_port",
            "formal remains private storage")
    return plan


def qualify(observed, live):
    cases = observed["cases"]
    require(set(cases) == {"direct.isf", "generated.isf", "library_named.isf", "library_literal.isf",
                          "atl.isf", "domains.isf", "generated_named.isf", "generated_literal.isf"},
            "complete first-touch source cohort")
    products = {name: private(row) for name, row in cases.items()}
    for value in products.values():
        scopes(value)
    direct = products["direct.isf"]
    declaration(named(direct["actor"]["interface"]["inputs"], "payload"),
                "W", "actor_parameter", "direct_widths", 8)
    declaration(named(direct["actor"]["storage"], "saved"),
                "ALIAS", "actor_parameter", "direct_widths", 8)
    for owner, name, token, width in (("left", "payload", "ALIAS", 4),
                                    ("left", "response", "W", 4), ("right", "payload", "W", 6)):
        formal(direct, owner, name, token, width)
    same({row["name"]: row["width"] for row in direct["ir"]["ports"]},
         {"start": 1, "other": 1, "payload": 8, "literal": "8", "typed": 8, "result": 8, "done": 1},
         "complete actor interface remains independent of physical formals")
    same(named(direct["ir"]["params"], "W")["value"], "8", "parent module selects actor parameter")
    require(type(direct["ir"]["states"][0]["assignments"][0]["rhs"]) is int and
            type(direct["clone_counterfactual"]["ir"]["states"][0]["assignments"][0]["rhs"]) is str,
            "actual lossy Storable observer counterfactual")

    library = products["library_named.isf"]
    same(library, products["library_literal.isf"], "complete independently observed override source erasure")
    for instance in ("first", "second"):
        use = next(row for row in library["actor"]["library_uses"] if row["instance"] == instance)
        require(use["actor"]["actor_name"] == "child", "lexical reusable actor name")
        declaration(use["actor"]["interface"]["inputs"][0], "ALIAS", "actor_parameter", "child", 8)
        child = library["ir"]["children"][use["module"]]
        require(child["actor_name"] == use["module"] and use["module"] != "child", "actual cloned module identity")
        same(named(child["params"], "W")["value"], "8", "existing child source default, not specialization")
    same(library["actor"]["uses"][0]["parameter_overrides"], [{"name": "W", "value": "16"}],
         "original use also loses named importing-actor reference")
    same(library["ir"]["library_uses"][0]["parameter_overrides"], [{"name": "W", "value": "16"}],
         "selected override remains separate from child default")

    atl = products["atl.isf"]
    resolution = atl["actor"]["_atl_actor_type_resolutions"]["worker"]
    declaration(named(resolution["actor"]["interface"]["inputs"], "payload"),
                "ALIAS", "actor_parameter", "child", 8)
    require(atl["ir"]["children"][resolution["module"]]["library_origin"]["usage"] == "atl_static_instance",
            "actual ATL constructor identity")
    same(named(atl["ir"]["children"][resolution["module"]]["params"], "W")["value"], "8",
         "actual ATL default environment")

    domains = products["domains.isf"]
    require({row["_scheduled_domain_name"] for row in domains["domain_sources"]} == {"core", "aux"},
            "complete actual domain source membership")
    require({row["domain"]["name"] for row in domains["realizations"]} == {"core", "aux"},
            "complete actual realization membership")
    for name, tx, signal, token, width in (("core", "core_tx", "data", "W", 4),
                                          ("aux", "aux_tx", "aux_data", "ALIAS", 6)):
        plan = formal(domains, tx, "payload", "W", width)
        source = next(row for row in domains["domain_sources"] if row["_scheduled_domain_name"] == name)
        declaration(named(source["interface"]["inputs"], signal), token, "actor_parameter", "domain_widths", 8)
        require([row["name"] for row in source["transactions"]] == [tx], "no sibling-domain transaction borrowing")
        realization = next(row for row in domains["realizations"] if row["domain"]["name"] == name)
        module = realization["ir"]
        require(module["actor_name"] == source["actor_name"] != "domain_widths", "physical domain rename")
        require(module["actor_name"] + ".fsm" == realization["domain"]["scheduled_fsm"], "partition/module artifact join")
        same(module["signal_widths"][plan["physical_name"]], width, "domain local private width")
        same(named(module["params"], "W")["value"], "8", "domain actor parameter distinct from local formal")
        require(not metadata_paths(module), "observed domain IR projection loss")

    require(set(live["cases"]) == {"generated_literal_port.isf", "generated_named_port.isf"}, "documented connected generated cohort")
    for name, row in live["cases"].items():
        value = private(row)
        scopes(value)
        require(value["formal_context"] is None, "generated-only source needs no direct physical allocation")
        declaration(named(value["actor"]["interface"]["inputs"], "data"),
                    "W", "actor_parameter", "generated_widths", 8)
        declaration(named(named(value["actor"]["transactions"], "child")["ports"]["inputs"], "payload"),
                    "ALIAS", "transaction_parameter", "child", 4)
        declaration(named(named(value["actor"]["transactions"], "child")["ports"]["inputs"], "data"),
                    "ACTOR_W", "actor_parameter", "generated_widths", 8)
        child = value["ir"]["children"]["child"]
        same({port["name"]: port["width"] for port in child["ports"]},
             {"start": 1, "data": 8, "payload": 4, "done": 1, "response": 4}, "complete connected child physical interface")
        same(named(child["params"], "W")["value"], "4", "child chooses local W4 while inherited data width is actor W8")
        spawn = next(clause for clause in named(value["actor"]["transactions"], "parent")["clauses"] if clause[0] == "spawn")
        params = next(clause for clause in spawn if isinstance(clause, list) and clause[0] == "params")
        same(params, ["params", ["W", "ACTIVATION" if "named" in name else "4"]],
             "authored activation value remains in source AST")
        same(value["ir"]["spawn_instances"][0]["parameter_overrides"], [{"name": "W", "value": "4"}],
             "separate selected activation environment")


first, generated, observed, wait, awaited, connected, live = map(load, (FIRST, GENERATED, OBSERVER, WAIT, AWAIT, CONNECTED, LIVE))
for packet in (first, generated, observed, wait, awaited, connected, live):
    require(packet["revision"] == REVISION, "exact selected own-repository revision")
    producer = packet["producer"]
    require(sha(Path(producer["path"]).read_bytes()) == producer["sha256"], "unchanged complete producer source")
    for row in packet["cases"].values():
        require(sha(row["source"].encode()) == row["sha256"], "complete source bytes")
    for path, digest in packet.get("baselines", {}).items():
        require(sha(Path(path).read_bytes()) == digest, "immutable prior packet join")
require(first["production_diff"] == "", "no production edits at first capture")
for path, identity in first["selected_inputs"].items():
    data = subprocess.check_output(["git", "show", REVISION + ":" + path])
    require(sha(data) == identity["sha256"] and len(data) == identity["bytes"], "selected implementation Git join")
require(generated["baseline"]["sha256"] == sha(Path(FIRST).read_bytes()), "first generated packet join")
originals = {**first["cases"], **generated["cases"]}
for name, row in originals.items():
    same(row["source"], observed["cases"][name]["source"], "observer repair preserves complete source")
    for kind, query in row["queries"].items():
        report = json.loads(query["stdout"]["text"])
        refused = name == "generated.isf" and kind != "schedule"
        require(query["exit"] == (1 if refused else 0), "original native epoch boundary")
        if kind != "schedule":
            require(report["success"] is (False if refused else True), "actual native success Boolean")
        if refused:
            require("leaves child port 'first.actor_result' unconnected" in report["diagnostics"][0]["message"],
                    "original exact composition refusal retained")
for name, row in wait["cases"].items():
    prior = generated["cases"][name.replace("_live", "")]["source"]
    require(row["source"] == prior.replace("(update response payload)", "(wait (== data 0)) (update response payload)"),
            "exact added runtime-count source read")
    value = private(row)
    child = value["ir"]["children"]["child"]
    require("data" not in {port["name"] for port in child["ports"]}, "owned leading-wait missing operand")
    entry = next(state for state in child["states"] if state["kind"] == "entry")
    waiting = next(state for state in child["states"] if state.get("wait_count_source") == "(== data 0)")
    require(len(entry["transitions"]) == 1 and entry["transitions"][0]["target"] == waiting["name"],
            "owned leading-wait unconditional entry lacks zero bypass")
    counter = waiting["wait_counter"]
    require(not any(assignment["lhs"] == counter and assignment["op"] != "--"
                    for state in child["states"] for assignment in state["assignments"]),
            "owned leading-wait never loads sampled count")
    for kind, query in row["queries"].items():
        require(query["exit"] == 0, "native admission despite owned runtime-wait defect")
for name, row in awaited["cases"].items():
    prior = wait["cases"][name.replace("_await", "_live")]["source"]
    require(row["source"] == prior.replace("(wait (== data 0))", "(await (== data 0))"),
            "exact await source control")
    for kind, query in row["queries"].items():
        require(query["exit"] == (0 if kind == "schedule" else 1), "malformed await source remains refused")
        if kind != "schedule":
            report = json.loads(query["stdout"]["text"])
            require(report["success"] is False and "Unsupported action form" in report["diagnostics"][0]["message"],
                    "intermediate malformed-await rendering refusal")
for name, row in connected["cases"].items():
    prior = awaited["cases"][name.replace("_connected_wait", "_await").replace("_connected_await", "_await")]["source"]
    for old, new in (("(ACTIVATION 4))", "(ACTIVATION 4) (ACTOR_W W))"),
                     ("(ports (input payload", "(ports (input data (width ACTOR_W)) (input payload"),
                     ("(bind (input payload", "(bind (input data data) (input payload")):
        prior = prior.replace(old, new)
    if name.endswith("_wait.isf"):
        prior = prior.replace("(await (== data 0))", "(wait (== data 0))")
        value = private(row)
        child = value["ir"]["children"]["child"]
        waiting = next(state for state in child["states"] if state.get("wait_count_source") == "(== data 0)")
        counter = waiting["wait_counter"]
        require(not any(assignment["lhs"] == counter and assignment["op"] != "--"
                        for state in child["states"] for assignment in state["assignments"]),
                "entry load defect persists with explicit connected count operand")
    require(row["source"] == prior, "exact connected formal/alias/binding source edits")
    for kind, query in row["queries"].items():
        malformed = name.endswith("_await.isf") and kind != "schedule"
        require(query["exit"] == (1 if malformed else 0), "exact connected native epoch")
        if malformed:
            report = json.loads(query["stdout"]["text"])
            require(report["success"] is False and "Unsupported action form" in report["diagnostics"][0]["message"],
                    "owned malformed-await opaque diagnostic")
            require("ARRAY(" in private(row)["files"]["child.fsm"], "actual malformed await rendering")
for name, row in live["cases"].items():
    prior = connected["cases"][name.replace("_port", "_connected_await")]["source"]
    require(row["source"] == prior.replace("(await (== data 0))", "(await data)"),
            "only documented scalar await spelling changes")
    for kind, query in row["queries"].items():
        require(query["exit"] == 0, "actual documented connected source success")
        if kind != "schedule":
            require(json.loads(query["stdout"]["text"])["success"] is True, "documented connected native Boolean")
require(first["cases"]["library_named.isf"]["source"] == first["cases"]["library_literal.isf"]["source"].replace(
    "(params (W 16))", "(params (W LIMIT))"), "exact single-slot library source peer")
qualify(observed, live)
for family in ("formal_owner", "domain_owner", "numeric_caller", "library_override", "child_width"):
    bad, bad_live = copy.deepcopy(observed), copy.deepcopy(live)
    name = {"formal_owner": "direct.isf", "domain_owner": "domains.isf", "numeric_caller": "atl.isf",
            "library_override": "library_named.isf", "child_width": "generated_named_port.isf"}[family]
    row = (bad_live if family == "child_width" else bad)["cases"][name]
    value = private(row)
    if family == "formal_owner":
        value["formal_context"]["plan"]["formals"]["left"]["payload"]["declaration"]["_width_declaration"]["owner"] = "right"
    elif family == "domain_owner":
        named(value["domain_sources"][0]["interface"]["inputs"], "data")["_width_declaration"]["owner"] = value["domain_sources"][0]["actor_name"]
    elif family == "numeric_caller":
        value["caller_unchanged"] = 1
    elif family == "library_override":
        value["actor"]["uses"][0]["parameter_overrides"][0]["value"] = "LIMIT"
    else:
        named(value["ir"]["children"]["child"]["ports"], "data")["width"] = 4
    row["private"]["stdout"]["text"] = json.dumps(value)
    try:
        qualify(bad, bad_live)
    except ValueError:
        pass
    else:
        raise ValueError("hostile source/physical allocation accepted: " + family)
print("physical width audit: lexical/physical/scope, native epochs, source erasure and copier counterfactual controls pass")
