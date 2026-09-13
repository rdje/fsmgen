"""Pin existing lifecycle bodies and enumerate a prospective serial-order domain."""
import hashlib
import itertools
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("ascii")


def authenticate():
    plan = json.loads((HERE / "plan.json").read_bytes())
    for row in plan["inputs"]:
        raw = (ROOT / row["path"]).read_bytes()
        assert len(raw) == row["size_bytes"] and digest(raw) == row["sha256"]
        assert raw == subprocess.check_output(["git", "show", plan["source_revision"] + ":" + row["path"]], cwd=ROOT)
    return plan


def function_span(raw, name):
    # These pinned Perl modules declare named top-level subs. This is a source
    # boundary scanner, not a Perl parser or a claim about arbitrary Perl code.
    declarations = list(re.finditer(rb"(?m)^sub ([A-Za-z_][A-Za-z_0-9]*)\b", raw))
    selected = [index for index, match in enumerate(declarations) if match[1].decode() == name]
    assert len(selected) == 1, name
    index = selected[0]
    start = declarations[index].start()
    end = declarations[index + 1].start() if index + 1 < len(declarations) else raw.rindex(b"\n1;\n") + 1
    return start, end


def schedules(plan):
    rows = []
    for profile in plan["profiles"]:
        edges = plan["common_edges"] + profile["additional_edges"]
        for order in itertools.permutations(plan["events"]):
            positions = {event: index for index, event in enumerate(order)}
            if all(positions[before] < positions[after] for before, after in edges):
                rows.append(dict(profile=profile["name"], order=list(order)))
    return rows


def build(plan):
    functions = []
    for module in plan["modules"]:
        raw = (ROOT / module["path"]).read_bytes()
        for name in module["functions"]:
            start, end = function_span(raw, name)
            functions.append(dict(id=module["id"] + "." + name, path=module["path"], name=name,
                                  start=start, end=end, sha256=digest(raw[start:end])))
    rows = schedules(plan)
    return dict(schema="fsmgen.inactive_lifetime_source_contract.v1", source_revision=plan["source_revision"],
                functions=functions, invariants=plan["invariants"], schedules=rows,
                schedule_domain_sha256=digest(canonical(rows)), scope=plan["scope"])


if __name__ == "__main__":
    plan = authenticate()
    result = build(plan)
    with (HERE / "contracts.json").open("x") as stream:
        json.dump(result, stream, sort_keys=True, indent=2); stream.write("\n")
    print(json.dumps(dict(source_functions=len(result["functions"]), prospective_schedules=len(result["schedules"]),
                          runtime_qualification=False)))
