import hashlib
import json
import os
import subprocess
from pathlib import Path

root = Path('.artifacts/conditional-origin-library')
paths = sorted((root / 'current').glob('*.json'))
assert len(paths) == 24
paths += [Path(p) for p in ('t/2045-isf-same-source-library-origins.t',
    't/lib/FSM/Test/SameSourceLibraryOriginParser.pm', 't/lib/FSM/Test/ConditionalOriginParser.pm',
    't/lib/FSM/Test/ConditionalOriginAuthority.pm', '.artifacts/conditional-origin-library/red_missing_export.t',
    '.artifacts/conditional-origin-library/run_bound.py')]
paths += [Path(p) for p in subprocess.check_output(['git', 'ls-files', 'bin', 'perl']).decode().splitlines()]
def identities(): return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}

for name, test, key, expected in (
    ('current-bound', 't/2045-isf-same-source-library-origins.t', 'FSMGEN_LIBRARY_ORIGIN_CAPTURE', 0),
    ('red-bound', '.artifacts/conditional-origin-library/red_missing_export.t', 'FSMGEN_LIBRARY_ORIGIN_RED_CAPTURE', 1),
):
    capture = root / name
    capture.mkdir(exist_ok=False)
    before = identities()
    argv = ['prove', '-v', '-Iperl', '-It/lib', test]
    with (root / (name + '.tap')).open('wb') as out, (root / (name + '-stderr.txt')).open('wb') as err:
        result = subprocess.run(argv, env=dict(os.environ, **{key: str(capture)}), stdout=out, stderr=err)
    after = identities()
    recipe = {'argv': argv, 'cwd': '.', 'environment': {key: str(capture)}, 'exit_status': result.returncode,
        'expected_status': expected, 'baseline': 'e95955e704c452e41277e3c402ce832912d700f5',
        'before': before, 'after': after}
    (root / (name + '-recipe.json')).write_text(json.dumps(recipe, indent=2, sort_keys=True) + '\n')
    assert before == after and result.returncode == expected
    assert len(list(capture.glob('*.json'))) == 24
    print(name + ': exact complete caller/source/instrument/producer identity and terminal result verified')
