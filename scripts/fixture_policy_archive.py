"""Bounded ordered daemon evidence, independent of private capture inputs.

The pinned index and its public pages establish artifact consistency only.
Legacy association, diagnostic and publication v1 contracts remain separate.
"""

from pathlib import Path

import fixture_policy_diagnostics as diagnostics


associations = diagnostics.associations
analysis = associations.analysis
ROOT = Path(__file__).resolve().parents[1]
SCHEMA = "fsmgen.fixture_policy_archive.v1"
PAGE_SCHEMA = "fsmgen.fixture_policy_archive_page.v1"
INDEX_FILE = "policy-archive.json"
MAX_PAGES = 16
MAX_PAGE_RECORDS = 4096
MAX_PAGE_BYTES = 2 * 1024 * 1024
MAX_INDEX_BYTES = 2 * 1024 * 1024
MAX_RECORDS = MAX_PAGES * MAX_PAGE_RECORDS
MAX_TOTAL_PAGE_BYTES = MAX_PAGES * MAX_PAGE_BYTES
PRODUCERS = (
    "scripts/analyze_fixture_policy.py",
    "scripts/fixture_policy_associations.py",
    "scripts/fixture_policy_diagnostics.py",
    "scripts/fixture_policy_archive.py",
)
LIMITS = {
    "authority": "separately_pinned_index_not_authentication",
    "raw_messages": "omitted",
    "raw_metadata": "omitted_hashes_and_positions_retained",
    "raw_errors": "omitted",
    "source_bodies": "not_included_or_rehashed_by_consumer",
    "private_inputs": "not_reloaded_by_consumer",
    "native_hash_rederivation": "unavailable_without_private_capture_root_and_native_abi",
    "source_identity": "empirical_within_observed_sources_not_universal",
    "original_qualification": "not_claimed",
    "observer_qualification": "not_claimed",
    "collector_settlement": "retained_flags_not_fresh_process_verification",
    "clock": "retained_policy_fields_no_cross_clock_conversion",
    "process_identity": "retained_numbers_not_native_birth_or_cross_run_identity",
    "complete_coverage": "unproved",
    "missing_records": "unknown",
    "unobserved_descendants": "unknown",
    "missing_progress": "does_not_prove_missing_execution",
    "raw_record_equivalence": "not_claimed",
}
DESCRIPTOR_FIELDS = (
    "path", "bytes", "sha256", "first_record", "record_count",
    "log_event_count", "metadata_count",
)


def page_path(run, number):
    associations.path_value(run, ".artifacts/logs/")
    associations.integer(number, MAX_PAGES, 1)
    return run + "/policy-archive-%04d.json" % number


def _optional_boolean(value):
    if value is not None and type(value) is not bool:
        raise ValueError("archive outcome flag is not an admitted boolean")


def _validate_outcomes(original, collector):
    associations.fields(original, ("returncode", "timeout", "released", "leader_reaped"))
    associations.integer(original["returncode"], 255, -255)
    if type(original["timeout"]) is not bool:
        raise ValueError("archive original timeout is not a boolean")
    for key in ("released", "leader_reaped"):
        _optional_boolean(original[key])
    associations.fields(collector, ("returncode", "reported_failure", "leader_reaped", "forced_kill"))
    if collector["returncode"] is not None:
        associations.integer(collector["returncode"], 255, -255)
    if type(collector["reported_failure"]) is not bool:
        raise ValueError("archive collector failure flag is not a boolean")
    for key in ("leader_reaped", "forced_kill"):
        _optional_boolean(collector[key])


def validate_context(context):
    associations.fields(context, ("run", "inputs", "sources", "calibrations", "producers",
                                  "scope", "original", "collector"))
    associations.path_value(context["run"], ".artifacts/logs/")
    associations.input_identities(context["inputs"])
    associations.unique_sources(context["sources"], 1)
    associations.bounded_list(context["calibrations"], analysis.MAX_CALIBRATIONS, 1)
    runs = {context["run"]}
    for calibration in context["calibrations"]:
        associations.calibration_identity(calibration)
        if calibration["run"] in runs:
            raise ValueError("archive calibration requires distinct separate runs")
        runs.add(calibration["run"])
    if [item["run"] for item in context["calibrations"]] != sorted(runs - {context["run"]}):
        raise ValueError("archive calibrations are not in canonical order")
    associations.fields(context["producers"], PRODUCERS)
    for identity in context["producers"].values():
        associations.identity(identity, analysis.MAX_FILE_BYTES)
    if context["scope"] != "daemon_context":
        raise ValueError("archive scope is not daemon_context")
    _validate_outcomes(context["original"], context["collector"])


def _validate_counts(value, maximum, *, nonempty):
    associations.integer(value["record_count"], maximum, 1 if nonempty else 0)
    for key in ("log_event_count", "metadata_count"):
        associations.integer(value[key], maximum)
    if value["record_count"] != value["log_event_count"] + value["metadata_count"]:
        raise ValueError("archive record counts disagree")


def _validate_descriptor(descriptor):
    associations.fields(descriptor, DESCRIPTOR_FIELDS)
    associations.path_value(descriptor["path"], ".artifacts/logs/")
    associations.integer(descriptor["bytes"], MAX_PAGE_BYTES, 1)
    associations.hex_value(descriptor["sha256"], 64)
    associations.integer(descriptor["first_record"], MAX_RECORDS - 1)
    _validate_counts(descriptor, MAX_PAGE_RECORDS, nonempty=True)
    if descriptor["first_record"] + descriptor["record_count"] > MAX_RECORDS:
        raise ValueError("archive page extends beyond its record envelope")


