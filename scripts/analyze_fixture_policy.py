"""Offline, calibrated attribution of retained fixture policy tokens.

CFString hashing empirically reproduces the observed PST path tokens. It is
not a cryptographic identity: calibration and unique observed-path matches
are required, and missing events remain unknown. No process is inspected or
launched, and historical capture roots are read as data from log headers.
"""

import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
MAX_FILE_BYTES = 16 * 1024 * 1024
MAX_EVENTS = 4096
MAX_SOURCES = 64
MAX_SOURCE_BYTES = 65536
MAX_CALIBRATIONS = 4
FIXTURE_PREFIX = ".artifacts/tmp/process-supervisor-tests/"
TOKEN = re.compile(r"PST: \(path: ([0-9a-f]{16})\)")


def verify_collector_command(collector):
    # This is the frozen retained v1 contract, independent of current launcher
    # defaults. A valid byte hash alone does not establish collection scope.
    expected = ["/usr/bin/log", "stream", "--style", "ndjson", "--level", "debug",
                "--timeout", "240", "--predicate",
                'process == "syspolicyd" AND (eventMessage CONTAINS '
                '"<repo>/.artifacts/tmp/process-supervisor-tests/" '
                'OR subsystem == "com.apple.syspolicy.exec")']
    if (not isinstance(collector, dict)
            or collector.get("schema") != "fsmgen.fixture_policy_log.v1"
            or collector.get("scope") != "execution_context"
            or collector.get("command") != expected):
        raise ValueError("retained collector command is not the reviewed execution-context contract")


class NativePathHash:
    def __init__(self):
        if sys.platform != "darwin" or ctypes.sizeof(ctypes.c_ulong) != 8:
            raise ValueError("native path hashing requires the reviewed Darwin ABI")
        self.cf = ctypes.CDLL("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
        self.cf.CFStringCreateWithCString.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint32]
        self.cf.CFStringCreateWithCString.restype = ctypes.c_void_p
        self.cf.CFHash.argtypes = [ctypes.c_void_p]
        self.cf.CFHash.restype = ctypes.c_ulong
        self.cf.CFRelease.argtypes = [ctypes.c_void_p]
        self.cf.CFRelease.restype = None

    def __call__(self, path):
        if not isinstance(path, str) or "\0" in path:
            raise ValueError("path hash input must be a NUL-free string")
        value = self.cf.CFStringCreateWithCString(None, path.encode("utf-8"), 0x08000100)
        if not value:
            raise RuntimeError("native CFString creation failed")
        try:
            return f"{self.cf.CFHash(value):016x}"
        finally:
            self.cf.CFRelease(value)


def relative_path(value, prefix):
    if (not isinstance(value, str) or "\0" in value or not value.startswith(prefix)
            or PurePosixPath(value).as_posix() != value
            or ".." in PurePosixPath(value).parts):
        raise ValueError("input must be a canonical repository-relative path in " + prefix)
    return value


