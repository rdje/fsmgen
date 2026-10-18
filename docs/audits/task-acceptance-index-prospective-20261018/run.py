"""One approved fixed intake using the unchanged original collector and controls."""
from pathlib import Path
import json
import gzip
import os
import shutil
import subprocess
import sys

if not __debug__:
    raise SystemExit('Qualification assertions must be enabled.')

ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-index-prospective-20261018')
ORIGINAL = Path('docs/audits/task-acceptance-index-observer-20261017')
sys.path.insert(0, str(ROOT / ORIGINAL))
import run as original

original.AUDIT = AUDIT
original.WORK = Path('.artifacts/task-acceptance-index-corrected-20261018')
original.LIB += ['-I' + str(AUDIT), '-MProspectiveIndexObserver']


def committed_inputs():
    assert Path.cwd().resolve() == ROOT
    contract = json.loads((ROOT / AUDIT / 'corrected-contract.json').read_bytes())
    assert contract['owner'] == 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.1.2.4.2'
    assert contract['controls_attempts'] == 1 and contract['historical_cause'] == 'P1-open'
    for name, row in original.sources().items():
        assert subprocess.check_output(['git', 'show', 'HEAD:' + name], timeout=30) == original.unblob(row), \
            'uncommitted qualification input: ' + name


def ready_for_reuse(rows):
    return len(rows) == 6 and all(original.control_ready(row, row['selector'][8:]) for row in rows)


def main():
    assert not os.environ.get('PERL5OPT'), 'inherited Perl configuration'
    committed_inputs()
    action = sys.argv[1]
    work = original.WORK
    for directory in (work, AUDIT):
        for parent in (directory, *directory.parents):
            if parent == Path('.'):
                break
            assert not parent.is_symlink() and not (parent / '.git').exists()
            if parent.exists():
                assert parent.is_dir() and parent.stat().st_dev == ROOT.stat().st_dev
    work.mkdir(parents=True, exist_ok=True)
    # Preserve every spent original marker. This is the sole approved new one.
    with (work / (action + '-started')).open('xb') as stream:
        stream.write(b'One approved prospective intake; no retry-until-green.\n')
    if action == 'regression':
        proof = AUDIT / 'corrected-controls.json.gz'
        assert subprocess.check_output(['git', 'show', 'HEAD:' + str(proof)], timeout=30) == proof.read_bytes()
        subprocess.run(['python3', '-B', str(AUDIT / 'verify.py'), 'controls'], check=True, timeout=30)
        original.qualified_sources(json.loads(gzip.decompress(proof.read_bytes())), original.sources())
    before, git_before = original.sources(), original.git_state()
    started = {'action': action, 'sources_before': before, 'git_before': git_before,
               'tools': {name: original.digest(Path(shutil.which(name)).resolve().read_bytes())
                         for name in ('perl', 'prove', 'bash', 'git', 'awk', 'grep', 'mktemp', 'mkdir', 'rm', 'rmdir')},
               'scope': 'Approved corrected current-observer qualification after the verified scalar-copy repair. '
                        'Historical native causes remain P1-open and the prior copy-preservation intake remains failed. '
                        'Fixed same-repository alternate indexes; unchanged native calls, limits and failure-only witness. '
                        'OS tools are required read-only external dependencies; all owned data is repository-local.'}
    original.save('corrected-' + action + '-started.json.gz', started)
    rows = []
    if action == 'controls':
        for scenario in ('healthy', 'query_gap', 'write_gap', 'retention_gap', 'diagnostic_errno', 'coverage_gap'):
            selector = 'control_' + scenario
            original.prepare(selector)
            row = original.command(['perl', *original.LIB, str(AUDIT / 'observe.pl'), selector])
            row['selector'] = selector
            rows.append(row)
            if not original.control_ready(row, scenario):
                break
        if ready_for_reuse(rows):
            row = original.command(['perl', *original.LIB, str(AUDIT / 'observe.pl'), 'control_healthy'])
            row['selector'] = 'reuse'
            rows.append(row)
    else:
        for target in original.TESTS:
            original.prepare(target)
        rows.append(original.command(['prove', '-v', '--exec', 'perl ' + str(AUDIT / 'observe.pl'), *original.TESTS]))
    after, git_after = original.sources(), original.git_state()
    record = {**started, 'sources_after': after, 'git_after': git_after,
              'source_conserved': before == after, 'git_conserved': git_before == git_after,
              'rows': rows,
              'captures': {str(path.relative_to(work)): original.blob(path.read_bytes())
                           for path in sorted(work.glob('*/*.json*')) if path.is_file()},
              'admissions': {path.name: original.blob(path.read_bytes())
                             for path in sorted(work.glob('*-admission.json'))}}
    original.save('corrected-' + action + '.json.gz', record)
    print(action, 'native statuses', [row['status'] for row in rows],
          'sources conserved', before == after, 'primary index conserved', git_before == git_after, flush=True)
    subprocess.run(['python3', '-B', str(AUDIT / 'verify.py'), action], check=True, timeout=30)


if __name__ == '__main__':
    assert sys.argv[1:] in (['controls'], ['regression'])
    main()
