"""Export a bounded policy diagnostic projection from separately pinned evidence.

Private snapshots are read locally and never copied into the report. Report
consumption needs only its bytes and a separately held digest, not the snapshots,
source bodies, historical checkout, or native hashing. Digests are not signatures.
"""

import datetime
import json
from pathlib import Path
import re
import sys

import fixture_policy_associations as associations


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = "fsmgen.fixture_policy_diagnostics.v1"
MAX_REPORT_BYTES = associations.MAX_MANIFEST_BYTES
CONTEXT_NUMBERS = {
    "process_id": ("processID", (1 << 31) - 1),
    "thread_id": ("threadID", (1 << 64) - 1),
    "activity_id": ("activityIdentifier", (1 << 64) - 1),
    "mach_timestamp": ("machTimestamp", (1 << 64) - 1),
}
TIMESTAMP = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6} ?[+-][0-9]{4}")
OMISSIONS = {
    "raw_messages": True, "raw_metadata": True, "raw_errors": True,
    "source_bodies": True, "unadmitted_context": True,
    "original_detail": True, "collector_detail": True,
}
LIMITS = {
    "association_authority": "separately_pinned_manifest_not_authentication",
    "report_authority": "separately_pinned_bytes_not_authentication",
    "source_identity": "pinned_associations_bodies_not_rehashed_or_disclosed",
    "native_hash_rederivation": "unavailable_without_private_capture_root_and_native_abi",
    "original_outcome": "exit_and_timeout_only_not_overall_qualification",
    "collector_settlement": "retained_flags_not_fresh_process_verification",
    "observer_outcome": "not_projected",
    "clock": "retained_policy_fields_no_cross_clock_conversion",
    "process_identity": "retained_numbers_not_native_birth_or_cross_run_identity",
    "complete_coverage": "unproved", "missing_records": "unknown",
    "unobserved_descendants": "unknown",
    "missing_progress": "does_not_prove_missing_execution",
    "raw_record_equivalence": "not_claimed",
}


def admitted_integer(value, maximum):
    return type(value) is int and 0 <= value <= maximum


def admitted_timestamp(value):
    if type(value) is not str or TIMESTAMP.fullmatch(value) is None:
        return False
    try:
        # Retained native NDJSON uses an adjacent offset; both that spelling and
        # a separated offset are closed, validated forms. Preserve the input.
        separator = " " if value[26] == " " else ""
        datetime.datetime.strptime(value, "%Y-%m-%d %H:%M:%S.%f" + separator + "%z")
        return True
    except ValueError:
        return False


def boolean_or_unknown(value):
    return value if type(value) is bool else None


def project_context(record):
    # Only fixed field names and individually admitted primitives cross this
    # boundary. Unknown strings, including subsystem names, are never copied.
    result = {key: record.get(source) if admitted_integer(record.get(source), maximum) else None
              for key, (source, maximum) in CONTEXT_NUMBERS.items()}
    result["timestamp"] = record.get("timestamp") if admitted_timestamp(record.get("timestamp")) else None
    subsystem = record.get("subsystem")
    result["subsystem"] = ("execution_policy" if subsystem == "com.apple.syspolicy.exec"
                           else "missing" if subsystem is None else "other")
    return result


def retained_scope(collector):
    if type(collector) is not dict:
        raise ValueError("diagnostic collector result is not an object")
    scope = collector.get("scope")
    if scope == "execution_context":
        associations.analysis.verify_collector_command(collector)
    elif (scope != "daemon_context" or collector.get("schema") != "fsmgen.fixture_policy_log.v1"
          or collector.get("command") != ["/usr/bin/log", "stream", "--style", "ndjson", "--level", "debug",
                                         "--timeout", "240", "--predicate", 'process == "syspolicyd"']):
        raise ValueError("diagnostic collector command is not a reviewed contract")
    return scope


