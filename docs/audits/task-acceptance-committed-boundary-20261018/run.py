"""One closed committed-only boundary acceptance using qualified observation methods."""
from pathlib import Path
import gzip
import hashlib
import json
import os
import shutil
import subprocess
import sys

if not __debug__:
    raise SystemExit('Acceptance assertions must be enabled.')
ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-committed-boundary-20261018')
WORK = Path('.artifacts/task-acceptance-committed-boundary-20261018')
BASE = Path('docs/audits/task-acceptance-index-observer-20261017')
PROSPECTIVE = Path('docs/audits/task-acceptance-index-prospective-20261018')
QUALIFIED = PROSPECTIVE / 'corrected-controls.json.gz'
TARGET = 't/2072-task-acceptance-box-boundaries.t'
sys.path.insert(0, str(ROOT / BASE))
import run as core
from verify import verify, qualified_sources

core.AUDIT, core.WORK = AUDIT, WORK
core.LIB += ['-I' + str(PROSPECTIVE), '-I' + str(AUDIT), '-MBoundaryIndexObserver']


def component_join(qualified, current):
    # Compare the complete qualified base, not a hand-picked method subset.
    return qualified_sources(qualified, {name: current[name] for name in qualified['sources_after']})


def committed_inputs(current):
    assert Path.cwd().resolve() == ROOT and not os.environ.get('PERL5OPT')
    contract = json.loads((AUDIT / 'contract.json').read_bytes())
    assert contract['owner'] == 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.2.2'
    assert contract['target'] == TARGET and contract['expected'] == [9, 90, 9]
    for name, row in current.items():
        assert subprocess.check_output(['git', 'show', 'HEAD:' + name], timeout=30) == core.unblob(row), name
    proof = QUALIFIED.read_bytes()
    assert subprocess.check_output(['git', 'show', 'HEAD:' + str(QUALIFIED)], timeout=30) == proof
    qualified = json.loads(gzip.decompress(proof))
    assert verify(qualified) and component_join(qualified, current)
    return {'path': str(QUALIFIED), 'sha256': hashlib.sha256(proof).hexdigest()}


def main():
    assert Path.cwd().resolve() == ROOT and not os.environ.get('PERL5OPT')
    assert not sys.argv[1:], 'this intake has one fixed programme'
    before = core.sources()
    qualification = committed_inputs(before)
    for directory in (AUDIT, WORK):
        for parent in (directory, *directory.parents):
            if parent == Path('.'):
                break
            assert not parent.is_symlink() and not (parent / '.git').exists()
            assert not ((parent / 'HEAD').exists() and (parent / 'objects').exists())
            if parent.exists():
                assert parent.is_dir() and parent.stat().st_dev == ROOT.stat().st_dev
    WORK.mkdir(parents=True, exist_ok=True)
    with (WORK / 'started').open('xb') as stream:
        stream.write(b'One committed-only boundary intake; preserve its first result.\n')
    started = {'schema': 'fsmgen.committed_boundary_observation.v1',
               'owner': 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.2.2',
               'qualification': qualification, 'sources_before': before, 'git_before': core.git_state(),
               'tools': {name: core.digest(Path(shutil.which(name)).resolve().read_bytes())
                         for name in ('perl', 'bash', 'git', 'awk', 'grep', 'mktemp', 'mkdir', 'rm', 'rmdir')},
               'scope': 'Closed T2072 admission data over unchanged qualified native observation methods. '
                        'All inputs committed; project-owned data stays repository-local. '
                        'Canonical OS/toolchain executables are required read-only external dependencies. '
                        'Historical failures and independent HIAL/full-CI/push/visual gates remain open.'}
    core.save('started.json.gz', started)
    admission = core.perl('print IndexObserver::encode(IndexObserver::admission($ARGV[0]))', TARGET)
    with (WORK / 'boundary-admission.json').open('xb') as stream:
        stream.write(admission)
    row = core.command(['perl', *core.LIB, str(PROSPECTIVE / 'observe.pl'), TARGET])
    after, git_after = core.sources(), core.git_state()
    record = {**started, 'row': row, 'sources_after': after, 'git_after': git_after,
              'source_conserved': before == after, 'git_conserved': started['git_before'] == git_after,
              'admission': core.blob(admission),
              'captures': {path.name: core.blob(path.read_bytes())
                           for path in sorted((WORK / 'boundary').glob('*.json*')) if path.is_file()}}
    core.save('result.json.gz', record)
    print('boundary native', row['status'], 'source conserved', record['source_conserved'],
          'primary index conserved', record['git_conserved'], flush=True)
    subprocess.run(['python3', '-B', str(AUDIT / 'verify.py')], check=True, timeout=30)


if __name__ == '__main__':
    main()
