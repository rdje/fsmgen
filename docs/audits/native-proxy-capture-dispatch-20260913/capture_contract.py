"""Inactive Rust-target and collector contracts over supplied observations.

This module performs no filesystem, native-process or collector operation.
Agreement between historical observations is not authentication of live births,
file modes, descriptor custody, loaded images or permission to execute.
"""

import copy
import hashlib
import json
from pathlib import PurePath
import re
import struct

PRIVATE = ".artifacts/tmp/process-supervisor-tests/"
STORE = ".artifacts/cache/rust-proxy-images/v1"
LAYOUTS = ("selected_perl_v1", "legacy_private_native_v1", "shared_native_v2")
SCOPES = ("fixture_path", "execution_context", "daemon_context")
COLLECTOR_SCHEMAS = ("fsmgen.fixture_policy_log.v1", "fsmgen.fixture_policy_log.v2")
BIRTH_FIELDS = ("pid", "ppid", "ruid", "start_sec", "start_usec", "uid")
IDENTITY_FIELDS = ("pid", "start_sec", "start_usec")
SOURCE_FIELDS = ("path", "device", "inode", "size_bytes", "sha256")
QUALIFIED_C = frozenset((
    "b689e2f7ee42bf7cac62f272a36d5313a272dddef15a75f8c66b126568fbf276",
    "a2ff3cf129d8c01d2b05c33b2df2ca18b68048972dcc86c00222786a6751defc",
))


def _require(condition, message):
    if not condition:
        raise ValueError(message)


def _fields(value, fields):
    _require(type(value) is dict and set(value) == set(fields), "record fields differ")


def _integer(value):
    _require(type(value) is int and value >= 0, "expected nonnegative integer")


def _string(value):
    _require(type(value) is str, "expected string")
    return value


def _canonical(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True,
                      separators=(",", ":"), allow_nan=False).encode("ascii")


def _digest(raw):
    return hashlib.sha256(raw).hexdigest()


def _relative(path):
    _string(path)
    _require(bool(path) and not re.search(r"[\x00-\x1f\x7f\\]", path)
             and all(part not in ("", ".", "..") for part in path.split("/")),
             "expected direct root-relative path")
    return path


def _root(root):
    _require(isinstance(root, PurePath) and root.is_absolute()
             and ".." not in root.parts, "expected runtime repository root")
    return str(root)


def collection_command(root, *, schema, scope):
    """Explicit version; all native flags, scopes and path prefixes are fixed."""
    root = _root(root)
    _require(schema in COLLECTOR_SCHEMAS and type(schema) is str, "unknown collector version")
    _require(scope in SCOPES and type(scope) is str, "unknown collection scope")
    prefixes = [PRIVATE]
    if schema == COLLECTOR_SCHEMAS[1]:
        prefixes.append(STORE + "/")
    terms = ["eventMessage CONTAINS " + json.dumps(root.rstrip("/") + "/" + path,
                                                 ensure_ascii=False)
             for path in prefixes]
    if scope == "execution_context":
        terms.append('subsystem == "com.apple.syspolicy.exec"')
    predicate = 'process == "syspolicyd"'
    if scope != "daemon_context":
        predicate += " AND " + (terms[0] if len(terms) == 1 else "(" + " OR ".join(terms) + ")")
    return ["/usr/bin/log", "stream", "--style", "ndjson", "--level", "debug",
            "--timeout", "240", "--predicate", predicate]


def retained_collection_command(argv, root, *, schema):
    """Relocate exact JSON-quoted prefixes; preserve malformed argv unchanged."""
    root = _root(root)
    _require(type(schema) is str and schema in COLLECTOR_SCHEMAS, "unknown collector version")
    _require(type(argv) is list and all(type(arg) is str for arg in argv), "expected literal argv")
    prefixes = [PRIVATE] + ([STORE + "/"] if schema == COLLECTOR_SCHEMAS[1] else [])
    result = list(argv)
    for prefix in prefixes:
        before = json.dumps(root.rstrip("/") + "/" + prefix, ensure_ascii=False)
        after = json.dumps("<repo>/" + prefix, ensure_ascii=False)
        result = [arg.replace(before, after) for arg in result]
    return result


def _birth(value):
    _fields(value, BIRTH_FIELDS)
    for item in value.values():
        _integer(item)
    _require(1 < value["pid"] <= 2**31 - 1 and value["start_usec"] < 1_000_000,
             "invalid native birth")


def _directory(value, path):
    _fields(value, ("path", "device", "inode"))
    _require(value["path"] == path, "directory path differs")
    _integer(value["device"])
    _integer(value["inode"])


