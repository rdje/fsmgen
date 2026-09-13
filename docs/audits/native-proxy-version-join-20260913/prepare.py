"""Construct matched inert preparation records from checked capture snapshots."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
UNITS = ("native-proxy-version-contracts-20260913", "native-proxy-preparation-records-20260913",
         "native-proxy-capture-dispatch-20260913", "native-proxy-retained-formats-20260913")


def canonical(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"), allow_nan=False)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def read(unit, name):
    return json.loads((ROOT / "docs/audits" / UNITS[unit] / name).read_bytes())


def build():
    prior = read(1, "vectors.json")
    capture = read(2, "vectors.json")["bases"]
    bases = {}
    for mode in (0, 1):
        name = "shared_" + str(mode)
        target = capture[name]
        source = target["before"]["sources"]
        record = copy.deepcopy(prior["base"])
        record["sources"] = [copy.deepcopy(row["identity"]) for row in source[3:]]
        record["image_reference"] = dict(record=json.loads(bytes.fromhex(source[1]["bytes_hex"])),
            private=copy.deepcopy(source[1]["identity"]), global_=copy.deepcopy(source[2]["identity"]))
        record["image_reference"]["global"] = record["image_reference"].pop("global_")
        record["compilation_sources"] = [dict(row, path=target["workspace"] + "/rust-tools/" + filename, inode=inode)
            for row, filename, inode in zip(record["sources"], ("rustup.c", "rustup"), (401, 402))]
        record["compilation_argv"][-3] = record["compilation_sources"][0]["path"]
        record["compilation_argv"][-1] = record["compilation_sources"][1]["path"]
        record["executable"] = record["sources"][1]["path"]
        assert record["compilation"] == prior["base"]["compilation"]
        assert all(record["sources"][index][key] == record["compilation_sources"][index][key]
                   for index in (0, 1) for key in ("size_bytes", "sha256"))
        bases[name] = record
    vectors = []
    def add(name, base, record, accept):
        vectors.append(dict(name=name, base=base, raw=canonical(record), accept=accept))
    for name, record in bases.items():
        add(name, name, record, True)
        changed_reference = copy.deepcopy(record)
        changed_reference["image_reference"]["global"]["inode"] += 1000
        add(name + "_different_reference_identity", name, changed_reference, True)
        reference_failure = copy.deepcopy(record)
        reference_failure.update(ok=0, status="invocation_error", failure_stage="image_reference",
                                 diagnostic="inert reference-stage failure", executable=None)
        add(name + "_retained_reference_failure", name, reference_failure, True)
        image_failure = copy.deepcopy(reference_failure)
        image_failure.update(failure_stage="image_admission", sources=[], image_reference=None,
                             diagnostic="inert image-admission failure")
        add(name + "_image_admission_failure", name, image_failure, True)
        changes = [
            ("runnable_failure", reference_failure, ["executable"], record["executable"]),
            ("missing_reference", record, ["image_reference"], None),
            ("wrong_version", record, ["schema"], "fsmgen.test.rust_proxy_fixture.v1"),
            ("private_executable", record, ["executable"], record["compilation_sources"][1]["path"]),
            ("bad_reference_digest", record, ["image_reference", "global", "sha256"], "0" * 64),
            ("different_private_bytes", record, ["compilation_sources", 0, "sha256"], "0" * 64),
            ("other_mode_sources", record, ["sources"], bases["shared_" + str(1 - int(name[-1]))]["sources"]),
        ]
        for label, original, path, replacement in changes:
            value = copy.deepcopy(original)
            target = value
            for field in path[:-1]:
                target = target[field]
            target[path[-1]] = copy.deepcopy(replacement)
            add(name + "_" + label, name, value, False)
    return dict(schema="fsmgen.inactive_version_bridge_vectors.v1", bases=bases, vectors=vectors,
        compiler_fields=prior["compiler_fields"], scope="Inert records and supplied byte snapshots only. The compiler receipt is a structural template; no compilation or native authority is claimed.")


def authenticate():
    plan = json.loads((HERE / "plan.json").read_bytes())
    for entry in plan["inputs"]:
        raw = (ROOT / entry["path"]).read_bytes()
        assert len(raw) == entry["size_bytes"] and digest(raw) == entry["sha256"]
        assert raw == subprocess.check_output(["git", "show", plan["source_revision"] + ":" + entry["path"]], cwd=ROOT)
    return plan


if __name__ == "__main__":
    authenticate()
    value = build()
    with (HERE / "bridge-vectors.json").open("x") as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write("\n")
    print(json.dumps(dict(preparation_cases=len(value["vectors"]), accepted=sum(row["accept"] for row in value["vectors"]))))
