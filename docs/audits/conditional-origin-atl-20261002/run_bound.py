import hashlib
import json
import os
import subprocess
from pathlib import Path

root = Path('.artifacts/conditional-origin-atl')
baseline = 'f392e33a491d7798193f72447cfb564f0152da4a'
paths = [Path(p) for p in subprocess.check_output(['git','ls-files','bin','perl',
    'docs/audits/conditional-origin-library-20261002','docs/audits/conditional-origin-documents-20261002',
    'docs/audits/conditional-origin-documents-finalization-20261002',
    't/lib/FSM/Test/ConditionalOriginParser.pm','t/lib/FSM/Test/SameSourceLibraryOriginParser.pm',
    't/lib/FSM/Test/LibraryDocumentOriginAuthority.pm']).decode().splitlines()]
paths += [Path(p) for p in ('t/2047-isf-atl-document-origin-authority.t',
    't/lib/FSM/Test/ATLDocumentOriginAuthority.pm', '.artifacts/conditional-origin-atl/run_bound.py',
    '.artifacts/conditional-origin-atl/red-lib/FSM/Test/NoATLComparison.pm')]
def identities(): return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))}
for name,status in [('current-bound',0),('red-bound',1)]:
    capture = root / name
    capture.mkdir(exist_ok=False)
    env = {'FSMGEN_ATL_ORIGIN_CAPTURE':str(capture)}
    argv = ['prove','-v','-Iperl','-It/lib']
    if status:
        env.update(FSMGEN_ATL_ORIGIN_AUTHORITY_CLASS='FSM::Test::NoATLComparison',
            PERL5OPT='-MFSM::Test::NoATLComparison', PERL5LIB='perl:t/lib:.artifacts/conditional-origin-atl/red-lib')
        argv.append('-I.artifacts/conditional-origin-atl/red-lib')
    argv.append('t/2047-isf-atl-document-origin-authority.t')
    before = identities()
    with (root / (name + '.tap')).open('wb') as out,(root / (name + '-stderr.txt')).open('wb') as err:
        result = subprocess.run(argv, env=dict(os.environ,**env),stdout=out,stderr=err)
    after = identities()
    (root / (name + '-recipe.json')).write_text(json.dumps({'argv':argv,'cwd':'.','environment':env,
        'exit_status':result.returncode,'expected_status':status,'before':before,'after':after,'baseline':baseline},
        indent=2,sort_keys=True) + '\n')
    assert before == after and result.returncode == status
    assert len(list(capture.glob('*.json'))) == 26
    print(name + ': full input/instrument/producer identities and terminal results bound')
