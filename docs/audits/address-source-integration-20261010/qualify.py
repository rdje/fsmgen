"""Retain each independent whole integration qualification and programme."""
import json
import re
import sys
from pathlib import Path

BASE = Path('docs/audits/address-source-integration-20261010')


def module(name):
    path = BASE / name
    ns = {'__name__': 'independent_source_integration'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def main():
    attempt = sys.argv[1]
    if re.fullmatch('[a-z][a-z0-9-]*', attempt) is None:
        raise ValueError('finite qualification attempt name')
    frozen = BASE / (attempt + '-oracle.py.txt')
    if frozen.exists():
        raise ValueError('retain each complete independent programme')
    frozen.write_bytes((BASE / 'oracle.py').read_bytes())
    source = module('source.py')
    spec = json.loads((BASE / 'inputs.json').read_bytes())
    product = json.loads((BASE / 'hypotheses.json').read_bytes())
    measured = module('oracle.py')['qualify'](product, source['data'](spec), spec)
    proof = {'measured': measured, 'product': source['pin']((BASE / 'hypotheses.json').read_bytes()),
             'oracle': source['pin'](frozen.read_bytes()),
             'scope': 'Complete independent source join; genuine separating controls and durability remain required.'}
    (BASE / (attempt + '-join-proof.json')).write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete independent source role/graph/lifetime join; separating controls and durability remain required.')


if __name__ == '__main__':
    main()
