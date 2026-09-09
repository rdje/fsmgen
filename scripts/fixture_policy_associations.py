"""Seal calibrated fixture associations before discarding the private capture root.

Sealing consumes settled local capture evidence and separate literal calibration.
Replay consumes only a pinned manifest and relocated source archives. It does
not load CoreFoundation, access original paths, or authenticate the supplied
digest. Raw diagnostic disclosure is a separate contract.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import uuid

import analyze_fixture_policy as analysis


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = "fsmgen.fixture_policy_associations.v1"
ALGORITHM = "darwin_corefoundation_cfstring_cfhash_64_v1"
MAX_MANIFEST_BYTES = 2 * 1024 * 1024
MAX_PATH_BYTES = 1024
MAX_RECORD_TOKENS = 16
INPUT_NAMES = {"observations.jsonl", "policy.stdout", "policy-result.json", "test-result.json"}
PRODUCERS = ("scripts/analyze_fixture_policy.py", "scripts/fixture_policy_associations.py")
LIMITS = {
    "native_hash_rederivation": "unavailable_without_private_capture_root_and_native_abi",
    "calibration_replay": "literal_policy_witnesses_pinned_by_supplied_digest",
    "digest_authority": "caller_retained_anchor_not_authentication",
    "identity": "empirical_within_observed_sources_not_universal",
    "complete_coverage": "unproved",
    "missing_records": "unknown",
    "raw_records": "omitted_token_projection_only",
    "original_outcome": "not_replayed_result_bytes_pinned_only",
}


def canonical(value):
    return (json.dumps(value, ensure_ascii=True, sort_keys=True,
                       separators=(",", ":"), allow_nan=False) + "\n").encode("ascii")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fields(value, expected):
    if type(value) is not dict or set(value) != set(expected):
        raise ValueError("association object has missing or unknown fields")


def integer(value, maximum, minimum=0):
    if type(value) is not int or not minimum <= value <= maximum:
        raise ValueError("association integer exceeds its fixed domain")


def hex_value(value, width):
    if type(value) is not str or re.fullmatch(r"[0-9a-f]{" + str(width) + "}", value) is None:
        raise ValueError("association digest or token is malformed")


def path_value(value, prefix):
    analysis.relative_path(value, prefix)
    if (len(value.encode("utf-8")) > MAX_PATH_BYTES
            or any(ord(char) < 32 or char == "\\" for char in value)):
        raise ValueError("association path exceeds its fixed domain")


def bounded_list(value, maximum, minimum=0):
    if type(value) is not list or not minimum <= len(value) <= maximum:
        raise ValueError("association list exceeds its fixed cardinality")


def identity(value, maximum):
    fields(value, ("bytes", "sha256"))
    integer(value["bytes"], maximum)
    hex_value(value["sha256"], 64)


def input_identities(value):
    fields(value, INPUT_NAMES)
    for item in value.values():
        identity(item, analysis.MAX_FILE_BYTES)


def source_identity(value):
    fields(value, ("path", "sha256", "size_bytes", "token"))
    path_value(value["path"], analysis.FIXTURE_PREFIX)
    hex_value(value["sha256"], 64)
    integer(value["size_bytes"], analysis.MAX_SOURCE_BYTES)
    hex_value(value["token"], 16)


def unique_sources(sources, minimum):
    bounded_list(sources, analysis.MAX_SOURCES, minimum)
    paths, tokens = set(), set()
    for source in sources:
        source_identity(source)
        if source["path"] in paths or source["token"] in tokens:
            raise ValueError("association sources have duplicate paths or colliding tokens")
        paths.add(source["path"])
        tokens.add(source["token"])
    if [source["path"] for source in sources] != sorted(paths):
        raise ValueError("association sources are not in canonical path order")


def validate(manifest):
    """Validate the frozen replay schema; no live producer or native dependency."""
    fields(manifest, ("schema", "algorithm", "producers", "target", "calibrations", "limits"))
    if manifest["schema"] != SCHEMA or manifest["algorithm"] != ALGORITHM or manifest["limits"] != LIMITS:
        raise ValueError("association schema, algorithm or replay limits disagree")
    fields(manifest["producers"], PRODUCERS)
    for producer in manifest["producers"].values():
        identity(producer, analysis.MAX_FILE_BYTES)
    target = manifest["target"]
    fields(target, ("run", "inputs", "sources", "records"))
    path_value(target["run"], ".artifacts/logs/")
    input_identities(target["inputs"])
    unique_sources(target["sources"], 1)
    bounded_list(target["records"], analysis.MAX_EVENTS)
    for record in target["records"]:
        fields(record, ("sha256", "tokens", "phase"))
        hex_value(record["sha256"], 64)
        bounded_list(record["tokens"], MAX_RECORD_TOKENS)
        for token in record["tokens"]:
            hex_value(token, 16)
        if record["tokens"] != sorted(set(record["tokens"])):
            raise ValueError("record tokens are not unique and canonically ordered")
        if record["phase"] not in ("queued", "started", "wakeups", "other"):
            raise ValueError("unknown association record phase")
    bounded_list(manifest["calibrations"], analysis.MAX_CALIBRATIONS, 1)
    runs = {target["run"]}
    for calibration in manifest["calibrations"]:
        fields(calibration, ("run", "inputs", "pairs"))
        path_value(calibration["run"], ".artifacts/logs/")
        if calibration["run"] in runs:
            raise ValueError("association calibration must use distinct separate runs")
        runs.add(calibration["run"])
        input_identities(calibration["inputs"])
        unique_sources(calibration["pairs"], 2)
    if [item["run"] for item in manifest["calibrations"]] != sorted(runs - {target["run"]}):
        raise ValueError("calibration runs are not in canonical order")
    if len(canonical(manifest)) > MAX_MANIFEST_BYTES:
        raise ValueError("association manifest exceeds its fixed byte bound")


def projected_source(source, token):
    return {key: source[key] for key in ("path", "sha256", "size_bytes")} | {"token": token}


def phase(message):
    for prefix, name in (("queueing up scan", "queued"), ("starting work for scan", "started"),
                         ("scan finished, waking", "wakeups")):
        if message.startswith(prefix):
            return name
    return "other"


def seal(target, calibrations, root=ROOT, path_hash=None):
    """Seal once collection has settled, while the caller still owns its root.

    This boundary never starts collection. Existing captures can be sealed in
    their original checkout, but doing so does not backdate manifest creation.
    """
    root = root.resolve()
    bounded_list(calibrations, analysis.MAX_CALIBRATIONS, 1)
    if target in calibrations or len(set(calibrations)) != len(calibrations):
        raise ValueError("association calibration must use distinct separate runs")
    runs = [analysis.load_run(name, root) for name in [target, *sorted(calibrations)]]
    run = runs[0]
    if run["capture_root"] != str(root):
        raise ValueError("seal requires the original capture checkout; replay requires no historical root")
    path_hash = analysis.NativePathHash() if path_hash is None else path_hash
    checked = []
    for calibration in runs[1:]:
        pairs = analysis.literal_pairs(calibration)
        if len(pairs) < 2 or len(set(pairs.values())) != len(pairs):
            raise ValueError("calibration requires distinct independently linked paths and tokens")
        sources = []
        for absolute, token in pairs.items():
            if path_hash(absolute) != token:
                raise ValueError("native path hash disagrees with literal policy calibration")
            relative = absolute[len(calibration["capture_root"]) + 1:]
            sources.append(projected_source(calibration["sources"][relative], token))
        checked.append(dict(run=calibration["directory"], inputs=calibration["inputs"],
                            pairs=sorted(sources, key=lambda source: source["path"])))
    sources = [projected_source(source, path_hash(str(root) + "/" + path))
               for path, source in sorted(run["sources"].items())]
    unique_sources(sources, 1)
    by_path = {str(root) + "/" + source["path"]: source["token"] for source in sources}
    for absolute, token in analysis.literal_pairs(run).items():
        if by_path[absolute] != token:
            raise ValueError("target literal policy record contradicts calibrated attribution")
    records = [dict(sha256=digest(canonical(record)),
                    tokens=sorted(set(analysis.TOKEN.findall(record["eventMessage"]))),
                    phase=phase(record["eventMessage"])) for record in run["records"]]
    producers = {}
    for name in PRODUCERS:
        # These are tool dependencies, not paths from the retained evidence.
        data = analysis.read_local(ROOT / name, ROOT)
        producers[name] = dict(bytes=len(data), sha256=digest(data))
    manifest = dict(schema=SCHEMA, algorithm=ALGORITHM, producers=producers,
                    target=dict(run=target, inputs=run["inputs"], sources=sources, records=records),
                    calibrations=checked, limits=dict(LIMITS))
    validate(manifest)
    # Reject a changing input set, including replacement between separate file
    # reads. Source archive identities are checked again by the same loader.
    for captured in runs:
        current = analysis.load_run(captured["directory"], root)
        if current != captured:
            raise ValueError("capture evidence changed during association sealing")
    return manifest


def replay(raw, expected_sha256, archive_directory, root=ROOT):
    """Check a separately pinned manifest and relocated target archives."""
    if type(raw) is not bytes or len(raw) > MAX_MANIFEST_BYTES:
        raise ValueError("association manifest exceeds its fixed byte bound")
    hex_value(expected_sha256, 64)
    if digest(raw) != expected_sha256:
        raise ValueError("association manifest disagrees with the independently retained digest")
    manifest = analysis.decode_json(raw)
    validate(manifest)
    if raw != canonical(manifest):
        raise ValueError("association manifest encoding is not canonical")
    root = root.resolve()
    path_value(archive_directory, ".artifacts/logs/")
    directory = root / archive_directory
    for source in manifest["target"]["sources"]:
        body = analysis.read_local(directory / (source["sha256"] + ".source"), root,
                                   analysis.MAX_SOURCE_BYTES)
        if len(body) != source["size_bytes"] or digest(body) != source["sha256"]:
            raise ValueError("relocated source archive disagrees with its sealed identity")
    sources = {source["token"]: source for source in manifest["target"]["sources"]}
    groups = {}
    for index, record in enumerate(manifest["target"]["records"]):
        for token in record["tokens"]:
            group = groups.setdefault(token, dict(token=token, source=sources.get(token),
                record_indices=[], queued=0, started=0, wakeups=0))
            group["record_indices"].append(index)
            if record["phase"] != "other":
                group[record["phase"]] += 1
    return dict(schema="fsmgen.fixture_policy_association_replay.v1", manifest_sha256=expected_sha256,
                tokens=[groups[token] for token in sorted(groups)], limits=dict(LIMITS))


def publish(manifest, relative, root=ROOT):
    """Publish complete bytes without replacing any existing evidence."""
    validate(manifest)
    root = root.resolve()
    path_value(relative, ".artifacts/logs/")
    destination = root / relative
    parent = destination.parent
    if (parent.resolve() != parent or root not in parent.parents
            or parent.stat().st_dev != root.stat().st_dev or parent.stat().st_uid != os.getuid()):
        raise ValueError("association destination requires an owned direct local directory")
    raw = canonical(manifest)
    pending = parent / ("associations-" + uuid.uuid4().hex + ".pending")
    owned = False
    try:
        with pending.open("xb") as stream:
            owned = True
            os.chmod(pending, 0o600)
            stream.write(raw)
            stream.flush()
            os.fsync(stream.fileno())
        os.link(pending, destination)
    finally:
        if owned:
            pending.unlink()
    return digest(raw)


class PrivateArgumentParser(argparse.ArgumentParser):
    def error(self, _message):
        # argparse normally quotes invalid arguments, which may be private paths.
        raise ValueError("invalid association command arguments")


def main(argv=None):
    parser = PrivateArgumentParser(description=__doc__)
    modes = parser.add_subparsers(dest="mode", required=True)
    capture = modes.add_parser("seal", help="seal settled evidence in its original checkout")
    capture.add_argument("run")
    capture.add_argument("--calibration", action="append", required=True)
    capture.add_argument("--output", required=True)
    consumer = modes.add_parser("replay", help="replay a separately pinned manifest and local archives")
    consumer.add_argument("manifest")
    consumer.add_argument("--sha256", required=True)
    consumer.add_argument("--archives", required=True)
    try:
        args = parser.parse_args(argv)
        if args.mode == "seal":
            manifest = seal(args.run, args.calibration)
            print(publish(manifest, args.output))
        else:
            path_value(args.manifest, ".artifacts/logs/")
            raw = analysis.read_local(ROOT / args.manifest, ROOT, MAX_MANIFEST_BYTES)
            print(json.dumps(replay(raw, args.sha256, args.archives), indent=2))
        return 0
    except (OSError, ValueError, TypeError, KeyError, RecursionError, RuntimeError):
        # Raw exceptions, JSON source snippets and OS filenames can disclose
        # private input. The CLI prints only a fixed failure classification.
        print("fixture policy association failed; no successful result", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