def validate(report):
    """Closed report admission also protects the public consumption path."""
    associations.fields(report, ("schema", "qualification", "manifest_sha256", "producer_sha256", "inputs", "scope",
        "sources", "records", "metadata_records_omitted", "original", "collector", "omissions", "limits"))
    if (report["schema"] != SCHEMA or report["qualification"] != "not_claimed"
            or report["scope"] not in ("execution_context", "daemon_context")
            or report["omissions"] != OMISSIONS or report["limits"] != LIMITS):
        raise ValueError("diagnostic schema, scope or disclosure limits disagree")
    if any(value is not True for value in report["omissions"].values()):
        raise ValueError("diagnostic omission flags are not booleans")
    associations.hex_value(report["manifest_sha256"], 64)
    associations.hex_value(report["producer_sha256"], 64)
    associations.input_identities(report["inputs"])
    associations.unique_sources(report["sources"], 1)
    associations.bounded_list(report["records"], associations.analysis.MAX_EVENTS)
    associations.integer(report["metadata_records_omitted"], associations.analysis.MAX_EVENTS)
    if len(report["records"]) + report["metadata_records_omitted"] > associations.analysis.MAX_EVENTS:
        raise ValueError("diagnostic records exceed the retained event bound")
    for record in report["records"]:
        associations.fields(record, ("sha256", "tokens", "phase", "context"))
        associations.hex_value(record["sha256"], 64)
        associations.bounded_list(record["tokens"], associations.MAX_RECORD_TOKENS)
        for token in record["tokens"]:
            associations.hex_value(token, 16)
        if record["tokens"] != sorted(set(record["tokens"])) or record["phase"] not in ("queued", "started", "wakeups", "other"):
            raise ValueError("diagnostic record projection disagrees with its closed domain")
        context = record["context"]
        associations.fields(context, (*CONTEXT_NUMBERS, "timestamp", "subsystem"))
        for key, (_, maximum) in CONTEXT_NUMBERS.items():
            if context[key] is not None:
                associations.integer(context[key], maximum)
        if context["timestamp"] is not None and not admitted_timestamp(context["timestamp"]):
            raise ValueError("diagnostic timestamp is not admitted")
        if context["subsystem"] not in ("execution_policy", "other", "missing"):
            raise ValueError("diagnostic subsystem class is not admitted")
    associations.fields(report["original"], ("returncode", "timeout", "released", "leader_reaped"))
    associations.integer(report["original"]["returncode"], 255, -255)
    if type(report["original"]["timeout"]) is not bool:
        raise ValueError("diagnostic original timeout is not a boolean")
    for key in ("released", "leader_reaped"):
        if report["original"][key] is not None and type(report["original"][key]) is not bool:
            raise ValueError("diagnostic original flag is not admitted")
    associations.fields(report["collector"], ("returncode", "reported_failure", "leader_reaped", "forced_kill"))
    if report["collector"]["returncode"] is not None:
        associations.integer(report["collector"]["returncode"], 255, -255)
    if type(report["collector"]["reported_failure"]) is not bool:
        raise ValueError("diagnostic failure flag is not a boolean")
    for key in ("leader_reaped", "forced_kill"):
        if report["collector"][key] is not None and type(report["collector"][key]) is not bool:
            raise ValueError("diagnostic collector flag is not admitted")
    if len(associations.canonical(report)) > MAX_REPORT_BYTES:
        raise ValueError("diagnostic report exceeds its fixed byte bound")


