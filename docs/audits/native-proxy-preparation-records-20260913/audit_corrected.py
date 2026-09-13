"""Source-derived, saved-only preparation qualification and independent oracles."""

import argparse
import ast
import copy
import hashlib
import json
from pathlib import Path
import re

import prepare

HERE, ROOT = prepare.HERE, prepare.ROOT
canonical = prepare.canonical
SOURCE_FIELDS = {"path", "device", "inode", "size_bytes", "sha256"}
STORE = ".artifacts/cache/rust-proxy-images/v1"


def pure_runtime_oracle():
    path = ROOT / "docs/audits/native-proxy-runtime-records-20260910/audit.py"
    tree = ast.parse(path.read_bytes())
    names = {"canonical", "key", "pairs", "validate"}
    selected = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in names]
    assert {node.name for node in selected} == names
    namespace = {"hashlib": hashlib, "json": json, "re": re,
                 "SCHEMA": "fsmgen.test.rust_proxy_image_reference.v1",
                 "FIELDS": {"schema", "reference_key", "image_key", "workspace", "workspace_identity", "selected_sources"}}
    exec(compile(ast.Module(body=selected, type_ignores=[]), str(path), "exec"), namespace)
    return namespace["validate"]


def fields(value, expected):
    assert type(value) is dict and set(value) == set(expected)


def integer(value, maximum=None):
    assert type(value) is int and value >= 0
    assert maximum is None or value <= maximum


def source(value, path, maximum=65536):
    fields(value, SOURCE_FIELDS)
    assert value["path"] == path
    for name in ("device", "inode", "size_bytes"):
        integer(value[name])
    assert value["size_bytes"] <= maximum
    assert type(value["sha256"]) is str and re.fullmatch("[0-9a-f]{64}", value["sha256"])


def validate(raw, vectors, old_runtime):
    assert type(raw) is str and raw.isascii() and len(raw) <= 65536
    value = json.loads(raw)
    assert canonical(value) == raw
    fields(value, vectors["base"])
    assert value["schema"] == "fsmgen.test.rust_proxy_fixture.v2"
    assert value["implementation"] == "native"
    assert value["selection_reason"] == vectors["base"]["selection_reason"]
    integer(value["ok"], 1)
    assert type(value["diagnostic"]) is str and len(value["diagnostic"]) <= 2048
    private, selected = value["compilation_sources"], value["sources"]
    assert type(private) is list and len(private) <= 2
    assert type(selected) is list and len(selected) in (0, 2)
    workspace = vectors["base"]["image_reference"]["record"]["workspace"]
    key = vectors["base"]["image_reference"]["record"]["image_key"]
    for index, item in enumerate(private):
        source(item, f"{workspace}/rust-tools/{('rustup.c', 'rustup')[index]}")
    for index, item in enumerate(selected):
        source(item, f"{STORE}/images/{key}/{('rustup.c', 'rustup')[index]}")
        assert len(private) == 2
        assert all(item[name] == private[index][name] for name in ("sha256", "size_bytes"))
    compilation = value["compilation"]
    argv = value["compilation_argv"]
    if argv is not None:
        assert private and argv == vectors["base"]["compilation_argv"]
    if compilation is not None:
        assert argv is not None
        fields(compilation, vectors["compiler_fields"])
        for field in ("schema", "schema_version", "stage", "timeout_seconds", "capture_limit_bytes"):
            assert type(compilation[field]) is type(vectors["base"]["compilation"][field])
            assert compilation[field] == vectors["base"]["compilation"][field]
        for field in ("ok", "timed_out", "output_limited", "exec_failed"):
            integer(compilation[field], 1)
        assert compilation["ok"] == int(compilation["status"] == "success")
        for field in ("stdout", "stderr"):
            assert type(compilation[field]) is str and all(ord(char) <= 255 for char in compilation[field])
            integer(compilation[field + "_bytes"])
            assert len(compilation[field]) == compilation[field + "_bytes"]
        assert compilation["stdout_bytes"] + compilation["stderr_bytes"] <= 4096
        cleanup = compilation["cleanup"]
        fields(cleanup, vectors["base"]["compilation"]["cleanup"])
        assert cleanup["containment"] == "rust_proxy_compiler_group"
        for field in set(cleanup) - {"containment"}:
            integer(cleanup[field], 1)
        if compilation["ok"]:
            assert compilation["exit_code"] == 0 and compilation["signal"] == 0
            assert not any(compilation[field] for field in ("timed_out", "output_limited", "exec_failed"))
            assert compilation["exec_error"] is None and not cleanup["surviving_descendants"]
    settled = compilation is not None and compilation["ok"] and all(
        compilation["cleanup"][field] for field in ("leader_reaped", "group_gone"))
    assert not selected or settled
    identities = [*private, *selected]
    reference = value["image_reference"]
    if reference is not None:
        fields(reference, ["record", "global", "private"])
        assert selected
        record = reference["record"]
        assert record["selected_sources"] == selected and record["workspace"] == workspace
        actual = canonical(record).encode("ascii")
        for name, path in [("global", f"{STORE}/references/{record['reference_key']}.json"),
                           ("private", f"{workspace}/rust-tools/image-reference.json")]:
            source(reference[name], path, 4096)
            assert reference[name]["size_bytes"] == len(actual)
            assert reference[name]["sha256"] == hashlib.sha256(actual).hexdigest()
        # New canonical prefix is checked above. The old oracle independently
        # checks every unchanged runtime-record field/type/key/order rule.
        case = ".artifacts/tmp/native-proxy-image-custody/cases/fsmgen-PreparationOracle20260913"
        translated = copy.deepcopy(record)
        for item in translated["selected_sources"]:
            assert item["path"].startswith(STORE + "/images/")
            item["path"] = case + item["path"][len(STORE):]
        old_runtime(case, canonical(translated))
        identities += [reference["global"], reference["private"], record["workspace_identity"]]
    assert len({row["device"] for row in identities}) <= 1
    assert len({row["inode"] for row in identities}) == len(identities)
    if value["ok"]:
        assert settled and len(selected) == 2 and reference is not None
        assert value["executable"] == selected[1]["path"]
        assert value["status"] == "success" and value["failure_stage"] is None
    else:
        assert value["executable"] is None and value["status"] != "success" and value["diagnostic"]
        stage = value["failure_stage"]
        if stage != "compile":
            assert value["status"] == "invocation_error"
        if stage in ("invocation", "workspace", "source"):
            assert compilation is None and argv is None and not selected
        if stage in ("invocation", "workspace"):
            assert not private
        if stage == "source":
            assert len(private) <= 1
        if stage in ("artifact_admission", "image_admission", "image_reference"):
            assert settled
        if stage in ("image_admission", "image_reference"):
            assert len(private) == 2
        if compilation is not None and not compilation["ok"]:
            assert stage == "compile" and value["status"] == compilation["status"]
        if stage == "compile":
            assert len(private) <= 1 and not settled
            if compilation is None:
                assert value["status"] == "invocation_error"
            elif compilation["ok"]:
                assert value["status"] == "cleanup_failed"
    return value


