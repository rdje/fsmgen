"""Check claim identity, source coordinates and derived book metrics separately."""

import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
REVISION = "012adadf38a529c93233584632fbf182fd88a217"
BOOKS = {"docs/book/src/16dk-inactive-proxy-lifetimes.md", "docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md"}
SURFACES = "doctrine/live_document_size/surfaces.jsonl"
INVENTORY = "doctrine/claim_verification/inventory.jsonl"


def old(path):
    return subprocess.check_output(["git", "show", REVISION + ":" + path], cwd=ROOT)


def rows(raw):
    return [json.loads(line) for line in raw.splitlines()]


def main():
    paths = [path for path in subprocess.check_output(["git", "ls-tree", "-r", "--name-only", REVISION, "--", "docs/book/src/"], cwd=ROOT).decode().splitlines() if path.endswith(".md")]
    baseline = [old(path) for path in paths]
    current_paths = sorted(paths)
    current = [(ROOT / path).read_bytes() for path in current_paths]
    metrics = dict(files=len(paths), bytes_total=sum(map(len, baseline)),
                   lines_total=sum(body.count(b"\n") for body in baseline))
    delta = dict(files=len(current_paths) - len(paths), bytes_total=sum(map(len, current)) - metrics["bytes_total"],
                 lines_total=sum(body.count(b"\n") for body in current) - metrics["lines_total"])
    before_surfaces, after_surfaces = rows(old(SURFACES)), rows((ROOT / SURFACES).read_bytes())
    position = next(index for index, row in enumerate(after_surfaces) if row.get("surface_id") == "shipped_behavior")
    previous_authority = before_surfaces[position]["reference_contract"].pop("aggregate_change")
    authority = after_surfaces[position]["reference_contract"].pop("aggregate_change")
    registration = json.loads((HERE / 'document-registration.json').read_bytes())
    assert after_surfaces[-1] == registration['surface']
    added_surface_line = len(after_surfaces)
    added_surface = after_surfaces.pop()
    assert before_surfaces == after_surfaces
    assert authority["baseline"] == metrics and authority["delta"] == delta
    expected_constants = {f"/reference_contract/aggregate_change/{group}/{field}": str(value)
                          for group, values in [("baseline", metrics), ("delta", delta)]
                          for field, value in values.items()}
    before, after = rows(old(INVENTORY)), rows((ROOT / INVENTORY).read_bytes())
    prior_constants = {r['constant_id'] for r in before if r['record_type']=='repository_constant'}
    added_constants = [r for r in after if r['record_type']=='repository_constant' and r['constant_id'] not in prior_constants]
    expected_added = {}
    def numeric_fields(value, pointer=''):
        if isinstance(value, dict):
            for key, item in value.items(): numeric_fields(item, pointer+'/'+key)
        elif type(value) is int: expected_added[pointer] = str(value)
    numeric_fields(added_surface)
    assert {r['source_pointer']:r['value'] for r in added_constants} == expected_added
    assert len(added_constants) == len(expected_added)
    for row in added_constants:
        assert row['path']==SURFACES and row['line']==added_surface_line
        is_file_count = row['source_pointer'] in {'/enforcement_ceilings/files','/health_targets/files'}
        assert row['classification']==('repository_derived_constant' if is_file_count else 'configured_policy_constant')
        assert row['verification_legs']==dict(durability='available',falsify='available',
            rederive='available' if is_file_count else 'not_applicable_policy_input')
        if is_file_count:
            assert row['value']==str(len(added_surface['targets']))=='1'
            assert (ROOT/added_surface['targets'][0]).is_file()
        assert row['watcher_paths']==['scripts/check_doctrines.sh']
    after=[r for r in after if r not in added_constants]
    assert len(before) == len(after)
    old_lines = {path: old(path).splitlines() for path in BOOKS}
    new_lines = {path: (ROOT / path).read_bytes().splitlines() for path in BOOKS}
    shifted, changed_constants = [], []
    for a, b in zip(before, after):
        if a == b or a["record_type"] == "census":
            continue
        if a["record_type"] == "published_candidate":
            assert a["path"] == b["path"] and a["path"] in BOOKS
            assert {key: value for key, value in a.items() if key != "line"} == {
                key: value for key, value in b.items() if key != "line"}
            assert old_lines[a["path"]][a["line"] - 1] == new_lines[b["path"]][b["line"] - 1]
            shifted.append(dict(candidate_id=a["candidate_id"], old_line=a["line"], new_line=b["line"]))
        else:
            assert a["record_type"] == b["record_type"] == "repository_constant"
            assert a["path"] == b["path"] == SURFACES and a["line"] == b["line"] == position + 1
            assert {key: value for key, value in a.items() if key != "value"} == {
                key: value for key, value in b.items() if key != "value"}
            assert b["value"] == expected_constants[b["source_pointer"]]
            changed_constants.append(dict(pointer=b["source_pointer"], old=a["value"], new=b["value"]))
    dispositions = (ROOT / "doctrine/claim_verification/dispositions.jsonl").read_bytes()
    assert dispositions == old("doctrine/claim_verification/dispositions.jsonl")
    outputs = []
    log = ROOT / ".artifacts/logs" / HERE.name
    for stage in ("claims-write-fixed", "claims-check-fixed"):
        assert (log / (stage + ".exit")).read_bytes() == b"0\n"
        for extension in ("stdout", "stderr", "exit"):
            path = log / (stage + "." + extension)
            body = path.read_bytes()
            outputs.append(dict(path=str(path.relative_to(ROOT)), size_bytes=len(body),
                                sha256=hashlib.sha256(body).hexdigest(), raw_hex=body.hex()))
    result = dict(source_revision=REVISION, dispositions_unchanged=True,
                  dispositions_sha256=hashlib.sha256(dispositions).hexdigest(),
                  candidate_identities_and_semantics_unchanged=True, shifted_candidates=shifted,
                  book_baseline=metrics, book_delta=delta, rederived_constants=changed_constants,
                  previous_authority=previous_authority["authority_id"], raw_outputs=outputs)
    result.update(existing_policy_ceilings_unchanged=True,exact_procedure_surface=added_surface,
                  added_procedure_constants=added_constants)
    with (HERE / "claim-review.json").open("x") as stream:
        stream.write(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(dict(claim_identity_unchanged=True, shifted_candidates=len(shifted),
                          rederived_constants=len(changed_constants))))


if __name__ == "__main__":
    main()
