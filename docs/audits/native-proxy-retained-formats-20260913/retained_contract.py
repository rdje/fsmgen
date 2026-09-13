"""Inactive private capture envelope and explicit frozen legacy reader routing.

The new envelope retains checked source snapshots and a collector command
contract. It contains no policy records, collector outcome or publication
claim. Legacy readers and their source-prefix rules remain unchanged.
"""

import hashlib
import importlib
import importlib.util
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
SCHEMA = "fsmgen.inactive_retained_proxy_capture.v2"
MAX_BYTES = 2 * 1024 * 1024
LIMITS = {
    "authority": "separately_retained_digest_not_authentication",
    "native_authentication": "not_claimed",
    "loaded_image": "not_attested",
    "filesystem_custody": "historical_snapshots_not_current_identity",
    "source_bodies": "private",
    "collector_outcome": "not_included",
    "policy_records": "not_included",
    "publication": "not_authorized",
}


def _capture_module():
    path = ROOT / "docs/audits/native-proxy-capture-dispatch-20260913/capture_contract.py"
    specification = importlib.util.spec_from_file_location("retained_capture_contract", path)
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


CAPTURE = _capture_module()


def _fields(value, expected):
    if type(value) is not dict or set(value) != set(expected):
        raise ValueError("retained object fields differ")


def _canonical(value):
    return (json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n").encode("ascii")


def _expand(value, root, system_perl):
    if type(value) is str:
        return value.replace("<repo>", str(root)).replace("<system-perl>", system_perl)
    if type(value) is list:
        return [_expand(item, root, system_perl) for item in value]
    if type(value) is dict:
        return {key: _expand(item, root, system_perl) for key, item in value.items()}
    return value


def validate(record, *, root, system_perl):
    _fields(record, ("schema", "normal_uid", "capture", "collector_contract", "limits"))
    if record["schema"] != SCHEMA or record["limits"] != LIMITS:
        raise ValueError("retained version or authority limits differ")
    capture = record["capture"]
    if type(capture) is not dict or capture.get("layout") != "shared_native_v2":
        raise ValueError("new retained envelope requires explicit shared-native layout")
    result = CAPTURE.target_contract(_expand(capture, root, system_perl), root,
        normal_uid=record["normal_uid"], system_perl=system_perl)
    # Require relocatable spellings in the retained bytes themselves. Accepting
    # their expansion alone would also admit a captured machine-local root.
    workspace = capture["workspace"]
    fixture = result["evidence"]["fixture"]
    wrapper = f"/usr/bin/perl -Iperl -It/lib <repo>/{workspace}/rust-tool-resolution <repo>/{workspace}/rust-tools"
    test = "t/1669-task-acceptance-fixture-runtime.t"
    for frame in (capture["before"], capture["after"]):
        child, parent, ancestor = frame["processes"]
        if (child["executable"] != "<repo>/" + fixture or child["command"] != "<repo>/" + fixture + " which cargo"
                or parent["executable"] != "<system-perl>" or parent["command"] != wrapper
                or ancestor["executable"] != "<system-perl>"
                or ancestor["command"] not in ("/usr/bin/perl " + test, "/usr/bin/perl <repo>/" + test)):
            raise ValueError("retained process spelling is not relocatable and literal")
    collector = record["collector_contract"]
    _fields(collector, ("schema", "scope", "command"))
    if collector["schema"] != "fsmgen.fixture_policy_log.v2":
        raise ValueError("shared native envelope requires the new collector contract")
    command = CAPTURE.collection_command(root, schema=collector["schema"], scope=collector["scope"])
    expected = CAPTURE.retained_collection_command(command, root, schema=collector["schema"])
    if collector["command"] != expected:
        raise ValueError("retained collector command differs from its exact version and scope")
    return result


def encode(record, *, root, system_perl):
    validate(record, root=root, system_perl=system_perl)
    raw = _canonical(record)
    if len(raw) > MAX_BYTES:
        raise ValueError("retained envelope exceeds its fixed byte bound")
    return raw


def _decode_pinned(raw, digest, maximum):
    if (type(raw) is not bytes or len(raw) > maximum or type(digest) is not str
            or re.fullmatch(r"[0-9a-f]{64}", digest) is None or hashlib.sha256(raw).hexdigest() != digest):
        raise ValueError("retained bytes disagree with their independent digest or bound")
    def unique(pairs):
        result = {}
        for key, item in pairs:
            if key in result:
                raise ValueError("duplicate retained field")
            result[key] = item
        return result
    def invalid(_):
        raise ValueError("nonfinite retained number")
    return json.loads(raw, object_pairs_hook=unique, parse_constant=invalid)


def decode(raw, digest, *, root, system_perl):
    record = _decode_pinned(raw, digest, MAX_BYTES)
    if raw != encode(record, root=root, system_perl=system_perl):
        raise ValueError("retained envelope encoding is not canonical")
    return record


def _legacy_modules():
    # Import only normal libraries; no original main, producer, filesystem
    # consumer, native ABI instance or publication function is invoked here.
    original = list(sys.path)
    try:
        sys.path.insert(0, str(ROOT / "scripts"))
        return {name: importlib.import_module("fixture_policy_" + name)
                for name in ("associations", "diagnostics", "publication", "archive")}
    finally:
        sys.path[:] = original


def read_legacy(kind, raw, digest, *, descriptor=None, context_sha256=None):
    """Select a frozen reader explicitly; never extend its paths or schemas."""
    if kind not in ("associations", "diagnostics", "publication", "archive", "archive_page", "collector"):
        raise ValueError("unknown frozen retained kind")
    value = _decode_pinned(raw, digest, 16 * 1024 * 1024 if kind == "collector" else MAX_BYTES)
    modules = _legacy_modules()
    if kind == "associations":
        return modules[kind].read_manifest(raw, digest)
    if kind == "diagnostics":
        return modules[kind].read_report(raw, digest)
    if kind == "publication":
        return modules[kind].read_receipt(raw, digest)
    if kind == "archive":
        return modules[kind].read_index(raw, digest)
    if kind == "archive_page":
        if type(descriptor) is not dict or descriptor.get("sha256") != digest:
            raise ValueError("archive descriptor does not bind supplied page bytes")
        return modules["archive"].read_page(raw, descriptor, context_sha256)
    modules["diagnostics"].retained_scope(value)
    return value
