"""Retain the complete closed inventory subtree through exact Git provenance."""
import argparse
import gzip
import importlib.util
import json
from pathlib import Path
import sys

sys.path.insert(0, 'docs/audits/task-terminal-rollover-20261011')
import common as retained

BASE = Path('docs/audits/inventory-task-rollover-20261019')
REVISION = 'b919b7f8ec74627ecb83fb80cb9d8b2f74c7f45d'
OWNER = retained.TREE + '.85'
ROOT = ('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3'
        '.2.2.3.3.2.3.3.2.1.1')
retained.REVISION, retained.OWNER, retained.ROOTS = REVISION, OWNER, (ROOT,)
retained.BASE, retained.SCRATCH = BASE, Path('.artifacts/inventory-task-rollover-20261019')
_terminal = retained.terminal


def terminal(root, source, count):
    return _terminal(root, source, count).replace(
        b'docs/audits/task-terminal-rollover-20261011', str(BASE).encode())


retained.terminal = terminal
spec = importlib.util.spec_from_file_location('retained_rollover_reader',
    'docs/audits/task-terminal-rollover-20261011/verify.py')
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)


def save(name, value):
    retained.save(BASE / name, gzip.compress(retained.canonical(value), mtime=0))


def load(name):
    return json.loads(gzip.decompress(retained.local(BASE / name).read_bytes()))


def exact(left, right):
    return retained.canonical(left) == retained.canonical(right)


def body(name):
    return gzip.decompress(retained.local(BASE / name).read_bytes())


def source_names():
    names = retained.git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    tasks = [name for name in names if retained.re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name)]
    registries = [name for name in names if name.startswith('doctrine/') and name.endswith(('.json', '.jsonl'))]
    return sorted(set(tasks + registries + [retained.CHECKER, retained.HISTORY, retained.RETENTION,
        'docs/audits/task-terminal-rollover-20261011/common.py',
        'docs/audits/task-terminal-rollover-20261011/verify.py']))


def reconstruct(sources, declared, compacted):
    assert set(sources) == set(source_names())
    assert sources == retained.frozen_sources(sources)
    owners = retained.owner_census(sources)
    original = retained.nodes(sources[retained.TASK])
    before, after = retained.nodes(declared), retained.nodes(compacted)
    assert set(before) == set(original) | {OWNER}
    expected_root = original[retained.TREE].replace(
        ('  Children: `' + retained.field(original[retained.TREE], 'Children') + '`').encode(),
        ('  Children: `' + retained.field(original[retained.TREE], 'Children') + ', ' + OWNER + '`').encode(), 1)
    assert before[retained.TREE] == expected_root
    assert all(before[name] == raw for name, raw in original.items() if name != retained.TREE)
    assert declared.replace(before[retained.TREE], original[retained.TREE], 1).replace(before[OWNER], b'', 1) == sources[retained.TASK]
    subtree = retained.eligible(original, ROOT, owners)
    assert compacted == retained.compact(declared, sources[retained.TASK], owners)
    assert after[ROOT] == terminal(ROOT, sources[retained.TASK], len(subtree))
    expanded = {name: raw for name, raw in after.items() if name != ROOT}
    expanded.update(subtree)
    assert expanded == before
    assert all(row['owner'] in after for row in owners if retained.selected(row['owner'], retained.TREE))
    assert retained.field(after[OWNER], 'Status') == 'active'
    for name in ('common.py', 'verify.py'):
        path = 'docs/audits/task-terminal-rollover-20261011/' + name
        assert retained.local(path).read_bytes() == sources[path]
    return owners, subtree


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.prepare:
        assert not args.write
        assert retained.git('rev-parse', 'HEAD').decode().strip() == REVISION
        assert set(retained.git('diff', '--name-only').decode().splitlines()) == {'MEMORY.md', 'docs/TASK_TREE.md', retained.TASK}
        sources = retained.frozen_sources(source_names())
        declared = retained.local(retained.TASK).read_bytes()
        owners = retained.owner_census(sources)
        compacted = retained.compact(declared, sources[retained.TASK], owners)
        reconstruct(sources, declared, compacted)
        retained.save(BASE / 'source.json.gz', retained.pack(sources))
        retained.save(BASE / 'declared.md.gz', gzip.compress(declared, mtime=0))
        retained.save(BASE / 'compacted.md.gz', gzip.compress(compacted, mtime=0))
        retained.local(retained.TASK).write_bytes(compacted)
        print('Exact completed inventory subtree retained; active owners and all original contract bytes reconstruct.')
    else:
        sources = retained.unpack(retained.local(BASE / 'source.json.gz').read_bytes())
        declared, compacted = body('declared.md.gz'), body('compacted.md.gz')
        owners, subtree = reconstruct(sources, declared, compacted)
        independent = native.independent(sources, dict(original=sources[retained.TASK], declared=declared, compacted=compacted))
        controls = native.controls(compacted, sources, retain=args.write)
        proof = dict(revision=REVISION, root=ROOT, owner=OWNER,
                     sources={name: retained.pin(raw) for name, raw in sources.items()},
                     owners=owners, subtree={name: retained.pin(raw) for name, raw in subtree.items()},
                     independent=independent, controls=controls,
                     programme=retained.local(BASE / 'rollover.py').read_text(),
                     scope='Complete immutable source/registry-owner and original subtree reconstruction, independent native census '
                           'and genuine unchanged-production-checker controls. Actual working set is separately measured; '
                           'retained complete source and subtree overlap. No contract/data loss, current role closure or semantic execution.')
        if args.write:
            save('proof-strict.json.gz', proof)
        else:
            assert exact(load('proof-strict.json.gz'), proof)
        print('Complete Git source/subtree/owner reconstruction and genuine native version-object controls pass.')
