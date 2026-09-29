"""Verify the immutable named-timer request baseline, not a future compiler version."""
import copy
import hashlib
import json
import re
from pathlib import Path

AUDIT = Path(__file__).resolve().parent


def verify(products, packet):
    for case, entry in products.items():
        failure = case != 'baseline-good'
        assert set(entry['queries']) == {'check', 'semantic', 'schedule'}
        for query, result in entry['queries'].items():
            native = result['native']
            assert (native['exit_code'] != 0) == failure
            assert result['wire']['exit_code'] == 0
            assert result['wire']['stderr'] == ''
            assert json.loads(result['wire']['stdout']) == result['api']
            if failure and query == 'schedule':
                assert native['stdout'] == '' and native['stderr']
                assert result['api']['error'] and result['report'] is None
                continue
            assert native['stderr'] == ''
            report = result['report']
            assert json.loads(native['stdout']) == report
            assert result['api']['result']['structuredContent']['report'] == report
            assert json.loads(result['api']['result']['content'][0]['text']) == result['api']['result']['structuredContent']
            if query != 'schedule':
                assert report['success'] == (not failure)
                assert bool(report['diagnostics']) == failure
    assert set(products) == {'baseline-good', 'named-timers', 'two-await-limits'}
    expected = {
        'named-timers': "unknown actor clause 'timers'",
        'two-await-limits': 'multiple distinct await watchdog limits are not supported by the current single watchdog counter',
    }
    for case, diagnostic in expected.items():
        for query, result in products[case]['queries'].items():
            actual = result['native']['stderr'] if query == 'schedule' else json.dumps(result['report']['diagnostics'])
            assert diagnostic in actual
    schedule = products['baseline-good']['queries']['schedule']['report']
    assert schedule['state_count'] == 4
    assert [row for row in schedule['inferred_storage'] if row['role'] == 'watchdog_counter'] == [
        {'kind': 'counter', 'name': 'pending_wd', 'role': 'watchdog_counter', 'width': 11}]
    carrier = products['baseline-good']['scheduled_files']['link_timers.fsm']
    assert '(pending_wd 11)' in carrier
    assert '(<= (pending_wd (- 1250 1)))' in carrier
    timeout = re.search(r'^  \(pending_timeout\n(.*?)^  \)', carrier, re.M | re.S)
    assert timeout
    for statement in ('(<1 (done> 1))', '(<- (last_error 1))', '(-> pending_idle_0)'):
        assert statement in timeout.group(1)
    old = json.loads(next(row['text'] for row in packet['files']
                          if row['path'] == 'observed/stdout/baseline-good-schedule.stdout'))
    current = copy.deepcopy(schedule)
    assert current.pop('reset_provenance') == [{'domain': None, 'origin': 'explicit'}]
    assert current == old, 'pre-existing baseline schedule fields changed'


def main():
    manifest = json.loads((AUDIT / 'manifest.json').read_text())
    for name, expected in manifest['files'].items():
        assert hashlib.sha256((AUDIT / name).read_bytes()).hexdigest() == expected, name
    packet = json.loads((AUDIT / 'packet.json').read_text())
    for row in packet['files']:
        data = row['text'].encode()
        assert len(data) == row['bytes']
        assert hashlib.sha256(data).hexdigest() == row['sha256']
    products = json.loads((AUDIT / 'current.json').read_text())
    for case in products:
        original = next(row for row in packet['files'] if row['path'] == 'sources/fsmgen-input/' + case + '.isf')
        assert (AUDIT / (case + '.isf')).read_bytes() == original['text'].encode()
    verify(products, packet)
    for mutation in ('count', 'counter', 'carrier', 'load', 'failure', 'provenance'):
        changed = copy.deepcopy(products)
        baseline = changed['baseline-good']
        if mutation == 'count':
            baseline['queries']['schedule']['report']['state_count'] = 3
        elif mutation == 'counter':
            baseline['queries']['schedule']['report']['inferred_storage'][0]['width'] = 12
        elif mutation == 'carrier':
            baseline['scheduled_files']['link_timers.fsm'] = baseline['scheduled_files']['link_timers.fsm'].replace('(<- (last_error 1))', '(<- (last_error 0))')
        elif mutation == 'load':
            baseline['scheduled_files']['link_timers.fsm'] = baseline['scheduled_files']['link_timers.fsm'].replace('(- 1250 1)', '1250')
        elif mutation == 'failure':
            changed['named-timers']['queries']['check']['report']['success'] = True
        else:
            baseline['queries']['schedule']['report']['reset_provenance'][0]['origin'] = 'legacy_default'
        # Corrupt all matching report copies together, so transport parity
        # cannot stand in for an independent baseline/semantic oracle.
        if mutation not in ('carrier', 'load'):
            case = 'named-timers' if mutation == 'failure' else 'baseline-good'
            query = 'check' if mutation == 'failure' else 'schedule'
            result = changed[case]['queries'][query]
            result['native']['stdout'] = json.dumps(result['report'])
            result['api']['result']['structuredContent']['report'] = copy.deepcopy(result['report'])
            result['api']['result']['content'][0]['text'] = json.dumps(result['api']['result']['structuredContent'])
            result['wire']['stdout'] = json.dumps(result['api'])
        try:
            verify(changed, packet)
        except AssertionError:
            continue
        raise AssertionError('hostile control accepted: ' + mutation)
    print('named-timer baseline: identities, complete reports, actual watchdog carrier and hostile controls PASS')


if __name__ == '__main__':
    main()
