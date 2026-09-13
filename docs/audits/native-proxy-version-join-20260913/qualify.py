"""Exercise matched inert records through unchanged version-stage helpers."""
import copy
import json
import sys

import loaders
import prepare

HERE, ROOT = prepare.HERE, prepare.ROOT
ROOTS = ("ordinary", "space in checkout", 'quote"and\\slash', "unicode-é-😀")
VARIANTS = ("matched", "different_reference_identity", "other_mode", "failed_preparation", "other_envelope")


def check_pins():
    pins = json.loads((HERE / "preflight-pins.json").read_bytes())
    for row in pins:
        raw = (ROOT / row["path"]).read_bytes()
        assert len(raw) == row["size_bytes"] and prepare.digest(raw) == row["sha256"]
    return pins


def candidates():
    bridge = json.loads((HERE / "bridge-vectors.json").read_bytes())
    admitted = {row["name"]: json.loads(row["encoded"]) for row in
                json.loads((HERE / "result/bridge.json").read_bytes())["rows"] if row["accepted"]}
    records = prepare.read(3, "vectors.json")["records"]
    rows = []
    for name, envelope in sorted(records.items()):
        base = "shared_1" if name.startswith("shared_1_") else "shared_0"
        scope = envelope["collector_contract"]["scope"]
        other = "shared_0" if base == "shared_1" else "shared_1"
        for variant in VARIANTS:
            preparation = admitted[base]
            retained = envelope
            if variant == "different_reference_identity":
                preparation = admitted[base + "_different_reference_identity"]
            elif variant == "other_mode":
                preparation = admitted[other]
            elif variant == "failed_preparation":
                preparation = admitted[base + "_retained_reference_failure"]
            elif variant == "other_envelope":
                retained = records[other + "_" + scope]
            rows.append(dict(name=name, variant=variant, preparation=copy.deepcopy(preparation),
                             capture=copy.deepcopy(envelope["capture"]), retained=copy.deepcopy(retained),
                             accept=variant == "matched"))
        assert admitted[base] == bridge["bases"][base]
    return rows


def joined(preparation, capture, retained, *, root, selector, target, envelope, expand, perl, contracts):
    if selector(preparation, contracts) != capture["layout"]:
        raise ValueError("preparation layout differs from capture")
    if preparation["ok"] != 1 or preparation["executable"] is None:
        raise ValueError("failed preparation cannot supply a runtime target")
    checked = target(expand(capture, root), root, normal_uid=501, system_perl=perl)
    sources = capture["before"]["sources"]
    reference = preparation["image_reference"]
    if preparation["executable"] != checked["evidence"]["fixture"]:
        raise ValueError("preparation executable differs from target")
    if preparation["sources"] != [row["identity"] for row in sources[3:]]:
        raise ValueError("preparation selected sources differ from capture")
    if reference["private"] != sources[1]["identity"] or reference["global"] != sources[2]["identity"]:
        raise ValueError("preparation reference identities differ from capture")
    raw_reference = prepare.canonical(reference["record"]).encode("ascii")
    if any(bytes.fromhex(row["bytes_hex"]) != raw_reference for row in sources[1:3]):
        raise ValueError("preparation reference bytes differ from capture")
    for private, selected in zip(preparation["compilation_sources"], sources[3:]):
        body = bytes.fromhex(selected["bytes_hex"])
        if private["size_bytes"] != len(body) or private["sha256"] != prepare.digest(body):
            raise ValueError("compiler-source bytes differ from selected capture")
    if prepare.canonical(retained["capture"]) != prepare.canonical(capture):
        raise ValueError("retained capture differs from selected capture")
    raw = envelope.encode(retained, root=root, system_perl=perl)
    if envelope.decode(raw, prepare.digest(raw), root=root, system_perl=perl) != retained:
        raise ValueError("retained round trip differs")
    return dict(target=checked, envelope_bytes=len(raw), envelope_sha256=prepare.digest(raw),
                preparation_sha256=prepare.digest(prepare.canonical(preparation).encode("ascii")))


def run():
    check_pins()
    selector = loaders.load("layout", "dispatch.py").select_layout
    target = loaders.load("capture", "capture_contract.py").target_contract
    capture_helpers = loaders.load("capture", "qualify.py")
    retained = loaders.load("retained", "retained_contract.py")
    contracts = prepare.read(0, "contracts.json")
    rows, attempts = [], []
    domain = candidates()
    def forbid(event, args):
        if event in ("subprocess.Popen", "os.system", "os.fork", "os.exec", "os.posix_spawn"):
            attempts.append(event)
            raise RuntimeError("no process creation in matched data qualification")
    sys.addaudithook(forbid)
    with (HERE / "result/qualification.jsonl").open("x", buffering=1) as stream:
        for suffix in ROOTS:
            root = ROOT / ".artifacts/tmp/inert-version-join-roots" / suffix
            for candidate in domain:
                before = prepare.canonical(candidate)
                row = dict(root=suffix, name=candidate["name"], variant=candidate["variant"])
                try:
                    result = joined(candidate["preparation"], candidate["capture"], candidate["retained"],
                        root=root, selector=selector, target=target, envelope=retained,
                        expand=capture_helpers.at_root, perl=capture_helpers.PERL, contracts=contracts)
                except ValueError as error:
                    row.update(accepted=False, error=str(error))
                else:
                    row.update(accepted=True, result=result)
                rows.append(row)
                stream.write(json.dumps(row, ensure_ascii=True, sort_keys=True) + "\n")
                assert row["accepted"] is candidate["accept"], row
                assert prepare.canonical(candidate) == before
    assert not attempts
    result = dict(schema="fsmgen.inactive_version_join_qualification.v1", roots=list(ROOTS), rows=rows,
                  process_attempts=attempts)
    with (HERE / "result/qualification.json").open("x") as stream:
        json.dump(result, stream, sort_keys=True, indent=2); stream.write("\n")
    print(json.dumps(dict(join_cases=len(rows), accepted=sum(row["accepted"] for row in rows), process_attempts=attempts)))


if __name__ == "__main__":
    run()
