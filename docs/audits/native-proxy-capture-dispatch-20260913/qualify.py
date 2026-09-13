"""New inert capture-contract qualification; never instantiate original producers."""
import copy
import hashlib
import json
from pathlib import Path
import sys

import capture_contract as implementation
import prepare

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ROOT_SUFFIXES = ("ordinary", "space in checkout", 'quote"and\\slash', "unicode-é-😀")
PERL = str(Path("/usr/bin/perl").resolve())  # Required read-only OS toolchain identity.


def at_root(value, root):
    if type(value) is str:
        return value.replace("<repo>", str(root)).replace("<system-perl>", PERL)
    if type(value) is list:
        return [at_root(item, root) for item in value]
    if type(value) is dict:
        return {key: at_root(item, root) for key, item in value.items()}
    return value


def check_pins():
    pins = json.loads((HERE / "preflight-pins.json").read_bytes())
    for entry in pins:
        raw = (ROOT / entry["path"]).read_bytes()
        assert len(raw) == entry["size_bytes"] and hashlib.sha256(raw).hexdigest() == entry["sha256"]
    return pins


def run():
    check_pins()
    vectors = json.loads((HERE / "vectors.json").read_bytes())
    directory = HERE / "result"
    directory.mkdir(exist_ok=True)
    # Reserve output before cases; first observations survive an assertion.
    with (directory / "qualification.jsonl").open("x", buffering=1) as stream:
        launches = []
        def forbid(event, args):
            if event in ("subprocess.Popen", "os.system", "os.fork", "os.exec", "os.posix_spawn"):
                launches.append(event)
                raise RuntimeError("process creation is forbidden in inert qualification")
        sys.addaudithook(forbid)
        rows, collections, mutants = [], [], []
        for suffix in ROOT_SUFFIXES:
            root = ROOT / ".artifacts/tmp/inert-capture-roots" / suffix
            accepted = {}
            for vector in vectors["vectors"]:
                value = at_root(prepare.apply(vector, vectors["bases"]), root)
                before = prepare.canonical(value)
                try:
                    output = implementation.target_contract(value, root, normal_uid=501, system_perl=PERL)
                except ValueError as failure:
                    row = dict(root=suffix, name=vector["name"], accepted=False, error=str(failure))
                else:
                    row = dict(root=suffix, name=vector["name"], accepted=True, output=copy.deepcopy(output))
                    accepted[vector["name"]] = copy.deepcopy(output)
                    output["evidence"]["sources"][0]["inode"] = 7
                assert prepare.canonical(value) == before, "contract or returned alias mutated caller data"
                stream.write(json.dumps(row, sort_keys=True, ensure_ascii=True) + "\n")
                rows.append(row)
                assert row["accepted"] == vector["accept"], vector["name"]
            assert accepted["shared_0"] == accepted["shared_other_observer"], "observer hold contaminated stable target evidence"
            for schema in implementation.COLLECTOR_SCHEMAS:
                for scope in implementation.SCOPES:
                    argv = implementation.collection_command(root, schema=schema, scope=scope)
                    retained = implementation.retained_collection_command(argv, root, schema=schema)
                    collections.append(dict(root=suffix, schema=schema, scope=scope, command=retained))
            # Deliberate counterimplementations operate on copies only.
            selected = next(row for row in vectors["vectors"] if row["name"] == "shared_0_changed_source_0")
            changed = at_root(prepare.apply(selected, vectors["bases"]), root)
            changed["after"] = copy.deepcopy(changed["before"])
            output = implementation.target_contract(changed, root, normal_uid=501, system_perl=PERL)
            mutants.append(dict(root=suffix, mutation="ignore_changed_after", name=selected["name"], output=output))
            output = copy.deepcopy(accepted["shared_0"])
            output["main_entry"] = "entered"
            mutants.append(dict(root=suffix, mutation="invent_native_entry", name="shared_0", output=output))
            output = copy.deepcopy(accepted["shared_0"])
            output["evidence"]["sources"].append(vectors["bases"]["shared_0"]["before"]["observation"]["identity"])
            mutants.append(dict(root=suffix, mutation="include_observer_hold", name="shared_0", output=output))
        assert not launches
        result = dict(schema="fsmgen.inactive_capture_qualification.v1", roots=list(ROOT_SUFFIXES), rows=rows,
                      collections=collections, mutants=mutants, process_attempts=launches)
        with (directory / "qualification.json").open("x") as output:
            json.dump(result, output, ensure_ascii=True, sort_keys=True, indent=2)
            output.write("\n")
        print(json.dumps(dict(target_cases=len(rows), accepted=sum(row["accepted"] for row in rows),
                              collector_commands=len(collections), counterimplementations=len(mutants), process_attempts=0)))


if __name__ == "__main__":
    run()
