"""Retain exact outputs and prove the bounded serialization correction."""

import argparse
import hashlib
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
LOG = ROOT / ".artifacts/logs" / HERE.name
STAGES = ["serialization-order", "corrected-admission", "corrected-qualify", "corrected-audit",
          "saved", "book", "book-inspect", "knowledge-generate"]


def captured_bytes(path):
    if path.exists():
        return path.read_bytes()
    encodings = json.loads((HERE / "raw-capture-encodings.json").read_bytes())
    record = encodings[str(path.relative_to(ROOT))]
    assert record["encoding"] == "lowercase_hex_lf"
    encoded = (ROOT / record["encoded_path"]).read_bytes()
    assert len(encoded) == record["encoded_size_bytes"]
    assert hashlib.sha256(encoded).hexdigest() == record["encoded_sha256"]
    body = bytes.fromhex(encoded.decode("ascii"))
    assert encoded == body.hex().encode("ascii") + b"\n"
    assert len(body) == record["raw_size_bytes"]
    assert hashlib.sha256(body).hexdigest() == record["raw_sha256"]
    return body


def pin(path):
    body = captured_bytes(path)
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def tap(path):
    text = captured_bytes(path).decode("utf-8")
    assert not re.search(r"^(?:not ok|Bail out!)", text, re.M)
    plans = re.findall(r"^1\.\.([0-9]+)$", text, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(number) for number in re.findall(r"^ok ([0-9]+) - ", text, re.M)] == list(range(1, total + 1))
    assert "All tests successful." in text and "Result: PASS" in text
    return total


def verify():
    first = HERE / "first-failure"
    receipt = json.loads((first / "review.json").read_bytes())
    for record in receipt["copies"]:
        actual = pin(ROOT / record["copy"])
        assert actual["size_bytes"] == record["size_bytes"] and actual["sha256"] == record["sha256"]
    assert (first / "audit.exit").read_bytes() == b"1\n"
    assert (first / "qualify.exit").read_bytes() == b"0\n"
    for name in ("PreparationRecord.pm", "audit.py", "prepare.py"):
        assert (HERE / name).read_bytes() == (first / (name + ".source")).read_bytes()
    original_harness = (first / "qualify.t.source").read_text()
    expected_harness = original_harness.replace(
        "print {$output} $json->pretty->encode({schema",
        "my $presentation = JSON::PP->new->canonical->ascii->pretty;\nprint {$output} $presentation->encode({schema")
    assert expected_harness != original_harness and expected_harness == (HERE / "qualify.t").read_text()
    assert (HERE / "audit_corrected.py").read_text() == (HERE / "audit.py").read_text().replace(
        '"preflight-pins.json"', '"corrected-preflight-pins.json"')
    vectors = json.loads((HERE / "vectors.json").read_bytes())
    old = json.loads((first / "result-qualification.json").read_bytes())
    new = json.loads((HERE / "result/qualification.json").read_bytes())
    assert old != new and old["original_v1_raw"] != vectors["original_v1_raw"]
    assert json.loads(old["original_v1_raw"]) == json.loads(new["original_v1_raw"])
    old["original_v1_raw"] = vectors["original_v1_raw"]
    assert old == new
    outputs = json.loads((HERE / "verification-outputs.json").read_bytes())
    expected_paths = {str((HERE / "result" / (stage + "." + extension)).relative_to(ROOT))
                      for stage in STAGES for extension in ("stdout", "stderr", "exit")}
    assert {row["path"] for row in outputs} == expected_paths and len(outputs) == len(expected_paths)
    for record in outputs:
        assert pin(ROOT / record["path"]) == {key: record[key] for key in ("path", "size_bytes", "sha256")}
    for stage in STAGES:
        assert (HERE / "result" / (stage + ".exit")).read_bytes() == b"0\n"
    original_tap = tap(first / "qualify.stdout")
    corrected_tap = tap(HERE / "result/corrected-qualify.stdout")
    expected_tap = len(vectors["vectors"]) + sum(row["accept"] for row in vectors["vectors"])
    expected_tap += sum(row["reason"] is not None for row in vectors["vectors"]) + 2 + 4 + 2 + 1
    assert original_tap == corrected_tap == expected_tap
    serialization_tap = tap(HERE / "result/serialization-order.stdout")
    assert serialization_tap == 5
    book = json.loads((HERE / "book-review.json").read_bytes())
    assert book["exact_output_absent"] and not (ROOT / book["output"]).exists()
    return dict(owner=receipt["owner"], schema="fsmgen.inactive_preparation_review.v1",
        source_revision="79101643fd047fd7d9fc9c7e1448f0748fc0fc35",
        outcome="Inactive preparation codec and complete finite corrected qualification pass.",
        original_outcome="Perl assertions passed; the independent audit correctly rejected the noncanonical embedded legacy record.",
        correction="A separate presentation encoder restores only the nested canonical legacy string. All other result fields and case verdicts are unchanged; codec and independent validation rules remain exact.",
        vectors=len(vectors["vectors"]), accepted=sum(row["accept"] for row in vectors["vectors"]),
        codec_assertions=corrected_tap, serialization_assertions=serialization_tap,
        raw_capture_encoding="Exact TAP bytes containing trailing whitespace are retained as lowercase hex; raw-capture-encodings.json binds logical captures to their byte-identical decoded storage. Original receipt hashes remain unchanged.",
        claim_legs=dict(
            re_derivation="audit_corrected.py --verify-saved authenticates source pins, derives vector shapes from producers, runs unchanged independent runtime-record rules and compares every saved verdict and byte string.",
            falsification="Cross-version, malformed, incomplete-reference and runnable-failure controls reject; deliberately broken validators are independently contradicted. Original shared-encoder behavior reproduces the saved failure, while isolated presentation preserves exact bytes. Missing/changed verdicts, lost mutants and hidden launches reject.",
            durability="Tracked code, vector builder, oracle, before-run pins, exact first failure sources/outputs, corrected result and byte-verified raw copies remain usable without original logs or fixture recreation. This review checks original-versus-corrected source and result equality independently."),
        limits="Pure finite data/serialization qualification. Synthetic identities and a copied compiler template do not attest current files, native births, actual compilation, image-key custody, transport or permission to execute. Original startup and hard-link failures remain failed.",
        next_action="Qualify inactive target and collection version dispatch under .5.3.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--retain", action="store_true")
    options = parser.parse_args()
    if options.retain:
        records = []
        for stage in STAGES:
            assert (LOG / (stage + ".exit")).read_bytes() == b"0\n"
            for extension in ("stdout", "stderr", "exit"):
                source = LOG / (stage + "." + extension)
                destination = HERE / "result" / source.name
                with destination.open("xb") as stream:
                    stream.write(source.read_bytes())
                assert source.read_bytes() == destination.read_bytes()
                records.append(dict(pin(destination), original=str(source.relative_to(ROOT))))
        with (HERE / "verification-outputs.json").open("x") as stream:
            stream.write(json.dumps(records, indent=2, sort_keys=True) + "\n")
    review = verify()
    if options.retain:
        with (HERE / "review.json").open("x") as stream:
            stream.write(json.dumps(review, indent=2, sort_keys=True) + "\n")
    else:
        assert review == json.loads((HERE / "review.json").read_bytes())
    print(json.dumps(review, sort_keys=True))


if __name__ == "__main__":
    main()
