"""Verify the immutable duration-request baseline, not a future compiler version."""
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
    assert set(products) == {'baseline-good', 'wait-in-ms', 'watchdog-in-us', 'clock-frequency'}
    schedule = products['baseline-good']['queries']['schedule']['report']
    assert schedule['state_count'] == 236
    assert len(schedule['transaction_waits']) == 1
    wait = schedule['transaction_waits'][0]
    assert wait['cycles'] == 234 and wait['count_kind'] == 'static'
    assert wait['count_source'] == 'QUIET_CYCLES'
    assert wait['counter_signal'] is None and wait['counter_width'] is None
    carrier = products['baseline-good']['scheduled_files']['link_quiet.fsm']
    names = re.findall(r'^\s*\(([A-Za-z_][A-Za-z0-9_]*)\s*$', carrier, re.M)
    assert len(names) == len(set(names)) == 236
    assert len([name for name in names if name.startswith('quiet_wait_')]) == 234
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
    for mutation in ('count', 'counter', 'carrier', 'failure', 'provenance'):
        changed = copy.deepcopy(products)
        baseline = changed['baseline-good']
        if mutation == 'count':
            baseline['queries']['schedule']['report']['state_count'] = 3
        elif mutation == 'counter':
            baseline['queries']['schedule']['report']['transaction_waits'][0]['counter_signal'] = 'invented'
        elif mutation == 'carrier':
            baseline['scheduled_files']['link_quiet.fsm'] = baseline['scheduled_files']['link_quiet.fsm'].replace('(quiet_wait_1\n', '(removed_wait_1\n')
        elif mutation == 'failure':
            changed['wait-in-ms']['queries']['check']['report']['success'] = True
        else:
            baseline['queries']['schedule']['report']['reset_provenance'][0]['origin'] = 'legacy_default'
        # Corrupt all matching report copies together, so transport parity
        # cannot stand in for an independent baseline/semantic oracle.
        if mutation != 'carrier':
            case = 'wait-in-ms' if mutation == 'failure' else 'baseline-good'
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
    print('duration baseline: identities, complete transport reports, carrier census and hostile controls PASS')


if __name__ == '__main__':
    main()