def validate_index(index):
    """Validate the complete closed index before following any page path."""
    associations.fields(index, ("schema", "context", "context_sha256", "pages", "record_count",
                                "log_event_count", "metadata_count", "limits"))
    if index["schema"] != SCHEMA or index["limits"] != LIMITS:
        raise ValueError("archive schema or limits disagree")
    validate_context(index["context"])
    associations.hex_value(index["context_sha256"], 64)
    if index["context_sha256"] != associations.digest(associations.canonical(index["context"])):
        raise ValueError("archive context disagrees with its digest")
    associations.bounded_list(index["pages"], MAX_PAGES, 1)
    _validate_counts(index, MAX_RECORDS, nonempty=True)
    totals = dict(record_count=0, log_event_count=0, metadata_count=0)
    total_bytes = 0
    for number, descriptor in enumerate(index["pages"], 1):
        _validate_descriptor(descriptor)
        if (descriptor["path"] != page_path(index["context"]["run"], number)
                or descriptor["first_record"] != totals["record_count"]):
            raise ValueError("archive pages are not fixed consecutive paths and record ranges")
        for key in totals:
            totals[key] += descriptor[key]
        total_bytes += descriptor["bytes"]
    if any(index[key] != value for key, value in totals.items()):
        raise ValueError("archive totals disagree with its page descriptors")
    if total_bytes > MAX_TOTAL_PAGE_BYTES:
        raise ValueError("archive pages exceed their aggregate byte bound")
    if len(associations.canonical(index)) > MAX_INDEX_BYTES:
        raise ValueError("archive index exceeds its byte bound")


def _validate_record(record):
    if type(record) is not dict or record.get("kind") not in ("metadata", "log_event"):
        raise ValueError("archive record kind is not admitted")
    expected = ("kind", "sha256") if record["kind"] == "metadata" else (
        "kind", "sha256", "tokens", "phase", "context")
    associations.fields(record, expected)
    associations.hex_value(record["sha256"], 64)
    if record["kind"] == "metadata":
        return
    associations.bounded_list(record["tokens"], associations.MAX_RECORD_TOKENS)
    for token in record["tokens"]:
        associations.hex_value(token, 16)
    if (record["tokens"] != sorted(set(record["tokens"]))
            or record["phase"] not in ("queued", "started", "wakeups", "other")):
        raise ValueError("archive token order or phase is not admitted")
    context = record["context"]
    associations.fields(context, (*diagnostics.CONTEXT_NUMBERS, "timestamp", "subsystem"))
    for key, (_, maximum) in diagnostics.CONTEXT_NUMBERS.items():
        if context[key] is not None:
            associations.integer(context[key], maximum)
    if context["timestamp"] is not None and not diagnostics.admitted_timestamp(context["timestamp"]):
        raise ValueError("archive timestamp is not admitted")
    if context["subsystem"] not in ("execution_policy", "other", "missing"):
        raise ValueError("archive subsystem class is not admitted")


def validate_page(page, descriptor, context_sha256):
    _validate_descriptor(descriptor)
    associations.hex_value(context_sha256, 64)
    associations.fields(page, ("schema", "context_sha256", "first_record", "records"))
    associations.integer(page["first_record"], MAX_RECORDS - 1)
    if (page["schema"] != PAGE_SCHEMA or page["context_sha256"] != context_sha256
            or page["first_record"] != descriptor["first_record"]):
        raise ValueError("archive page disagrees with its bound context or range")
    associations.bounded_list(page["records"], MAX_PAGE_RECORDS, 1)
    log_events = 0
    for record in page["records"]:
        _validate_record(record)
        log_events += record["kind"] == "log_event"
    if (len(page["records"]) != descriptor["record_count"]
            or log_events != descriptor["log_event_count"]
            or len(page["records"]) - log_events != descriptor["metadata_count"]):
        raise ValueError("archive page entries disagree with its descriptor counts")
    if len(associations.canonical(page)) > MAX_PAGE_BYTES:
        raise ValueError("archive page exceeds its byte bound")


def _decode_pinned(raw, expected_sha256, maximum, label):
    if type(raw) is not bytes or len(raw) > maximum:
        raise ValueError("archive " + label + " exceeds its byte bound")
    associations.hex_value(expected_sha256, 64)
    if associations.digest(raw) != expected_sha256:
        raise ValueError("archive " + label + " disagrees with its pinned digest")
    value = analysis.decode_json(raw)
    if associations.canonical(value) != raw:
        raise ValueError("archive " + label + " encoding is not canonical")
    return value


def read_index(raw, expected_sha256):
    index = _decode_pinned(raw, expected_sha256, MAX_INDEX_BYTES, "index")
    validate_index(index)
    return index


def read_page(raw, descriptor, context_sha256):
    _validate_descriptor(descriptor)
    page = _decode_pinned(raw, descriptor["sha256"], MAX_PAGE_BYTES, "page")
    if len(raw) != descriptor["bytes"]:
        raise ValueError("archive page bytes disagree with its descriptor")
    validate_page(page, descriptor, context_sha256)
    return page


def consume(raw, expected_sha256, root=ROOT):
    """Read only an anchored index and its fixed bounded public page set."""
    index = read_index(raw, expected_sha256)
    root = root.resolve()
    if root.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError("archive pages and consumer must share the repository volume")
    pages = []
    for descriptor in index["pages"]:
        data = analysis.read_local(root / descriptor["path"], root, MAX_PAGE_BYTES)
        pages.append(read_page(data, descriptor, index["context_sha256"]))
    return {"index": index, "pages": pages}