def read_local(path, root, limit=MAX_FILE_BYTES):
    if root not in path.parents or path.resolve() != path:
        raise ValueError("retained input is indirect or outside the repository")
    before = path.lstat()
    if (not stat.S_ISREG(before.st_mode) or before.st_dev != root.stat().st_dev
            or before.st_uid != os.getuid()):
        raise ValueError("retained input must be an owned same-volume regular file")
    fields = ("st_dev", "st_ino", "st_mode", "st_uid", "st_size", "st_mtime_ns", "st_ctime_ns")
    expected = tuple(getattr(before, field) for field in fields)
    with os.fdopen(os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb") as stream:
        opened = os.fstat(stream.fileno())
        if tuple(getattr(opened, field) for field in fields) != expected:
            raise ValueError("retained input changed before reading")
        data = stream.read(limit + 1)
        after = os.fstat(stream.fileno())
    if any(tuple(getattr(info, field) for field in fields) != expected
           for info in (opened, after, path.lstat())):
        raise ValueError("retained input changed during reading")
    if len(data) > limit:
        raise ValueError("retained input exceeds its fixed byte bound")
    return data


def decode_json(value):
    def invalid_constant(_value):
        raise ValueError("non-finite retained JSON number")

    def unique(pairs):
        result = {}
        for key, item in pairs:
            if key in result:
                raise ValueError("duplicate retained JSON field")
            result[key] = item
        return result
    return json.loads(value, object_pairs_hook=unique, parse_constant=invalid_constant)


def load_run(relative, root):
    directory = root / relative_path(relative, ".artifacts/logs/")
    journal = [decode_json(line) for line in read_local(directory / "observations.jsonl", root).splitlines()]
    if len(journal) > MAX_EVENTS:
        raise ValueError("retained journal exceeds its event bound")
    sources = {}
    for row in journal:
        if not isinstance(row, dict):
            raise ValueError("retained journal record is not an object")
        if row.get("event") != "candidate":
            continue
        for source in row["evidence"]["sources"]:
            if set(source) != {"path", "sha256", "device", "inode", "size_bytes"}:
                raise ValueError("retained source fields disagree with the archive contract")
            path = relative_path(source["path"], FIXTURE_PREFIX)
            if (not isinstance(source["sha256"], str)
                    or not re.fullmatch(r"[0-9a-f]{64}", source["sha256"])
                    or any(type(source[key]) is not int or source[key] < 0
                           for key in ("device", "inode", "size_bytes"))):
                raise ValueError("invalid retained source identity")
            if path in sources and sources[path] != source:
                raise ValueError("source path has multiple observed identities")
            sources[path] = source
            if len(sources) > MAX_SOURCES:
                raise ValueError("retained sources exceed their fixed count bound")
    if not sources:
        raise ValueError("run has no observed source archive")
    for source in sources.values():
        data = read_local(directory / (source["sha256"] + ".source"), root, MAX_SOURCE_BYTES)
        if len(data) != source["size_bytes"] or hashlib.sha256(data).hexdigest() != source["sha256"]:
            raise ValueError("retained source archive does not match its byte identity")

    policy_bytes = read_local(directory / "policy.stdout", root)
    collector = decode_json(read_local(directory / "policy-result.json", root))
    verify_collector_command(collector)
    retained = collector["outputs"]["stdout"]
    if (retained["path"] != str((directory / "policy.stdout").relative_to(root))
            or type(retained["bytes"]) is not int or retained["bytes"] != len(policy_bytes)
            or retained["sha256"] != hashlib.sha256(policy_bytes).hexdigest()
            or retained["hash_complete"] is not True or retained["path_identity_matches"] is not True):
        raise ValueError("retained policy bytes disagree with the collector manifest")
    lines = policy_bytes.decode("utf-8").splitlines()
    if not lines or not lines[0].startswith("Filtering the log data using "):
        raise ValueError("capture-root header is unavailable")
    fields = re.findall(r'\b(?:composedMessage|eventMessage) CONTAINS ("(?:[^"\\]|\\.)*")', lines[0])
    if len(fields) != 1:
        raise ValueError("capture-root header is ambiguous")
    # Native log output renders eventMessage as composedMessage. Admit that
    # observed alias only; arbitrary predicates containing a root are invalid.
    headers = {
        'Filtering the log data using "process == "syspolicyd" AND (' + field
        + " CONTAINS " + fields[0] + ' OR subsystem == "com.apple.syspolicy.exec")"'
        for field in ("eventMessage", "composedMessage")
    }
    if lines[0] not in headers:
        raise ValueError("capture-root header predicate disagrees with the collector command")
    prefix = decode_json(fields[0])
    suffix = "/" + FIXTURE_PREFIX
    if not isinstance(prefix, str) or not prefix.endswith(suffix):
        raise ValueError("capture-root header is outside the selected fixture policy")
    capture_root = prefix[:-len(suffix)]
    if (not capture_root.startswith("/") or "\0" in capture_root
            or PurePosixPath(capture_root).as_posix() != capture_root
            or ".." in PurePosixPath(capture_root).parts):
        raise ValueError("historical capture root is not canonical")
    records, metadata = [], []
    for line in lines[1:]:
        if not line.strip():
            continue
        row = decode_json(line)
        if not isinstance(row, dict):
            raise ValueError("retained policy record is not an object")
        if row.get("eventType") == "logEvent":
            if not isinstance(row.get("eventMessage"), str):
                raise ValueError("retained policy event lacks its message")
            records.append(row)
        else:
            metadata.append(row)
        if len(records) + len(metadata) > MAX_EVENTS:
            raise ValueError("retained policy exceeds its event bound")
    return dict(directory=relative, capture_root=capture_root, sources=sources,
                records=records, metadata=metadata, collector_result=collector,
                original_result=decode_json(read_local(directory / "test-result.json", root)))


def literal_pairs(run):
    pairs = {}
    absolute_sources = {run["capture_root"] + "/" + path: path for path in run["sources"]}
    for row in run["records"]:
        message = row["eventMessage"]
        if "file://" not in message:
            continue
        url = urlsplit("file://" + message.split("file://", 1)[1])
        absolute = unquote(url.path, errors="strict")
        if absolute not in absolute_sources:
            continue
        if url.netloc or url.query or url.fragment:
            raise ValueError("literal source URL is ambiguous")
        tokens = set(TOKEN.findall(message))
        if len(tokens) != 1:
            raise ValueError("literal source record lacks an unambiguous PST token")
        token = tokens.pop()
        if absolute in pairs and pairs[absolute] != token:
            raise ValueError("literal source records disagree on their token")
        pairs[absolute] = token
    return pairs


def analyze(target, calibrations, root=ROOT, path_hash=None):
    root = root.resolve()
    if not 1 <= len(calibrations) <= MAX_CALIBRATIONS or len(set(calibrations)) != len(calibrations):
        raise ValueError("supply a bounded distinct calibration run set")
    if target in calibrations:
        raise ValueError("calibration must come from a separate retained run")
    path_hash = NativePathHash() if path_hash is None else path_hash
    checked = []
    for calibration in calibrations:
        run = load_run(calibration, root)
        pairs = literal_pairs(run)
        if len(pairs) < 2 or len(set(pairs.values())) != len(pairs):
            raise ValueError("calibration requires distinct independently linked paths and tokens")
        for absolute, token in pairs.items():
            if path_hash(absolute) != token:
                raise ValueError("native path hash disagrees with literal policy calibration")
        checked.append(dict(run=calibration, verified_pairs=len(pairs)))
    run = load_run(target, root)
    predicted = {}
    for path, source in run["sources"].items():
        token = path_hash(run["capture_root"] + "/" + path)
        if not isinstance(token, str) or not re.fullmatch(r"[0-9a-f]{16}", token):
            raise ValueError("native path hash returned an invalid token")
        if token in predicted:
            raise ValueError("observed source paths have ambiguous native hash attribution")
        predicted[token] = source
    for absolute, token in literal_pairs(run).items():
        if path_hash(absolute) != token:
            raise ValueError("target literal policy record contradicts calibrated attribution")
    groups = {}
    for index, row in enumerate(run["records"]):
        for token in set(TOKEN.findall(row["eventMessage"])):
            groups.setdefault(token, []).append(index)
    tokens = []
    for token, indices in sorted(groups.items()):
        source = predicted.get(token)
        messages = [run["records"][i]["eventMessage"] for i in indices]
        tokens.append(dict(token=token, source=source,
            attribution="calibrated_observed_path_hash" if source else "unattributed",
            record_indices=indices, queued=sum(m.startswith("queueing up scan") for m in messages),
            started=sum(m.startswith("starting work for scan") for m in messages),
            wakeups=sum(m.startswith("scan finished, waking") for m in messages)))
    return dict(schema="fsmgen.fixture_policy_analysis.v1", run=target, calibration=checked,
                original_result=run["original_result"], collector_result=run["collector_result"],
                records=run["records"], metadata=run["metadata"],
                tokens=tokens, complete_coverage="unproved", missing_records="unknown",
                identity_limit="empirical hash attribution within verified observed paths; not universal identity",
                missing_progress_limit="missing work-start or wakeup records do not prove missing execution")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run", help="repository-relative retained run directory")
    parser.add_argument("--calibration", action="append", required=True,
                        help="separate retained run with literal source/token pairs")
    args = parser.parse_args()
    print(json.dumps(analyze(args.run, args.calibration), indent=2))


if __name__ == "__main__":
    main()
