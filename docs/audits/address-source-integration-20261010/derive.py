"""Retain each whole source integration derivation and its exact programmes."""
import json
import re
import sys
from pathlib import Path

BASE = Path('docs/audits/address-source-integration-20261010')


def module(name):
    path = BASE / name
    namespace = {'__name__': 'whole_source_integration_derivation'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def main():
    attempt = sys.argv[1]
    if re.fullmatch('[a-z][a-z0-9-]*', attempt) is None:
        raise ValueError('finite local attempt name')
    source = module('source.py')
    archive = BASE / (attempt + '-model.py.txt')
    if archive.exists() or (BASE / 'hypotheses.json').exists():
        raise ValueError('retain each whole first programme/product')
    archive.write_bytes((BASE / 'model.py').read_bytes())
    pin = {name: source['pin']((BASE / name).read_bytes()) for name in ('source.py', 'model.py', 'derive.py')}
    (BASE / (attempt + '-programmes.json')).write_text(json.dumps(pin, sort_keys=True, indent=2) + '\n')
    spec = json.loads((BASE / 'inputs.json').read_bytes())
    product = module('model.py')['derive'](source['data'](spec), spec)
    (BASE / 'hypotheses.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete source role integration derived; independent membership/alias/lifetime qualification remains required.')


if __name__ == '__main__':
    main()
