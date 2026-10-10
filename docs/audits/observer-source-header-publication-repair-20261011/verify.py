"""Conserve the entire first claim registry while ordering only new evidence arrays."""
import copy
import gzip
import hashlib
import json
import sys
from pathlib import Path

BASE = Path('docs/audits/observer-source-header-publication-repair-20261011')
SOURCE = Path('docs/audits/observer-source-headers-20261011')
IDENTIFIER = 'published-9f1399675253281f17f34832'


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def rows(raw):
    return [json.loads(line) for line in raw.splitlines()]


def saved(name, epoch):
    return gzip.decompress((BASE / (name + '.' + epoch + '.gz')).read_bytes())


def qualify(candidate, before):
    expected = copy.deepcopy(before)
    selected = next(r for r in expected if r.get('candidate_id') == IDENTIFIER)
    for leg, field in load(BASE / 'changed-arrays.json'):
        original = selected[leg][field]
        need(len(original) == len(set(original)), 'original evidence paths unique')
        selected[leg][field] = sorted(original)
    need(candidate == expected, 'entire canonical-only disposition repair')
    for row in candidate[1:]:
        for leg, field in [('rederive', 'producer_paths'), ('falsify', 'oracle_paths'),
                           ('durability', 'producer_paths'), ('durability', 'watcher_paths')]:
            if leg in row and field in row[leg]:
                values = row[leg][field]
                need(values == sorted(set(values)), 'all actual evidence arrays sorted and unique')
    return selected


def main():
    need(sys.argv[1:] in ([], ['--current']), 'explicit dated or current repair role')
    before = rows(saved('dispositions.jsonl', 'before'))
    after = rows(saved('dispositions.jsonl', 'after'))
    added = load(SOURCE / 'claim-disposition-added.json')
    need(next(r for r in before if r.get('candidate_id') == IDENTIFIER) == added,
         'whole first rejected disposition remains unchanged')
    prior = rows(gzip.decompress((SOURCE / 'claim-dispositions-before.jsonl.gz').read_bytes()))
    need(before[0] == prior[0] and sorted(before[1:], key=lambda r:r['candidate_id']) ==
         sorted([*prior[1:], added], key=lambda r:r['candidate_id']), 'every complete prior row conserves')
    selected = qualify(after, before)
    need(selected == load(BASE / 'repaired-disposition.json'), 'whole final disposition')
    rejected = load(BASE / 'first-staged-gate.json')
    need(type(rejected['status']) is int and rejected['status'] != 0 and
         'must be sorted and unique' in rejected['stderr'], 'actual first ordering refusal retains')
    controls = []
    for name in ['first-unsorted', 'lost-prior-row', 'wrong-original-profile', 'lost-evidence-path']:
        candidate = copy.deepcopy(before if name == 'first-unsorted' else after)
        row = next(r for r in candidate if r.get('candidate_id') == IDENTIFIER)
        if name == 'lost-prior-row':
            candidate.pop(1)
        elif name == 'wrong-original-profile':
            row['rederive']['evidence'] += ' Original runtime settings measured.'
        elif name == 'lost-evidence-path':
            row['durability']['producer_paths'].pop()
        need(candidate != after, 'genuine complete repair intervention')
        try:
            qualify(candidate, before)
        except ValueError as error:
            need(str(error) == 'entire canonical-only disposition repair', 'intended repair refusal')
            controls.append(dict(name=name, status='rejected', cause=str(error),
                                 whole_candidate=candidate))
        else:
            raise ValueError('accepted invalid ordering repair')
    # The task changes only its same-owner verification. Original contracts and
    # all other nodes remain complete, and only the measured byte allowance moves.
    old_task = saved('SEMANTIC-INTROSPECTION-MCP-FRONTIER.md', 'before')
    new_task = saved('SEMANTIC-INTROSPECTION-MCP-FRONTIER.md', 'after')
    insertion = ('First staged gate refuses unsorted evidence-path arrays in the new profile claim disposition. '
                 'Whole first registry/gate and immutable header seal retain; sort only the four unique path arrays, '
                 'independently conserve every prior row and semantic field, and qualify genuine ordering/member/content '
                 'controls in docs/audits/observer-source-header-publication-repair-20261011. Final claim/native/source/staged '
                 'and normal gates require the canonical repair. ')
    need(old_task.count(b'Only the unchanged source-header parent closes;') == 1 and
         new_task == old_task.replace(b'Only the unchanged source-header parent closes;',
                    (insertion + 'Only the unchanged source-header parent closes;').encode(), 1),
         'exact same-owner task verification extension')
    original = rows(saved('surfaces.jsonl', 'before'))
    need(original == load(SOURCE / 'publication-proof.json')['after'], 'whole first publication declaration')
    expected = copy.deepcopy(original)
    task = next(r for r in expected if r.get('surface_id') == 'task_evidence')
    dimensions = load(SOURCE / 'publication-metrics.json')['task']
    dimensions['bytes_total'] += len(new_task) - len(old_task)
    metrics = load(BASE / 'metrics.json')
    need(dimensions == metrics['task'], 'independent complete task dimension delta')
    for key, value in dimensions.items():
        if value > task['baseline'][key] + task['transition']['max_growth'][key]:
            task['transition']['max_growth'][key] = min(value + task['transition']['ratchet_step'][key],
                task['enforcement_ceilings'][key]) - task['baseline'][key]
    need(expected == rows(saved('surfaces.jsonl', 'after')) and task == metrics['task_declaration'],
         'entire unchanged surfaces and ceilings with exact measured task allowance')
    need(saved('MEMORY.md', 'before') == saved('MEMORY.md', 'after'), 'unchanged bounded resume')
    if sys.argv[1:]:
        for filename, path in [('dispositions.jsonl', 'doctrine/claim_verification/dispositions.jsonl'),
                               ('surfaces.jsonl', 'doctrine/live_document_size/surfaces.jsonl'),
                               ('SEMANTIC-INTROSPECTION-MCP-FRONTIER.md', 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'),
                               ('MEMORY.md', 'MEMORY.md')]:
            need(Path(path).read_bytes() == saved(filename, 'after'), 'complete current repaired source')
        data = [p.read_bytes() for p in sorted({p for pattern in task['targets'] for p in Path('.').glob(pattern)})]
        actual = dict(files=len(data), lines_total=sum(x.count(b'\n') for x in data), bytes_total=sum(map(len,data)),
                      lines_each=max(x.count(b'\n') for x in data), bytes_each=max(map(len,data)),
                      line_bytes_each=max(len(line.rstrip(b'\r')) for x in data for line in x.split(b'\n')))
        need(actual == dimensions, 'complete current task collection')
    proof = dict(controls=controls, result='canonical ordering only; all source-header semantics and ceilings conserve')
    raw = (json.dumps(proof, sort_keys=True, separators=(',', ':')) + '\n').encode()
    if (BASE / 'proof.json').exists():
        need((BASE / 'proof.json').read_bytes() == raw, 'complete immutable repair proof')
    else:
        (BASE / 'proof.json').write_bytes(raw)
    if (BASE / 'manifest.json').exists():
        need(load(BASE / 'manifest.json') == {str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name not in ('manifest.json', 'checks.json')}, 'whole immutable repair namespace')
    print('PASS complete canonical-only claim repair, actual first refusal, whole controls, source conservation and unchanged ceilings.')


if __name__ == '__main__':
    main()
