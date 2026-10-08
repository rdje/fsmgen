"""Consume the whole independent qualification receipt and its exact proof."""
import copy
import hashlib
import json
import re
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-qualification-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-public-qualification-20261008')
SUCCESS = 'PASS independent complete public source/wire/result qualification and genuine controls; no original identity or capture execution.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def check(row):
    need(type(row['status']) is int and row['status'] == 0, 'actual whole-public reader integer success')
    script = BASE / 'verify_saved.py'
    paths = [BASE / 'run.py', Path('scripts/run_with_ram_guard.sh'), script]
    need(set(row) == {'status', 'command', 'stdout', 'stderr', 'instruments'}
         and row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(script)]
         and row['stdout'] == SUCCESS
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and row['instruments'] == {str(p): pin(p.read_bytes()) for p in paths},
         'actual whole-public command/streams/instruments')


def main():
    actual = json.loads((BASE / 'saved-result.json').read_bytes()); check(actual)
    proof = json.loads((BASE / 'proof.json').read_bytes())
    need(proof['members'] == {p.name: pin(p.read_bytes()) for p in MODEL.iterdir() if p.name != 'manifest.json'},
         'actual independent proof binds the whole sealed product')
    controls = []
    for name, mutate, cause in (
        ('Boolean-status', lambda c: c.update(status=False), 'actual whole-public reader integer success'),
        ('borrowed-reader', lambda c: c['instruments'].pop(str(BASE / 'verify_saved.py')), 'actual whole-public command/streams/instruments'),
        ('lost-output', lambda c: c.update(stdout=''), 'actual whole-public command/streams/instruments'),
    ):
        candidate = copy.deepcopy(actual); mutate(candidate)
        need(json.dumps(candidate, sort_keys=True) != json.dumps(actual, sort_keys=True), 'genuine actual receipt mutation')
        try:
            check(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended actual qualification refusal')
            controls.append(dict(control=name, status=1, cause=cause, candidate=candidate))
        else:
            raise ValueError('false-green actual qualification control')
    result = dict(actual=actual, controls=controls, independent_proof=pin((BASE / 'proof.json').read_bytes()),
                  programme=pin((BASE / 'execute_readers.py').read_bytes()),
                  scope='Actual dated finite public qualification consumed. Final publication and every original/private/formatter/toolchain/address identity remain pending.')
    path = BASE / 'actual-proof.json'; raw = json.dumps(result, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained actual qualification proof')
    else:
        path.write_text(raw)
    print('PASS whole independent public qualification actual result custody and genuine controls; final publication and original identities remain pending.')


if __name__ == '__main__':
    main()
