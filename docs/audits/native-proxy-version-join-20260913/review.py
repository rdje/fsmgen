"""Verify durable input membership, raw outputs, data results and book checks."""
import argparse
import json
import subprocess

import prepare
import qualify

HERE, ROOT = prepare.HERE, prepare.ROOT
LOG = ROOT / ".artifacts/logs" / HERE.name
STAGES = ("prepare", "bridge", "qualify", "audit", "saved", "book", "book-inspect", "knowledge-generate", "knowledge-check")


def verify():
    plan = prepare.authenticate()
    pins = qualify.check_pins()
    expected = set()
    for index, unit in enumerate(prepare.UNITS):
        directory = "docs/audits/" + unit
        names = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", plan["source_revision"], "--", directory], cwd=ROOT)
        expected.update(names.decode().splitlines())
        meta = prepare.read(index, "contracts.json" if index == 0 else "plan.json")
        expected.update(row["path"] for row in meta["inputs"])
    assert [row["path"] for row in plan["inputs"]] == sorted(expected)
    captures = json.loads((HERE / "verification-outputs.json").read_bytes())
    assert len(captures) == len(STAGES) * 3
    assert [row["path"] for row in captures] == [str((LOG / (stage + "." + extension)).relative_to(ROOT))
        for stage in STAGES for extension in ("stdout", "stderr", "exit")]
    raw = {}
    for row in captures:
        value = bytes.fromhex(row["raw_hex"])
        assert value.hex() == row["raw_hex"] and len(value) == row["size_bytes"] and prepare.digest(value) == row["sha256"]
        raw[row["path"].rsplit("/", 1)[-1]] = value
    for stage in STAGES:
        assert raw[stage + ".exit"] == b"0\n"
    assert b"All tests successful." in raw["bridge.stdout"] and b"Tests=31," in raw["bridge.stdout"]
    # Raw streams are hex-encoded losslessly, including TAP's trailing spaces.
    audit = json.loads((HERE / "result/audit.json").read_bytes())
    assert json.loads(raw["audit.stdout"]) == json.loads(raw["saved.stdout"]) == audit
    result = json.loads((HERE / "result/qualification.json").read_bytes())
    assert [json.loads(line) for line in (HERE / "result/qualification.jsonl").read_bytes().splitlines()] == result["rows"]
    assert audit["join_cases"] == len(result["rows"]) and audit["joined"] == sum(row["accepted"] for row in result["rows"])
    assert b"knowledge-map: OK" in raw["knowledge-check.stdout"] + raw["knowledge-check.stderr"]
    book = json.loads((HERE / "book-review.json").read_bytes())
    assert book["exit_code"] == 0 and book["exact_output_absent"]
    assert not (ROOT / book["output"]).exists() and not (ROOT / book["output"]).is_symlink()
    card = "docs/knowledge/test-subprocess-policy-adapters.md"
    original = subprocess.check_output(["git", "show", plan["source_revision"] + ":" + card], cwd=ROOT).decode()
    questions = lambda value: [line for line in value.splitlines() if line.startswith('  - "')]
    assert questions(original) == questions((ROOT / card).read_text())
    authoring = json.loads((HERE / "authoring-review.json").read_bytes())
    assert authoring["first_error"] == "KeyError: 'surface_id'" and authoring["owner"] == plan["owner"]
    failure = json.loads((HERE / "first-retention-review/failure.json").read_bytes())
    original_source = (ROOT / failure["source"]["path"]).read_bytes()
    assert len(original_source) == failure["source"]["size_bytes"] and prepare.digest(original_source) == failure["source"]["sha256"]
    assert b'assert b"knowledge-map: OK" in raw["knowledge-check.stdout"]' in original_source
    assert b"knowledge-map: OK" not in raw["knowledge-check.stdout"]
    assert b"knowledge-map: OK" in raw["knowledge-check.stderr"]
    for row in failure["outputs"]:
        body = bytes.fromhex(row["raw_hex"])
        assert len(body) == row["size_bytes"] and prepare.digest(body) == row["sha256"]
    assert bytes.fromhex(failure["outputs"][-1]["raw_hex"]) == b"1\n"
    return dict(schema="fsmgen.inactive_version_join_review.v1", owner=plan["owner"], source_revision=plan["source_revision"],
        source_inputs=len(plan["inputs"]), source_bytes=sum(row["size_bytes"] for row in plan["inputs"]),
        prospective_pins=len(pins), raw_captures=len(captures), bridge_cases=audit["bridge_cases"],
        bridge_accepted=audit["bridge_accepted"], join_cases=audit["join_cases"], joined=audit["joined"],
        stages=audit["stages"], saved_result_falsifiers=audit["saved_result_falsifiers"],
        declared_absent=len(plan["declared_absent"]), claim_legs=plan["claim_legs"], limits=plan["limits"],
        outcome="First new preparation, Perl bridge, matched qualification, independent audit, saved verification and book checks pass. Historical stage failures remain original. A documentation-authoring registry-row lookup stopped before its surface write and was corrected without changing ceilings. The first retention checker inspected the wrong success-output stream; exact stderr proves the earlier check succeeded, and the corrected seal preserves both streams without replay.",
        next_action="Close combined observation, runtime retirement, archive and maintenance lifetimes under .12.4.1.3.6.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--retain", action="store_true")
    parser.add_argument("--seal", action="store_true", help="seal previously retained outputs after a reviewed correction")
    options = parser.parse_args()
    assert not (options.retain and options.seal)
    if options.retain:
        captures = []
        for stage in STAGES:
            for extension in ("stdout", "stderr", "exit"):
                path = LOG / (stage + "." + extension)
                raw = path.read_bytes()
                captures.append(dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=prepare.digest(raw), raw_hex=raw.hex()))
        with (HERE / "verification-outputs.json").open("x") as stream:
            json.dump(captures, stream, sort_keys=True, indent=2); stream.write("\n")
    result = verify()
    if options.retain or options.seal:
        with (HERE / "review.json").open("x") as stream:
            json.dump(result, stream, sort_keys=True, indent=2); stream.write("\n")
    else:
        assert result == json.loads((HERE / "review.json").read_bytes())
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
