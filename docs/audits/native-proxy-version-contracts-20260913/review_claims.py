"""Verify claim identity while proving the exact book-insertion line shift."""

import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
REVISION = "8dbea4b6a76de2417a9a66e535b574572212c481"
BOOK = "docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md"
INVENTORY = "doctrine/claim_verification/inventory.jsonl"


def original(path):
    return subprocess.check_output(["git", "show", REVISION + ":" + path], cwd=ROOT)


def main():
    old_book = original(BOOK).splitlines()
    new_book = (ROOT / BOOK).read_bytes().splitlines()
    insertion = next(index for index, pair in enumerate(zip(old_book, new_book)) if pair[0] != pair[1])
    delta = len(new_book) - len(old_book)
    assert delta > 0 and old_book[insertion:] == new_book[insertion + delta:]
    old = [json.loads(line) for line in original(INVENTORY).splitlines()]
    new = [json.loads(line) for line in (ROOT / INVENTORY).read_bytes().splitlines()]
    assert len(old) == len(new)
    shifted = []
    changed_constants = []
    book_paths = subprocess.check_output(["git", "ls-files", "docs/book/src/*.md"], cwd=ROOT).decode().splitlines()
    old_bodies = [original(path) for path in book_paths]
    new_bodies = [(ROOT / path).read_bytes() for path in book_paths]
    expected_constants = {
        "/reference_contract/aggregate_change/baseline/bytes_total": sum(map(len, old_bodies)),
        "/reference_contract/aggregate_change/baseline/lines_total": sum(body.count(b"\n") for body in old_bodies),
        "/reference_contract/aggregate_change/delta/bytes_total": sum(map(len, new_bodies)) - sum(map(len, old_bodies)),
        "/reference_contract/aggregate_change/delta/lines_total": sum(body.count(b"\n") for body in new_bodies) - sum(body.count(b"\n") for body in old_bodies),
    }
    for before, after in zip(old, new):
        if before["record_type"] == "census":
            continue
        if before == after:
            continue
        if before["record_type"] == "repository_constant":
            assert before["path"] == after["path"] == "doctrine/live_document_size/surfaces.jsonl"
            assert {key: value for key, value in before.items() if key != "value"} == {
                key: value for key, value in after.items() if key != "value"}
            assert after["value"] == str(expected_constants[after["source_pointer"]])
            changed_constants.append(dict(pointer=after["source_pointer"], old=before["value"], new=after["value"]))
            continue
        assert before["record_type"] == after["record_type"] == "published_candidate"
        assert before["path"] == after["path"] == BOOK
        assert {key: value for key, value in before.items() if key != "line"} == {
            key: value for key, value in after.items() if key != "line"}
        assert before["line"] > insertion and after["line"] == before["line"] + delta
        assert old_book[before["line"] - 1] == new_book[after["line"] - 1]
        shifted.append(dict(candidate_id=before["candidate_id"], old_line=before["line"], new_line=after["line"]))
    assert {row["pointer"] for row in changed_constants} == set(expected_constants)
    disposition = "doctrine/claim_verification/dispositions.jsonl"
    raw = (ROOT / disposition).read_bytes()
    assert raw == original(disposition)
    outputs = []
    log = ROOT / ".artifacts/logs" / HERE.name
    for stage in ["claims-write", "claims-check"]:
        assert (log / (stage + ".exit")).read_bytes() == b"0\n"
        for extension in ["stdout", "stderr", "exit"]:
            path = log / (stage + "." + extension)
            body = path.read_bytes()
            outputs.append(dict(path=str(path.relative_to(ROOT)), sha256=hashlib.sha256(body).hexdigest(),
                                size_bytes=len(body), raw_hex=body.hex()))
    review = dict(source_revision=REVISION, dispositions_unchanged=True,
                  dispositions_sha256=hashlib.sha256(raw).hexdigest(),
                  candidate_identities_and_semantics_unchanged=True, other_constants_unchanged=True,
                  rederived_book_constants=changed_constants,
                  exact_book_insertion=dict(before_line=insertion + 1, added_lines=delta),
                  shifted_candidates=shifted, raw_outputs=outputs,
                  first_author_review_failure=dict(
                      failed_expression="non-census inventory rows are byte-identical",
                      exit_code=1, diagnostic="AssertionError at inline author line 13",
                      followup_stage_exit=128,
                      followup_stage_diagnostic="fatal: pathspec 'docs/audits/native-proxy-version-contracts-20260913/claim-review.json' did not match any files",
                      cause="Book insertion shifts later candidate coordinates and updates derived aggregate book values; candidate identities and all other constant values remain unchanged.",
                      correction="Prove every changed coordinate against the actual book insertion and independently rederive the changed book aggregate values; compare all other fields exactly.",
                      intermediate_review=dict(source="claim-review-first.py", exit_code=1,
                          diagnostic="AssertionError at review_claims.py line 34",
                          cause="The first source-bound review handles coordinate shifts but still assumes derived aggregate book constants are unchanged."),
                      qualification_impact="None; original source/format qualification and required inventory checks already passed and were not rerun."))
    with (HERE / "claim-review.json").open("x") as stream:
        stream.write(json.dumps(review, sort_keys=True, indent=2) + "\n")
    print(json.dumps(dict(claim_identities_unchanged=True, exact_shifted_candidates=len(shifted))))


if __name__ == "__main__":
    main()
