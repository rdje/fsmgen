"""Verify durable capture receipts and the completed book-path recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

import prepare
import qualify

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
LOG = ROOT / ".artifacts/logs" / HERE.name
STAGES = ("prepare", "qualify", "audit", "saved", "book", "book-inspect-corrected", "knowledge-generate")


def pin(path):
    raw = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def verify():
    plan = prepare.authenticate()
    qualify.check_pins()
    outputs = json.loads((HERE / "verification-outputs.json").read_bytes())
    assert len(outputs) == len(STAGES) * 3
    for entry in outputs:
        assert pin(ROOT / entry["path"]) == {key: entry[key] for key in ("path", "size_bytes", "sha256")}
    for stage in STAGES:
        assert (HERE / "result" / (stage + ".exit")).read_bytes() == b"0\n"
    vectors = json.loads((HERE / "vectors.json").read_bytes())
    result = json.loads((HERE / "result/qualification.json").read_bytes())
    streamed = [json.loads(line) for line in (HERE / "result/qualification.jsonl").read_bytes().splitlines()]
    assert streamed == result["rows"]
    audit = json.loads((HERE / "result/audit.json").read_bytes())
    assert json.loads((HERE / "result/saved.stdout").read_bytes()) == audit
    assert audit["target_cases"] == len(vectors["vectors"]) * len(result["roots"])
    assert audit["accepted"] == sum(row["accept"] for row in vectors["vectors"]) * len(result["roots"])
    assert not result["process_attempts"]
    first = json.loads((HERE / "first-book-inspect/review.json").read_bytes())
    for output in first["outputs"]:
        raw = bytes.fromhex(output["hex"])
        assert len(raw) == output["size_bytes"] and hashlib.sha256(raw).hexdigest() == output["sha256"]
    assert next(bytes.fromhex(row["hex"]) for row in first["outputs"] if row["path"].endswith("book-inspect.exit")) == b"1\n"
    copy = json.loads((HERE / "book-copy-review.json").read_bytes())
    cleanup = json.loads((HERE / "book-relocation-cleanup.json").read_bytes())
    book = json.loads((HERE / "book-review.json").read_bytes())
    assert copy["files"] == cleanup["deleted_files"] == book["rendered_files"] == len(first["files"])
    assert copy["bytes"] == cleanup["deleted_bytes"] == book["rendered_bytes"] == sum(row["size_bytes"] for row in first["files"])
    assert copy["all_file_hashes_agree"] and copy["same_volume"] and cleanup["copy_verified"]
    assert cleanup["corrected_inspection_exit"] == 0 and cleanup["misplaced_task_root_absent"] and cleanup["intended_task_root_absent"]
    assert book["exact_output_absent"] and not (ROOT / book["output"]).exists()
    assert not (ROOT / ".artifacts/tmp/inert-capture-roots").exists()
    card = "docs/knowledge/test-subprocess-policy-adapters.md"
    old = subprocess.check_output(["git", "show", plan["source_revision"] + ":" + card], cwd=ROOT).decode()
    questions = lambda text: [line for line in text.splitlines() if line.startswith('  - "')]
    assert questions(old) == questions((ROOT / card).read_text())
    return dict(schema="fsmgen.inactive_capture_review.v1", owner=plan["owner"], source_revision=plan["source_revision"],
        source_inputs=len(plan["inputs"]), prospective_pins=len(qualify.check_pins()), raw_copies=len(outputs),
        target_cases=audit["target_cases"], accepted=audit["accepted"], collector_commands=audit["collector_commands"],
        counterimplementations=audit["counterimplementations"], result_falsifiers=audit["saved_result_falsifiers"],
        outcome="First qualification, independent audit and saved-only verification pass. No native fixture, compiler, original producer, collector or native query runs.",
        book_recovery="First inspection rejected an absent destination because mdBook resolved the output from the invocation root. Exact same-volume copy, complete file hash verification, corrected inspection and exact old/new cleanup pass; first-book-inspect/review.json preserves original failure and file manifest.",
        claim_legs=plan["independent_legs"],
        limits="Supplied observations and synthetic in-memory bytes establish finite contract agreement. Native authentication, real mode/custody, preparation integration, loaded-image attestation, collector delivery, retained formats and historical startup/parent/full CI/push remain separate.",
        next_action="Qualify explicit retained source and policy-format compatibility under .5.4.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--retain", action="store_true")
    options = parser.parse_args()
    if options.retain:
        outputs = []
        for stage in STAGES:
            assert (LOG / (stage + ".exit")).read_bytes() == b"0\n"
            for extension in ("stdout", "stderr", "exit"):
                source = LOG / (stage + "." + extension)
                destination = HERE / "result" / source.name
                with destination.open("xb") as stream:
                    stream.write(source.read_bytes())
                assert source.read_bytes() == destination.read_bytes()
                outputs.append(dict(pin(destination), original=source.relative_to(ROOT).as_posix()))
        with (HERE / "verification-outputs.json").open("x") as stream:
            json.dump(outputs, stream, sort_keys=True, indent=2); stream.write("\n")
    review = verify()
    if options.retain:
        with (HERE / "review.json").open("x") as stream:
            json.dump(review, stream, sort_keys=True, indent=2); stream.write("\n")
    else:
        assert review == json.loads((HERE / "review.json").read_bytes())
    print(json.dumps(review, sort_keys=True))


if __name__ == "__main__":
    main()
