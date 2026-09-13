"""Independent saved-data oracle using unchanged legacy admission and codecs.

Only named pure definitions are extracted from historical audit sources. Their
mains, original fixture builders, native APIs and collectors never execute.
"""
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
PRIVATE = ".artifacts/tmp/process-supervisor-tests/"
STORE = ".artifacts/cache/rust-proxy-images/v1"
CASE = ".artifacts/tmp/native-proxy-image-custody/cases/fsmgen-CaptureOracle"


def definitions(path, names, namespace):
    tree = ast.parse((ROOT / path).read_text())
    selected = [node for node in tree.body if isinstance(node, (ast.FunctionDef, ast.Assign))
                and (getattr(node, "name", None) in names or isinstance(node, ast.Assign)
                     and any(isinstance(target, ast.Name) and target.id in names for target in node.targets))]
    present = {node.name for node in selected if isinstance(node, ast.FunctionDef)}
    present.update(target.id for node in selected if isinstance(node, ast.Assign) for target in node.targets if isinstance(target, ast.Name))
    assert present == set(names)
    exec(compile(ast.Module(body=selected, type_ignores=[]), path, "exec"), namespace)
    return namespace


def codecs():
    runtime = definitions("docs/audits/native-proxy-runtime-records-20260910/audit.py",
        ["SCHEMA", "FIELDS", "canonical", "key", "pairs", "validate"], dict(json=json, hashlib=hashlib, re=re))
    observation = definitions("docs/audits/native-proxy-observation-records-20260910/audit.py",
        ["SCHEMA", "FIELDS", "BIRTH", "canonical", "key", "fields", "integer", "digest", "path", "pairs", "validate"],
        dict(json=json, hashlib=hashlib, re=re))
    return runtime, observation


def carrier(source):
    assert type(source) is dict and set(source) == {"identity", "bytes_hex"}
    identity = source["identity"]
    assert type(identity) is dict and set(identity) == {"path", "device", "inode", "size_bytes", "sha256"}
    assert all(type(identity[key]) is int and identity[key] >= 0 for key in ("device", "inode", "size_bytes"))
    encoded = source["bytes_hex"]
    assert type(encoded) is str and re.fullmatch(r"(?:[0-9a-f]{2})*", encoded) and len(encoded) <= 131072
    raw = bytes.fromhex(encoded)
    assert identity["size_bytes"] == len(raw) and identity["sha256"] == hashlib.sha256(raw).hexdigest()
    return raw


