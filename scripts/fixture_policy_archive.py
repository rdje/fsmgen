"""Bounded ordered daemon evidence, independent of private capture inputs.

The pinned index and its public pages establish artifact consistency only.
Legacy association, diagnostic and publication v1 contracts remain separate.
"""

import os
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


def _project_rows(raw):
    """Retain one ordered entry per nonblank native row, including metadata."""
    records, entries = [], []
    for line in raw.decode("utf-8").splitlines()[1:]:
        if not line.strip():
            continue
        if len(entries) >= MAX_RECORDS:
            raise ValueError("archive input exceeds its combined record bound")
        row = analysis.decode_json(line)
        if type(row) is not dict:
            raise ValueError("archive native record is not an object")
        entry = dict(kind="metadata", sha256=associations.digest(associations.canonical(row)))
        if row.get("eventType") == "logEvent":
            if type(row.get("eventMessage")) is not str:
                raise ValueError("archive log event lacks its message")
            records.append(row)
            entry.update(kind="log_event", tokens=sorted(analysis.policy_tokens(row["eventMessage"])),
                         phase=associations.phase(row["eventMessage"]), context=diagnostics.project_context(row))
        _validate_record(entry)
        entries.append(entry)
    if not entries:
        raise ValueError("archive input contains no retained rows")
    return records, entries


def _pack_pages(entries, context_sha256, run):
    """Greedy whole-entry packing with exact linear canonical byte accounting."""
    pages, descriptors = [], []
    first = 0

    def empty_page():
        return dict(schema=PAGE_SCHEMA, context_sha256=context_sha256,
                    first_record=first, records=[])

    page = empty_page()
    page_size = len(associations.canonical(page))

    def finish_page():
        if len(pages) >= MAX_PAGES:
            raise ValueError("archive exceeds its fixed page-count bound")
        raw = associations.canonical(page)
        if len(raw) != page_size:
            raise ValueError("archive canonical byte accounting disagrees")
        log_count = sum(entry["kind"] == "log_event" for entry in page["records"])
        descriptor = dict(path=page_path(run, len(pages) + 1), bytes=len(raw),
            sha256=associations.digest(raw), first_record=first,
            record_count=len(page["records"]), log_event_count=log_count,
            metadata_count=len(page["records"]) - log_count)
        validate_page(page, descriptor, context_sha256)
        pages.append(raw)
        descriptors.append(descriptor)

    for entry in entries:
        # canonical(entry) includes one trailing newline, absent inside a list.
        entry_size = len(associations.canonical(entry)) - 1
        additional = entry_size + bool(page["records"])
        if page["records"] and (len(page["records"]) == MAX_PAGE_RECORDS
                                or page_size + additional > MAX_PAGE_BYTES):
            finish_page()
            first += len(page["records"])
            page = empty_page()
            page_size = len(associations.canonical(page))
            additional = entry_size
        if page_size + additional > MAX_PAGE_BYTES:
            raise ValueError("archive entry cannot fit its fixed page byte bound")
        page["records"].append(entry)
        page_size += additional
    if page["records"]:
        finish_page()
    return descriptors, pages


