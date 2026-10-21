"""Retain disjoint closed source-audit subtrees before the next helper capture."""
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

REVISION = '4ec13f0786c60fe073487b3dba9257253d52170e'
ROOTS = (
    'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2',
    'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.2',
)
BASE = execute.AUDIT
PATH = BASE / 'closed-task-capacity-qualified.json.gz'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.90'


def terminal(root, original, count):
    return (f'- ID: `{root}`\n  Status: `done`\n'
            f'  Goal: `{common.field(common.nodes(original)[root], "Goal")}`\n'
            '  Terminal: `version_object`\n'
            f'  Revision: `{REVISION}`\n  Retrieval path: `{common.TASK}`\n'
            f'  Retrieved SHA256: `{prepare.identity(original)["sha256"]}`\n'
            f'  Archived node count: `{count}`\n  Retention contract: `fsmgen_required_history`\n'
            '  Verification: `Complete original source/subtree/owner parity and genuine native controls retain in closed-task-capacity-qualified.json.gz under docs/audits/original-join-parent-acceptance-20261018. Every original contract byte remains retrievable.`\n'
            f'  Commit: `{OWNER}: retain closed source-audit task history`\n\n').encode()


def current_admission():
    names = execute.command(['git', 'ls-files', '-z', '--', 'doctrine/']).decode().split('\0')
    names = sorted(name for name in names if name.endswith(('.json', '.jsonl')))
    assert names and len(names) == len(set(names)), 'complete tracked current registry namespace'
    sources = {name: execute.read(name) for name in names}
    assert not any(common.selected(row['owner'], root) for row in common.owner_census(sources) for root in ROOTS), 'no hidden current registry owner'
    return sources


def derive(write, admission):
    members = epoch.tree(REVISION)[1]
    names = sorted(name for name in members if name.startswith('doctrine/') and name.endswith(('.json', '.jsonl')))
    sources = epoch.batch(REVISION, [*names, common.TASK, common.CHECKER, common.HISTORY, common.RETENTION,
        'docs/audits/task-terminal-rollover-20261011/common.py', 'docs/audits/task-terminal-rollover-20261011/verify.py'])
    original = sources[common.TASK]
    graph = common.nodes(original)
    owners = common.owner_census(sources)
    assert len(ROOTS) == len(set(ROOTS)) and all(
        not common.selected(left, right) for left in ROOTS for right in ROOTS if left != right)
    subtrees = {root: common.eligible(graph, root, owners) for root in ROOTS}
    assert all(common.field(raw, 'Status') == 'done'
               for subtree in subtrees.values() for raw in subtree.values())
    assert admission and all(name.startswith('doctrine/') and name.endswith(('.json', '.jsonl')) for name in admission)
    assert not any(common.selected(row['owner'], root) for row in common.owner_census(admission)
                   for root in ROOTS), 'no hidden captured admission owner'
    before_path, after_path = BASE / 'closed-task-before.md.gz', BASE / 'closed-task-compacted.md.gz'
    if write:
        before = execute.read(common.TASK)
        compacted = before
        live = common.nodes(before)
        for root, subtree in subtrees.items():
            for name, raw in subtree.items():
                assert live[name] == raw, 'whole original selected node unchanged'
                compacted = compacted.replace(raw, terminal(root, original, len(subtree)) if name == root else b'', 1)
        for path, raw in ((before_path, before), (after_path, compacted)):
            with execute.safe(path).open('xb') as stream:
                stream.write(gzip.compress(raw, mtime=0))
        execute.safe(common.TASK).write_bytes(compacted)
    else:
        before = gzip.decompress(execute.read(before_path))
        compacted = gzip.decompress(execute.read(after_path))
    prior, after = common.nodes(before), common.nodes(compacted)
    for root, subtree in subtrees.items():
        assert after[root] == terminal(root, original, len(subtree))
    rebuilt = {name: raw for name, raw in after.items() if name not in ROOTS}
    for subtree in subtrees.values():
        rebuilt.update(subtree)
    assert rebuilt == prior, 'every complete original/current node reconstructs'
    expected = before
    for root, subtree in subtrees.items():
        for name, raw in subtree.items():
            expected = expected.replace(raw, terminal(root, original, len(subtree)) if name == root else b'', 1)
    assert compacted == expected, 'all other prefix/footer/task bytes exact'
    for name in ('common.py', 'verify.py'):
        path = 'docs/audits/task-terminal-rollover-20261011/' + name
        assert execute.read(path) == sources[path], 'unchanged supporting bookkeeping instrument'
    # A fresh module instance configures only this independent bookkeeping
    # oracle. None of the selected-epoch semantic readers are loaded.
    spec = importlib.util.spec_from_file_location('closed_task_capacity_native_oracle',
        'docs/audits/task-terminal-rollover-20261011/verify.py')
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    native.REVISION = REVISION
    independent = native.independent({common.TASK: original}, dict(original=original, before=before, compacted=compacted))
    # Exercise each retained terminal against the genuine unchanged checker.
    common.REVISION = REVISION
    controls = {}
    for index, root in enumerate(ROOTS):
        native.ROOTS = (root,)
        native.BASE = BASE / ('closed-task-controls-' + str(index))
        native.SCRATCH = Path('.artifacts/closed-task-capacity-20261021-' + str(index))
        controls[root] = native.controls(compacted, sources, retain=write)
    return dict(revision=REVISION, roots=list(ROOTS), owner=OWNER,
        original=prepare.blob(original), before=prepare.blob(before), compacted=prepare.blob(compacted),
        registries={name: prepare.blob(sources[name]) for name in names},
        admission_registry_sources={name: prepare.blob(raw) for name, raw in sorted(admission.items())},
        admission_scope='Complete tracked Git-index registry namespace observed at the explicit admission capture; saved recovery uses these retained bytes. --current checks live eligibility separately. Current eligibility is an explicit separate check, never a claim that dated registry bytes describe now.',
        owners=owners, subtrees={root: {name: prepare.blob(raw) for name, raw in subtree.items()}
                                  for root, subtree in subtrees.items()},
        independent=independent, controls=controls,
        programme=prepare.blob(execute.read(BASE / 'closed_task_capacity.py')),
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
