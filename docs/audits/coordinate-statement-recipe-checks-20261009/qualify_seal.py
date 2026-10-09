"""Actual immutable-member controls in disposable same-volume copies."""
import contextlib
import io
import json
import runpy
import shutil
import tempfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-statement-recipes-20261009')
CHECKS = Path('docs/audits/coordinate-statement-recipe-checks-20261009')


def main():
    published = runpy.run_path(str(CHECKS / 'verify_recipes.py'))
    published['authenticate'](BASE)
    pin = published['pin']
    original = {p.name: pin(p.read_bytes()) for p in BASE.iterdir()}
    scratch = Path('.artifacts/tmp')
    scratch.mkdir(parents=True, exist_ok=True)
    controls = []
    with tempfile.TemporaryDirectory(prefix='statement-seal-', dir=scratch) as temporary:
        root = Path(temporary)
        fixture = root / 'first'
        shutil.copytree(BASE, fixture)
        (fixture / 'extra.txt').write_text('extra member\n')
        (fixture / 'seal.json').write_text(json.dumps(
            {p.name: pin(p.read_bytes()) for p in fixture.iterdir() if p.name != 'seal.json'},
            sort_keys=True, indent=2) + '\n')
        old = runpy.run_path(str(BASE / 'verify.py'))
        old['main'].__globals__['BASE'] = fixture
        stream = io.StringIO()
        with contextlib.redirect_stdout(stream):
            old['main']()
        # The complete original reader actually passes this hostile copy;
        # compare its complete source-allocation result, not a PASS substring.
        baseline = runpy.run_path(str(BASE / 'verify.py'))
        clean_stream = io.StringIO()
        with contextlib.redirect_stdout(clean_stream):
            baseline['main']()
        if stream.getvalue() != clean_stream.getvalue():
            raise ValueError('exact original resealed-member false-green result')
        try:
            published['authenticate'](fixture)
        except ValueError as error:
            if str(error) != 'fixed complete recipe seal identity':
                raise
            controls.append({'control': 'self-resealed-extra', 'original_status': 0,
                             'original_stdout': stream.getvalue(), 'published_status': 1, 'cause': str(error)})
        else:
            raise ValueError('published resealed-member false green')
        cases = (
            ('missing-seal', lambda p: (p / 'seal.json').unlink(), 'fixed complete recipe seal identity'),
            ('missing-member', lambda p: (p / 'recipes.json').unlink(), 'fixed complete recipe member domain'),
            ('borrowed-body', lambda p: (p / 'recipes.json').write_text('{}\n'), 'fixed complete recipe member bytes'),
            ('changed-seal', lambda p: (p / 'seal.json').write_text('{}\n'), 'fixed complete recipe seal identity'),
            ('extra-member', lambda p: (p / 'extra.txt').write_text('extra\n'), 'fixed complete recipe member domain'),
        )
        for name, mutate, cause in cases:
            fixture = root / name
            shutil.copytree(BASE, fixture)
            mutate(fixture)
            try:
                published['authenticate'](fixture)
            except ValueError as error:
                if str(error) != cause:
                    raise ValueError('intended sealed-member refusal: ' + name) from error
                controls.append({'control': name, 'status': 1, 'cause': cause})
            else:
                raise ValueError('false-green sealed-member control: ' + name)
    if root.exists() or original != {p.name: pin(p.read_bytes()) for p in BASE.iterdir()}:
        raise ValueError('complete fixture removal and unchanged original recipe members')
    published['authenticate'](BASE)
    print(json.dumps({'status': 0, 'controls': controls,
                      'scope': 'Whole first reader false green retained; fixed published seal rejects actual member/body/identity corruptions.'}, sort_keys=True))


if __name__ == '__main__':
    main()