def build(target, calibrations, root=ROOT, path_hash=None):
    """Return a validated index and page_bytes; never publish or launch.

    All private inputs, archives, calibration and producer bytes are rechecked
    before returning. Public consumption still needs only the resulting pages.
    """
    root = root.resolve()
    if root.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError("archive inputs and producer must share the repository volume")
    associations.path_value(target, ".artifacts/logs/")
    associations.bounded_list(calibrations, analysis.MAX_CALIBRATIONS, 1)
    if target in calibrations or len(set(calibrations)) != len(calibrations):
        raise ValueError("archive calibration requires distinct separate runs")
    path_hash = analysis.NativePathHash() if path_hash is None else path_hash
    admitted = associations.calibration_snapshot(calibrations, root, path_hash)
    captured, raw_inputs = analysis._load_capture_inputs(target, root, daemon_capture=True)
    raw_inputs["test-result.json"] = analysis.read_local(root / target / "test-result.json", root)
    original = analysis.decode_json(raw_inputs["test-result.json"])
    collector = captured["collector_result"]
    if type(original) is not dict or type(collector.get("failures")) is not dict:
        raise ValueError("archive outcome is not a retained result object")
    records, entries = _project_rows(raw_inputs["policy.stdout"])
    sources = [associations.projected_source(source, path_hash(str(root / path)))
               for path, source in sorted(captured["sources"].items())]
    associations.unique_sources(sources, 1)
    by_path = {str(root / source["path"]): source["token"] for source in sources}
    for absolute, token in analysis.literal_pairs(captured | {"records": records}).items():
        if by_path[absolute] != token:
            raise ValueError("archive literal policy record contradicts calibrated attribution")
    producer_bytes = {name: analysis.read_local(ROOT / name, ROOT) for name in PRODUCERS}
    context = dict(run=target,
        inputs={name: dict(bytes=len(raw), sha256=associations.digest(raw)) for name, raw in raw_inputs.items()},
        sources=sources, calibrations=admitted,
        producers={name: dict(bytes=len(raw), sha256=associations.digest(raw))
                   for name, raw in producer_bytes.items()},
        scope="daemon_context",
        original=dict(returncode=original.get("returncode"), timeout=original.get("timeout"),
            released=diagnostics.boolean_or_unknown(original.get("released")),
            leader_reaped=diagnostics.boolean_or_unknown(original.get("leader_reaped"))),
        collector=dict(returncode=collector.get("returncode"), reported_failure=bool(collector["failures"]),
            leader_reaped=diagnostics.boolean_or_unknown(collector.get("leader_reaped")),
            forced_kill=diagnostics.boolean_or_unknown(collector.get("forced_kill"))))
    validate_context(context)
    binding = associations.digest(associations.canonical(context))
    descriptors, page_bytes = _pack_pages(entries, binding, target)
    log_count = len(records)
    index = dict(schema=SCHEMA, context=context, context_sha256=binding, pages=descriptors,
        record_count=len(entries), log_event_count=log_count,
        metadata_count=len(entries) - log_count, limits=dict(LIMITS))
    validate_index(index)
    if associations.calibration_snapshot(calibrations, root, path_hash) != admitted:
        raise ValueError("calibration changed during archive building")
    current, current_inputs = analysis._load_capture_inputs(target, root, daemon_capture=True)
    current_inputs["test-result.json"] = analysis.read_local(root / target / "test-result.json", root)
    if current != captured or current_inputs != raw_inputs:
        raise ValueError("private capture changed during archive building")
    for name, previous in producer_bytes.items():
        if analysis.read_local(ROOT / name, ROOT) != previous:
            raise ValueError("producer changed during archive building")
    return {"index": index, "page_bytes": page_bytes}


def publish(target, calibrations, admitted, root=ROOT, path_hash=None):
    """Publish complete pages exclusively, verify them, then retain the index.

    Any existing fixed archive destination rejects the operation. A later
    failure retains earlier complete files; callers must consume the separately
    pinned index and preserve original/collector failure truth.
    """
    root = root.resolve()
    associations.bounded_list(admitted, analysis.MAX_CALIBRATIONS, 1)
    for calibration in admitted:
        associations.calibration_identity(calibration)
    admission = associations.canonical(admitted)
    built = build(target, calibrations, root, path_hash)
    index, page_bytes = built["index"], built["page_bytes"]
    validate_index(index)
    if index["context"]["run"] != target:
        raise ValueError("archive builder returned a foreign run")
    if associations.canonical(index["context"]["calibrations"]) != admission:
        raise ValueError("calibration changed after prospective admission")
    associations.bounded_list(page_bytes, MAX_PAGES, 1)
    if len(page_bytes) != len(index["pages"]):
        raise ValueError("archive builder returned an incomplete page set")
    for raw, descriptor in zip(page_bytes, index["pages"]):
        read_page(raw, descriptor, index["context_sha256"])
    raw_index = associations.canonical(index)
    anchor = associations.digest(raw_index)
    index_path = target + "/" + INDEX_FILE
    # An unreferenced page from an earlier attempt is still existing evidence.
    destinations = [index_path] + [page_path(target, n) for n in range(1, MAX_PAGES + 1)]
    parent = associations._publication_parent(root, index_path)
    try:
        for relative in destinations:
            try:
                os.stat(Path(relative).name, dir_fd=parent, follow_symlinks=False)
            except FileNotFoundError:
                continue
            raise FileExistsError("archive publication destination already exists")
        for raw, descriptor in zip(page_bytes, index["pages"]):
            associations._check_publication_parent(root, index_path, parent)
            if associations.publish_bytes(raw, descriptor["path"], root) != descriptor["sha256"]:
                raise ValueError("published archive page digest disagrees with prepared bytes")
        consume(raw_index, anchor, root)
        associations._check_publication_parent(root, index_path, parent)
        if associations.publish_bytes(raw_index, index_path, root) != anchor:
            raise ValueError("published archive index digest disagrees with prepared bytes")
        retained = analysis.read_local(root / index_path, root, MAX_INDEX_BYTES)
        consumed = consume(retained, anchor, root)
        associations._check_publication_parent(root, index_path, parent)
        return {"index": consumed["index"], "sha256": anchor}
    finally:
        os.close(parent)
