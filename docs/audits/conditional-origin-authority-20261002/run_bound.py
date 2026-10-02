import hashlib
import json
import os
import subprocess
from pathlib import Path

root = Path('.artifacts/conditional-origin-authority')
sources = sorted(Path('docs/audits/conditional-origin-parser-20261002/current-corrected').glob('*.json'))
inputs = sources + [Path(p) for p in (
    't/lib/FSM/Test/ConditionalOriginParser.pm',
    't/lib/FSM/Test/ConditionalOriginAuthority.pm',
    't/2044-isf-conditional-origin-source-authority.t',
    '.artifacts/conditional-origin-authority/red_unbound.t',
    '.artifacts/conditional-origin-authority/run_bound.py')]
inputs += [Path(p) for p in subprocess.check_output(['git', 'ls-files', 'bin', 'perl']).decode().splitlines()]

def identities():
    return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}

for name, test, capture_key, expected in (
    ('current-bound', 't/2044-isf-conditional-origin-source-authority.t', 'FSMGEN_ORIGIN_AUTHORITY_CAPTURE', 0),
    ('red-bound', '.artifacts/conditional-origin-authority/red_unbound.t', 'FSMGEN_ORIGIN_AUTHORITY_RED_CAPTURE', 1),
):
    capture = root / name
    capture.mkdir(exist_ok=False)
    before = identities()
    argv = ['prove', '-v', '-Iperl', '-It/lib', test]
    env = dict(os.environ, **{capture_key: str(capture)})
    with (root / (name + '.tap')).open('wb') as out, (root / (name + '-stderr.txt')).open('wb') as err:
        result = subprocess.run(argv, env=env, stdout=out, stderr=err)
    after = identities()
    recipe = {'argv': argv, 'cwd': '.', 'environment': {capture_key: str(capture)},
        'exit_status': result.returncode, 'expected_status': expected,
        'baseline': 'cb2a156df5a3c8169ad9ca1cfaa9c05046e33bf8',
        'before': before, 'after': after}
    (root / (name + '-recipe.json')).write_text(json.dumps(recipe, indent=2, sort_keys=True) + '\n')
    assert before == after, name
    assert result.returncode == expected, (name, result.returncode)
    assert len(list(capture.glob('*.json'))) == 54, name
    print(name + ': exact complete source/instrument/producer identity and terminal expected result verified')
