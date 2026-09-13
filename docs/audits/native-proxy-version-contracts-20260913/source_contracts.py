"""Read-only derivation of the frozen producer/reader compatibility boundary."""

import ast
import hashlib
import json
from pathlib import Path
import re
import subprocess

DIRECTORY = Path(__file__).resolve().parent
ROOT = DIRECTORY.parents[2]
REVISION = "8dbea4b6a76de2417a9a66e535b574572212c481"
PREPARER = "t/lib/FSM/Test/RustProxyFixture.pm"
DESIGN = "docs/audits/native-proxy-canonical-contract-20260910/contract.json"
ACQUISITION = "docs/audits/native-proxy-observation-acquisition-20260910/ObservationAcquisition.pm"
ORIGINAL_PREPARATION = "docs/audits/native-proxy-hardlink-20260910/result/preparation.json"
ORIGINAL_COLLECTOR = "docs/audits/native-proxy-daemon-original-20260910/policy-result.json"
PYTHON_CONTRACTS = {
    "scripts/fixture_kernel_sampler.py": ["_read_source", "_native_rust_sources", "_supervisor_wrapper", "validate_target"],
    "scripts/observe_fixture_startup.py": ["Evidence", "main_entry", "FixtureCensus"],
    "scripts/fixture_policy_log.py": ["require_scope", "command", "retained_command"],
    "scripts/analyze_fixture_policy.py": ["verify_collector_command", "_load_capture_inputs"],
    "scripts/fixture_policy_associations.py": ["source_identity", "validate"],
    "scripts/fixture_policy_diagnostics.py": ["validate"],
    "scripts/fixture_policy_publication.py": ["validate_receipt"],
    "scripts/fixture_policy_archive.py": ["validate_index", "validate_page"],
}


def digest(body):
    return hashlib.sha256(body).hexdigest()


def body(path):
    return (ROOT / path).read_bytes()


def pin(path):
    raw = body(path)
    return dict(path=path, sha256=digest(raw), size_bytes=len(raw))


def verify_pin(record):
    if pin(record["path"]) != record:
        raise ValueError("changed pinned input: " + record["path"])


def definition(path, name):
    raw = body(path).decode("utf-8")
    matches = [node for node in ast.parse(raw).body
               if isinstance(node, (ast.FunctionDef, ast.ClassDef)) and node.name == name]
    if len(matches) != 1:
        raise ValueError("source definition is not unique: " + path + ":" + name)
    node = matches[0]
    return dict(name=name, first_line=node.lineno, last_line=node.end_lineno,
                source="".join(raw.splitlines(keepends=True)[node.lineno - 1:node.end_lineno]))


def literal(path, name):
    nodes = [node.value for node in ast.parse(body(path)).body
             if isinstance(node, ast.Assign)
             and any(isinstance(target, ast.Name) and target.id == name for target in node.targets)]
    if len(nodes) != 1:
        raise ValueError("source literal is not unique: " + path + ":" + name)
    return ast.literal_eval(nodes[0])


def ordered(source, fragments):
    positions = [source.index(fragment) for fragment in fragments]
    if positions != sorted(set(positions)):
        raise ValueError("producer ordering changed")
    return positions


def derive():
    inputs = [PREPARER, DESIGN, ACQUISITION, ORIGINAL_PREPARATION, ORIGINAL_COLLECTOR,
              "t/1669-task-acceptance-fixture-runtime.t", "t/1816-rust-proxy-integration.t",
              *PYTHON_CONTRACTS]
    bindings = []
    for path in inputs:
        record = pin(path)
        original = subprocess.run(["git", "show", REVISION + ":" + path], cwd=ROOT,
                                  check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
        if body(path) != original:
            raise ValueError("current source differs from selected Git epoch: " + path)
        bindings.append(record)

    perl = body(PREPARER).decode()
    initial = re.search(r"my \$result = \{\n(.*?)\n    \};", perl, re.S).group(1)
    fields = re.findall(r"\b([a-z_]+)\s*=>", initial)
    if len(fields) != len(set(fields)):
        raise ValueError("duplicate initial preparation fields")
    v1 = re.search(r"schema => '([^']+)'", initial).group(1)
    design = json.loads(body(DESIGN))
    native = design["capture_and_policy"]["preparation_format"]
    if native["fields"][:len(fields)] != fields:
        raise ValueError("native version changes legacy field order")
    preparation_order = ordered(perl, [
        'push @{$result->{sources}}, $source_identity;',
        'push @{$result->{sources}}, _seal_executable',
        '$result->{executable} = File::Spec->abs2rel($proxy, $ROOT);',
        '$result->{ok} = 1;',
    ])
    integration = body("t/1669-task-acceptance-fixture-runtime.t").decode()
    diagnostic_order = ordered(integration, [
        '$prepared = prepare_rust_proxy', "diag 'Rust proxy preparation: '",
        'ok($prepared->{ok}', 'symlink $proxy, $cargo',
        "schema => 'fsmgen.test.rust_tool_resolution_probe.v1'",
    ])
    acquisition = body(ACQUISITION).decode()
    snapshot_block = re.search(r'\$plan->\{specifications\} = \[\n(.*?)\n        \];', acquisition, re.S).group(1)
    snapshot_paths = re.findall(r'\["([^"]+)"', snapshot_block)
    runtime_fields = design["reference_contract"]["fields"]["runtime"]
    native_sources = ast.parse(definition("scripts/fixture_kernel_sampler.py", "_native_rust_sources")["source"])
    source_return = native_sources.body[0].body[-1]
    legacy_capture_order = [item.id for item in source_return.value.elts]
    schemas = {path: literal(path, "SCHEMA") for path in PYTHON_CONTRACTS
               if path.startswith("scripts/fixture_policy_") and path != "scripts/fixture_policy_log.py"}
    schemas["archive_page"] = literal("scripts/fixture_policy_archive.py", "PAGE_SCHEMA")
    return dict(
        schema="fsmgen.inactive_proxy_version_contracts.v1", source_revision=REVISION,
        scope="Source contract and layout selection only; not record validity, runtime authority or native qualification.",
        inputs=bindings,
        definitions={path: [definition(path, name) for name in names]
                     for path, names in PYTHON_CONTRACTS.items()},
        preparation=dict(legacy_schema=v1, legacy_fields=fields, native_schema=native["schema"],
                         native_fields=native["fields"], legacy_initial_source=initial,
                         source_order_offsets=preparation_order, diagnostic_order_offsets=diagnostic_order,
                         native_format=native),
        capture=dict(legacy_prefix=literal("scripts/analyze_fixture_policy.py", "FIXTURE_PREFIX"),
                     canonical_root=design["layout"]["root"], snapshot_paths=snapshot_paths,
                     legacy_native_return_order=legacy_capture_order,
                     runtime_fields=runtime_fields, constraints=design["capture_and_policy"],
                     observation_lifetime=design["observation_lifetime"]),
        retained_schemas=schemas,
        limits="Original bounds, failures, main-entry uncertainty and frozen old readers remain authoritative.",
    )


def selected_functions(path, names, namespace):
    """Compile only the named, source-pinned pure definitions, never module setup."""
    source = "\n".join(definition(path, name)["source"] for name in names)
    exec(compile(source, path, "exec"), namespace)
    return namespace
