"""Retain first/corrected contract evidence and verify exact task continuity."""
import argparse
import ast
import copy
import json
import subprocess

import audit
import audit_corrected
import prepare

HERE, ROOT = prepare.HERE, prepare.ROOT
LOG = ROOT / ".artifacts/logs" / HERE.name
STAGES = ("prepare", "audit", "corrected-prepare", "corrected-audit", "saved", "book", "book-inspect", "knowledge-generate", "knowledge-check")


def layout():
    original = json.loads((HERE / "task-layout-review.json").read_bytes())
    recovery = json.loads((HERE / "task-layout-recovery.json").read_bytes())
    assert {key: recovery[key] for key in original} == original
    raw = subprocess.check_output(["git", "show", recovery["source_revision"] + ":" + recovery["source_task"]], cwd=ROOT)
    assert prepare.digest(raw) == recovery["source_git_sha256"]
    text = raw.decode("utf-8")
    edit = recovery["source_edit"]
    parent = recovery["owner"].rsplit(".", 1)[0]
    assert edit["start"] == text.index('- ID: `' + parent + '`\n')
    assert edit["end"] == text.index('\n- ID:', edit["start"] + 1)
    expanded = text[:edit["start"]] + edit["replacement"] + text[edit["end"]:]
    assert prepare.digest(expanded.encode()) == recovery["expanded_before_normalization_sha256"]
    children = expanded.index('  Children:', edit["start"])
    before = expanded[:children] + text[edit["end"]:]
    assert prepare.digest(before.encode()) == recovery["pre_expansion_sha256"]
    normalized = expanded
    offsets = recovery["removed_empty_line_offsets"]
    assert offsets == sorted(set(offsets))
    for offset in reversed(offsets):
        assert normalized[offset:offset + 2] == "\n\n"
        normalized = normalized[:offset] + normalized[offset + 1:]
    assert prepare.digest(normalized.encode()) == recovery["normalized_sha256"]
    assert normalized.count("\n") == recovery["live_lines"]
    assert [line for line in expanded.splitlines() if line.strip()] == [line for line in normalized.splitlines() if line.strip()]
    return dict(added_children=recovery["added_children"], removed_empty_separators=len(offsets),
                captured_task_lines=recovery["live_lines"], exact_reconstruction=True)


def verify():
    original_plan = prepare.authenticate()
    pins = audit_corrected.check_pins()
    original_contract = json.loads((HERE / "contracts.json").read_bytes())
    corrected_plan = json.loads((HERE / "corrected-plan.json").read_bytes())
    expected = copy.deepcopy(original_plan)
    next(row for row in expected["invariants"] if row["id"] == "private_before_global")["functions"].append("cleanup.cleanup_receipts_settled")
    assert corrected_plan == expected
    corrected = json.loads((HERE / "corrected-contracts.json").read_bytes())
    assert corrected == prepare.build(corrected_plan)
    assert corrected["functions"] == original_contract["functions"] and corrected["schedules"] == original_contract["schedules"]
    try:
        audit.verify(original_contract, original_plan)
    except AssertionError:
        declared = {row["id"] for row in original_contract["functions"]}
        linked = {name for row in original_contract["invariants"] for name in row["functions"]}
        assert declared - linked == {"cleanup.cleanup_receipts_settled"} and not linked - declared
    else:
        raise AssertionError("original missing-link contract was promoted")
    # All validation functions remain exact; only corrected input/pin routing
    # in the main path differs. Never invoke the original main.
    functions = lambda filename: {node.name: ast.dump(node) for node in ast.parse((HERE / filename).read_bytes()).body
        if isinstance(node, ast.FunctionDef) and node.name not in ("main", "check_pins")}
    assert functions("audit.py") == functions("audit_corrected.py")
    counts = audit_corrected.verify(corrected, corrected_plan)
    captures = json.loads((HERE / "verification-outputs.json").read_bytes())
    assert len(captures) == len(STAGES) * 3
    assert [row["path"] for row in captures] == [str((LOG / (stage + "." + extension)).relative_to(ROOT))
        for stage in STAGES for extension in ("stdout", "stderr", "exit")]
    raw = {}
    for row in captures:
        body = bytes.fromhex(row["raw_hex"])
        assert body.hex() == row["raw_hex"] and len(body) == row["size_bytes"] and prepare.digest(body) == row["sha256"]
        raw[row["path"].rsplit("/", 1)[-1]] = body
    for stage in STAGES:
        assert raw[stage + ".exit"] == (b"1\n" if stage == "audit" else b"0\n")
    failure = json.loads((HERE / "first-failure.json").read_bytes())
    for row in failure["unchanged_first_files"]:
        body = (ROOT / row["path"]).read_bytes()
        assert len(body) == row["size_bytes"] and prepare.digest(body) == row["sha256"]
    for row in failure["outputs"]:
        assert bytes.fromhex(row["raw_hex"]) == raw[row["path"].rsplit("/", 1)[-1]]
    report = json.loads((HERE / "result/audit.json").read_bytes())
    assert report == json.loads(raw["corrected-audit.stdout"]) == json.loads(raw["saved.stdout"])
    assert {key: report[key] for key in counts} == counts and report["runtime_qualification"] is False
    assert b"knowledge-map: OK" in raw["knowledge-check.stdout"] + raw["knowledge-check.stderr"]
    book = json.loads((HERE / "book-review.json").read_bytes())
    assert book["exit_code"] == 0 and book["exact_output_absent"]
    assert not (ROOT / book["output"]).exists() and not (ROOT / book["output"]).is_symlink()
    card = "docs/knowledge/test-subprocess-policy-adapters.md"
    old_card = subprocess.check_output(["git", "show", original_plan["source_revision"] + ":" + card], cwd=ROOT).decode()
    questions = lambda body: [line for line in body.splitlines() if line.startswith('  - "')]
    assert questions(old_card) == questions((ROOT / card).read_text())
    return dict(schema="fsmgen.inactive_lifetime_contract_review.v1", owner=original_plan["owner"],
        source_revision=original_plan["source_revision"], source_inputs=len(original_plan["inputs"]),
        source_bytes=sum(row["size_bytes"] for row in original_plan["inputs"]), prospective_pins=len(pins),
        raw_captures=len(captures), **counts, falsifiers=report["falsifiers"], task_layout=layout(),
        first_failure="The independent complete-binding check rejected one omitted cleanup-helper link. Original sources, plan, contract, pins and failed output remain unchanged. Corrected inputs add exactly that link; validation functions, source bodies and ordering domain remain exact.",
        claim_legs=original_plan["claim_legs"], limits=original_plan["scope"],
        next_action="Qualify pure combined lifetime transitions and matched evidence under .12.4.1.3.6.2, using corrected-plan.json and corrected-contracts.json.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--retain", action="store_true")
    options = parser.parse_args()
    if options.retain:
        captures = []
        for stage in STAGES:
            for extension in ("stdout", "stderr", "exit"):
                path = LOG / (stage + "." + extension)
                body = path.read_bytes()
                captures.append(dict(path=str(path.relative_to(ROOT)), size_bytes=len(body), sha256=prepare.digest(body), raw_hex=body.hex()))
        with (HERE / "verification-outputs.json").open("x") as stream:
            json.dump(captures, stream, sort_keys=True, indent=2); stream.write("\n")
    report = verify()
    if options.retain:
        with (HERE / "review.json").open("x") as stream:
            json.dump(report, stream, sort_keys=True, indent=2); stream.write("\n")
    else:
        assert report == json.loads((HERE / "review.json").read_bytes())
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
