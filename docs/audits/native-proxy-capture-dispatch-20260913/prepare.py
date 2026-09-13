"""Construct inert data carriers and a declared mutation domain from exact sources."""
import copy
import hashlib
import json
from pathlib import Path
import struct
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def canonical(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def snapshot(path, inode, raw):
    return dict(identity=dict(path=path, device=17, inode=inode, size_bytes=len(raw), sha256=digest(raw)),
                bytes_hex=raw.hex())


def base(layout, mode=0, observer_pid=111):
    workspace = ".artifacts/tmp/process-supervisor-tests/fsmgen-CaptureContract20260913"
    store = ".artifacts/cache/rust-proxy-images/v1"
    template = (ROOT / "t/fixtures/rust-tool-proxy.c").read_bytes()
    c = f"#define PROXY_NONZERO {mode}\n".encode() + template
    image = struct.pack("<8I", 0xfeedfacf, 0x0100000c, 0, 2, 0, 0, 0, 0) + b"inert data; never an executable file"
    key = digest(b"fsmgen.rust_proxy_image.v1\0" + len(c).to_bytes(8, "big") + c + len(image).to_bytes(8, "big") + image)
    native = layout != "selected_perl_v1"
    shared = layout == "shared_native_v2"
    executable = f"{store}/images/{key}/rustup" if shared else workspace + "/rust-tools/rustup"
    identities = [dict(pid=pid, ppid=parent, uid=501, ruid=501, start_sec=1234, start_usec=usec)
                  for pid, parent, usec in [(103, 102, 789), (102, 101, 456), (101, 99, 123)]]
    request = {prefix + field: birth[field] for prefix, birth in zip(("", "parent_", "ancestor_"), identities)
               for field in ("pid", "start_sec", "start_usec")}
    # Root tokens become native absolute strings only in memory at invocation.
    processes = [dict(identity=identities[0], executable="<repo>/" + executable if native else "<system-perl>",
                      command=("" if native else "/usr/bin/perl ") + "<repo>/" + executable + " which cargo"),
                 dict(identity=identities[1], executable="<system-perl>", command="/usr/bin/perl -Iperl -It/lib <repo>/"
                      + workspace + "/rust-tool-resolution <repo>/" + workspace + "/rust-tools"),
                 dict(identity=identities[2], executable="<system-perl>", command="/usr/bin/perl t/1669-task-acceptance-fixture-runtime.t")]
    wrapper = snapshot(workspace + "/rust-tool-resolution", 201, b"inert wrapper source\n")
    directory = dict(path=workspace, device=17, inode=100)
    evidence = dict(path=".artifacts/logs/inert-capture-contract", device=17, inode=101)
    observer = dict(pid=observer_pid, ppid=99, uid=501, ruid=501, start_sec=1234, start_usec=321)
    if shared:
        pair = [snapshot(f"{store}/images/{key}/{name}", inode, body)
                for name, inode, body in [("rustup.c", 202, c), ("rustup", 203, image)]]
        selected = [value["identity"] for value in pair]
        reference_key = digest(b"fsmgen.rust_proxy_reference.runtime.v1\0" + workspace.encode())
        reference = dict(schema="fsmgen.test.rust_proxy_image_reference.v1", reference_key=reference_key, image_key=key,
                         workspace=workspace, workspace_identity=directory, selected_sources=selected)
        raw = canonical(reference).encode()
        sources = [wrapper, snapshot(workspace + "/rust-tools/image-reference.json", 204, raw),
                   snapshot(f"{store}/references/{reference_key}.json", 205, raw), *pair]
        hold_key = digest(b"fsmgen.rust_proxy_reference.observation.v1\0" + canonical([evidence["path"], observer, identities[0]]).encode())
        hold = dict(schema="fsmgen.test.rust_proxy_image_observation_reference.v1", reference_key=hold_key,
                    image_key=key, evidence_directory=evidence["path"], evidence_directory_identity=evidence,
                    observer_birth=observer, target_birth=identities[0], selected_sources=selected)
        observation = snapshot(f"{store}/references/{hold_key}.json", 206 + observer_pid, canonical(hold).encode())
    else:
        sources = [wrapper, snapshot(executable, 203, image if native else b"inert Perl proxy source\n")]
        if native:
            sources.append(snapshot(workspace + "/rust-tools/rustup.c", 202, c))
        observation = None
    frame = dict(processes=processes, sources=sources, observation=observation)
    return dict(schema="fsmgen.inactive_capture_input.v1", layout=layout, workspace=workspace,
                workspace_identity=directory if shared else None, observer_birth=observer if shared else None,
                evidence_directory_identity=evidence if shared else None, request=request,
                before=frame, after=copy.deepcopy(frame))


def apply(vector, bases):
    value = copy.deepcopy(bases[vector["base"]])
    for operation in vector["operations"]:
        parent = value
        for field in operation["path"][:-1]:
            parent = parent[field]
        field = operation["path"][-1]
        if operation.get("delete"):
            del parent[field]
        else:
            parent[field] = copy.deepcopy(operation["value"])
    return value


def build():
    bases = {"perl": base("selected_perl_v1"), "private_0": base("legacy_private_native_v1"),
             "private_1": base("legacy_private_native_v1", 1), "shared_0": base("shared_native_v2"),
             "shared_1": base("shared_native_v2", 1), "shared_other_observer": base("shared_native_v2", observer_pid=112)}
    vectors = [dict(name=name, base=name, operations=[], accept=True, rule="exact source-derived family") for name in bases]

    def change(name, path, value=None, *, selected="shared_0", delete=False, both=False, rule=None):
        operation = dict(path=path, value=value)
        if delete:
            operation["delete"] = True
        operations = [operation]
        if both:
            assert path[0] == "before"
            operations.append({**copy.deepcopy(operation), "path": ["after", *path[1:]]})
        vectors.append(dict(name=name, base=selected, operations=operations, accept=False, rule=rule or name))

    for layout in bases:
        change(layout + "_wrong_layout", ["layout"], "unselected_failure_v1", selected=layout)
        for index in range(3):
            for field in ("pid", "ppid", "uid", "ruid", "start_sec", "start_usec"):
                value = bases[layout]["before"]["processes"][index]["identity"][field]
                change(f"{layout}_changed_after_{index}_{field}", ["after", "processes", index, "identity", field], value + 1, selected=layout)
            change(f"{layout}_foreign_uid_{index}", ["before", "processes", index, "identity", "uid"], 502, selected=layout, both=True)
            change(f"{layout}_argv_alias_{index}", ["before", "processes", index, "command"], bases[layout]["before"]["processes"][index]["command"] + " ", selected=layout, both=True)
        for index in range(len(bases[layout]["before"]["sources"])):
            change(f"{layout}_changed_source_{index}", ["after", "sources", index, "identity", "inode"], 999, selected=layout)
        change(layout + "_incomplete_sources", ["before", "sources"], bases[layout]["before"]["sources"][:-1], selected=layout, both=True)
        change(layout + "_executable_alias", ["before", "processes", 0, "executable"], "<repo>/" + bases[layout]["workspace"] + "/rust-tools/cargo", selected=layout, both=True)
        change(layout + "_source_order", ["before", "sources"], list(reversed(bases[layout]["before"]["sources"])), selected=layout, both=True)
    for field in bases["shared_0"]:
        change("missing_bundle_" + field, [field], delete=True)
    change("unknown_bundle_field", ["unknown"], 1)
    change("unknown_input_schema", ["schema"], "fsmgen.inactive_capture_input.v2")
    for field in bases["shared_0"]["request"]:
        change("request_bool_" + field, ["request", field], True)
    for which in ("before", "after"):
        change(which + "_missing_hold", [which, "observation"], None)
        change(which + "_empty_processes", [which, "processes"], [])
    for field in ("workspace_identity", "observer_birth", "evidence_directory_identity"):
        change("missing_shared_" + field, [field], None)
    change("workspace_parent_alias", ["workspace"], bases["shared_0"]["workspace"] + "/..")
    change("runtime_identity_alias", ["before", "sources", 2, "identity", "inode"], 204, both=True)
    change("cross_volume_source", ["before", "sources", 0, "identity", "device"], 18, both=True)
    change("target_source_contains_hold", ["before", "sources"], bases["shared_0"]["before"]["sources"] + [bases["shared_0"]["before"]["observation"]], both=True)
    change("after_numeric_type_drift", ["after", "processes", 0, "identity", "start_sec"], 1234.0)
    for index in range(5):
        change("missing_snapshot_identity_" + str(index), ["before", "sources", index, "identity"], delete=True, both=True)
        change("incorrect_snapshot_bytes_" + str(index), ["before", "sources", index, "bytes_hex"], "00", both=True)
    for layout in ("perl", "private_0"):
        change(layout + "_shared_hold", ["before", "observation"], bases["shared_0"]["before"]["observation"], both=True, selected=layout)
    assert len({vector["name"] for vector in vectors}) == len(vectors)
    return dict(schema="fsmgen.inactive_capture_vectors.v1", bases=bases, vectors=vectors,
                scope="Synthetic process identities and in-memory bytes only; no native executable or fixture file exists.")


def authenticate():
    plan = json.loads((HERE / "plan.json").read_bytes())
    for entry in plan["inputs"]:
        raw = (ROOT / entry["path"]).read_bytes()
        assert len(raw) == entry["size_bytes"] and digest(raw) == entry["sha256"]
        assert raw == subprocess.check_output(["git", "show", plan["source_revision"] + ":" + entry["path"]], cwd=ROOT)
    return plan


if __name__ == "__main__":
    authenticate()
    value = build()
    with (HERE / "vectors.json").open("x") as stream:
        stream.write(json.dumps(value, ensure_ascii=True, sort_keys=True, indent=2) + "\n")
    print(json.dumps(dict(vectors=len(value["vectors"]), accepted=sum(row["accept"] for row in value["vectors"]))))
