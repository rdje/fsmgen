"""Retain a complete first join attempt before adding separating controls."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/address-parser-context-closure-20261010')


def module(name):
    path = BASE / name
    ns = {'__name__': 'first_original_context_join'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def main():
    pins = {}
    for name in ('source.py', 'model.py', 'oracle.py', 'runtime.py', 'qualify.py'):
        raw = (BASE / name).read_bytes()
        frozen = BASE / ('first-join-' + name + '.txt')
        if frozen.exists():
            raise ValueError('retain first complete join programmes')
        frozen.write_bytes(raw)
        pins[name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    inputs = json.loads((BASE / 'inputs.json').read_bytes())
    product = module('model.py')['derive'](inputs)
    (BASE / 'first-join-hypotheses.json.txt').write_text(json.dumps(product, sort_keys=True, indent=2)+'\n')
    product = json.loads((BASE / 'first-join-hypotheses.json.txt').read_bytes())
    measured = module('oracle.py')['qualify'](product, inputs)
    (BASE / 'first-join-proof.json.txt').write_text(json.dumps({'measured': measured, 'programmes': pins},sort_keys=True,indent=2)+'\n')
    print('PASS complete first original parser/context source join; independent separating controls remain required.')


if __name__ == '__main__':
    main()