def oracle(value, root, runtime, observation):
    assert type(value) is dict and set(value) == {"schema", "layout", "workspace", "workspace_identity", "observer_birth",
        "evidence_directory_identity", "request", "before", "after"}
    assert value["schema"] == "fsmgen.inactive_capture_input.v1"
    layout = value["layout"]
    assert layout in ("selected_perl_v1", "legacy_private_native_v1", "shared_native_v2")
    assert re.fullmatch(re.escape(PRIVATE) + r"fsmgen-[A-Za-z0-9_]+", value["workspace"])
    assert set(value["request"]) == {prefix + key for prefix in ("", "parent_", "ancestor_") for key in ("pid", "start_sec", "start_usec")}
    assert all(type(number) is int and number >= 0 for number in value["request"].values())
    before, after = value["before"], value["after"]
    assert type(before) is dict and set(before) == {"processes", "sources", "observation"}
    assert prepare.canonical(before) == prepare.canonical(after)
    assert len(before["processes"]) == 3
    for process in before["processes"]:
        assert set(process) == {"identity", "executable", "command"}
        birth = process["identity"]
        assert set(birth) == {"pid", "ppid", "uid", "ruid", "start_sec", "start_usec"}
        assert all(type(number) is int and number >= 0 for number in birth.values())
        assert 1 < birth["pid"] <= 2147483647 and birth["start_usec"] < 1000000
    assert len({process["identity"]["pid"] for process in before["processes"]}) == 3
    sources = before["sources"]
    assert type(sources) is list
    bodies = [carrier(source) for source in sources]
    workspace = value["workspace"]
    shared = layout == "shared_native_v2"
    native = layout != "selected_perl_v1"
    if shared:
        assert len(sources) == 5
        assert len(bodies[1]) <= 4096 and bodies[1] == bodies[2]
        raw = bodies[1].decode("ascii")
        record = json.loads(raw)
        assert raw == prepare.canonical(record)
        key = hashlib.sha256(b"fsmgen.rust_proxy_image.v1\0"
            + struct.pack(">Q", len(bodies[3])) + bodies[3] + struct.pack(">Q", len(bodies[4])) + bodies[4]).hexdigest()
        expected_paths = [workspace + "/rust-tool-resolution", workspace + "/rust-tools/image-reference.json",
            STORE + "/references/" + runtime["key"](workspace) + ".json", STORE + "/images/" + key + "/rustup.c", STORE + "/images/" + key + "/rustup"]
        assert [source["identity"]["path"] for source in sources] == expected_paths
        assert record["workspace_identity"] == value["workspace_identity"] and record["workspace"] == workspace
        assert record["image_key"] == key and record["selected_sources"] == [source["identity"] for source in sources[3:]]
        adapted = copy.deepcopy(record)
        for source in adapted["selected_sources"]:
            assert source["path"].startswith(STORE + "/images/")
            source["path"] = CASE + source["path"][len(STORE):]
        runtime["validate"](CASE, prepare.canonical(adapted))
        hold_body = carrier(before["observation"])
        assert len(hold_body) <= 4096
        hold = json.loads(hold_body)
        assert hold_body == prepare.canonical(hold).encode("ascii")
        assert hold["target_birth"] == before["processes"][0]["identity"] and hold["observer_birth"] == value["observer_birth"]
        assert hold["observer_birth"]["uid"] == hold["observer_birth"]["ruid"] == 501
        assert hold["observer_birth"]["pid"] != hold["target_birth"]["pid"]
        assert hold["evidence_directory_identity"] == value["evidence_directory_identity"]
        assert hold["evidence_directory"].startswith(".artifacts/logs/")
        assert hold["selected_sources"] == record["selected_sources"] and hold["image_key"] == key
        assert before["observation"]["identity"]["path"] == STORE + "/references/" + observation["key"](hold) + ".json"
        adapted = copy.deepcopy(hold)
        for source in adapted["selected_sources"]:
            source["path"] = CASE + source["path"][len(STORE):]
        observation["validate"](CASE, prepare.canonical(adapted))
        objects = [source["identity"] for source in sources] + [before["observation"]["identity"], value["workspace_identity"], value["evidence_directory_identity"]]
        assert len({obj["device"] for obj in objects}) == 1
        assert len({(obj["device"], obj["inode"]) for obj in objects}) == len(objects)
        c, image = bodies[3:]
    else:
        assert all(value[key] is None for key in ("workspace_identity", "observer_birth", "evidence_directory_identity")) and before["observation"] is None
        expected_paths = [workspace + "/rust-tool-resolution", workspace + "/rust-tools/rustup"]
        if native:
            expected_paths.append(workspace + "/rust-tools/rustup.c")
        assert [source["identity"]["path"] for source in sources] == expected_paths
        if native:
            image, c = bodies[1:]
    if native:
        template = (ROOT / "t/fixtures/rust-tool-proxy.c").read_bytes()
        assert c in [f"#define PROXY_NONZERO {mode}\n".encode() + template for mode in (0, 1)]
        assert len(image) >= 32 and struct.unpack_from("<IIII", image) == (0xfeedfacf, 0x0100000c, 0, 2)
    # Reuse the exact old native birth/UID/ancestry/argv/readback checker.
    # Only the new canonical source family is translated to its old private
    # shape, after independently checking every new source and reference above.
    frames = copy.deepcopy([before, after])
    original_fixture = expected_paths[-1] if shared else expected_paths[1]
    private_fixture = workspace + "/rust-tools/rustup"
    if shared:
        for frame in frames:
            process = frame["processes"][0]
            assert process["executable"] == str(root / original_fixture)
            assert process["command"] == str(root / original_fixture) + " which cargo"
            process["executable"] = str(root / private_fixture)
            process["command"] = str(root / private_fixture) + " which cargo"
            frame["sources"] = [frame["sources"][0], frame["sources"][4], frame["sources"][3]]
            frame["sources"][1]["identity"]["path"] = private_fixture
            frame["sources"][2]["identity"]["path"] = private_fixture + ".c"
    calls = {}
    class Native:
        def field(self, pid, field):
            count = calls.get((pid, field), 0)
            calls[pid, field] = count + 1
            process = next(p for p in frames[min(count, 1)]["processes"] if p["identity"]["pid"] == pid)
            result = copy.deepcopy(process[field])
            return Path(result) if field == "executable" else result
        def identity(self, pid): return self.field(pid, "identity")
        def executable(self, pid): return self.field(pid, "executable")
        def command(self, pid): return self.field(pid, "command")
    namespace = dict(Path=Path, re=re, os=types.SimpleNamespace(getuid=lambda: 501))
    names = ["IDENTITY_FIELDS", "TEST_PATH", "SUPERVISOR_TEST_PATH", "_test_command", "_workspace", "_supervisor_wrapper", "validate_target"]
    namespace = definitions("scripts/fixture_kernel_sampler.py", names, namespace)
    source_map = {source["identity"]["path"]: source["identity"] for source in frames[0]["sources"]}
    namespace["source_identity"] = lambda path, root: copy.deepcopy(source_map[str(path.relative_to(root))])
    namespace["_native_rust_sources"] = lambda path, root: [copy.deepcopy(source_map[str(path.relative_to(root))]), copy.deepcopy(source_map[str(path.relative_to(root)) + ".c"])]
    evidence = namespace["validate_target"](value["request"], Native(), root)
    if shared:
        evidence["fixture"] = original_fixture
        evidence["sources"] = [source["identity"] for source in sources]
    return dict(layout=layout, evidence=evidence, main_entry="unknown", runtime_authorized=False)


