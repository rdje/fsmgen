"""Run the real test with bound inputs and independent consumer counterfactuals."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
baseline = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
paths = subprocess.check_output(['git', 'ls-files', 'bin', 'perl', 't/lib']).decode().splitlines()
paths += ['t/2046-isf-library-document-origin-authority.t', str(BASE / 'run_bound.py'),
          str(BASE / 'red-lib/NoLibrarySourceComparison.pm')]


def fingerprints():
    return {name: hashlib.sha256(Path(name).read_bytes()).hexdigest() for name in sorted(paths)}


for band, expected in (('current-bound', 0), ('full-stack-red', 1), ('bypass-red', 1)):
    directory = BASE / band
    directory.mkdir(exist_ok=False)
    env = dict(os.environ)
    settings = {'FSMGEN_DOCUMENT_ORIGIN_CAPTURE': str(directory)}
    if band == 'full-stack-red':
        settings['FSMGEN_LIBRARY_DIAGNOSTIC_FULL_STACK'] = '1'
    if band == 'bypass-red':
        settings['FSMGEN_DOCUMENT_ORIGIN_AUTHORITY_CLASS'] = 'NoLibrarySourceComparison'
        settings['PERL5OPT'] = '-MNoLibrarySourceComparison'
        includes = ['perl', 't/lib', str(BASE / 'red-lib')]
        env['PERL5LIB'] = ':'.join(str(Path(name).resolve()) for name in includes)
    env.update(settings)
    argv = ['prove', '-Iperl', '-It/lib', 't/2046-isf-library-document-origin-authority.t']
    before = fingerprints()
    with (BASE / (band + '.txt')).open('wb') as output:
        result = subprocess.run(argv, env=env, stdout=output, stderr=subprocess.STDOUT)
    after = fingerprints()
    recipe = {'baseline': baseline, 'band': band, 'argv': argv,
              'environment': settings, 'before': before, 'after': after,
              'status': result.returncode, 'expected': expected}
    if band == 'bypass-red':
        recipe['PERL5LIB_entries'] = includes
    (BASE / (band + '-recipe.json')).write_text(json.dumps(recipe, sort_keys=True, indent=2) + '\n')
    assert before == after and result.returncode == expected, band
    assert len(list(directory.glob('*.json'))) == 30, band
    print(band + ': complete unchanged-source binding and expected actual terminal outcome', flush=True)
