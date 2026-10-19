"""Retain completed history for the executable-operand reconstruction leaves."""
import argparse
import gzip
import importlib.util
import json
from pathlib import Path
import sys

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import prepare

sys.path.insert(0, 'docs/audits/task-terminal-rollover-20261011')
import common as common

REVISION = 'dccd681e075c3b9df74811109de8a7cc427dae7a'
ROOT = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.4'
BASE = execute.AUDIT
PATH = BASE / 'operand-task-capacity-qualified.json.gz'
OWNER = ('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2.2.1')


def terminal(original, count):
    return (f'- ID: `{ROOT}`\n  Status: `done`\n'
            f'  Goal: `{common.field(common.nodes(original)[ROOT], "Goal")}`\n'
            '  Terminal: `version_object`\n'
            f'  Revision: `{REVISION}`\n  Retrieval path: `{common.TASK}`\n'
            f'  Retrieved SHA256: `{prepare.identity(original)["sha256"]}`\n'
            f'  Archived node count: `{count}`\n  Retention contract: `fsmgen_required_history`\n'
            '  Verification: `Complete original source/subtree/owner parity and genuine native controls retain in operand-task-capacity-qualified.json.gz under docs/audits/original-join-parent-acceptance-20261018. Every original contract byte remains retrievable.`\n'
            f'  Commit: `{OWNER}: retain task history for operand reconstruction`\n\n').encode()


def current_admission():
    names = execute.command(['git', 'ls-files', '-z', '--', 'doctrine/']).decode().split('\0')
    names = sorted(name for name in names if name.endswith(('.json', '.jsonl')))
    assert names and len(names) == len(set(names)), 'complete tracked current registry namespace'
    sources = {name: execute.read(name) for name in names}
    assert not any(common.selected(row['owner'], ROOT) for row in common.owner_census(sources)), 'no hidden current registry owner'
    return sources


def derive(write, admission):
    members = epoch.tree(REVISION)[1]
    names = sorted(name for name in members if name.startswith('doctrine/') and name.endswith(('.json', '.jsonl')))
    sources = epoch.batch(REVISION, [*names, common.TASK, common.CHECKER, common.HISTORY, common.RETENTION,
        'docs/audits/task-terminal-rollover-20261011/common.py', 'docs/audits/task-terminal-rollover-20261011/verify.py'])
    original = sources[common.TASK]
    graph = common.nodes(original)
    owners = common.owner_census(sources)
    subtree = {name: raw for name, raw in graph.items() if common.selected(name, ROOT)}
    assert len(subtree) > 1 and all(common.field(raw, 'Status') == 'done' and b'  Terminal:' not in raw for raw in subtree.values())
    assert not any(common.selected(row['owner'], ROOT) for row in owners), 'no hidden fixed registry owner'
    assert admission and all(name.startswith('doctrine/') and name.endswith(('.json', '.jsonl')) for name in admission)
    assert not any(common.selected(row['owner'], ROOT) for row in common.owner_census(admission)), 'no hidden captured admission owner'
    before_path, after_path = BASE / 'operand-task-before.md.gz', BASE / 'operand-task-compacted.md.gz'
    if write:
        before = execute.read(common.TASK)
        compacted = before
        live = common.nodes(before)
        for name, raw in subtree.items():
            assert live[name] == raw, 'whole original selected node unchanged'
            compacted = compacted.replace(raw, terminal(original, len(subtree)) if name == ROOT else b'', 1)
        for path, raw in ((before_path, before), (after_path, compacted)):
            with execute.safe(path).open('xb') as stream:
                stream.write(gzip.compress(raw, mtime=0))
        execute.safe(common.TASK).write_bytes(compacted)
    else:
        before = gzip.decompress(execute.read(before_path))
        compacted = gzip.decompress(execute.read(after_path))
    prior, after = common.nodes(before), common.nodes(compacted)
    assert after[ROOT] == terminal(original, len(subtree))
    rebuilt = {name: raw for name, raw in after.items() if name != ROOT}
    rebuilt.update(subtree)
    assert rebuilt == prior, 'every complete original/current node reconstructs'
    expected = before
    for name, raw in subtree.items():
        expected = expected.replace(raw, terminal(original, len(subtree)) if name == ROOT else b'', 1)
    assert compacted == expected, 'all other prefix/footer/task bytes exact'
    for name in ('common.py', 'verify.py'):
        path = 'docs/audits/task-terminal-rollover-20261011/' + name
        assert execute.read(path) == sources[path], 'unchanged supporting bookkeeping instrument'
    # A fresh module instance configures only this independent bookkeeping
    # oracle. None of the selected-epoch semantic readers are loaded.
    spec = importlib.util.spec_from_file_location('operand_capacity_native_oracle',
        'docs/audits/task-terminal-rollover-20261011/verify.py')
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    native.REVISION, native.ROOTS, native.BASE = REVISION, (ROOT,), BASE / 'operand-task-controls'
    native.SCRATCH = Path('.artifacts/operand-task-capacity')
    independent = native.independent({common.TASK: original}, dict(original=original, before=before, compacted=compacted))
    # The separate eligibility control uses the same exact source population.
    common.REVISION = REVISION
    controls = native.controls(compacted, sources, retain=write)
    return dict(revision=REVISION, root=ROOT, owner=OWNER,
        original=prepare.blob(original), before=prepare.blob(before), compacted=prepare.blob(compacted),
        registries={name: prepare.blob(sources[name]) for name in names},
        admission_registry_sources={name: prepare.blob(raw) for name, raw in sorted(admission.items())},
        admission_scope='Complete tracked Git-index registry namespace observed at the explicit admission capture; saved recovery uses these retained bytes. --current checks live eligibility separately. The initial proof did not retain its live admission bytes and is not replaced retroactively.',
        owners=owners, subtree={name: prepare.blob(raw) for name, raw in subtree.items()},
        independent=independent, controls=controls,
        programme=prepare.blob(execute.read(BASE / 'operand_task_capacity.py')),
        scope='Exact fixed-source terminal retention and independent complete node parity; native version/digest/count/goal/retrieval/node and synthetic live-owner controls. Full source and subtree overlap; no original bytes are lost. Product/source closure and runtime authority do not follow.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--capture-admission', action='store_true', help='qualify existing source snapshots with a fresh complete admission capture')
    mode.add_argument('--current', action='store_true', help='also check the complete live tracked registry namespace')
    args = parser.parse_args()
    capture = args.write or args.capture_admission
    saved = None if capture else json.loads(gzip.decompress(execute.read(PATH)))
    admission = current_admission() if capture else {
        name: prepare.unblob(blob) for name, blob in saved['admission_registry_sources'].items()}
    if args.current:
        current_admission()
    result = derive(args.write, admission)
    if capture:
        execute.save(PATH, result)
    else:
        bounded.strict_equal(saved, result)
    print('Exact completed task subtree, whole-source/node reconstruction and genuine native controls pass.')
