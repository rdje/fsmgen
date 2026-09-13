"""Authenticate saved stage domains and independently verify their matched join."""
import copy
import json
import subprocess
import sys

import loaders
import prepare
import qualify

HERE, ROOT = prepare.HERE, prepare.ROOT


def stage_domains():
    layout = loaders.load("layout", "qualify.py")
    contracts = prepare.read(0, "contracts.json")
    assert contracts == layout.source.derive()
    result = layout.qualification(contracts, prepare.read(0, "plan.json"))
    assert result == prepare.read(0, "result/qualification.json")
    preparation = loaders.load("preparation", "audit_corrected.py")
    vectors = prepare.read(1, "vectors.json")
    assert vectors == preparation.prepare.build()
    old_runtime = preparation.pure_runtime_oracle()
    preparation.check_result(prepare.read(1, "result/qualification.json"), vectors, old_runtime)
    # The first all-green TAP output still fails its unchanged independent oracle.
    first = prepare.read(1, "first-failure/result-qualification.json")
    try:
        preparation.check_result(first, vectors, old_runtime)
    except AssertionError:
        assert first["original_v1_raw"] != vectors["original_v1_raw"]
        assert json.loads(first["original_v1_raw"]) == json.loads(vectors["original_v1_raw"])
    else:
        raise AssertionError("first noncanonical saved result was promoted")
    capture = loaders.load("capture", "audit.py")
    capture_vectors = prepare.read(2, "vectors.json")
    assert capture_vectors == capture.prepare.build()
    capture_counts = capture.check_result(prepare.read(2, "result/qualification.json"), capture_vectors)
    retained = loaders.load("retained", "audit.py")
    retained_vectors = prepare.read(3, "vectors.json")
    assert retained_vectors == retained.prepare.build()
    retained_counts = retained.verify(prepare.read(3, "result/qualification.json"), retained_vectors, prepare.read(3, "plan.json"))
    return dict(layout_cases=len(result["rows"]), preparation_cases=len(vectors["vectors"]),
                preparation_accepted=sum(row["accept"] for row in vectors["vectors"]),
                first_preparation_result_still_rejected=True, capture=capture_counts, retained=retained_counts)


def bridge_result(result, vectors):
    assert set(result) == {"schema", "rows", "forbidden_process_attempts"}
    assert result["schema"] == "fsmgen.inactive_version_bridge_result.v1"
    assert type(result["forbidden_process_attempts"]) is int and result["forbidden_process_attempts"] == 0
    assert [row["name"] for row in result["rows"]] == [row["name"] for row in vectors["vectors"]]
    oracle = loaders.load("preparation", "audit_corrected.py")
    runtime = oracle.pure_runtime_oracle()
    prior = prepare.read(1, "vectors.json")
    for base in vectors["bases"].values():
        assert base["compilation"] == prior["base"]["compilation"]
        argv = list(prior["base"]["compilation_argv"])
        argv[-3], argv[-1] = [row["path"] for row in base["compilation_sources"]]
        assert base["compilation_argv"] == argv
    for row, vector in zip(result["rows"], vectors["vectors"]):
        assert set(row) == {"name", "accepted", "encoded", "error"}
        assert type(row["accepted"]) is int and row["accepted"] == int(vector["accept"])
        context = dict(base=vectors["bases"][vector["base"]], compiler_fields=vectors["compiler_fields"])
        if vector["accept"]:
            assert row["encoded"] == vector["raw"] and row["error"] == ""
            oracle.validate(row["encoded"], context, runtime)
        else:
            assert row["encoded"] is None and row["error"]
            oracle.rejected(vector["raw"], context, runtime)