def rejected(raw, vectors, old_runtime):
    try:
        validate(raw, vectors, old_runtime)
    except (AssertionError, ValueError, TypeError, KeyError, IndexError):
        return True
    raise AssertionError("independent oracle accepted invalid record")


def check_result(result, vectors, old_runtime):
    assert result["schema"] == "fsmgen.inactive_preparation_qualification.v1" and result["success"] is True
    assert type(result["forbidden_process_attempts"]) is int and result["forbidden_process_attempts"] == 0
    assert type(result["fixture_allocations"]) is int and result["fixture_allocations"] == 0
    assert result["original_v1_raw"] == vectors["original_v1_raw"]
    assert [row["name"] for row in result["rows"]] == [row["name"] for row in vectors["vectors"]]
    for row, vector in zip(result["rows"], vectors["vectors"]):
        assert type(row["accepted"]) is int and row["accepted"] == int(vector["accept"])
        if vector["accept"]:
            assert row["encoded"] == vector["raw"] and row["diagnostic"] == ""
            validate(row["encoded"], vectors, old_runtime)
        else:
            assert row["encoded"] is None and row["diagnostic"]
            assert vector["reason"] is None or vector["reason"] in row["diagnostic"]
            rejected(vector["raw"], vectors, old_runtime)
    assert [row["name"] for row in result["mutants"]] == ["validation_of_sanitized_copy", "omitted_reference_validation"]
    for row in result["mutants"]:
        rejected(row["raw"], vectors, old_runtime)
    assert [row["name"] for row in result["interface_controls"]] == [
        "extra encode argument", "missing decode argument", "character input", "reference input"]
    assert all(row["rejected"] == 1 for row in result["interface_controls"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--admit-only", action="store_true")
    parser.add_argument("--verify-saved", action="store_true")
    options = parser.parse_args()
    for record in json.loads((HERE / "corrected-preflight-pins.json").read_bytes()):
        body = (ROOT / record["path"]).read_bytes()
        assert len(body) == record["size_bytes"] and hashlib.sha256(body).hexdigest() == record["sha256"]
    vectors = prepare.build()
    assert vectors == json.loads((HERE / "vectors.json").read_bytes())
    old_runtime = pure_runtime_oracle()
    for vector in vectors["vectors"]:
        if vector["accept"]:
            validate(vector["raw"], vectors, old_runtime)
        else:
            rejected(vector["raw"], vectors, old_runtime)
    if options.admit_only:
        assert not (HERE / "result/qualification.json").exists()
        print(json.dumps(dict(admitted=True, vectors=len(vectors["vectors"]), native_authorized=False)))
        return
    result = json.loads((HERE / "result/qualification.json").read_bytes())
    check_result(result, vectors, old_runtime)
    falsifiers = []
    for name, change in [
        ("missing_case", lambda v: v["rows"].pop()),
        ("changed_verdict", lambda v: v["rows"][0].update(accepted=0)),
        ("changed_encoded_bytes", lambda v: v["rows"][0].update(encoded=v["rows"][0]["encoded"] + "\n")),
        ("lost_mutant", lambda v: v["mutants"].pop()),
        ("hidden_launch", lambda v: v.update(forbidden_process_attempts=1)),
    ]:
        changed = copy.deepcopy(result)
        change(changed)
        try:
            check_result(changed, vectors, old_runtime)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError("result falsifier was accepted: " + name)
    report = dict(schema="fsmgen.inactive_preparation_audit.v1", success=True,
                  vectors=len(vectors["vectors"]), accepted=sum(row["accept"] for row in vectors["vectors"]),
                  result_falsifiers=falsifiers, original_v1_unchanged=True,
                  scope="Finite inert records and serialization; no native authority or current filesystem custody.")
    if options.verify_saved:
        assert report == json.loads((HERE / "result/audit.json").read_bytes())
    else:
        with (HERE / "result/audit.json").open("x") as stream:
            stream.write(json.dumps(report, sort_keys=True, indent=2) + "\n")
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
