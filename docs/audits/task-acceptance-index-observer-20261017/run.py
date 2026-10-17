"""Fixed qualification and required regression capture; no arbitrary commands."""
from pathlib import Path
import base64
import gzip
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from verify import qualified_sources, unblob

ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-index-observer-20261017')
WORK = Path('.artifacts/task-acceptance-index-observer-20261017')
LIB = ['-Iperl', '-It/lib', '-Idocs/audits/native-group-witness-20260927',
       '-Idocs/audits/native-group-witness-20260927/failure-only', '-I' + str(AUDIT)]
TESTS = ['t/2068-task-acceptance-index-runtime.t', 't/2070-audit-index-fixture-policy.t',
         't/2071-audit-source-acceptance.t']


def digest(body):
    return hashlib.sha256(body).hexdigest()


def blob(body):
    return {'bytes': len(body), 'sha256': digest(body),
            'body_base64': base64.b64encode(body).decode()}


def perl(expression, *args):
    return subprocess.check_output(['perl', *LIB, '-MIndexObserver', '-e', expression, *args], timeout=30)


def sources():
    names = json.loads(perl('print IndexObserver::encode([IndexObserver::paths()])'))
    return {name: blob(Path(name).read_bytes()) for name in names}


def git_state():
    # These read-only commands neither refresh nor write the primary index.
    return {'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], timeout=30).decode().strip(),
            'entries': blob(subprocess.check_output(['git', 'ls-files', '--stage', '-z'], timeout=30)),
            'index': blob(Path('.git/index').read_bytes()),
            'fixture_baseline': blob(subprocess.check_output(
                ['git', 'show', 'HEAD:docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md'], timeout=30))}


def save(name, record):
    with (AUDIT / name).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(record, sort_keys=True).encode(), mtime=0))


def command(argv):
    completed = subprocess.run(argv, capture_output=True, timeout=300)
    return {'command': argv, 'status': completed.returncode,
            'stdout': blob(completed.stdout), 'stderr': blob(completed.stderr)}


def control_ready(row, scenario):
    output = unblob(row['stdout'])
    success = scenario in ('healthy', 'diagnostic_errno')
    return ((row['status'] == 0) == success
            and re.search(rb'^1\.\.167$', output, re.M) is not None
            and re.search(rb'^(?:not ok|Bail out!)', output, re.M) is None
            and len(re.findall(rb'^ok \d+ - ', output, re.M)) == 167)


def prepare(selector):
    body = perl('print IndexObserver::encode(IndexObserver::admission($ARGV[0]))', selector)
    name = {'t/2068-task-acceptance-index-runtime.t': 'index',
            't/2070-audit-index-fixture-policy.t': 'policy',
            't/2071-audit-source-acceptance.t': 'scope'}.get(selector, selector)
    with (WORK / (name + '-admission.json')).open('xb') as stream:
        stream.write(body)


def main():
    assert Path.cwd().resolve() == ROOT, 'run from script-derived repository root'
    assert len(sys.argv) == 2 and sys.argv[1] in ('controls', 'regression')
    action = sys.argv[1]
    assert not os.environ.get('PERL5OPT'), 'inherited Perl configuration'
    for directory in (WORK, AUDIT):
        for parent in (directory, *directory.parents):
            if parent == Path('.'):
                break
            assert not parent.is_symlink()
            if parent.exists():
                assert parent.is_dir() and parent.stat().st_dev == ROOT.stat().st_dev
            assert not (parent / '.git').exists(), 'never create or enter another repository'
    WORK.mkdir(parents=True, exist_ok=True)
    marker = WORK / (action + '-started')
    with marker.open('xb') as stream:
        stream.write(b'One fixed capture; do not replay to seek recurrence.\n')
    if action == 'regression':
        # Original test execution is allowed only after the exact qualification
        # and its observer sources have landed in this repository's HEAD.
        proof = AUDIT / 'controls.json.gz'
        assert subprocess.check_output(['git', 'show', f'HEAD:{proof}'], timeout=30) == proof.read_bytes()
        for path in sources():
            assert subprocess.check_output(['git', 'show', 'HEAD:' + path], timeout=30) == Path(path).read_bytes()
        assert command(['python3', '-B', str(AUDIT / 'verify.py'), 'controls'])['status'] == 0
        qualified_sources(json.loads(gzip.decompress(proof.read_bytes())), sources())
    before, git_before = sources(), git_state()
    tools = {name: digest(Path(shutil.which(name)).resolve().read_bytes())
             for name in ('perl', 'prove', 'bash', 'git', 'awk', 'grep', 'mktemp', 'mkdir', 'rm', 'rmdir')}
    started = {'action': action, 'sources_before': before, 'git_before': git_before, 'tools': tools,
               'scope': 'Fixed primary-repository alternate-index qualification; OS/Perl tools are '
                        'read-only external dependencies. Events are sequential after-return snapshots. '
                        'Original EPERM has no retained native context and remains unproved.'}
    save(action + '-started.json.gz', started)
    rows = []
    if action == 'controls':
        for scenario in ('healthy', 'query_gap', 'write_gap', 'retention_gap', 'diagnostic_errno', 'coverage_gap'):
            selector = 'control_' + scenario
            prepare(selector)
            row = command(['perl', *LIB, str(AUDIT / 'observe.pl'), selector])
            row['selector'] = selector
            rows.append(row)
            # Never turn an unexpected original result into another attempt.
            if not control_ready(row, scenario):
                break
        if len(rows) == 6:
            row = command(['perl', *LIB, str(AUDIT / 'observe.pl'), 'control_healthy'])
            row['selector'] = 'reuse'
            rows.append(row)
    else:
        for target in TESTS:
            prepare(target)
        rows.append(command(['prove', '-v', '--exec', 'perl ' + str(AUDIT / 'observe.pl'), *TESTS]))
    after, git_after = sources(), git_state()
    captures = {str(path.relative_to(WORK)): blob(path.read_bytes())
                for path in sorted(WORK.glob('*/*.json*')) if path.is_file()}
    admissions = {path.name: blob(path.read_bytes()) for path in sorted(WORK.glob('*-admission.json'))}
    record = {**started, 'sources_after': after, 'git_after': git_after,
              'source_conserved': before == after, 'git_conserved': git_before == git_after,
              'rows': rows, 'captures': captures, 'admissions': admissions}
    save(action + '.json.gz', record)
    print(action, 'native statuses', [row['status'] for row in rows],
          'sources conserved', before == after, 'primary index conserved', git_before == git_after, flush=True)
    subprocess.run(['python3', '-B', str(AUDIT / 'verify.py'), action], check=True, timeout=30)


if __name__ == '__main__':
    main()
