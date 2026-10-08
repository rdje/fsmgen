"""Consume complete actual current/native/copy results without summary substitution."""
import copy
import hashlib
import json
import re
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-route-checks-20261008')
CURRENT = 'PASS current class/frame facts, complete current source/query allocation and unchanged capacity/source contracts.\n'
COPIED = 'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def check(row, args, success):
    need(type(row['status']) is int and row['status'] == 0, 'actual workflow integer success')
    paths = [BASE / 'run.py', Path('scripts/run_with_ram_guard.sh')]
    paths.extend(Path(arg) for arg in args if arg.startswith(('docs/', 'scripts/', 't/')) and Path(arg).is_file())
    need(set(row) == {'command', 'status', 'stdout', 'stderr', 'instruments'}
         and row['command'] == ['scripts/run_with_ram_guard.sh', '--', *args]
         and row['stdout'] == success
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and row['instruments'] == {str(p): pin(p.read_bytes()) for p in paths}, 'complete actual workflow command streams and instruments')


def main():
    results = []
    for name, args, success in (
        ('current', ['python3', '-B', 'scripts/check_record_value_publication.py'], CURRENT),
        ('current-native', ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', '.artifacts/coordinate-public-route-book'], CURRENT),
        ('copied', ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', '.artifacts/coordinate-public-route-book'], COPIED),
    ):
        row = json.loads((BASE / (name + '.json')).read_bytes()); check(row, args, success)
        controls = []
        for control, mutate, cause in (
            ('Boolean-status', lambda r: r.update(status=False), 'actual workflow integer success'),
            ('lost-output', lambda r: r.update(stdout=''), 'complete actual workflow command streams and instruments'),
            ('borrowed-source', lambda r: r['instruments'].pop(next(iter(r['instruments']))), 'complete actual workflow command streams and instruments'),
        ):
            candidate = copy.deepcopy(row); mutate(candidate)
            need(json.dumps(candidate, sort_keys=True) != json.dumps(row, sort_keys=True), 'genuine actual workflow control')
            try:
                check(candidate, args, success)
            except ValueError as error:
                need(str(error) == cause, 'intended actual workflow refusal')
                controls.append(dict(name=control, status=1, cause=cause))
            else:
                raise ValueError('false-green actual workflow control')
        results.append(dict(name=name, actual=row, controls=controls))
    instruments = {str(p): pin(p.read_bytes()) for p in map(Path, (
        'scripts/check_record_value_publication.py', 'scripts/record_value_public_reference_fact.py',
        't/python/test_record_value_current_publication.py'))}
    proof = dict(results=results, programme_closure=instruments,
                 scope='Whole actual current and native/copy receipts. Prose review, independent source allocation and public raw custody retain their separate proofs. Visual QA and original identities remain open.')
    path = BASE / 'workflow-proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained workflow proof')
    else:
        path.write_text(raw)
    print('PASS whole actual current/native/copied-source results and genuine receipt controls; original identities and visual QA remain open.')


if __name__ == '__main__':
    main()
