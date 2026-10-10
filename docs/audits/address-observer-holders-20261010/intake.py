"""Bind historical nonzero outcomes, trial aliases and inherited caller origins."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-observer-holders-20261010')
REVISION = 'db3712f8a8f01219b256f07741afcfdfc83bdb2b'


def rebuild():
    pins = {}
    def load(path):
        raw = Path(path).read_bytes()
        committed = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if raw != committed:
            raise ValueError('whole supplemental fixed Git input: ' + path)
        pins[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
        return json.loads(raw)
    original = 'docs/audits/record-value-original-candidate-20261004/'
    execution = load(original + 'execution.json')
    results = {r['mode']: {'status': r['status'], 'captured': r['captured']}
               for r in execution['modes'] if r['mode'] in ('ordinary', 'storable', 'controls')}
    trials = {}
    for mode in results:
        captured = load(original + mode + '.json')
        trials[mode] = [{key: row[key] for key in ('copy', 'provider', 'caller')}
                        for row in captured['trials']]
    helper = load('docs/audits/address-helper-bindings-20261010/hypotheses.json')
    parser = load('docs/audits/address-parser-context-closure-20261010/hypotheses.json')
    bridges = {}
    for mode in results:
        entries = []
        h = next(m for m in helper['modes'] if m['mode'] == mode)
        for key, row in h['bindings'].items():
            origin = row['origin']
            if origin['kind'] in ('observer_helper_caller_snapshot', 'observer_api_caller_snapshot'):
                group, index = ('helpers', origin['helper']) if 'helper' in origin else ('api', origin['api'])
                entries.append({'model': 'helper', 'binding': key, 'table': group, 'index': index})
        p = next(m for m in parser['modes'] if m['mode'] == mode)
        for key, row in p['bindings'].items():
            origin = row['origin']
            if origin['kind'] == 'retained_context_protocol_caller':
                group = 'api' if origin['group'] == 'api' else 'copies'
                entries.append({'model': 'parser-context', 'binding': key, 'table': group,
                                'index': origin['index']})
            elif origin['kind'] == 'observer_caller_snapshot':
                entries.append({'model': 'parser-context', 'binding': key, 'table': 'parses',
                                'index': origin['parse_index']})
        bridges[mode] = entries
    return {'results': results, 'trials': trials, 'bridges': bridges}, pins


def main():
    value, pins = rebuild()
    for name, item in (('supplement.json', value), ('supplement-binding.json', pins)):
        target = BASE / name
        if target.exists():
            raise ValueError('retain first supplemental intake')
        target.write_text(json.dumps(item, sort_keys=True, indent=2) + '\n')
    print('PASS every original mode outcome, trial caller alias and inherited helper/context caller origin retained.')


if __name__ == '__main__':
    main()
