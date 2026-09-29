"""Verify the immutable aggregate-port request baseline, not a future compiler version."""
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
    assert set(products) == {'baseline-good', 'record-port', 'record-port-field-guard'}
    diagnostic = "interface port 'lmp_in' references aggregate type 'lmp_t'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables"
    for case in ('record-port', 'record-port-field-guard'):
        for query, result in products[case]['queries'].items():
            actual = result['native']['stderr'] if query == 'schedule' else json.dumps(result['report']['diagnostics'])
            assert diagnostic in actual
    baseline = products['baseline-good']
    schedule = baseline['queries']['schedule']['report']
    assert schedule['state_count'] == 3
    assert [row for row in schedule['inferred_storage'] if row['name'] == 'last_lmp'] == [
        {'kind': 'register', 'name': 'last_lmp', 'role': 'actor_storage', 'width': 16,
         'type': 'lmp_t', 'type_kind': 'record'}]
    assert baseline['storage_type'] == {
        'kind': 'record', 'width': 16, 'signed': 0, 'member_order': ['subtype', 'payload'],
        'members': {'subtype': {'kind': 'bits', 'width': 4, 'signed': 0},
                    'payload': {'kind': 'bits', 'width': 12, 'signed': 0}}}
    carrier = baseline['scheduled_files']['link_rx.fsm']
    for fragment in ('(type lmp_t (record (subtype (bits 4)) (payload (bits 12))))',
                     '(last_lmp lmp_t)', '(<- (last_lmp.subtype subtype_in))'):
        assert fragment in carrier
    old = json.loads(next(row['text'] for row in packet['files']
                          if row['path'] == 'expected/baseline-good.strict-check.json'))
    current = copy.deepcopy(baseline['queries']['check']['report'])
    assert current['source'].pop('reset_provenance') == [{'domain': None, 'origin': 'explicit'}]
    for key in ('input', 'resolved_path'):
        assert old['source'][key] == '<FSMGEN_ROOT>/scratch-bundles/sf-isf-aggregate-interface-ports/sources/fsmgen-input/baseline-good.isf'
        assert current['source'][key] == 'docs/audits/specforge-aggregate-intake-20260930/baseline-good.isf'
        old['source'][key] = current['source'][key]
    assert current == old, 'pre-existing baseline check fields changed'


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
    for mutation in ('count', 'storage', 'carrier', 'order', 'failure', 'provenance'):
        changed = copy.deepcopy(products)
        baseline = changed['baseline-good']
        if mutation == 'count':
            baseline['queries']['schedule']['report']['state_count'] = 4
        elif mutation == 'storage':
            baseline['queries']['schedule']['report']['inferred_storage'][0]['width'] = 15
        elif mutation == 'carrier':
            baseline['scheduled_files']['link_rx.fsm'] = baseline['scheduled_files']['link_rx.fsm'].replace('last_lmp.subtype subtype_in', 'last_lmp.payload subtype_in')
        elif mutation == 'order':
            baseline['storage_type']['member_order'].reverse()
        elif mutation == 'failure':
            changed['record-port']['queries']['check']['report']['success'] = True
        else:
            baseline['queries']['check']['report']['source']['reset_provenance'][0]['origin'] = 'legacy_default'
        # Corrupt matching reports together; parity is not the semantic oracle.
        if mutation not in ('carrier', 'order'):
            case = 'record-port' if mutation == 'failure' else 'baseline-good'
            query = 'check' if mutation in ('failure', 'provenance') else 'schedule'
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
    print('aggregate-port baseline: identities, complete reports, actual typed storage carrier and hostile controls PASS')


if __name__ == '__main__':
    main()
