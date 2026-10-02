import hashlib
import json
import os
import subprocess
from pathlib import Path

ROOT = Path('docs/audits/conditional-origin-files-20261002')
BASELINE = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
paths = [Path(p) for p in subprocess.check_output(['git', 'ls-files', 'bin', 'perl',
    'docs/audits/conditional-origin-atl-20261002',
    't/lib/FSM/Test/ConditionalOriginParser.pm',
    't/lib/FSM/Test/SameSourceLibraryOriginParser.pm',
    't/lib/FSM/Test/LibraryDocumentOriginAuthority.pm',
    't/lib/FSM/Test/ATLDocumentOriginAuthority.pm'], text=True).splitlines()]
paths += [Path('t/2048-isf-file-document-origin-authority.t'),
    Path('t/lib/FSM/Test/FileDocumentOriginAuthority.pm'), ROOT / 'run_bound.py', ROOT / 'red_form.t']
paths += sorted((ROOT / 'red-lib').rglob('*.pm'))

def identities():
    return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))}

# Portable recipes name relative inputs. PERL5LIB entries become absolute only
# in the child environment so later fixture chdir cannot invalidate module load.
for name, status, module in [('current-bound', 0, None), ('red-bound', 1, 'NoFileComparison'),
                             ('form-bound', 0, None), ('form-red-bound', 1, 'NoFileFormAssociation')]:
    capture = ROOT / name
    capture.mkdir(exist_ok=False)
    argv = ['prove', '-v', '-Iperl', '-It/lib']
    env_recipe = {}
    env = dict(os.environ)
    if name.startswith('form-'):
        env_recipe['FSMGEN_FILE_FORM_CAPTURE'] = str(capture / 'product.json')
        argv.append(str(ROOT / 'red_form.t'))
    else:
        env_recipe['FSMGEN_FILE_ORIGIN_CAPTURE'] = str(capture)
        argv.append('t/2048-isf-file-document-origin-authority.t')
    env.update(env_recipe)
    if module:
        env_recipe['PERL5LIB_entries'] = ['perl', 't/lib', str(ROOT / 'red-lib')]
        env['PERL5LIB'] = ':'.join(str(Path(p).resolve()) for p in env_recipe['PERL5LIB_entries'])
        env_recipe['PERL5OPT'] = '-MFSM::Test::' + module
        env['PERL5OPT'] = env_recipe['PERL5OPT']
        if module == 'NoFileComparison':
            env_recipe['FSMGEN_FILE_ORIGIN_AUTHORITY_CLASS'] = 'FSM::Test::NoFileComparison'
            env['FSMGEN_FILE_ORIGIN_AUTHORITY_CLASS'] = env_recipe['FSMGEN_FILE_ORIGIN_AUTHORITY_CLASS']
    before = identities()
    with (ROOT / (name + '.tap')).open('wb') as out, (ROOT / (name + '-stderr.txt')).open('wb') as err:
        result = subprocess.run(argv, env=env, stdout=out, stderr=err)
    after = identities()
    # Runtime root prefixes in diagnostic stacks are normalized for portable
    # retained receipts; status and TAP bytes are untouched.
    err_path = ROOT / (name + '-stderr.txt')
    err_path.write_bytes(err_path.read_bytes().replace(os.fsencode(Path.cwd()), b'.'))
    recipe = {'argv': argv, 'cwd': '.', 'environment_recipe': env_recipe,
              'exit_status': result.returncode, 'expected_status': status,
              'before': before, 'after': after, 'baseline': BASELINE,
              'stderr_normalization': 'runtime repository root prefix -> .'}
    (ROOT / (name + '-recipe.json')).write_text(json.dumps(recipe, indent=2, sort_keys=True) + '\n')
    assert before == after and result.returncode == status, name
    assert len(list(capture.glob('*.json'))) == (1 if name.startswith('form-') else 26), name
    print(name + ': complete input/instrument/producer binding and expected terminal result', flush=True)
