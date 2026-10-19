"""Retain a completed task subtree to make this source slice signoff-safe."""
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

REVISION = 'c862c27c5f9955d98d4d732fe29c33032532cad8'
ROOT = common.TREE + '.72'
BASE = execute.AUDIT
PATH = BASE / 'caller-task-capacity-qualified.json.gz'
OWNER = ('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.1.2')


def terminal(original, count):
    return (f'- ID: `{ROOT}`\n  Status: `done`\n'
            f'  Goal: `{common.field(common.nodes(original)[ROOT], "Goal")}`\n'
            '  Terminal: `version_object`\n'
            f'  Revision: `{REVISION}`\n  Retrieval path: `{common.TASK}`\n'
            f'  Retrieved SHA256: `{prepare.identity(original)["sha256"]}`\n'
            f'  Archived node count: `{count}`\n  Retention contract: `fsmgen_required_history`\n'
            '  Verification: `Complete original source/subtree/owner parity and genuine native controls retain in caller-task-capacity-qualified.json.gz under docs/audits/original-join-parent-acceptance-20261018. Every original contract byte remains retrievable.`\n'
            f'  Commit: `{OWNER}: qualify caller namespace fixed module closure`\n\n').encode()


def derive(write):
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
    current_registries = {name: execute.read(name) for name in names}
    assert not any(common.selected(row['owner'], ROOT) for row in common.owner_census(current_registries)), 'no hidden current registry owner'
    before_path, after_path = BASE / 'caller-task-before.md.gz', BASE / 'caller-task-compacted.md.gz'
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
    spec = importlib.util.spec_from_file_location('caller_capacity_native_oracle',
        'docs/audits/task-terminal-rollover-20261011/verify.py')
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    native.REVISION, native.ROOTS, native.BASE = REVISION, (ROOT,), BASE / 'caller-task-controls'
    native.SCRATCH = Path('.artifacts/caller-task-capacity')
    independent = native.independent({common.TASK: original}, dict(original=original, before=before, compacted=compacted))
    # The separate eligibility control uses the same exact source population.
    common.REVISION = REVISION
    controls = native.controls(compacted, sources, retain=write)
    return dict(revision=REVISION, root=ROOT, owner=OWNER,
        original=prepare.blob(original), before=prepare.blob(before), compacted=prepare.blob(compacted),
        registries={name: prepare.blob(sources[name]) for name in names},
        owners=owners, subtree={name: prepare.blob(raw) for name, raw in subtree.items()},
        independent=independent, controls=controls,
        programme=prepare.blob(execute.read(BASE / 'caller_task_capacity.py')),
        scope='Exact fixed-source terminal retention and independent complete node parity; native version/digest/count/goal/retrieval/node and synthetic live-owner controls. Full source and subtree overlap; no original bytes are lost. Product/source closure and runtime authority do not follow.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    result = derive(args.write)
    if args.write:
        execute.save(PATH, result)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), result)
    print('Exact completed task subtree, whole-source/node reconstruction and genuine native controls pass.')
