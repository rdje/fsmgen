"""Authenticate output-context prerequisites without source or HDL promotion."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = '8f31768d06083a1eccaec31d4b4d482eeb89e6c6'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def validate_probe(before, current):
    old = {r['case']: r for r in before['cases']}
    new = {r['case']: r for r in current['cases']}
    expected = {'literal': False, 'field': False, 'whole': True, 'sample': True,
                'foreign_domain': False, 'same_domain': True}
    assert len(before['cases']) == len(current['cases']) == len(expected)
    assert old.keys() == new.keys() == expected.keys()
    for name, accepted in expected.items():
        assert old[name]['built'] is True
        assert type(new[name]['built']) is bool and new[name]['built'] is accepted
        assert old[name]['source'] == new[name]['source']
        assert '(output placeholder (width 5)' in new[name]['source']
        output = next(p for p in new[name]['actor']['interface']['outputs'] if p['name'] == 'packet')
        assert output['type_spec']['kind'] == 'record' and int(output['width']) == 5
    assert new['literal']['reason'] == "Invalid ISF record value: transaction 'main' set whole record port copy requires declared record roots"
    assert 'record output field writes are not yet admitted' in new['field']['reason']
    assert new['foreign_domain']['reason'] == "ISF clock-domain violation: transaction 'main' set clause read signal 'packet.payload' owned by domain 'bus' from domain 'core' without a crossing primitive"
    assert old['sample']['ir'].get('signal_type_refs', {}).get('captured') is None
    ir = new['sample']['ir']
    assert type(ir['counters']['captured']) is int and ir['counters']['captured'] == 3
    alias = ir['signal_type_refs']['captured']
    assert [d for d in ir['type_declarations'] if d[1] == alias] == [
        ['type', alias, ['four_state', ['signed', ['bits', 3]]]]]


def main():
    m = json.loads((HERE / 'manifest.json').read_bytes())
    assert m['baseline_revision'] == BASE
    assert set(m['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in m['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, item in m['baseline_sources'].items():
        blob = subprocess.check_output(['git', 'rev-parse', BASE + ':' + path], cwd=ROOT).decode().strip()
        assert blob == item['git_blob']
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == item['sha256']
        assert sha((HERE / item['snapshot']).read_bytes()) == item['sha256']
    for dirname, members in m['parent_members'].items():
        parent = ROOT / 'docs/audits' / dirname
        assert set(members) == {p.name for p in parent.iterdir() if p.is_file()}
        for name, digest in members.items():
            assert sha((parent / name).read_bytes()) == digest
    for name, projection in m['receipt_projections'].items():
        assert len((HERE / name).read_bytes()) == projection['raw_bytes'] - projection['replacement_count'] * (projection['root_prefix_bytes'] - len(b'<repo>'))
    assert all(type(code) is int for code in m['terminal_exit_codes'].values())
    for name, count in [('focused.txt', 'Files=2, Tests=12'), ('regression.txt', 'Files=8, Tests=71'), ('docs.txt', 'Files=3, Tests=310')]:
        text = (HERE / name).read_text()
        assert count in text and 'All tests successful.' in text and 'Result: PASS' in text
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    assert (HERE / 'syntax.txt').read_text().count('syntax OK') == 5
    red = (HERE / 'baseline-final-test.txt').read_text()
    assert "literal whole target refuses" in red and "unqualified field target refuses" in red
    assert 'Undefined subroutine' in red and 'Result: FAIL' in red
    policy = (HERE / 'policy-before.txt').read_text()
    assert 'validation requires predicate and message' in policy
    assert 'existing malformed scalar sample selection' in policy
    old_parser = (HERE / 'baseline-parser.pm.source').read_text()
    new_parser = (HERE / 'parser.pm.source').read_text()
    assert new_parser == old_parser.replace('actor_has_record_input', 'actor_has_record_port').replace(
        'validate_actor_record_contexts(actor => $result)',
        'validate_actor_record_contexts(actor => $result, whole_output_writes_only => 1)')
    old_samples = (HERE / 'baseline-samples.pm.source').read_text()
    samples = (HERE / 'samples.pm.source').read_text()
    assert old_samples[old_samples.index('sub actor_has_record_input {'):old_samples.index('# Detached preparation only.')] == samples[samples.index('sub actor_has_record_input {'):samples.index('sub actor_has_record_port {')]
    old_admission = (HERE / 'prior-admission-test.t.source').read_text()
    current_admission = (HERE / 'admission-test.t.source').read_text()
    assert current_admission == old_admission.replace(
        "['different_values', '(transaction left (on start) (set packet held)) (transaction right (on other) (set packet 0))']",
        "['different_values', '(transaction left (on start) (set held.payload 1) (set packet held)) (transaction right (on other) (set alternate.payload 2) (set packet alternate))']").replace(
        '(storage (var held (type $type)))', '(storage (var held (type $type)) (var alternate (type $type)))')
    paths = (HERE / 'baseline-production.txt').read_text().splitlines()
    assert set(paths) == set(m['baseline_sources']) and len(paths) == 5
    before = json.loads((HERE / 'baseline-probe.json').read_bytes())
    current = json.loads((HERE / 'probe.json').read_bytes())
    validate_probe(before, current)
    for mutate in [lambda p: p['cases'][4].update(built=True), lambda p: p['cases'][3]['ir']['counters'].update(captured=1), lambda p: p['cases'][4].update(reason='a different error'), lambda p: p['cases'][0].update(built=0)]:
        bad = copy.deepcopy(current)
        mutate(bad)
        try:
            validate_probe(before, bad)
        except AssertionError:
            continue
        raise AssertionError('Hostile domain, scalar-width, primary-cause or Boolean-kind substitution accepted')
    print('Exact baseline/current parsed-role probes and final baseline RED authenticate copy/field/domain omissions and typed sample repair. Input selector and Parser declaration boundary stay exact; valid writer refinement, policy diagnosis, complete regressions/docs/book and immutable parents authenticate. Hostile domain, sample-width, cause and JSON-kind substitutions reject. No output source or HDL promotion.')


if __name__ == '__main__':
    main()
