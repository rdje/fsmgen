"""Verify durable retained-format results, raw captures and documentation checks."""
import argparse
import json
from pathlib import Path
import subprocess

import prepare
import qualify

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
LOG = ROOT / ".artifacts/logs" / HERE.name
STAGES = ("prepare", "qualify", "audit", "saved", "book", "book-inspect", "knowledge-generate", "knowledge-check")


def pin(path):
    raw = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(raw), sha256=prepare.digest(raw))


def verify():
    plan = prepare.authenticate()
    pins = qualify.check_pins()
    copies = json.loads((HERE / "verification-outputs.json").read_bytes())
    assert len(copies) == len(STAGES) * 3
    for record in copies:
        assert pin(ROOT / record["path"]) == {key: record[key] for key in ("path", "size_bytes", "sha256")}
    for stage in STAGES:
        assert (HERE / "result" / (stage + ".exit")).read_bytes() == b"0\n"
    vectors = json.loads((HERE / "vectors.json").read_bytes())
    result = json.loads((HERE / "result/qualification.json").read_bytes())
    audit = json.loads((HERE / "result/audit.json").read_bytes())
    assert json.loads((HERE / "result/saved.stdout").read_bytes()) == audit
    assert [json.loads(line) for line in (HERE / "result/qualification.jsonl").read_bytes().splitlines()] == result["rows"]
    assert audit["envelope_cases"] == len(vectors["vectors"]) * len(result["roots"])
    assert audit["accepted"] == sum(vector["accept"] for vector in vectors["vectors"]) * len(result["roots"])
    assert audit["legacy_checks"] == len(vectors["legacy"]) * len(result["roots"]) * 4
    envelopes = list((HERE / "result/envelopes").glob('*.json'))
    assert {path.stem for path in envelopes} == {vector["name"] for vector in vectors["vectors"] if vector["accept"]}
    for path in envelopes:
        assert path.read_bytes() == prepare.canonical(vectors["records"][path.stem])
    assert not result["process_attempts"] and not (ROOT / ".artifacts/tmp/inert-retained-roots").exists()
    book = json.loads((HERE / "book-review.json").read_bytes())
    assert book["exit_code"] == 0 and book["exact_output_absent"] and not (ROOT / book["output"]).exists()
    card = "docs/knowledge/test-subprocess-policy-adapters.md"
    previous = subprocess.check_output(["git", "show", plan["source_revision"] + ":" + card], cwd=ROOT).decode()
    questions = lambda body: [line for line in body.splitlines() if line.startswith('  - "')]
    assert questions(previous) == questions((ROOT / card).read_text())
    return dict(schema="fsmgen.inactive_retained_review.v1", owner=plan["owner"], source_revision=plan["source_revision"],
        source_inputs=len(plan["inputs"]), prospective_pins=len(pins), raw_copies=len(copies), canonical_envelopes=len(envelopes),
        envelope_cases=audit["envelope_cases"], accepted=audit["accepted"], raw_controls=audit["raw_controls"],
        legacy_checks=audit["legacy_checks"], saved_result_falsifiers=audit["saved_result_falsifiers"],
        outcome="First qualification, independent audit, saved-only verification and documentation checks pass. Frozen legacy bytes and reader semantics remain unchanged.",
        claim_legs=plan["claim_legs"],
        limits="New private envelope syntax and finite frozen-format interpretation only. Supplied process IDs, bodies and digests are not native authentication or current custody. Collector outcomes and policy records are excluded; no public artifact consumption, calibration, original archive replay, publication or native execution is qualified.",
        next_action="Join complete inactive version compatibility and source applicability under .5.5.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--retain", action="store_true")
    options = parser.parse_args()
    if options.retain:
        copies = []
        for stage in STAGES:
            assert (LOG / (stage + ".exit")).read_bytes() == b"0\n"
            for extension in ("stdout", "stderr", "exit"):
                source = LOG / (stage + "." + extension)
                destination = HERE / "result" / source.name
                with destination.open("xb") as stream:
                    stream.write(source.read_bytes())
                assert source.read_bytes() == destination.read_bytes()
                copies.append(dict(pin(destination), original=source.relative_to(ROOT).as_posix()))
        with (HERE / "verification-outputs.json").open("x") as stream:
            json.dump(copies, stream, sort_keys=True, indent=2)
            stream.write("\n")
    review = verify()
    if options.retain:
        with (HERE / "review.json").open("x") as stream:
            json.dump(review, stream, sort_keys=True, indent=2)
            stream.write("\n")
    else:
        assert review == json.loads((HERE / "review.json").read_bytes())
    print(json.dumps(review, sort_keys=True))


if __name__ == "__main__":
    main()