def export(raw, expected_sha256, private_directory, root=ROOT):
    """Project pinned private bytes; never read source bodies or native state."""
    manifest = associations.read_manifest(raw, expected_sha256)
    root = root.resolve()
    producer_path = Path(__file__).resolve()
    producer_root = producer_path.parents[1]
    if root.stat().st_dev != producer_root.stat().st_dev:
        raise ValueError("diagnostic inputs and producer must share the repository volume")
    associations.path_value(private_directory, ".artifacts/logs/")
    directory = root / private_directory
    inputs = {}
    for name, identity in manifest["target"]["inputs"].items():
        data = associations.analysis.read_local(directory / name, root)
        if len(data) != identity["bytes"] or associations.digest(data) != identity["sha256"]:
            raise ValueError("private diagnostic input disagrees with its pinned identity")
        inputs[name] = data
    collector = associations.analysis.decode_json(inputs["policy-result.json"])
    scope = retained_scope(collector)
    original = associations.analysis.decode_json(inputs["test-result.json"])
    if type(original) is not dict or type(collector.get("failures")) is not dict:
        raise ValueError("diagnostic outcome is not a retained result object")
    lines = inputs["policy.stdout"].decode("utf-8").splitlines()
    if not lines or not lines[0].startswith("Filtering the log data using "):
        raise ValueError("diagnostic native header is unavailable")
    if scope == "execution_context":
        associations.analysis.capture_root_from_header(lines[0])
    elif lines[0] != 'Filtering the log data using "process == "syspolicyd""':
        raise ValueError("diagnostic native header disagrees with the reviewed daemon scope")
    records, metadata_count = [], 0
    sealed_records = manifest["target"]["records"]
    for line in lines[1:]:
        if not line.strip():
            continue
        record = associations.analysis.decode_json(line)
        if type(record) is not dict:
            raise ValueError("diagnostic retained record is not an object")
        if record.get("eventType") == "logEvent":
            if type(record.get("eventMessage")) is not str:
                raise ValueError("diagnostic log event lacks a message")
            projection = dict(sha256=associations.digest(associations.canonical(record)),
                tokens=sorted(set(associations.analysis.TOKEN.findall(record["eventMessage"]))),
                phase=associations.phase(record["eventMessage"]))
            if len(records) >= len(sealed_records) or projection != sealed_records[len(records)]:
                raise ValueError("diagnostic event projection disagrees with pinned associations")
            records.append(projection | {"context": project_context(record)})
        else:
            metadata_count += 1
        if len(records) + metadata_count > associations.analysis.MAX_EVENTS:
            raise ValueError("diagnostic records exceed the retained event bound")
    if len(records) != len(sealed_records):
        raise ValueError("diagnostic event count disagrees with pinned associations")
    report = dict(schema=SCHEMA, qualification="not_claimed", manifest_sha256=expected_sha256,
        producer_sha256=associations.digest(associations.analysis.read_local(producer_path, producer_root)),
        inputs=manifest["target"]["inputs"], scope=scope, sources=manifest["target"]["sources"],
        records=records, metadata_records_omitted=metadata_count,
        original=dict(returncode=original.get("returncode"), timeout=original.get("timeout"),
            released=boolean_or_unknown(original.get("released")), leader_reaped=boolean_or_unknown(original.get("leader_reaped"))),
        collector=dict(returncode=collector.get("returncode"), reported_failure=bool(collector["failures"]),
            leader_reaped=boolean_or_unknown(collector.get("leader_reaped")), forced_kill=boolean_or_unknown(collector.get("forced_kill"))),
        omissions=dict(OMISSIONS), limits=dict(LIMITS))
    validate(report)
    for name, previous in inputs.items():
        if associations.analysis.read_local(directory / name, root) != previous:
            raise ValueError("private diagnostic input changed during projection")
    return report


def read_report(raw, expected_sha256):
    if type(raw) is not bytes or len(raw) > MAX_REPORT_BYTES:
        raise ValueError("diagnostic report exceeds its fixed byte bound")
    associations.hex_value(expected_sha256, 64)
    if associations.digest(raw) != expected_sha256:
        raise ValueError("diagnostic report disagrees with its separately retained digest")
    report = associations.analysis.decode_json(raw)
    validate(report)
    if raw != associations.canonical(report):
        raise ValueError("diagnostic encoding is not canonical")
    return report


def main(argv=None):
    parser = associations.PrivateArgumentParser(prog="fixture-policy-diagnostics", description=__doc__)
    modes = parser.add_subparsers(dest="mode", required=True)
    producer = modes.add_parser("export", help="project matching local private snapshots")
    producer.add_argument("manifest")
    producer.add_argument("--sha256", required=True)
    producer.add_argument("--private-inputs", required=True)
    producer.add_argument("--output", required=True)
    consumer = modes.add_parser("read", help="read a separately pinned diagnostic report")
    consumer.add_argument("report")
    consumer.add_argument("--sha256", required=True)
    try:
        args = parser.parse_args(argv)
        path = args.manifest if args.mode == "export" else args.report
        associations.path_value(path, ".artifacts/logs/")
        raw = associations.analysis.read_local(ROOT / path, ROOT, MAX_REPORT_BYTES)
        if args.mode == "export":
            report = export(raw, args.sha256, args.private_inputs, ROOT)
            print(associations.publish_bytes(associations.canonical(report), args.output, ROOT))
        else:
            print(json.dumps(read_report(raw, args.sha256), indent=2))
        return 0
    except (Exception, KeyboardInterrupt):
        # Tracebacks, parser diagnostics and OS errors can contain private paths,
        # input fragments or field names. Only this fixed status is disclosed.
        print("fixture policy diagnostic failed; no successful result", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
