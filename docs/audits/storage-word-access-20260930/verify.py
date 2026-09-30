"""Verify retained pre-change controls and exact original packet sources."""
import hashlib
import json
from pathlib import Path

AUDIT = Path(__file__).resolve().parent
ROOT = AUDIT.parents[2]


def main():
    manifest = json.loads((AUDIT / 'manifest.json').read_text())
    for name, digest in manifest['files'].items():
        assert hashlib.sha256((AUDIT / name).read_bytes()).hexdigest() == digest, name
    intake = json.loads((ROOT / 'docs/audits/specforge-storage-register-access-intake-20260926.json').read_text())
    for case in intake['cases']:
        source = case['source']
        original = source['text'].encode()
        assert hashlib.sha256(original).hexdigest() == source['sha256']
        assert (AUDIT / Path(source['path']).name).read_bytes() == original
    products = json.loads((AUDIT / 'baseline.json').read_text())
    assert set(products) == {'baseline-good', 'whole-word-field'}
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
                assert not any('access' in item for item in result['report']['inferred_storage'])
            else:
                assert result['report']['success'] and not result['report']['diagnostics']
        assert set(case['scheduled_files']) == {'csr_access.fsm'}
        assert '(internal status)' in case['scheduled_files']['csr_access.fsm']
        assert set(case['generated']) == {'systemverilog', 'verilog'}
        for result in case['generated'].values():
            assert result['command']['exit_code'] == 0
            assert result['command']['stderr'] == ''
            assert 'module csr_access' in result['hdl']
    logs = json.loads((AUDIT / 'logs.json').read_text())
    for record in logs.values():
        assert hashlib.sha256(record['text'].encode()).hexdigest() == record['sha256']
    print('storage-word evidence: packet identities, pre-change complete products and log integrity PASS')


if __name__ == '__main__':
    main()
