"""Retain and rederive the exact first pure-source scanner defect and repair."""
import json
import re
import runpy
from pathlib import Path

BASE = Path('docs/audits/coordinate-statement-recipe-checks-20261009')
RECIPES = Path('docs/audits/coordinate-statement-recipes-20261009')


def main():
    first = runpy.run_path(str(BASE / 'first-verify.py.txt'))
    original = json.loads((BASE / 'checks.json').read_bytes())['independent-preseal']
    if type(original['status']) is not int or original['status'] != 1:
        raise ValueError('retain actual original scanner failure')
    try:
        first['expectation']()
    except re.PatternError as error:
        if str(error) != 'unbalanced parenthesis at position 52':
            raise ValueError('exact original source scanner mechanism') from error
    else:
        raise ValueError('original broken regex unexpectedly accepted')
    repaired = runpy.run_path(str(RECIPES / 'verify.py'))
    repaired['authenticate'](RECIPES)
    repaired['check'](json.loads((RECIPES / 'recipes.json').read_bytes()), repaired['expectation']())
    print('PASS exact original scanner failure and repaired complete source allocation; no capture or raw-coordinate intake.')


if __name__ == '__main__':
    main()
