"""Qualify new pure-source construction before freezing its immutable members."""
import json
import runpy
from pathlib import Path

BASE = Path('docs/audits/coordinate-statement-recipes-20261009')


def main():
    if (BASE / 'seal.json').exists():
        raise ValueError('pre-seal preparation cannot rerun on a sealed product')
    reader = runpy.run_path(str(BASE / 'verify.py'))
    actual = json.loads((BASE / 'recipes.json').read_bytes())
    reader['check'](actual, reader['expectation']())
    print('PASS independent pre-seal whole statement reconstruction; published reader still requires its final seal.')


if __name__ == '__main__':
    main()
