"""Re-derive private envelope bytes and frozen reader results independently."""
import ast
import copy
import hashlib
import json
from pathlib import Path
import re
import struct
import types

import prepare
import qualify

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PRIOR = "docs/audits/native-proxy-capture-dispatch-20260913"


def capture_oracle():
    names = {"definitions", "codecs", "carrier", "oracle"}
    tree = ast.parse((ROOT / PRIOR / "audit.py").read_text())
    functions = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in names]
    assert {node.name for node in functions} == names
    scalar = lambda value: json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False)
    namespace = dict(ROOT=ROOT, Path=Path, ast=ast, re=re, json=json, struct=struct, copy=copy, types=types,
        hashlib=hashlib, PRIVATE=".artifacts/tmp/process-supervisor-tests/", STORE=".artifacts/cache/rust-proxy-images/v1",
        CASE=".artifacts/tmp/native-proxy-image-custody/cases/fsmgen-CaptureOracle", prepare=types.SimpleNamespace(canonical=scalar))
    exec(compile(ast.Module(body=functions, type_ignores=[]), PRIOR + "/audit.py", "exec"), namespace)
    runtime, observation = namespace["codecs"]()
    return lambda value, root: namespace["oracle"](value, root, runtime, observation)


def expand(value, root):
    if isinstance(value, list):return [expand(item, root) for item in value]
    if isinstance(value, dict):return {key: expand(item, root) for key, item in value.items()}
    if isinstance(value, str):return value.replace("<repo>", str(root)).replace("<system-perl>", qualify.PERL)
    return value


def envelope(record, root, plan, commands, inspect):
    assert type(record) is dict and set(record) == {"schema", "normal_uid", "capture", "collector_contract", "limits"}
    assert record["schema"] == plan["new_schema"] and record["limits"] == plan["limits"]
    assert type(record["normal_uid"]) is int and record["normal_uid"] == 501
    capture = record["capture"]
    assert capture["layout"] == "shared_native_v2"
    checked = inspect(expand(capture, root), root)
    fixture = checked["evidence"]["fixture"]
    workspace = capture["workspace"]
    for frame in (capture["before"], capture["after"]):
        processes = frame["processes"]
        assert processes[0]["executable"] == "<repo>/" + fixture
        assert processes[0]["command"] == "<repo>/" + fixture + " which cargo"
        assert [row["executable"] for row in processes[1:]] == ["<system-perl>", "<system-perl>"]
        assert processes[1]["command"] == f"/usr/bin/perl -Iperl -It/lib <repo>/{workspace}/rust-tool-resolution <repo>/{workspace}/rust-tools"
        test = "t/1669-task-acceptance-fixture-runtime.t"
        assert processes[2]["command"] in ("/usr/bin/perl " + test, "/usr/bin/perl <repo>/" + test)
    collector = record["collector_contract"]
    assert type(collector) is dict and set(collector) == {"schema", "scope", "command"}
    assert collector["schema"] == "fsmgen.fixture_policy_log.v2" and collector["command"] == commands[collector["scope"]]
    raw = prepare.canonical(record)
    assert len(raw) <= plan["max_bytes"]
    return raw


def legacy_reader(modules, example, raw):
    digest = prepare.digest(raw)
    kind = example["kind"]
    if kind == "associations":return modules[kind].read_manifest(raw, digest)
    if kind == "diagnostics":return modules[kind].read_report(raw, digest)
    if kind == "publication":return modules[kind].read_receipt(raw, digest)
    if kind == "archive":return modules[kind].read_index(raw, digest)
    if kind == "archive_page":
        descriptor = dict(example["descriptor"], bytes=len(raw), sha256=digest)
        return modules["archive"].read_page(raw, descriptor, example["context_sha256"])
    value = json.loads(raw)
    modules["diagnostics"].retained_scope(value)
    return value


