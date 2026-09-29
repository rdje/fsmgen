"""Offline evidence checks; no checkout outside FSMGen and no HDL execution."""
import copy
import hashlib
import json
import re
from pathlib import Path

AUDIT = Path(__file__).resolve().parent


def verify(products):
    def report(case, query):
        return products[case]['queries'][query]['report']

    expected = {'name': 'rst_n', 'kind': 'async', 'polarity': 'active_low'}
    for case in ('baseline-good', 'omitted-reset', 'clock-domain-no-reset'):
        assert report(case, 'check')['success'] is True
        schedule = report(case, 'schedule')
        assert schedule['reset'] == (None if case == 'clock-domain-no-reset' else expected)
        contract = report(case, 'semantic')['semantic']['explicit_system_contract']
        assert contract == {
            'clock': 'clk', 'reset': None if case == 'clock-domain-no-reset' else 'rst_n',
            'reset_active_level': None if case == 'clock-domain-no-reset' else 0,
            'reset_keyword': None if case == 'clock-domain-no-reset' else 'areset',
            'reset_kind': None if case == 'clock-domain-no-reset' else 'async',
        }
        for language in ('systemverilog', 'verilog'):
            generated = products[case]['generated'][language]
            assert generated['command']['exit_code'] == 0
            hdl = [text for path, text in generated['files'].items()
                   if path.endswith(('.sv', '.v'))]
            assert len(hdl) == 1
            hdl = re.sub(r'//[^\n]*', '', hdl[0])
            assert not re.search(r'\binitial\b', hdl)
            assert re.search(r'reg\s+\[1:0\]\s+current_state,\s*next_state\s*;', hdl)
            state_writes = re.findall(r'\bcurrent_state\s*<=\s*([^;]+);', hdl)
            if case == 'clock-domain-no-reset':
                assert not re.search(r'\brst_n\b|\bnegedge\b', hdl)
                assert state_writes == ['next_state']
                assert re.search(r'next_state\s*=\s*current_state\s*;', hdl)
            else:
                assert re.search(r'@\(posedge clk or negedge rst_n\)', hdl)
                assert state_writes == ['MAIN_IDLE_0', 'next_state']
    for query in ('check', 'semantic', 'schedule'):
        a = copy.deepcopy(report('baseline-good', query))
        b = copy.deepcopy(report('omitted-reset', query))
        if query != 'schedule':
            for value in (a, b):
                value['source']['input'] = 'CASE.isf'
                value['source']['resolved_path'] = 'CASE.isf'
        assert a == b, query
    return True


def main():
    manifest = json.loads((AUDIT / 'manifest.json').read_text())
    for path, expected in manifest['files'].items():
        assert hashlib.sha256((AUDIT / path).read_bytes()).hexdigest() == expected, path
    packet = json.loads((AUDIT / 'packet.json').read_text())
    for entry in packet['files']:
        content = entry['text'].encode()
        assert len(content) == entry['bytes'], entry['path']
        assert hashlib.sha256(content).hexdigest() == entry['sha256'], entry['path']
    for case in ('baseline-good', 'omitted-reset', 'clock-domain-no-reset'):
        original = next(entry for entry in packet['files']
                        if entry['path'] == 'sources/fsmgen-input/' + case + '.isf')
        assert (AUDIT / (case + '.isf')).read_bytes() == original['text'].encode()
    products = json.loads((AUDIT / 'current.json').read_text())
    assert verify(products)
    for mutation in ('missing-reset', 'invented-reset', 'invented-initial', 'changed-default'):
        corrupt = copy.deepcopy(products)
        if mutation == 'missing-reset':
            corrupt['baseline-good']['queries']['semantic']['report']['semantic']['explicit_system_contract']['reset'] = None
        elif mutation == 'invented-reset':
            corrupt['clock-domain-no-reset']['queries']['schedule']['report']['reset'] = {'name': 'rst_n'}
        elif mutation == 'changed-default':
            corrupt['omitted-reset']['queries']['schedule']['report']['watchdog'] = 7
        else:
            files = corrupt['clock-domain-no-reset']['generated']['systemverilog']['files']
            path = next(path for path in files if path.endswith('.sv'))
            files[path] += '\ninitial current_state = MAIN_IDLE_0;\n'
        try:
            verify(corrupt)
        except AssertionError:
            continue
        raise AssertionError('hostile control accepted: ' + mutation)
    print('reset baseline: identities, public contracts, HDL structure and hostile controls PASS')


if __name__ == '__main__':
    main()
