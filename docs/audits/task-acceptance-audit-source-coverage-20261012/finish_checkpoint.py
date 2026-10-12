"""TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.1 live-document delivery."""
from pathlib import Path
import argparse
import glob
import gzip
import json
import subprocess

BASE = Path(__file__).parent
OWNER = 'TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.1'
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')

def metrics(bodies):
    rows = [(len(body), body.count(b'\n'), max(map(len, body.splitlines()), default=0))
            for body in bodies.values()]
    return dict(files=len(rows), bytes_total=sum(r[0] for r in rows),
                lines_total=sum(r[1] for r in rows),
                bytes_each=max((r[0] for r in rows), default=0),
                lines_each=max((r[1] for r in rows), default=0),
                line_bytes_each=max((r[2] for r in rows), default=0))

def git(*arguments):
    return subprocess.check_output(['git', *arguments])

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('label')
    args = parser.parse_args()
    assert args.label and all(c in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in args.label)
    before = REGISTRY.read_bytes()
    rows = list(map(json.loads, before.splitlines()))
    tracked = set(git('ls-tree', '-r', '--name-only', 'HEAD').decode().splitlines())
    measured = {}
    for row in rows:
        surface = row.get('surface_id')
        if surface not in {'task_evidence', 'shipped_behavior', 'knowledge_cards',
                           'fact_index', 'fact_index_shards'}:
            continue
        names = sorted({name for pattern in row['targets'] for name in glob.glob(pattern)
                        if Path(name).is_file()})
        current = {name: Path(name).read_bytes() for name in names}
        baseline = {name: git('show', 'HEAD:' + name) for name in names if name in tracked}
        actual, original = metrics(current), metrics(baseline)
        measured[surface] = dict(before=original, after=actual, members=names)
        for axis, value in actual.items():
            ceiling = row['enforcement_ceilings'].get(axis)
            assert ceiling is None or value <= ceiling, (surface, axis, value, ceiling)
        if surface == 'task_evidence':
            row['transition']['max_growth'] = {
                axis: max(0, value + row['transition']['ratchet_step'][axis]
                          - row['baseline'][axis]) for axis, value in actual.items()}
        elif surface == 'shipped_behavior':
            axes = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(
                authority_id='TASK-ACCEPTANCE-INDEX-CHECKPOINT-20261012', owner=OWNER,
                baseline={axis: original[axis] for axis in axes},
                delta={axis: actual[axis] - original[axis] for axis in axes},
                rationale='Document bounded same-repository index policy, native checker truth, '
                          'synthetic retention boundary and open GHDL/audit dependencies. '
                          'Preserve existing facts, runnable commands and unchanged ceilings.')
        else:
            transition = row.get('transition')
            if transition:
                for axis, value in actual.items():
                    allowed = transition['max_growth'].get(axis)
                    base = row['baseline'].get(axis)
                    assert base is None or allowed is None or value <= base + allowed, (
                        surface, axis, value, base, allowed)
    after = b''.join((json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n').encode()
                     for row in rows)
    names = ['MEMORY.md', 'docs/TASK_TREE.md',
             'docs/tasks/TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.md',
             'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md',
             'docs/knowledge/task-acceptance-portable-contract.md', str(REGISTRY)]
    snapshots = {name: dict(before=git('show', 'HEAD:' + name).decode() if name in tracked else None,
                            after=(after if name == str(REGISTRY) else Path(name).read_bytes()).decode())
                 for name in names}
    record = dict(owner=OWNER, revision=git('rev-parse', 'HEAD').decode().strip(),
                  metrics=measured, snapshots=snapshots,
                  condition='Complete declared membership and six byte/line/file axes. '
                            'No ceiling or Knowledge Map allowance increase. '
                            'The fresh book aggregate authority uses committed HEAD as baseline.')
    with (BASE / (args.label + '.json.gz')).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(record, sort_keys=True).encode(), mtime=0))
    REGISTRY.write_bytes(after)
    print(json.dumps({name: {key: value for key, value in row.items() if key != 'members'}
                      for name, row in measured.items()}, sort_keys=True))

if __name__ == '__main__':
    main()
