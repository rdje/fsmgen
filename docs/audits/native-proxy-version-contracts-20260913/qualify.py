"""Finite, source-bound compatibility checks; no fixture/native/old main replay."""

import argparse
import copy
import itertools
import json
from pathlib import Path

import source_contracts as source
from dispatch import select_layout

HERE = Path(__file__).resolve().parent


def write_new(path, value):
    with path.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(value, indent=2, sort_keys=True) + "\n")


def rejects(function, *args):
    try:
        function(*args)
    except ValueError:
        return True
    raise AssertionError("invalid control was accepted")


def source_checks(contracts):
    # Compile only pure command/retention definitions. No module import can
    # construct a collector, load native libraries or inspect a native birth.
    launcher = source.selected_functions("scripts/fixture_policy_log.py",
        ["require_scope", "command", "retained_command"],
        {"json": json, "SCOPES": ("fixture_path", "execution_context", "daemon_context"),
         "LIFETIME_SECONDS": source.literal("scripts/fixture_policy_log.py", "LIFETIME_SECONDS")})
    reader = source.selected_functions("scripts/analyze_fixture_policy.py",
                                      ["verify_collector_command"], {})["verify_collector_command"]
    entry = source.selected_functions("scripts/observe_fixture_startup.py", ["main_entry"], {})["main_entry"]
    prefix = contracts["capture"]["legacy_prefix"]
    canonical = contracts["capture"]["canonical_root"] + "/"
    rows = []
    # These are inert strings, not filesystem allocations or persisted roots.
    for spelling in ("<repo>", 'root with spaces', 'root"quoted', 'root\\escaped'):
        root = Path(spelling)
        argv = launcher["command"](root, scope="execution_context")
        retained = launcher["retained_command"](argv, root)
        receipt = dict(schema="fsmgen.fixture_policy_log.v1", scope="execution_context", command=retained)
        reader(receipt)
        changes = {
            "canonical_only": retained[-1].replace(prefix, canonical),
            "mixed_prefix": retained[-1].replace(' OR subsystem',
                ' OR eventMessage CONTAINS ' + json.dumps("<repo>/" + canonical) + ' OR subsystem'),
            "missing_delimiter": retained[-1].replace(prefix, prefix.rstrip("/")),
        }
        for name, predicate in changes.items():
            changed = copy.deepcopy(receipt)
            changed["command"][-1] = predicate
            rejects(reader, changed)
        wrong_schema = dict(receipt, schema="fsmgen.fixture_policy_log.v2")
        rejects(reader, wrong_schema)
        # Wrong quoting must survive normalization, never be repaired into a
        # valid old command by replacing a loosely matching root substring.
        malformed = list(argv)
        malformed[-1] = malformed[-1].replace(json.dumps(str(root / prefix) + "/", ensure_ascii=False),
                                             str(root / prefix) + "/")
        changed = dict(receipt, command=launcher["retained_command"](malformed, root))
        rejects(reader, changed)
        rows.append(dict(root_spelling=spelling, retained_command=retained,
                         rejected=[*changes, "wrong_schema", "unquoted_prefix"]))
    original = json.loads(source.body(source.ORIGINAL_COLLECTOR))
    daemon = launcher["command"](Path("<repo>"), scope="daemon_context")
    assert original["schema"] == "fsmgen.fixture_policy_log.v1" and original["scope"] == "daemon_context"
    assert daemon == original["command"]
    rejects(reader, original)  # execution-context reader must not accept daemon-only evidence
    for role in ("rust-proxy", "rust-wrapper"):
        assert entry({"target_role": role}, Path("<repo>")) == "unknown"
        assert entry({"target_role": role}, Path("<repo>"), include_wrapper=True) == "unknown"
    assert contracts["capture"]["legacy_native_return_order"] == ["executable", "source"]
    assert [path.rsplit("/", 1)[-1] for path in contracts["capture"]["snapshot_paths"]] == [
        "rust-tool-resolution", "image-reference.json", "$runtime_key.json", "rustup.c", "rustup"]
    return dict(retained_command_controls=rows, original_daemon_preserved=True,
                daemon_rejected_by_execution_reader=True, native_main_entry="unknown")