def verify(result, vectors, plan):
    assert set(result) == {"schema", "roots", "rows", "raw_controls", "legacy", "process_attempts"}
    assert result["schema"] == "fsmgen.inactive_retained_qualification.v1" and result["process_attempts"] == []
    assert result["roots"] == list(qualify.ROOT_SUFFIXES)
    prior = json.loads((ROOT / PRIOR / "result/qualification.json").read_bytes())
    commands = {row["scope"]: row["command"] for row in prior["collections"] if row["root"] == "ordinary" and row["schema"] == "fsmgen.fixture_policy_log.v2"}
    inspect = capture_oracle()
    rows = {(row["root"], row["name"]): row for row in result["rows"]}
    expected = {(suffix, vector["name"]): vector for suffix in result["roots"] for vector in vectors["vectors"]}
    assert len(rows) == len(result["rows"]) == len(expected) and set(rows) == set(expected)
    for (suffix, name), vector in expected.items():
        record = prepare.apply(vector, vectors["records"])
        root = ROOT / ".artifacts/tmp/inert-retained-roots" / suffix
        try:
            raw = envelope(record, root, plan, commands, inspect)
        except (AssertionError, KeyError, ValueError, TypeError):
            assert vector["accept"] is False, name
            assert set(rows[suffix, name]) == {"root", "name", "accepted", "error"} and rows[suffix, name]["error"]
        else:
            assert vector["accept"] is True, name
            assert rows[suffix, name] == dict(root=suffix, name=name, accepted=True, bytes=len(raw), sha256=prepare.digest(raw))
            assert (HERE / "result/envelopes" / (name + ".json")).read_bytes() == raw
        assert rows[suffix, name]["accepted"] is vector["accept"]
    controls = {(row["root"], row["name"]): row for row in result["raw_controls"]}
    names = {"wrong_anchor", "pretty_json", "missing_lf", "duplicate_schema", "oversized_bytes", "absolute_process_paths"}
    assert len(controls) == len(result["raw_controls"]) and set(controls) == {(root, name) for root in result["roots"] for name in names}
    selected = vectors["records"]["shared_0_execution_context"]
    original = prepare.canonical(selected)
    raw_values = dict(wrong_anchor=original, pretty_json=(json.dumps(selected, sort_keys=True, indent=2) + "\n").encode(),
        missing_lf=original[:-1], duplicate_schema=original.replace(b'{"capture":', b'{"schema":"duplicate","capture":', 1),
        oversized_bytes=b" " * (plan["max_bytes"] + 1))
    for (suffix, name), row in controls.items():
        assert row["rejected"] is True
        if name != "absolute_process_paths":
            assert row["bytes"] == len(raw_values[name]) and row["sha256"] == prepare.digest(raw_values[name])
    modules = prepare.libraries()
    old_rows = {(row["root"], row["kind"], row.get("cross", "accepted")): row for row in result["legacy"]}
    domain = {(root, example["kind"], kind) for root in result["roots"] for example in vectors["legacy"]
              for kind in ("accepted", "old_to_new", "new_to_old", "changed_prefix_or_fields")}
    assert len(old_rows) == len(result["legacy"]) == len(domain) and set(old_rows) == domain
    for suffix in result["roots"]:
        for example in vectors["legacy"]:
            raw = bytes.fromhex(example["raw_hex"])
            parsed = legacy_reader(modules, example, raw)
            assert parsed == json.loads(raw)
            assert old_rows[suffix, example["kind"], "accepted"] == dict(root=suffix, kind=example["kind"], accepted=True,
                raw_sha256=prepare.digest(raw), interpreted_sha256=prepare.digest(prepare.canonical(parsed)))
            assert parsed.get("schema") != plan["new_schema"]
            for name, changed in [("new_to_old", original), ("changed_prefix_or_fields", qualify.changed_legacy(example, selected))]:
                try:legacy_reader(modules, example, changed)
                except ValueError:pass
                else:raise AssertionError("original frozen reader accepted cross-version bytes")
                assert old_rows[suffix, example["kind"], name]["rejected"] is True
            assert old_rows[suffix, example["kind"], "old_to_new"]["rejected"] is True
    return dict(envelope_cases=len(rows), accepted=sum(row["accepted"] for row in rows.values()), raw_controls=len(controls), legacy_checks=len(old_rows))


def main():
    plan = prepare.authenticate()
    qualify.check_pins()
    vectors = json.loads((HERE / "vectors.json").read_bytes())
    assert vectors == prepare.build()
    result = json.loads((HERE / "result/qualification.json").read_bytes())
    report = verify(result, vectors, plan)
    bad = []
    value = copy.deepcopy(result);value["rows"].pop();bad.append(value)
    value = copy.deepcopy(result);value["rows"][0]["sha256"] = "0" * 64;bad.append(value)
    value = copy.deepcopy(result);value["raw_controls"].pop();bad.append(value)
    value = copy.deepcopy(result);value["legacy"].pop();bad.append(value)
    value = copy.deepcopy(result);next(row for row in value["legacy"] if row.get("accepted"))["interpreted_sha256"] = "0" * 64;bad.append(value)
    value = copy.deepcopy(result);value["process_attempts"] = ["hidden publication"];bad.append(value)
    for value in bad:
        try:verify(value, vectors, plan)
        except (AssertionError, KeyError):pass
        else:raise AssertionError("altered saved result survived")
    report.update(saved_result_falsifiers=len(bad), source_revision=plan["source_revision"],
        scope="Private envelope and frozen-format interpretation only; no original archive replay, native authentication, collector outcome or public artifact consumption.")
    if "--verify-saved" in __import__("sys").argv:
        assert json.loads((HERE / "result/audit.json").read_bytes()) == report
    else:
        with (HERE / "result/audit.json").open("x") as stream:json.dump(report, stream, sort_keys=True, indent=2);stream.write("\n")
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
