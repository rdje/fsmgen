"""Build inert preparation records from pinned producer shapes and byte rules."""

import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def canonical(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False)


def digest(body):
    return hashlib.sha256(body).hexdigest()


def source_identity(path, inode, body):
    return dict(path=path, device=17, inode=inode, size_bytes=len(body), sha256=digest(body))


def build():
    plan = json.loads((HERE / "plan.json").read_bytes())
    for record in plan["inputs"]:
        body = (ROOT / record["path"]).read_bytes()
        assert len(body) == record["size_bytes"] and digest(body) == record["sha256"]
        assert body == subprocess.check_output(["git", "show", plan["source_revision"] + ":" + record["path"]], cwd=ROOT)
    design = json.loads((ROOT / "docs/audits/native-proxy-canonical-contract-20260910/contract.json").read_bytes())
    old = json.loads((ROOT / "docs/audits/native-proxy-hardlink-20260910/result/preparation.json").read_bytes())["prepared"]
    engine = (ROOT / "perl/FSM/Support/ProcessSupervisor.pm").read_text()
    finish = engine.split("sub _finish_result {", 1)[1].split("\nsub _new_cleanup", 1)[0]
    compiler_fields = re.findall(r"^        ([a-z_]+) =>", finish, re.M)
    assert set(old["compilation"]) == set(compiler_fields)
    workspace = ".artifacts/tmp/process-supervisor-tests/fsmgen-Preparation20260913"
    store = design["layout"]["root"]
    c, image = b"/* inert compilation source */\n", b"inert non-executable image\x00\xff"
    image_key = digest(b"fsmgen.rust_proxy_image.v1\0" + len(c).to_bytes(8, "big") + c
                       + len(image).to_bytes(8, "big") + image)
    reference_key = digest(b"fsmgen.rust_proxy_reference.runtime.v1\0" + workspace.encode("ascii"))
    selected = [source_identity(f"{store}/images/{image_key}/{name}", inode, data)
                for name, inode, data in [("rustup.c", 201, c), ("rustup", 202, image)]]
    private = [source_identity(f"{workspace}/rust-tools/{name}", inode, data)
               for name, inode, data in [("rustup.c", 101, c), ("rustup", 102, image)]]
    runtime = dict(schema="fsmgen.test.rust_proxy_image_reference.v1", reference_key=reference_key,
                   image_key=image_key, workspace=workspace,
                   workspace_identity=dict(path=workspace, device=17, inode=100), selected_sources=selected)
    raw = canonical(runtime).encode("ascii")
    reference = dict(record=runtime,
        global_=source_identity(f"{store}/references/{reference_key}.json", 301, raw),
        private=source_identity(f"{workspace}/rust-tools/image-reference.json", 302, raw))
    reference["global"] = reference.pop("global_")
    base = copy.deepcopy(old)
    base.update(schema=design["capture_and_policy"]["preparation_format"]["schema"], sources=selected,
                compilation_sources=private, image_reference=reference,
                executable=selected[1]["path"])
    base["compilation_argv"][-3] = private[0]["path"]
    base["compilation_argv"][-1] = private[1]["path"]
    assert list(base["compilation"]) == list(old["compilation"])
    assert set(base) == set(design["capture_and_policy"]["preparation_format"]["fields"])
    vectors = []

    def add(name, record, accept=True, reason=None):
        vectors.append(dict(name=name, raw=canonical(record), accept=accept, reason=reason))

    def failure(stage, private_count=2, selected_pair=False, complete_reference=False):
        value = copy.deepcopy(base)
        value.update(ok=0, executable=None, status="invocation_error", failure_stage=stage,
                     diagnostic="controlled " + stage + " failure")
        value["compilation_sources"] = value["compilation_sources"][:private_count]
        if not selected_pair:
            value["sources"] = []
        if not complete_reference:
            value["image_reference"] = None
        if stage in ("invocation", "workspace", "source"):
            value.update(compilation=None, compilation_argv=None)
        return value

    add("complete_shared_native", base)
    for stage, count in [("invocation", 0), ("workspace", 0), ("source", 0), ("source", 1)]:
        add(f"early_{stage}_{count}", failure(stage, count))
    invocation = failure("compile", 1)
    invocation["compilation"] = None
    add("compiler_invocation_exception", invocation)
    compile_failures = []
    statuses = ["invocation_error", "host_error", "timed_out", "output_limited", "exec_error",
                "surviving_descendants", "cleanup_failed", "signaled", "nonzero_exit"]
    for status in statuses:
        value = failure("compile", 1)
        value["status"] = status
        compilation = value["compilation"]
        compilation.update(ok=0, status=status, exit_code=9)
        if status in ("timed_out", "output_limited", "exec_error"):
            compilation[{"timed_out": "timed_out", "output_limited": "output_limited", "exec_error": "exec_failed"}[status]] = 1
        if status == "exec_error":
            compilation["exec_error"] = "controlled exec failure"
        if status == "cleanup_failed":
            compilation["cleanup"]["group_gone"] = 0
        if status == "surviving_descendants":
            compilation["cleanup"]["surviving_descendants"] = 1
        if status == "signaled":
            compilation.update(signal=9, exit_code=None)
        add("compiler_" + status, value)
        compile_failures.append(value)
    suspect = failure("compile", 1)
    suspect["status"] = "cleanup_failed"
    suspect["compilation"]["cleanup"]["group_gone"] = 0
    add("compiler_success_with_unsettled_cleanup", suspect)
    for count in (1, 2):
        add(f"artifact_failure_{count}", failure("artifact_admission", count))
    for stage in ("image_admission", "image_reference"):
        for selected_pair in (False, True):
            add(f"{stage}_selected_{int(selected_pair)}", failure(stage, selected_pair=selected_pair))
    retained = failure("image_reference", selected_pair=True, complete_reference=True)
    add("failed_with_complete_retained_reference", retained)
    octets = copy.deepcopy(base)
    octets["compilation"].update(stdout="\x00\xff" * 2048, stdout_bytes=4096)
    add("compiler_aggregate_octet_boundary", octets)
    diagnostic = copy.deepcopy(retained)
    diagnostic["diagnostic"] = "x" * 2048
    add("diagnostic_character_boundary", diagnostic)
    integer = copy.deepcopy(base)
    integer["compilation_sources"][1]["inode"] = 9007199254740993
    add("integer_above_binary64_precision", integer)

    def change(name, path, value, original=base, delete=False, reason=None):
        changed = copy.deepcopy(original)
        target = changed
        for key in path[:-1]:
            target = target[key]
        if delete:
            del target[path[-1]]
        else:
            target[path[-1]] = value
        add(name, changed, False, reason)

    for field in design["capture_and_policy"]["preparation_format"]["fields"]:
        change("missing_preparation_" + field, [field], None, delete=True)
    change("unknown_preparation_field", ["unknown"], 1)
    for field in compiler_fields:
        change("missing_compiler_" + field, ["compilation", field], None, delete=True)
    change("wrong_version", ["schema"], "fsmgen.test.rust_proxy_fixture.v1")
    change("perl_in_native_version", ["implementation"], "perl")
    for value, name in [(True, "boolean"), ("1", "string"), (2, "range")]:
        change("preparation_ok_" + name, ["ok"], value)
    change("failed_executable", ["executable"], base["executable"], retained,
           reason="failed preparation exposes an executable")
    change("failed_success_status", ["status"], "success", retained)
    change("failed_empty_diagnostic", ["diagnostic"], "", retained)
    change("excess_diagnostic", ["diagnostic"], "x" * 2049, retained)
    change("missing_complete_reference", ["image_reference"], None)
    change("compile_outcome_rewritten", ["status"], "invocation_error", compile_failures[-1])
    change("unsettled_success", ["compilation", "cleanup", "group_gone"], 0)
    change("compiler_exit_contradicts_success", ["compilation", "exit_code"], 9)
    change("compiler_bound_changed", ["compilation", "timeout_seconds"], 11)
    change("compiler_argv_changed", ["compilation_argv", 7], "-O0")
    change("compiler_argv_private_path_changed", ["compilation_argv", 13], selected[0]["path"])
    change("compiler_byte_count_changed", ["compilation", "stdout_bytes"], 1)
    excessive_output = copy.deepcopy(base)
    excessive_output["compilation"].update(stderr="x" * 4097, stderr_bytes=4097)
    add("compiler_output_over_bound", excessive_output, False, "compiler output exceeds aggregate bound")
    for name in ("sources", "compilation_sources"):
        change(name + "_reversed", [name], list(reversed(base[name])))
        change(name + "_missing_image", [name], base[name][:1])
        change(name + "_foreign_prefix", [name, 0, "path"], "elsewhere/rustup.c")
        for index in (0, 1):
            for field, value in [("inode", "101"), ("device", True), ("size_bytes", 65537), ("sha256", "G" * 64)]:
                change(f"{name}_{index}_{field}_invalid", [name, index, field], value)
    change("source_digest_disagreement", ["sources", 0, "sha256"], "0" * 64)
    change("source_inode_alias", ["sources", 0, "inode"], private[0]["inode"])
    change("source_volume_disagreement", ["sources", 0, "device"], 18)
    for name in ("global", "private", "record"):
        change("missing_reference_" + name, ["image_reference", name], None, delete=True)
    for name in ("global", "private"):
        change(name + "_reference_digest", ["image_reference", name, "sha256"], "0" * 64)
        change(name + "_reference_size", ["image_reference", name, "size_bytes"], len(raw) + 1)
        change(name + "_reference_path", ["image_reference", name, "path"], "elsewhere/reference.json")
    change("reference_key_changed", ["image_reference", "record", "reference_key"], "0" * 64)
    change("reference_schema_changed", ["image_reference", "record", "schema"], "fsmgen.test.rust_proxy_image_observation_reference.v1")
    change("reference_workspace_changed", ["image_reference", "record", "workspace"], workspace + "Other")
    change("reference_selected_sources_reversed", ["image_reference", "record", "selected_sources"], list(reversed(selected)))
    raw_base = canonical(base)
    for name, value in [("newline", raw_base + "\n"), ("duplicate_schema", '{"schema":"discarded",' + raw_base[1:]),
                        ("noncanonical_integer", raw_base.replace('"inode":101', '"inode":101.0', 1)),
                        ("invalid_json", "{"), ("non_object", "[]"), ("decode_bound", " " * 65537)]:
        vectors.append(dict(name=name, raw=value, accept=False, reason=None))
    assert len({row["name"] for row in vectors}) == len(vectors)
    return dict(schema="fsmgen.inactive_preparation_vectors.v1", vectors=vectors,
                compiler_fields=compiler_fields, base=base, generated_c_hex=c.hex(), image_hex=image.hex(),
                original_v1=old, original_v1_raw=canonical(old),
                limits="All new paths and identities are inert data. The copied compiler receipt is an original structural template, not evidence that these inert bytes were compiled.")


if __name__ == "__main__":
    for pin in json.loads((HERE / "prepare-pins.json").read_bytes()):
        body = (ROOT / pin["path"]).read_bytes()
        assert len(body) == pin["size_bytes"] and digest(body) == pin["sha256"]
    result = build()
    with (HERE / "vectors.json").open("x") as stream:
        stream.write(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(dict(vectors=len(result["vectors"]), fixture_allocations=0)))