def expected_collector(root, schema, scope):
    old = definitions("scripts/fixture_policy_log.py", ["SCOPES", "LIFETIME_SECONDS", "require_scope", "command", "retained_command"], dict(json=json))
    argv = old["command"](root, scope=scope)
    if schema.endswith(".v1") or scope == "daemon_context":
        return old["retained_command"](argv, root)
    assert schema == "fsmgen.fixture_policy_log.v2"
    legacy = 'eventMessage CONTAINS "<repo>/' + PRIVATE + '"'
    canonical = 'eventMessage CONTAINS "<repo>/' + STORE + '/"'
    if scope == "fixture_path":
        predicate = 'process == "syspolicyd" AND (' + legacy + " OR " + canonical + ")"
    else:
        assert scope == "execution_context"
        predicate = 'process == "syspolicyd" AND (' + legacy + " OR " + canonical + ' OR subsystem == "com.apple.syspolicy.exec")'
    return [*argv[:-1], predicate]


def check_result(result, vectors):
    assert set(result) == {"schema", "roots", "rows", "collections", "mutants", "process_attempts"}
    assert result["schema"] == "fsmgen.inactive_capture_qualification.v1" and result["process_attempts"] == []
    assert result["roots"] == list(qualify.ROOT_SUFFIXES)
    expected = {(suffix, vector["name"]): vector for suffix in qualify.ROOT_SUFFIXES for vector in vectors["vectors"]}
    rows = {(row["root"], row["name"]): row for row in result["rows"]}
    assert len(rows) == len(result["rows"]) == len(expected) and set(rows) == set(expected)
    runtime, observation = codecs()
    for key, vector in expected.items():
        root = ROOT / ".artifacts/tmp/inert-capture-roots" / key[0]
        value = qualify.at_root(prepare.apply(vector, vectors["bases"]), root)
        try:
            output = oracle(value, root, runtime, observation)
        except (AssertionError, ValueError, TypeError, KeyError, StopIteration):
            assert vector["accept"] is False, key
        else:
            assert vector["accept"] is True, key
            assert rows[key]["output"] == output, key
        assert rows[key]["accepted"] is vector["accept"], key
        if not vector["accept"]:
            assert set(rows[key]) == {"root", "name", "accepted", "error"} and rows[key]["error"]
    expected_commands = {(suffix, schema, scope): expected_collector(ROOT / ".artifacts/tmp/inert-capture-roots" / suffix, schema, scope)
                         for suffix in qualify.ROOT_SUFFIXES for schema in ("fsmgen.fixture_policy_log.v1", "fsmgen.fixture_policy_log.v2")
                         for scope in ("fixture_path", "execution_context", "daemon_context")}
    commands = {(row["root"], row["schema"], row["scope"]): row["command"] for row in result["collections"]}
    assert len(commands) == len(result["collections"]) and commands == expected_commands
    mutations = {(row["root"], row["mutation"]): row for row in result["mutants"]}
    assert len(mutations) == len(result["mutants"]) == len(qualify.ROOT_SUFFIXES) * 3
    assert set(mutations) == {(suffix, kind) for suffix in qualify.ROOT_SUFFIXES for kind in ("ignore_changed_after", "invent_native_entry", "include_observer_hold")}
    for (suffix, kind), mutant in mutations.items():
        if kind == "ignore_changed_after":
            assert mutant["name"] == "shared_0_changed_source_0" and rows[suffix, mutant["name"]]["accepted"] is False
            assert mutant["output"] == rows[suffix, "shared_0"]["output"]
        else:
            assert mutant["output"] != rows[suffix, "shared_0"]["output"]
            if kind == "invent_native_entry":
                assert mutant["output"]["main_entry"] == "entered"
            else:
                assert mutant["output"]["evidence"]["sources"][-1] == vectors["bases"]["shared_0"]["before"]["observation"]["identity"]
    return dict(target_cases=len(rows), accepted=sum(row["accepted"] for row in rows.values()), collector_commands=len(commands), counterimplementations=len(mutations))


