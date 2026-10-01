"""Authenticate conservative private writer admission without replaying HDL."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = '6b39c7d18305697021135dad6c6b1902d6644e61'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def validate_probe(report):
    cases = {row['case']: row for row in report['cases']}
    expected = {'sole': (True, 1), 'ordered': (True, 2), 'competing': (False, 2),
                'roots': (True, 2), 'rule': (True, 1), 'generated': (False, None)}
    assert len(report['cases']) == len(cases) == len(expected)
    assert cases.keys() == expected.keys()
    for name, (accepted, count) in expected.items():
        row = cases[name]
        assert type(row['admitted']) is bool and row['admitted'] is accepted
        assert row['caller_unchanged'] is True
        assert '(output packet (width 5))' in row['source']
        assert row['actor']['actor_name'] == row['ir']['actor_name'] == name
        if count is None:
            assert row['inventory'] is None
            assert len(row['ir']['children']) == 1 and len(row['ir']['spawn_instances']) == 2
            assert 'generated record-output mappings' in row['reason']
            continue
        writers = row['inventory']['writers']
        assert len(writers) == count
        actual = []
        for kind, key in [('state', 'states'), ('dt', 'dt_blocks')]:
            for container in row['ir'][key]:
                for index, assignment in enumerate(container['assignments']):
                    if assignment['lhs'] in ('packet', 'spare'):
                        actual.append((kind, container, index, assignment))
        assert len(actual) == count
        for writer, (kind, container, index, assignment) in zip(writers, actual):
            assert writer['assignment'] == assignment
            assert writer['activation']['assignment_index'] == index
            assert writer['owner']['container_kind'] == kind
            assert writer['owner']['container_name'] == container['name']
            assert [writer['target'][key] for key in ['module', 'root', 'low', 'high', 'width']] == [name, assignment['lhs'], 0, 4, 5]
        if name == 'competing':
            assert {w['owner']['source_name'] for w in writers} == {'left', 'right'}
            assert {w['assignment']['rhs'] for w in writers} == {'held'}
            assert 'cannot admit overlapping writers' in row['reason']
        if name == 'ordered':
            assert {w['owner']['source_name'] for w in writers} == {'main'}
            assert len({w['owner']['container_name'] for w in writers}) == 2
        if name == 'roots':
            assert {w['target']['root'] for w in writers} == {'packet', 'spare'}


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['baseline_revision'] == BASE
    assert set(manifest['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in manifest['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, item in manifest['baseline_sources'].items():
        blob = subprocess.check_output(['git', 'rev-parse', BASE + ':' + path], cwd=ROOT).decode().strip()
        assert blob == item['git_blob']
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == item['sha256']
    parent = ROOT / 'docs/audits/record-output-writer-inventory-20261001'
    assert set(manifest['parent_members']) == {p.name for p in parent.iterdir() if p.is_file()}
    for name, digest in manifest['parent_members'].items():
        assert sha((parent / name).read_bytes()) == digest
    for name, projection in manifest['receipt_projections'].items():
        assert len((HERE / name).read_bytes()) == projection['raw_bytes'] - projection['replacement_count'] * (projection['root_prefix_bytes'] - len(b'<repo>'))
    assert all(type(code) is int for code in manifest['terminal_exit_codes'].values())
    for name, count in [('focused.txt', 'Files=1, Tests=6'), ('regression.txt', 'Files=4, Tests=24'), ('docs.txt', 'Files=3, Tests=310')]:
        text = (HERE / name).read_text()
        assert count in text and 'All tests successful.' in text and 'Result: PASS' in text
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    assert 'syntax OK' in (HERE / 'syntax.txt').read_text()
    assert 'Can\'t locate object method "assert_admitted"' in (HERE / 'before.txt').read_text()
    assert 'when requires' in (HERE / 'draft-entry.txt').read_text()
    assert 'on requires' in (HERE / 'draft-on.txt').read_text()
    old = subprocess.check_output(['git', 'show', BASE + ':perl/FSM/Scheduler/ISF/RecordOutputWriters.pm'], cwd=ROOT).decode()
    new = (HERE / 'inventory.pm.source').read_text()
    assert old[old.index('sub inventory {'):old.index('sub _records {')] == new[new.index('sub inventory {'):new.index('sub assert_admitted {')]
    assert (HERE / 'baseline-production.txt').read_text().strip() == 'perl/FSM/Scheduler/ISF/RecordOutputWriters.pm'
    current = (HERE / 'test.t.source').read_text()
    for marker in ['caller cannot omit actual writers', 'timed operators do not inherit', 'actual sole or reused generated', "['0:2:3','3:4:2']", 'complementary_conditions', 'complete unpruned inventory']:
        assert marker in current
    draft_on = (HERE / 'draft-on-test.t.source').read_text()
    corrected = (HERE / 'corrected-conditions-test.t.source').read_text()
    assert corrected == draft_on.replace("['complementary_entry', '(transaction left (on start) (set packet held)) (transaction right (on (! start)) (set packet held))']", "['complementary_conditions', '(transaction left (when start (sample start as accepted_left)) (set packet held)) (transaction right (when (! start) (sample start as accepted_right)) (set packet held))']")
    report = json.loads((HERE / 'probe.json').read_bytes())
    validate_probe(report)
    for mutate in [lambda p: p['cases'][2]['inventory']['writers'].pop(), lambda p: p['cases'][2].update(admitted=True), lambda p: p['cases'][1]['inventory']['writers'][1]['owner'].update(source_name='foreign'), lambda p: p['cases'][0].update(admitted=1)]:
        bad = copy.deepcopy(report)
        mutate(bad)
        try:
            validate_probe(bad)
        except AssertionError:
            continue
        raise AssertionError('Hostile omitted writer, false admission, owner or Boolean-kind substitution accepted')
    print('Actual complete source/IR/inventory decisions, sole/ordered/disjoint witnesses and competing/generated refusals authenticate with immutable callers. Original inventory and baseline objects, exact guard correction and terminal focus/regression/docs/book receipts remain intact; omitted writers, false admission, owner and Boolean-kind substitutions reject. No source-output or HDL promotion.')


if __name__ == '__main__':
    main()