def joined_result(result, vectors):
    assert set(result) == {"schema", "roots", "rows", "process_attempts"}
    assert result["schema"] == "fsmgen.inactive_version_join_qualification.v1" and result["process_attempts"] == []
    assert result["roots"] == list(qualify.ROOTS)
    old = loaders.load("retained", "audit.py")
    inspect = old.capture_oracle()
    plan = prepare.read(3, "plan.json")
    commands = {row["scope"]: row["command"] for row in prepare.read(2, "result/qualification.json")["collections"]
                if row["root"] == "ordinary" and row["schema"] == "fsmgen.fixture_policy_log.v2"}
    envelopes = prepare.read(3, "vectors.json")["records"]
    # Independent Cartesian domain: do not import the qualifier's candidate builder.
    expected = {(root, name, variant) for root in qualify.ROOTS for name in envelopes
                for variant in ("matched", "different_reference_identity", "other_mode", "failed_preparation", "other_envelope")}
    rows = {(row["root"], row["name"], row["variant"]): row for row in result["rows"]}
    assert len(rows) == len(result["rows"]) == len(expected) and set(rows) == expected
    for (suffix, name, variant), row in rows.items():
        assert row["accepted"] is (variant == "matched")
        record = envelopes[name]
        base = "shared_1" if name.startswith("shared_1_") else "shared_0"
        preparation = vectors["bases"][base]
        root = ROOT / ".artifacts/tmp/inert-version-join-roots" / suffix
        capture = record["capture"]
        target = inspect(old.expand(capture, root), root)
        bodies = capture["before"]["sources"]
        assert preparation["sources"] == [row["identity"] for row in bodies[3:]]
        assert preparation["executable"] == target["evidence"]["fixture"]
        reference = preparation["image_reference"]
        assert reference["record"]["workspace_identity"] == capture["workspace_identity"]
        assert reference["record"]["workspace"] == capture["workspace"]
        for index, field in ((1, "private"), (2, "global")):
            assert reference[field] == bodies[index]["identity"]
            assert prepare.canonical(reference["record"]).encode("ascii") == bytes.fromhex(bodies[index]["bytes_hex"])
        for private, selected in zip(preparation["compilation_sources"], bodies[3:]):
            body = bytes.fromhex(selected["bytes_hex"])
            assert private["size_bytes"] == len(body) and private["sha256"] == prepare.digest(body)
        raw = old.envelope(record, root, plan, commands, inspect)
        assert raw == (ROOT / "docs/audits" / prepare.UNITS[3] / "result/envelopes" / (name + ".json")).read_bytes()
        if variant == "matched":
            assert row == dict(root=suffix, name=name, variant=variant, accepted=True,
                result=dict(target=target, envelope_bytes=len(raw), envelope_sha256=prepare.digest(raw),
                            preparation_sha256=prepare.digest(prepare.canonical(preparation).encode("ascii"))))
        else:
            assert set(row) == {"root", "name", "variant", "accepted", "error"} and row["error"]
            other = "shared_0" if base == "shared_1" else "shared_1"
            if variant == "different_reference_identity":
                changed = next(v for v in vectors["vectors"] if v["name"] == base + "_different_reference_identity")
                assert json.loads(changed["raw"])["image_reference"]["global"] != bodies[2]["identity"]
            elif variant == "other_mode":
                assert vectors["bases"][other]["sources"] != preparation["sources"]
            elif variant == "failed_preparation":
                failed = next(v for v in vectors["vectors"] if v["name"] == base + "_retained_reference_failure")
                assert json.loads(failed["raw"])["ok"] == 0 and json.loads(failed["raw"])["executable"] is None
            else:
                other_record = envelopes[other + "_" + record["collector_contract"]["scope"]]
                assert prepare.canonical(other_record["capture"]) != prepare.canonical(capture)
    return dict(join_cases=len(rows), joined=sum(row["accepted"] for row in rows.values()))


