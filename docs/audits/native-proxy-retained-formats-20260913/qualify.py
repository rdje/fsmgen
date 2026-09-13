"""Qualify new private bytes and frozen reader routing with inert records only."""
import copy
import hashlib
import json
from pathlib import Path
import sys

import prepare
import retained_contract as implementation

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ROOT_SUFFIXES = ("ordinary", "space in checkout", 'quote"and\\slash', "unicode-é-😀")
PERL = str(Path("/usr/bin/perl").resolve())  # Required read-only OS dependency.


def check_pins():
    pins = json.loads((HERE / "preflight-pins.json").read_bytes())
    for record in pins:
        raw = (ROOT / record["path"]).read_bytes()
        assert len(raw) == record["size_bytes"] and prepare.digest(raw) == record["sha256"]
    return pins


def cross_legacy(example, raw):
    descriptor = copy.deepcopy(example["descriptor"])
    if descriptor is not None:
        descriptor.update(bytes=len(raw), sha256=prepare.digest(raw))
    return dict(descriptor=descriptor, context_sha256=example["context_sha256"])


def changed_legacy(example, selected):
    value = json.loads(bytes.fromhex(example["raw_hex"]))
    path = selected["capture"]["before"]["sources"][-1]["identity"]["path"]
    kind = example["kind"]
    if kind == "associations":
        value["target"]["sources"][0]["path"] = path
    elif kind == "diagnostics":
        value["sources"][0]["path"] = path
    elif kind == "archive":
        value["context"]["sources"][0]["path"] = path
        value["context_sha256"] = prepare.digest(prepare.canonical(value["context"]))
    elif kind == "publication":
        value["artifacts"]["manifest"]["path"] = path
    elif kind == "archive_page":
        value["sources"] = [path]
    else:
        value["scope"] = "execution_context"
        value["command"] = selected["collector_contract"]["command"]
    return prepare.canonical(value)


def run():
    check_pins()
    vectors = json.loads((HERE / "vectors.json").read_bytes())
    directory = HERE / "result"
    (directory / "envelopes").mkdir(parents=True, exist_ok=True)
    with (directory / "qualification.jsonl").open("x", buffering=1) as stream:
        attempts = []
        def forbidden(event, arguments):
            if event in ("subprocess.Popen", "os.system", "os.fork", "os.exec", "os.posix_spawn"):
                attempts.append(event)
                raise RuntimeError("no process may be created by inert retained qualification")
        sys.addaudithook(forbidden)
        rows, raw_controls, legacy_rows = [], [], []
        for suffix in ROOT_SUFFIXES:
            root = ROOT / ".artifacts/tmp/inert-retained-roots" / suffix
            options = dict(root=root, system_perl=PERL)
            for vector in vectors["vectors"]:
                value = prepare.apply(vector, vectors["records"])
                original = prepare.canonical(value)
                try:
                    raw = implementation.encode(value, **options)
                    decoded = implementation.decode(raw, prepare.digest(raw), **options)
                except ValueError as error:
                    row = dict(root=suffix, name=vector["name"], accepted=False, error=str(error))
                else:
                    assert raw == original and decoded == value
                    destination = directory / "envelopes" / (vector["name"] + ".json")
                    if suffix == ROOT_SUFFIXES[0]:
                        with destination.open("xb") as output:output.write(raw)
                    assert destination.read_bytes() == raw
                    row = dict(root=suffix, name=vector["name"], accepted=True, bytes=len(raw), sha256=prepare.digest(raw))
                    decoded["limits"]["publication"] = "changed returned copy"
                assert prepare.canonical(value) == original
                rows.append(row);stream.write(json.dumps(row, sort_keys=True) + "\n")
                assert row["accepted"] is vector["accept"], vector["name"]
            selected = vectors["records"]["shared_0_execution_context"]
            raw = prepare.canonical(selected)
            malformed = [
                ("wrong_anchor", raw, "0" * 64),
                ("pretty_json", (json.dumps(selected, sort_keys=True, indent=2) + "\n").encode(), None),
                ("missing_lf", raw[:-1], None),
                ("duplicate_schema", raw.replace(b'{"capture":', b'{"schema":"duplicate","capture":', 1), None),
                ("oversized_bytes", b" " * (implementation.MAX_BYTES + 1), None),
            ]
            for name, candidate, anchor in malformed:
                parser = implementation.json.loads
                def unexpected_parse(*args, **kwargs):
                    raise RuntimeError("oversized bytes reached JSON parsing")
                try:
                    if name == "oversized_bytes":
                        implementation.json.loads = unexpected_parse
                    try:
                        implementation.decode(candidate, anchor or prepare.digest(candidate), **options)
                    except ValueError:
                        raw_controls.append(dict(root=suffix, name=name, rejected=True, bytes=len(candidate), sha256=prepare.digest(candidate)))
                    else:
                        raise AssertionError(name)
                finally:
                    implementation.json.loads = parser
            local = copy.deepcopy(selected)
            for frame in (local["capture"]["before"], local["capture"]["after"]):
                for process in frame["processes"]:
                    process["executable"] = process["executable"].replace("<repo>", str(root)).replace("<system-perl>", PERL)
                    process["command"] = process["command"].replace("<repo>", str(root))
            try:
                implementation.encode(local, **options)
            except ValueError:
                raw_controls.append(dict(root=suffix, name="absolute_process_paths", rejected=True))
            else:
                raise AssertionError("machine-local process spellings entered retained bytes")
            for example in vectors["legacy"]:
                old = bytes.fromhex(example["raw_hex"])
                changed = changed_legacy(example, selected)
                try:
                    implementation.read_legacy(example["kind"], changed, prepare.digest(changed), **cross_legacy(example, changed))
                except ValueError:
                    legacy_rows.append(dict(root=suffix, kind=example["kind"], cross="changed_prefix_or_fields", rejected=True))
                else:
                    raise AssertionError("frozen reader accepted a changed source family or command")
                parsed = implementation.read_legacy(example["kind"], old, example["sha256"], **cross_legacy(example, old))
                assert parsed == json.loads(old)
                legacy_rows.append(dict(root=suffix, kind=example["kind"], accepted=True, raw_sha256=prepare.digest(old),
                                        interpreted_sha256=prepare.digest(prepare.canonical(parsed))))
                try:
                    implementation.decode(old, example["sha256"], **options)
                except ValueError:
                    legacy_rows.append(dict(root=suffix, kind=example["kind"], cross="old_to_new", rejected=True))
                else:
                    raise AssertionError("old format entered new envelope")
                try:
                    implementation.read_legacy(example["kind"], raw, prepare.digest(raw), **cross_legacy(example, raw))
                except ValueError:
                    legacy_rows.append(dict(root=suffix, kind=example["kind"], cross="new_to_old", rejected=True))
                else:
                    raise AssertionError("new envelope entered frozen reader")
        assert not attempts
        result = dict(schema="fsmgen.inactive_retained_qualification.v1", roots=list(ROOT_SUFFIXES), rows=rows,
                      raw_controls=raw_controls, legacy=legacy_rows, process_attempts=attempts)
        with (directory / "qualification.json").open("x") as output:
            json.dump(result, output, sort_keys=True, indent=2);output.write("\n")
        print(json.dumps(dict(envelope_cases=len(rows), accepted=sum(row["accepted"] for row in rows),
                              raw_controls=len(raw_controls), legacy_checks=len(legacy_rows), process_attempts=0)))


if __name__ == "__main__":
    run()
