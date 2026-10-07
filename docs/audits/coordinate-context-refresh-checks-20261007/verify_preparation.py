"""Verify exact unexecuted preparation retention and the pending clean frontier."""
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-context-refresh-checks-20261007')
REVISION = 'e78541a5a84559c56cbef73d9afe5cbe1f1e498a'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def check_preparation(candidate):
    expected = {
        'docs/audits/record-value-coordinate-native-control-plans-20261007/scope.txt': 'unexecuted-plan-scope.txt',
        'docs/audits/coordinate-native-control-plan-checks-20261007/run.py': 'unexecuted-plan-runner.py.txt',
    }
    need(set(candidate['retained']) == set(expected), 'complete exact unexecuted scaffold allocation')
    for old, filename in expected.items():
        row = candidate['retained'][old]; saved = BASE / filename
        need(saved.is_file() and not saved.is_symlink()
             and saved.stat().st_dev == Path.cwd().stat().st_dev
             and row['retained'] == str(saved) and row['identity'] == pin(saved.read_bytes()),
             'whole exact unexecuted preparation bytes')
        need(not Path(old).parent.exists(), 'unstarted scaffold removed from active work')


def main():
    preparation = json.loads((BASE / 'preparation.json').read_bytes())
    check_preparation(preparation)
    # Compare the complete closed committed coordinate/public audit population,
    # including extra-member refusal; no spent producer executes.
    roots = sorted(p for p in Path('docs/audits').iterdir()
                   if p.name.startswith(('record-value-coordinate-', 'coordinate-public-')))
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only', REVISION + ':docs/audits']).split(b'\0')
    committed_roots = sorted(Path('docs/audits') / name.decode() for name in names
                             if name.startswith((b'record-value-coordinate-', b'coordinate-public-')))
    need(roots == committed_roots and all(p.is_dir() and not p.is_symlink()
         and p.stat().st_dev == Path.cwd().stat().st_dev for p in roots),
         'complete fixed committed same-volume coordinate/public root population')
    archive = subprocess.check_output(['git', 'archive', REVISION, *map(str, roots)])
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        fixed = {m.name: source.extractfile(m).read() for m in source.getmembers() if m.isfile()}
    current = {str(p): p.read_bytes() for root in roots for p in root.iterdir() if p.is_file() and not p.is_symlink()}
    need(current == fixed and all(p.is_file() and not p.is_symlink() for root in roots for p in root.iterdir()),
         'every complete committed coordinate/public source/raw/programme/actual member conserves')
    scope = (BASE / 'unexecuted-plan-scope.txt').read_text()
    owner = scope.splitlines()[0].removeprefix('Owner: ')
    task = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_text()
    next_owner = owner + '.2'
    start = task.index('- ID: `' + next_owner + '`'); stop = task.index('\n- ID:', start + 1)
    need('\n  Status: `pending`\n' in task[start:stop], 'exact unstarted source-plan frontier remains pending')
    memory = Path('MEMORY.md').read_text()
    need('active_work_unit: `' + next_owner + '` (pending)' in memory
         and 'session paused' in memory, 'committed-pause pointer and exact next owned action')
    mutated = json.loads(json.dumps(preparation))
    mutated['retained'][next(iter(mutated['retained']))]['identity']['sha256'] = '0' * 64
    try:
        check_preparation(mutated)
    except ValueError as error:
        need(str(error) == 'whole exact unexecuted preparation bytes', 'intended borrowed preparation identity refusal')
        refusal = str(error)
    else:
        raise ValueError('false-green changed preparation identity')
    proof = dict(preparation=preparation, protected_members={p: pin(raw) for p, raw in fixed.items()},
                 next_owner=next_owner, next_node=task[start:stop], control=dict(status=1, cause=refusal),
                 scope='Exact preparation retention, whole committed coordinate/public-domain conservation and pending handoff frontier only; no native bad variant or complete source-plan qualification.')
    path = BASE / 'preparation-proof.json'; encoded = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == encoded, 'whole retained dated preparation proof')
    else:
        path.write_text(encoded)
    print('PASS exact unexecuted preparation retention, genuine identity refusal, whole committed coordinate/public conservation and pending source-plan handoff.')


if __name__ == '__main__':
    main()