def _snapshot(value, path=None, limit=65536):
    _fields(value, ("identity", "bytes_hex"))
    identity = value["identity"]
    _fields(identity, SOURCE_FIELDS)
    if path is None:
        path = _relative(identity["path"])
    _require(identity["path"] == path, "source path or ordering differs")
    for field in ("device", "inode", "size_bytes"):
        _integer(identity[field])
    raw_hex = _string(value["bytes_hex"])
    _require(len(raw_hex) <= 2 * limit and re.fullmatch(r"(?:[0-9a-f]{2})*", raw_hex) is not None,
             "source bytes are not bounded canonical hex")
    raw = bytes.fromhex(raw_hex)
    _require(identity["size_bytes"] == len(raw) and identity["sha256"] == _digest(raw),
             "source byte identity differs")
    return raw


def _native_bytes(source, image):
    _require(source["identity"]["sha256"] in QUALIFIED_C, "C source is not a qualified mode")
    raw = bytes.fromhex(image["bytes_hex"])
    _require(len(raw) >= 32 and struct.unpack_from("<4I", raw) == (0xfeedfacf, 0x0100000c, 0, 2),
             "native header is not an arm64 executable")


def _shared_sources(bundle, frame, target):
    workspace = bundle["workspace"]
    sources = frame["sources"]
    _require(type(sources) is list and len(sources) == 5, "expected five stable target snapshots")
    directory = bundle["workspace_identity"]
    _directory(directory, workspace)
    reference_key = _digest(b"fsmgen.rust_proxy_reference.runtime.v1\0" + workspace.encode("utf-8"))
    # Content is bounded before calculating the key or admitting its paths.
    c = _snapshot(sources[3])
    image = _snapshot(sources[4])
    image_key = _digest(b"fsmgen.rust_proxy_image.v1\0" + len(c).to_bytes(8, "big") + c
                        + len(image).to_bytes(8, "big") + image)
    paths = [workspace + "/rust-tool-resolution", workspace + "/rust-tools/image-reference.json",
             f"{STORE}/references/{reference_key}.json", f"{STORE}/images/{image_key}/rustup.c",
             f"{STORE}/images/{image_key}/rustup"]
    raw = [_snapshot(source, path, 4096 if index in (1, 2) else 65536)
           for index, (source, path) in enumerate(zip(sources, paths))]
    _native_bytes(sources[3], sources[4])
    selected = [source["identity"] for source in sources[3:]]
    runtime = dict(schema="fsmgen.test.rust_proxy_image_reference.v1", reference_key=reference_key,
                   image_key=image_key, workspace=workspace, workspace_identity=directory,
                   selected_sources=selected)
    _require(raw[1] == raw[2] == _canonical(runtime), "matching runtime references are required")
    evidence = bundle["evidence_directory_identity"]
    _fields(evidence, ("path", "device", "inode"))
    _require(_relative(evidence["path"]).startswith(".artifacts/logs/"), "evidence directory is outside logs")
    _directory(evidence, evidence["path"])
    observer = bundle["observer_birth"]
    _birth(observer)
    _require((observer["uid"], observer["ruid"]) == (target["uid"], target["ruid"]),
             "observer user differs")
    _require(observer["pid"] != target["pid"], "observer and target are not distinct")
    hold_key = _digest(b"fsmgen.rust_proxy_reference.observation.v1\0"
                       + _canonical([evidence["path"], observer, target]))
    hold = dict(schema="fsmgen.test.rust_proxy_image_observation_reference.v1", reference_key=hold_key,
                image_key=image_key, evidence_directory=evidence["path"],
                evidence_directory_identity=evidence, observer_birth=observer,
                target_birth=target, selected_sources=selected)
    held = _snapshot(frame["observation"], f"{STORE}/references/{hold_key}.json", 4096)
    _require(held == _canonical(hold), "matching observation hold is required")
    identities = [source["identity"] for source in sources] + [frame["observation"]["identity"]]
    _require(all(value["device"] == directory["device"] for value in [*identities, evidence]),
             "source or evidence volume differs")
    objects = [(value["device"], value["inode"]) for value in [*identities, directory, evidence]]
    _require(len(objects) == len(set(objects)), "source or directory identities alias")
    return paths[-1]