def evidence(plan):
    epochs = []
    for index, unit in enumerate(prepare.UNITS):
        stage = prepare.read(index, "plan.json")
        sources = prepare.read(index, "contracts.json")["inputs"] if index == 0 else stage["inputs"]
        for row in sources:
            raw = subprocess.check_output(["git", "show", stage["source_revision"] + ":" + row["path"]], cwd=ROOT)
            assert raw == (ROOT / row["path"]).read_bytes()
            assert len(raw) == row["size_bytes"] and prepare.digest(raw) == row["sha256"]
        epochs.append(dict(unit=unit, source_revision=stage["source_revision"], inputs=len(sources)))
        # Corrected preparation pins are distinct from preserved first pins.
        filename = "corrected-preflight-pins.json" if index == 1 else "preflight-pins.json"
        for row in prepare.read(index, filename):
            raw = (ROOT / row["path"]).read_bytes()
            assert len(raw) == row["size_bytes"] and prepare.digest(raw) == row["sha256"]
    original = prepare.read(1, "first-failure/review.json")
    assert original["original_audit_exit"] == 1 and original["original_tap_exit"] == 0
    # The exact historical pin-to-copy mapping is explicit; no global hash search.
    copies = {row["source"]: row for row in original["copies"]}
    for row in prepare.read(1, "preflight-pins.json"):
        actual = (ROOT / row["path"]).read_bytes()
        if prepare.digest(actual) != row["sha256"]:
            saved = copies[row["path"]]
            actual = (ROOT / saved["copy"]).read_bytes()
        assert len(actual) == row["size_bytes"] and prepare.digest(actual) == row["sha256"]
    gate = prepare.read(1, "first-staged-gate/review.json")
    assert "nested" in gate["root_cause"] and "Restore" in gate["correction"]
    cleanup = prepare.read(2, "book-relocation-cleanup.json")
    assert cleanup["copy_verified"] and cleanup["corrected_inspection_exit"] == 0
    assert cleanup["misplaced_task_root_absent"] and cleanup["intended_task_root_absent"]
    for path in plan["declared_absent"]:
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink(), path
    return dict(source_epochs=epochs, declared_absent=list(plan["declared_absent"]),
                first_preparation_failure_preserved=True, first_staged_gate_failure_preserved=True,
                first_book_destination_failure_preserved=True)


def main():
    plan = prepare.authenticate()
    qualify.check_pins()
    stages = stage_domains()
    provenance = evidence(plan)
    vectors = json.loads((HERE / "bridge-vectors.json").read_bytes())
    assert vectors == prepare.build()
    bridge = json.loads((HERE / "result/bridge.json").read_bytes())
    bridge_result(bridge, vectors)
    result = json.loads((HERE / "result/qualification.json").read_bytes())
    counts = joined_result(result, vectors)
    falsifiers = []
    for label, original, checker, change in (
        ("missing_preparation", bridge, bridge_result, lambda v: v["rows"].pop()),
        ("changed_preparation_bytes", bridge, bridge_result, lambda v: v["rows"][0].update(encoded="{}")),
        ("hidden_preparation_launch", bridge, bridge_result, lambda v: v.update(forbidden_process_attempts=1)),
        ("missing_join", result, joined_result, lambda v: v["rows"].pop()),
        ("changed_envelope", result, joined_result, lambda v: v["rows"][0]["result"].update(envelope_sha256="0" * 64)),
        ("accepted_mismatch", result, joined_result, lambda v: v["rows"][1].update(accepted=True)),
        ("hidden_join_launch", result, joined_result, lambda v: v.update(process_attempts=["hidden"]))):
        changed = copy.deepcopy(original); change(changed)
        try:
            checker(changed, vectors)
        except (AssertionError, KeyError, ValueError):
            falsifiers.append(label)
        else:
            raise AssertionError("saved falsifier survived: " + label)
    report = dict(schema="fsmgen.inactive_version_join_audit.v1", source_revision=plan["source_revision"],
        source_inputs=len(plan["inputs"]), stages=stages, provenance=provenance,
        bridge_cases=len(bridge["rows"]), bridge_accepted=sum(row["accepted"] for row in bridge["rows"]),
        **counts, saved_result_falsifiers=falsifiers, limits=plan["limits"])
    if "--verify-saved" in sys.argv:
        assert report == json.loads((HERE / "result/audit.json").read_bytes())
    else:
        with (HERE / "result/audit.json").open("x") as stream:
            json.dump(report, stream, sort_keys=True, indent=2); stream.write("\n")
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
