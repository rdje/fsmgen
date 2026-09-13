"""New inert retained-format examples; no capture, archive or publication runs."""
import copy
import hashlib
import importlib
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CAPTURE = ROOT / "docs/audits/native-proxy-capture-dispatch-20260913"


def canonical(value):
    return (json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n").encode("ascii")


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def libraries():
    before = list(sys.path)
    try:
        sys.path.insert(0, str(ROOT / "scripts"))
        return {kind: importlib.import_module("fixture_policy_" + kind)
                for kind in ("associations", "diagnostics", "publication", "archive")}
    finally:
        sys.path[:] = before


def legacy_examples():
    modules = libraries()
    association, diagnostic, publication, archive = [modules[key] for key in ("associations", "diagnostics", "publication", "archive")]
    empty = dict(bytes=0, sha256=digest(b""))
    inputs = {name: dict(empty) for name in association.INPUT_NAMES}
    run = ".artifacts/logs/inert-retained-legacy"
    source = dict(path=".artifacts/tmp/process-supervisor-tests/fsmgen-LegacyRetained/rust-tools/rustup",
                  size_bytes=1, sha256=digest(b"x"), token="0000000000000001")
    pairs = [dict(source, path=f".artifacts/tmp/process-supervisor-tests/fsmgen-CalibrationRetained/{name}", token=token)
             for name, token in [("first", "0000000000000002"), ("second", "0000000000000003")]]
    calibration = dict(run=".artifacts/logs/inert-retained-calibration", inputs=inputs, pairs=pairs)
    identity = lambda path: dict(bytes=len((ROOT / path).read_bytes()), sha256=digest((ROOT / path).read_bytes()))
    manifest = dict(schema=association.SCHEMA, algorithm=association.ALGORITHM,
        producers={path: identity(path) for path in association.PRODUCERS},
        target=dict(run=run, inputs=inputs, sources=[source], records=[]), calibrations=[calibration], limits=association.LIMITS)
    manifest_raw = canonical(manifest)
    original = dict(returncode=0, timeout=False, released=None, leader_reaped=None)
    collector = dict(returncode=None, reported_failure=False, leader_reaped=None, forced_kill=None)
    report = dict(schema=diagnostic.SCHEMA, qualification="not_claimed", manifest_sha256=digest(manifest_raw),
        producer_sha256=digest((ROOT / "scripts/fixture_policy_diagnostics.py").read_bytes()), inputs=inputs,
        scope="daemon_context", sources=[source], records=[], metadata_records_omitted=0,
        original=original, collector=collector, omissions=diagnostic.OMISSIONS, limits=diagnostic.LIMITS)
    report_raw = canonical(report)
    receipt = dict(schema=publication.SCHEMA, run=run, admission_sha256=digest(canonical([calibration])),
        artifacts={kind: dict(path=run + "/" + filename, bytes=len(raw), sha256=digest(raw))
                   for kind, filename, raw in [("manifest", "policy-associations.json", manifest_raw),
                                               ("diagnostic", "policy-diagnostic.json", report_raw)]}, limits=publication.LIMITS)
    context = dict(run=run, inputs=inputs, sources=[source], calibrations=[calibration],
        producers={path: identity(path) for path in archive.PRODUCERS}, scope="daemon_context", original=original, collector=collector)
    context_sha = digest(canonical(context))
    page = dict(schema=archive.PAGE_SCHEMA, context_sha256=context_sha, first_record=0,
                records=[dict(kind="metadata", sha256=digest(b"inert metadata"))])
    page_raw = canonical(page)
    descriptor = dict(path=run + "/policy-archive-0001.json", bytes=len(page_raw), sha256=digest(page_raw),
                      first_record=0, record_count=1, log_event_count=0, metadata_count=1)
    index = dict(schema=archive.SCHEMA, context=context, context_sha256=context_sha, pages=[descriptor],
                 record_count=1, log_event_count=0, metadata_count=1, limits=archive.LIMITS)
    result = []
    for kind, value in [("associations", manifest), ("diagnostics", report), ("publication", receipt), ("archive", index), ("archive_page", page)]:
        raw = canonical(value)
        result.append(dict(kind=kind, raw_hex=raw.hex(), sha256=digest(raw), descriptor=descriptor if kind == "archive_page" else None,
                           context_sha256=context_sha if kind == "archive_page" else None, provenance="new inert structural example; no policy calibration or published files"))
    raw = (ROOT / "docs/audits/native-proxy-daemon-original-20260910/policy-result.json").read_bytes()
    result.append(dict(kind="collector", raw_hex=raw.hex(), sha256=digest(raw), descriptor=None, context_sha256=None,
                       provenance="byte-exact original daemon collector record; original outcome is unchanged"))
    return result


def build():
    plan = json.loads((HERE / "plan.json").read_bytes())
    prior = json.loads((CAPTURE / "vectors.json").read_bytes())
    checked = json.loads((CAPTURE / "result/qualification.json").read_bytes())
    commands = {row["scope"]: row["command"] for row in checked["collections"]
                if row["root"] == "ordinary" and row["schema"] == "fsmgen.fixture_policy_log.v2"}
    records = {base + "_" + scope: dict(schema=plan["new_schema"], normal_uid=501, capture=copy.deepcopy(prior["bases"][base]),
        collector_contract=dict(schema="fsmgen.fixture_policy_log.v2", scope=scope, command=command), limits=copy.deepcopy(plan["limits"]))
        for base in ("shared_0", "shared_1", "shared_other_observer") for scope, command in commands.items()}
    vectors = [dict(name=name, base=name, operations=[], accept=True) for name in records]
    default = "shared_0_execution_context"
    def change(name, path, value=None, *, delete=False):
        vectors.append(dict(name=name, base=default, operations=[dict(path=path, value=value, delete=delete)], accept=False))
    for field in records[default]:
        change("missing_" + field, [field], delete=True)
    for field in plan["limits"]:
        change("promote_" + field, ["limits", field], "qualified")
    change("unknown_outer_field", ["policy_records"], [])
    change("legacy_outer_version", ["schema"], "fsmgen.inactive_retained_proxy_capture.v1")
    change("legacy_collector_version", ["collector_contract", "schema"], "fsmgen.fixture_policy_log.v1")
    change("foreign_scope", ["collector_contract", "scope"], "free_form")
    change("foreign_collector_field", ["collector_contract", "predicate"], "true")
    change("unversioned_collector", ["collector_contract", "schema"], delete=True)
    old = next(row["command"] for row in checked["collections"] if row["root"] == "ordinary" and row["scope"] == "execution_context" and row["schema"].endswith(".v1"))
    change("mixed_legacy_command", ["collector_contract", "command"], old)
    bad = copy.deepcopy(commands["execution_context"]); bad[-1] = bad[-1].replace('/rust-proxy-images/v1/', '/rust-proxy-images/')
    change("broadened_canonical_prefix", ["collector_contract", "command"], bad)
    for base in ("perl", "private_0"):
        change("wrong_capture_family_" + base, ["capture"], prior["bases"][base])
    for number in range(5):
        change("missing_source_" + str(number), ["capture", "before", "sources", number], delete=True)
    change("missing_hold", ["capture", "before", "observation"], None)
    change("invented_native_entry", ["capture", "before", "main_entry"], "entered")
    change("stale_birth", ["capture", "after", "processes", 0, "identity", "start_usec"], 790)
    change("normal_uid_bool", ["normal_uid"], True)
    change("root_uid", ["normal_uid"], 0)
    change("reference_byte_drift", ["capture", "after", "sources", 1, "bytes_hex"], "00")
    return dict(schema="fsmgen.inactive_retained_vectors.v1", records=records, vectors=vectors, legacy=legacy_examples(),
        scope="New inert format examples plus an unchanged original collector record; no archive, fixture, publication or native producer is replayed.")


def apply(vector, records):
    record = copy.deepcopy(records[vector["base"]])
    for operation in vector["operations"]:
        value = record
        for key in operation["path"][:-1]:value = value[key]
        if operation["delete"]:del value[operation["path"][-1]]
        else:value[operation["path"][-1]] = copy.deepcopy(operation["value"])
    return record


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
        json.dump(value, stream, sort_keys=True, indent=2); stream.write("\n")
    print(json.dumps(dict(vectors=len(value["vectors"]), accepted=sum(row["accept"] for row in value["vectors"]), frozen_families=len(value["legacy"]))))