def main():
    prepare.authenticate()
    qualify.check_pins()
    vectors = json.loads((HERE / "vectors.json").read_bytes())
    assert vectors == prepare.build()
    result = json.loads((HERE / "result/qualification.json").read_bytes())
    report = check_result(result, vectors)
    bad = []
    value = copy.deepcopy(result); value["rows"].pop(); bad.append(value)
    value = copy.deepcopy(result); value["rows"][0]["output"]["runtime_authorized"] = True; bad.append(value)
    value = copy.deepcopy(result); value["rows"][0]["output"]["evidence"]["sources"].reverse(); bad.append(value)
    value = copy.deepcopy(result); value["collections"][0]["command"][-1] = 'process == "syspolicyd"'; bad.append(value)
    value = copy.deepcopy(result); value["mutants"].pop(); bad.append(value)
    value = copy.deepcopy(result); value["process_attempts"] = ["hidden native query"]; bad.append(value)
    for value in bad:
        try:
            check_result(value, vectors)
        except (AssertionError, KeyError):
            pass
        else:
            raise AssertionError("altered saved result survived")
    report.update(saved_result_falsifiers=len(bad), source_revision=json.loads((HERE / "plan.json").read_bytes())["source_revision"],
                  scope="Inert contract agreement only; native authentication, real custody and collector delivery remain unproved.")
    if "--verify-saved" in __import__("sys").argv:
        assert json.loads((HERE / "result/audit.json").read_bytes()) == report
    else:
        with (HERE / "result/audit.json").open("x") as stream:
            json.dump(report, stream, sort_keys=True, indent=2); stream.write("\n")
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
