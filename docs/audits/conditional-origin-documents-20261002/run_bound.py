import hashlib
import json
import os
import subprocess
from pathlib import Path

root = Path('.artifacts/conditional-origin-documents')
baseline = 'de856cd10c74bc2114076a1d7913e7ca151ec11d'
paths = [Path(p) for p in subprocess.check_output(['git','ls-files','bin','perl',
    'docs/audits/conditional-origin-library-20261002', 'docs/audits/conditional-origin-authority-20261002',
    'docs/audits/conditional-origin-parser-20261002']).decode().splitlines()]
paths += [Path(p) for p in ('t/2046-isf-library-document-origin-authority.t',
    't/lib/FSM/Test/LibraryDocumentOriginAuthority.pm', 't/lib/FSM/Test/SameSourceLibraryOriginParser.pm',
    't/lib/FSM/Test/ConditionalOriginParser.pm', 't/lib/FSM/Test/ConditionalOriginAuthority.pm',
    '.artifacts/conditional-origin-documents/red-lib/FSM/Test/NoDocumentComparison.pm',
    '.artifacts/conditional-origin-documents/run_bound.py')]
def identities(): return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))}
for name, expected in [('current-bound',0), ('red-bound',1)]:
    capture = root / name
    capture.mkdir(exist_ok=False)
    env = {'FSMGEN_DOCUMENT_ORIGIN_CAPTURE': str(capture)}
    argv = ['prove','-v','-Iperl','-It/lib']
    if expected:
        env.update(FSMGEN_DOCUMENT_ORIGIN_AUTHORITY_CLASS='FSM::Test::NoDocumentComparison',
            PERL5OPT='-MFSM::Test::NoDocumentComparison',
            PERL5LIB='perl:t/lib:.artifacts/conditional-origin-documents/red-lib')
        argv.append('-I.artifacts/conditional-origin-documents/red-lib')
    argv.append('t/2046-isf-library-document-origin-authority.t')
    before = identities()
    with (root / (name + '.tap')).open('wb') as out, (root / (name + '-stderr.txt')).open('wb') as err:
        result = subprocess.run(argv, env=dict(os.environ,**env), stdout=out, stderr=err)
    after = identities()
    (root / (name + '-recipe.json')).write_text(json.dumps({'argv':argv, 'cwd':'.', 'environment':env,
        'exit_status':result.returncode, 'expected_status':expected, 'before':before,'after':after,
        'baseline':baseline},indent=2,sort_keys=True) + '\n')
    assert before == after and result.returncode == expected
    assert len(list(capture.glob('*.json'))) == 27
    print(name + ': complete exact inputs/instruments/producers and terminal receipt bound')