def qualification(contracts, plan):
    preparation = contracts["preparation"]
    v1, v2 = preparation["legacy_schema"], preparation["native_schema"]
    schemas = [v1, v2, "unknown", None]
    implementations = ["perl", "native", None, "unknown", [], 1, True]
    sets = [preparation["legacy_fields"], preparation["native_fields"],
            [key for key in preparation["legacy_fields"] if key != "diagnostic"],
            [*preparation["legacy_fields"], "unknown"]]
    # This independently declared finite relation comes from the original
    # producer branches plus the pre-existing native design, not the selector.
    expected = {tuple(row["coordinates"]): row["layout"] for row in plan["accepted_coordinates"]}
    rows = []
    for coordinates in itertools.product(range(len(schemas)), range(len(implementations)), range(len(sets))):
        schema_index, implementation_index, fields_index = coordinates
        record = dict.fromkeys(sets[fields_index])
        record.update(schema=schemas[schema_index], implementation=implementations[implementation_index], ok=0)
        try:
            actual = select_layout(record, contracts)
        except ValueError:
            actual = "rejected"
        assert actual == expected.get(coordinates, "rejected"), (coordinates, actual)
        rows.append(dict(coordinates=list(coordinates), outcome=actual))
    base = dict.fromkeys(preparation["legacy_fields"])
    base.update(schema=v1, implementation=None, ok=0)
    rejected = []
    for field, value in [("ok", True), ("ok", 1), ("ok", "0"), ("executable", "inert/rustup")]:
        changed = dict(base, **{field: value})
        rejects(select_layout, changed, contracts)
        rejected.append(dict(field=field, value=value))
    for value in (None, [], "record", 0):
        rejects(select_layout, value, contracts)
    original = json.loads(source.body(source.ORIGINAL_PREPARATION))["prepared"]
    before = json.dumps(original, sort_keys=True)
    assert select_layout(original, contracts) == "legacy_private_native_v1"
    assert json.dumps(original, sort_keys=True) == before
    # Deliberately wrong selectors must disagree on existing, pinned examples.
    # Neither successful legacy native preparation nor pre-selection failure
    # can be classified by "native implies v2" or "v1 implies Perl".
    counterexamples = [dict(control="native_implies_v2", original_schema=original["schema"],
                            correct=select_layout(original, contracts), wrong="shared_native_v2"),
                       dict(control="v1_implies_perl", correct=select_layout(base, contracts),
                            wrong="selected_perl_v1")]
    assert all(row["correct"] != row["wrong"] for row in counterexamples)
    return dict(schema="fsmgen.inactive_proxy_version_qualification.v1", rows=rows,
                unselected_failure_controls=rejected, malformed_envelopes_rejected=4,
                classifier_counterexamples=counterexamples, source_checks=source_checks(contracts),
                original_preparation_preserved=True, native_executions=0, fixture_allocations=0,
                limitations=plan["limitations"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prepare", action="store_true")
    parser.add_argument("--admit-only", action="store_true")
    parser.add_argument("--verify-saved", action="store_true")
    options = parser.parse_args()
    pins = json.loads((HERE / ("source-pins.json" if options.prepare else "preflight-pins.json")).read_bytes())
    for record in pins:
        source.verify_pin(record)
    contracts = source.derive()
    if options.prepare:
        write_new(HERE / "contracts.json", contracts)
        print(json.dumps(dict(source_contracts="prepared", inputs=len(contracts["inputs"]))))
        return
    assert contracts == json.loads((HERE / "contracts.json").read_bytes())
    if options.admit_only:
        print(json.dumps(dict(admitted=True, original_sources_unchanged=True, native_authorized=False)))
        return
    plan = json.loads((HERE / "plan.json").read_bytes())
    result = qualification(contracts, plan)
    if options.verify_saved:
        assert result == json.loads((HERE / "result/qualification.json").read_bytes())
    else:
        write_new(HERE / "result/qualification.json", result)
    print(json.dumps(dict(qualified=True, version_cases=len(result["rows"]),
                          source_bound=True, native_authorized=False), sort_keys=True))


if __name__ == "__main__":
    main()
