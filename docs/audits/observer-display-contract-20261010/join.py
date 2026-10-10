"""Join the complete pre-observation source hypotheses to their own native epoch."""
import hashlib
import json
import traceback
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    destination = BASE / 'joined.json'
    assert not destination.exists(), 'retain first complete join epoch'
    inputs = ['pre-native.json', 'qualify-catalogue.json', 'hypotheses.json',
              'qualify-native.json', 'model.py', 'join.py']
    identities = {name: pin((BASE / name).read_bytes()) for name in inputs}
    result = {'inputs': identities, 'role': 'Current finite public fixtures only; no original formatter/settings identity or general parser contract.'}
    try:
        pre = json.loads((BASE / 'pre-native.json').read_bytes())
        assert pre['inputs'] == {name: pin((BASE / name).read_bytes()) for name in pre['inputs']}, 'complete pre-observation source epoch'
        record = json.loads((BASE / 'qualify-native.json').read_bytes())
        assert type(record['status']) is int and record['status'] == 0 and record['stderr'] == '', 'actual native success'
        assert record['stdout_identity'] == pin(record['stdout'].encode()) and record['stderr_identity'] == pin(b''), 'whole native streams'
        assert record['command'] == ['perl', '-Iperl', str(BASE / 'fixtures.pl'), str(BASE / 'qualify-catalogue.json')], 'own declared public invocation'
        assert record['inputs'] == {str(BASE / name): pre['inputs'][name] for name in ('fixtures.pl', 'qualify-catalogue.json', 'capture.py')}, 'source-selected native inputs'
        module = {'__name__': 'finite_display_join'}
        exec(compile((BASE / 'model.py').read_bytes(), str(BASE / 'model.py'), 'exec'), module)
        catalogue = json.loads((BASE / 'qualify-catalogue.json').read_bytes())
        hypotheses = json.loads((BASE / 'hypotheses.json').read_bytes())
        assert module['same'](module['plan'](catalogue), hypotheses), 'complete preselected source hypotheses'
        result['products'] = module['join'](hypotheses, json.loads(record['stdout']))
        result['status'] = 0
        result['error'] = ''
    except Exception:
        result['status'] = 1
        result['error'] = traceback.format_exc()
    assert identities == {name: pin((BASE / name).read_bytes()) for name in inputs}, 'whole join input epoch conserves'
    destination.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    if result['status']:
        print(result['error'], end='')
    else:
        print('PASS every preselected complete public token/header, source lifetime and raw-body reconstruction; original identity remains unmeasured.')
    raise SystemExit(result['status'])


if __name__ == '__main__':
    main()
