"""Verify immutable pre-change domain reports, carriers, HDL and logs."""
import hashlib
import json
from pathlib import Path

AUDIT = Path(__file__).resolve().parent
ROOT = AUDIT.parents[2]


def main():
    manifest = json.loads((AUDIT / 'manifest.json').read_text())
    for name, digest in manifest['files'].items():
        assert hashlib.sha256((AUDIT / name).read_bytes()).hexdigest() == digest, name
    products = json.loads((AUDIT / 'baseline.json').read_text())
    assert set(products) == {'domains'}
    for case in products.values():
        assert set(case['queries']) == {'check', 'semantic', 'schedule'}
        for query, result in case['queries'].items():
            assert result['native']['exit_code'] == result['wire']['exit_code'] == 0
            assert result['native']['stderr'] == result['wire']['stderr'] == ''
            assert json.loads(result['wire']['stdout']) == result['api']
            assert json.loads(result['native']['stdout']) == result['report']
            assert result['report'] == result['api']['result']['structuredContent']['report']
            assert json.loads(result['api']['result']['content'][0]['text']) == result['api']['result']['structuredContent']
            if query == 'schedule':
                assert result['report']['inferred_storage'] == []
                assert [d['name'] for d in result['report']['clock_domains']] == ['core', 'aux']
                assert all('inferred_storage' not in d for d in result['report']['clock_domains'])
            else:
                assert result['report']['success'] and not result['report']['diagnostics']
        assert set(case['scheduled_files']) == {'domain_storage_report__domain_core.fsm', 'domain_storage_report__domain_aux.fsm', 'domain_storage_report_top.fsm'}
        assert '(internal core_word)' in case['scheduled_files']['domain_storage_report__domain_core.fsm']
        assert '(internal aux_word)' in case['scheduled_files']['domain_storage_report__domain_aux.fsm']
        assert set(case['generated']) == {'systemverilog', 'verilog'}
        for result in case['generated'].values():
            assert result['command']['exit_code'] == 0
            assert result['command']['stderr'] == ''
            assert 'module domain_storage_report_top' in result['hdl']
    logs = json.loads((AUDIT / 'logs.json').read_text())
    for record in logs.values():
        assert hashlib.sha256(record['text'].encode()).hexdigest() == record['sha256']
    print('domain-storage evidence: pre-change complete reports, artifact identities and log integrity PASS')


if __name__ == '__main__':
    main()
