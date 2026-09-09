"""Publish a calibrated daemon manifest/report pair after capture settlement.

A separately pinned receipt binds only artifact consistency. It neither
authenticates evidence nor qualifies the original invocation or its observer.
"""

from pathlib import Path

import fixture_policy_diagnostics as diagnostics


associations = diagnostics.associations
analysis = associations.analysis
ROOT = Path(__file__).resolve().parents[1]
SCHEMA = "fsmgen.fixture_policy_publication.v1"
FILES = {"manifest": "policy-associations.json", "diagnostic": "policy-diagnostic.json"}
RECEIPT = "policy-publication.json"
LIMITS = {
    "authority": "separately_pinned_receipt_not_authentication",
    "original_qualification": "not_claimed",
    "observer_qualification": "not_claimed",
    "source_bodies": "not_rehashed_or_included_by_receipt_consumer",
    "private_inputs": "not_reloaded_by_receipt_consumer",
    "complete_coverage": "unproved",
}


def validate_receipt(receipt):
    associations.fields(receipt, ("schema", "run", "admission_sha256", "artifacts", "limits"))
    if receipt["schema"] != SCHEMA or receipt["limits"] != LIMITS:
        raise ValueError("publication receipt schema or limits disagree")
    associations.path_value(receipt["run"], ".artifacts/logs/")
    associations.hex_value(receipt["admission_sha256"], 64)
    associations.fields(receipt["artifacts"], FILES)
    for key, filename in FILES.items():
        artifact = receipt["artifacts"][key]
        associations.fields(artifact, ("path", "bytes", "sha256"))
        associations.path_value(artifact["path"], ".artifacts/logs/")
        if artifact["path"] != receipt["run"] + "/" + filename:
            raise ValueError("publication artifact path is outside its fixed capture")
        associations.integer(artifact["bytes"], associations.MAX_MANIFEST_BYTES)
        associations.hex_value(artifact["sha256"], 64)
    if len(associations.canonical(receipt)) > associations.MAX_MANIFEST_BYTES:
        raise ValueError("publication receipt exceeds its fixed byte bound")


def read_receipt(raw, expected_sha256):
    if type(raw) is not bytes or len(raw) > associations.MAX_MANIFEST_BYTES:
        raise ValueError("publication receipt exceeds its fixed byte bound")
    associations.hex_value(expected_sha256, 64)
    if associations.digest(raw) != expected_sha256:
        raise ValueError("publication receipt disagrees with its separately retained digest")
    receipt = analysis.decode_json(raw)
    validate_receipt(receipt)
    if associations.canonical(receipt) != raw:
        raise ValueError("publication receipt encoding is not canonical")
    return receipt


def consume(raw, expected_sha256, root=ROOT):
    """Verify a pinned receipt and its public files without private/native input."""
    receipt = read_receipt(raw, expected_sha256)
    root = root.resolve()
    contents = {}
    for key, artifact in receipt["artifacts"].items():
        data = analysis.read_local(root / artifact["path"], root, associations.MAX_MANIFEST_BYTES)
        if len(data) != artifact["bytes"] or associations.digest(data) != artifact["sha256"]:
            raise ValueError("publication artifact disagrees with its pinned identity")
        contents[key] = data
    manifest = associations.read_manifest(contents["manifest"], receipt["artifacts"]["manifest"]["sha256"])
    report = diagnostics.read_report(contents["diagnostic"], receipt["artifacts"]["diagnostic"]["sha256"])
    projected = [{key: row[key] for key in ("sha256", "tokens", "phase")} for row in report["records"]]
    if (manifest["target"]["run"] != receipt["run"] or report["scope"] != "daemon_context"
            or associations.digest(associations.canonical(manifest["calibrations"])) != receipt["admission_sha256"]
            or report["manifest_sha256"] != receipt["artifacts"]["manifest"]["sha256"]
            or report["inputs"] != manifest["target"]["inputs"]
            or report["sources"] != manifest["target"]["sources"]
            or projected != manifest["target"]["records"]):
        raise ValueError("publication artifacts disagree with their calibrated linkage")
    return {"receipt": receipt, "manifest": manifest, "diagnostic": report}


def publish(target, calibrations, admitted, root=ROOT, path_hash=None):
    """Publish only after unchanged calibration and complete projection verify.

    Earlier complete artifacts remain if a later publication fails; no receipt
    is attempted before both artifacts pass consumption. Existing files are
    never overwritten. The caller still owns original/observer failure truth.
    """
    root = root.resolve()
    associations.path_value(target, ".artifacts/logs/")
    associations.bounded_list(admitted, analysis.MAX_CALIBRATIONS, 1)
    for entry in admitted:
        associations.calibration_identity(entry)
    admission = associations.canonical(admitted)
    manifest = associations.seal_daemon_capture(target, calibrations, root, path_hash)
    if associations.canonical(manifest["calibrations"]) != admission:
        raise ValueError("calibration changed after prospective admission")
    manifest_raw = associations.canonical(manifest)
    manifest_sha256 = associations.digest(manifest_raw)
    report = diagnostics.export(manifest_raw, manifest_sha256, target, root)
    contents = {"manifest": manifest_raw, "diagnostic": associations.canonical(report)}
    artifacts = {key: dict(path=target + "/" + FILES[key], bytes=len(data), sha256=associations.digest(data))
                 for key, data in contents.items()}
    receipt = dict(schema=SCHEMA, run=target, admission_sha256=associations.digest(admission),
                   artifacts=artifacts, limits=dict(LIMITS))
    validate_receipt(receipt)
    destinations = [value["path"] for value in artifacts.values()] + [target + "/" + RECEIPT]
    for relative in destinations:
        try:
            (root / relative).lstat()
        except FileNotFoundError:
            continue
        raise FileExistsError("publication destination already exists")
    for key, data in contents.items():
        artifact = artifacts[key]
        if associations.publish_bytes(data, artifact["path"], root) != artifact["sha256"]:
            raise ValueError("published artifact digest disagrees with its prepared bytes")
    raw = associations.canonical(receipt)
    anchor = associations.digest(raw)
    consume(raw, anchor, root)
    if associations.publish_bytes(raw, target + "/" + RECEIPT, root) != anchor:
        raise ValueError("published receipt digest disagrees with its prepared bytes")
    if analysis.read_local(root / target / RECEIPT, root, associations.MAX_MANIFEST_BYTES) != raw:
        raise ValueError("publication receipt changed after publication")
    return {"receipt": receipt, "sha256": anchor}
