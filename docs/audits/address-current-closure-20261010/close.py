"""Produce the complete closure witness and exact current guidance changes."""
import json
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from contracts import (ADDRESS, ARCHIVES, BASE, CLOSED, MODULE, NAMESPACES, OPEN, OWNER,
                       PARENT, READERS, REGISTRY, REVISION, SCOPE, TASK, aggregate,
                       baseline, contract, git, load, need, nodes, objects, paths,
                       pin, read, root, wanted)


def main():
    root()
    need(not (BASE / 'acceptance.json').exists(), 'retain first whole closure witness')
    canonical_paths, book_paths, before = baseline()
    names = sorted(p for folder in NAMESPACES for p in paths('docs/audits/' + folder + '-20261010'))
    fixed = objects(names)
    need(all(read(p) == raw for p, raw in fixed.items()), 'complete unchanged historical prerequisite namespaces')
    old_nodes = nodes(before[TASK]); current_nodes = nodes(read(TASK))
    need(all(contract(old_nodes[key]) == contract(current_nodes[key]) for key in CLOSED), 'unchanged whole closure contracts')
    checks = load(BASE / 'checks.json')
    need(all(type(checks[name]['status']) is int and checks[name]['status'] == 0 for name in READERS),
         'complete fresh semantic success before publication closure')
    source = runpy.run_path(PARENT + '/source.py'); registry, binding = source['rebuild']()
    data = {name: json.loads(read(row['path'])) for name, row in registry.items() if row['path'].endswith('.json')}
    produce = runpy.run_path(PARENT + '/audit.py')['produce']
    raw_parent = produce(data, registry, binding, load(PARENT + '/checks.json'))
    need(raw_parent == load(PARENT + '/acceptance.json'), 'whole original qualified raw-parent witness')
    result = {'revision': REVISION, 'owner': OWNER, 'scope': SCOPE, 'open': OPEN,
              'contracts': {key: contract(old_nodes[key]) for key in sorted(CLOSED)},
              'completed': {key: block for key, block in old_nodes.items() if key.startswith(ADDRESS + '.')
                            and key not in CLOSED and '  Status: `done`\n' in block},
              'historical_members': {p: pin(raw) for p, raw in fixed.items()},
              'source_products': {p: pin(fixed[p]) for p in names if p.endswith('/hypotheses.json')},
              'raw_parent': raw_parent, 'actual_readers': {name: checks[name] for name in READERS},
              'canonical': {p: pin(before[p]) for p in canonical_paths},
              'archives': pin(before[ARCHIVES])}
    module, books, _, _ = wanted(before)
    need(read(MODULE) == before[MODULE] and all(read(p) == before[p] for p in book_paths)
         and read(REGISTRY) == before[REGISTRY], 'whole unchanged publication input before exact closure writes')
    rows = list(map(json.loads, before[REGISTRY].splitlines()))
    next(r for r in rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change'] = aggregate(before, books)
    Path(MODULE).write_bytes(module)
    for p in book_paths:
        if books[p] != before[p]:
            Path(p).write_bytes(books[p])
    Path(REGISTRY).write_text(''.join(json.dumps(r, sort_keys=True) + '\n' for r in rows))
    (BASE / 'acceptance.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    command = ['git', '--no-replace-objects', 'log', '-1', '--format=%H %s', '-S',
               'Final address-container', '--', MODULE]
    actual = subprocess.run(command, capture_output=True, text=True)
    (BASE / 'root-cause.json').write_text(json.dumps({'command': command, 'status': actual.returncode,
        'stdout': actual.stdout, 'stderr': actual.stderr}, sort_keys=True, indent=2) + '\n')
    need(actual.returncode == 0 and not actual.stderr and actual.stdout.startswith(REVISION + ' '),
         'complete actual publication predecessor and remaining-container contract history')
    print('PASS complete closure witness and exact finite address book/reader status change; independent whole acceptance remains required.')


if __name__ == '__main__':
    main()