def target_contract(bundle, root, *, normal_uid, system_perl):
    """Check supplied before/after Rust-proxy data, returning no runtime authority.

    The tagged bundle and hex bodies are this inactive adapter's input format;
    they do not redefine frozen retained-v1 records. A caller must separately
    authenticate native processes and acquire/recheck real storage custody.
    """
    root = _root(root)
    _integer(normal_uid)
    _require(normal_uid != 0, "normal-user contract excludes root")
    _require(type(system_perl) is str and system_perl.startswith("/"), "expected resolved system Perl")
    _fields(bundle, ("schema", "layout", "workspace", "workspace_identity", "observer_birth",
                     "evidence_directory_identity", "request", "before", "after"))
    _require(bundle["schema"] == "fsmgen.inactive_capture_input.v1", "unknown capture input version")
    layout = bundle["layout"]
    _require(type(layout) is str and layout in LAYOUTS, "unknown preparation layout")
    workspace = _string(bundle["workspace"])
    _require(re.fullmatch(re.escape(PRIVATE) + r"fsmgen-[A-Za-z0-9_]+", workspace) is not None,
             "workspace is not builder-owned")
    request = bundle["request"]
    _fields(request, [prefix + field for prefix in ("", "parent_", "ancestor_") for field in IDENTITY_FIELDS])
    for value in request.values():
        _integer(value)
    frame = bundle["before"]
    for sample in (frame, bundle["after"]):
        _fields(sample, ("processes", "sources", "observation"))
    processes = frame["processes"]
    _require(type(processes) is list and len(processes) == 3, "expected proxy/wrapper/test chain")
    for prefix, process in zip(("", "parent_", "ancestor_"), processes):
        _fields(process, ("identity", "executable", "command"))
        info = process["identity"]
        _birth(info)
        _require(all(info[field] == request[prefix + field] for field in IDENTITY_FIELDS), "stale requested birth")
        _require(info["uid"] == info["ruid"] == normal_uid, "process user differs")
        _string(process["executable"])
        _string(process["command"])
    births = [process["identity"] for process in processes]
    _require(len({birth["pid"] for birth in births}) == 3, "process chain aliases")
    _require(all(child["ppid"] == parent["pid"] for child, parent in zip(births, births[1:])),
             "process ancestry differs")
    _require(all(process["executable"] == system_perl for process in processes[1:]),
             "wrapper or test executable differs")
    absolute_workspace = root.rstrip("/") + "/" + workspace
    wrapper = f"/usr/bin/perl -Iperl -It/lib {absolute_workspace}/rust-tool-resolution {absolute_workspace}/rust-tools"
    test = "t/1669-task-acceptance-fixture-runtime.t"
    _require(processes[1]["command"] == wrapper, "literal wrapper command differs")
    _require(processes[2]["command"] in ("/usr/bin/perl " + test, "/usr/bin/perl " + root.rstrip("/") + "/" + test),
             "literal original test command differs")
    if layout == "shared_native_v2":
        fixture = _shared_sources(bundle, frame, births[0])
    else:
        _require(all(bundle[field] is None for field in ("workspace_identity", "observer_birth", "evidence_directory_identity"))
                 and frame["observation"] is None, "legacy layout cannot acquire shared-image fields")
        fixture = workspace + "/rust-tools/rustup"
        paths = [workspace + "/rust-tool-resolution", fixture]
        if layout == "legacy_private_native_v1":
            paths.append(workspace + "/rust-tools/rustup.c")
        _require(type(frame["sources"]) is list and len(frame["sources"]) == len(paths), "legacy source count differs")
        for source, path in zip(frame["sources"], paths):
            _snapshot(source, path)
        if layout == "legacy_private_native_v1":
            _native_bytes(frame["sources"][2], frame["sources"][1])
    native = layout != "selected_perl_v1"
    executable = root.rstrip("/") + "/" + fixture
    expected_command = ("" if native else "/usr/bin/perl ") + executable + " which cargo"
    _require(processes[0]["executable"] == (executable if native else system_perl)
             and processes[0]["command"] == expected_command, "literal proxy executable or command differs")
    # Equality includes complete byte carriers and exact birth, argv and sources.
    # The caller-owned hold is checked, but deliberately excluded from evidence.
    _require(_canonical(bundle["after"]) == _canonical(frame), "process, source or observation identity changed")
    sources = [source["identity"] for source in frame["sources"]]
    fixture_source = next(source for source in sources if source["path"] == fixture)
    evidence = dict(child=births[0], parent=births[1], ancestor=births[2], fixture=fixture,
                    fixture_sha256=fixture_source["sha256"], target_role="rust-proxy", sources=sources)
    return copy.deepcopy(dict(layout=layout, evidence=evidence, main_entry="unknown", runtime_authorized=False))
