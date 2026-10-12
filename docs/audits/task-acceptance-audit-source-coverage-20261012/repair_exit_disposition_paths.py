"""Repair only the rejected native-exit disposition's locality and ordering."""
from pathlib import Path
import json

BASE = Path('docs/audits/task-acceptance-audit-source-coverage-20261012')
REGISTRY = Path('doctrine/claim_verification/dispositions.jsonl')
CANDIDATE = 'published-a8de5f1e3a283483d3bcf130'
before = REGISTRY.read_text()
rows = list(map(json.loads, before.splitlines()))
selected = [row for row in rows if row.get('candidate_id') == CANDIDATE]
assert len(selected) == 1
row = selected[0]
repaired = 0
for leg in ('rederive', 'falsify', 'durability'):
    for key in ('producer_paths', 'oracle_paths', 'watcher_paths'):
        if key not in row[leg]:
            continue
        paths = []
        for raw in row[leg][key]:
            path = Path(raw)
            if path.is_absolute():
                relative = path.relative_to(Path.cwd())
                assert relative == BASE / 'focused-index-actual.json'
                path = relative
                repaired += 1
            assert path.is_file() and not path.is_symlink()
            paths.append(path.as_posix())
        row[leg][key] = sorted(set(paths))
assert repaired == 2
after = '\n'.join(json.dumps(row, sort_keys=True, separators=(',', ':')) for row in rows) + '\n'
with (BASE / 'claim-exit-path-repair.json').open('x') as stream:
    json.dump(dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.1',
                   first_native='staged-repaired-actual.json', actual_status=1, expected_status=0,
                   cause='Python __file__ produced absolute BASE; path arrays were not sorted.',
                   before=before, after=after,
                   condition='Exact local-path/order repair. The first writer and native '
                             'failure retain; no claim evidence or completeness rule changes.'),
              stream, sort_keys=True, separators=(',', ':'))
    stream.write('\n')
REGISTRY.write_text(after)
print('Native-exit disposition paths are repository-relative and sorted.')
