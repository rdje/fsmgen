"""Reexecute whole unchanged semantic candidates and independent native bodies."""
import json
from pathlib import Path
import subprocess

from capture import BASE, canonical, pin, save

PRIOR = Path('docs/audits/raw-semantic-links-20261011')
SEMANTIC = 'PASS independent complete original raw semantic links; inherited bodies and native/private limits conserve.\n'
NATIVE = 'PASS independent original UTF-8 body, empty membership and lossless physical byte conservation; semantics remain pending.\n'
SUCCESS = 'PASS complete original positive/hostile semantic and native-body controls; prior meanings and native/private limits conserve.\n'


def cases():
    rows = json.loads((PRIOR / 'controls.json').read_bytes())['cases']
    return [dict(name=row['name'], member=row['member'], cause=row['cause']) for row in rows] + [
        dict(name='boolean-phase', member='control-boolean-phase.json.gz', cause='semantic complete ordered throw-phase allocation')]


def programmes():
    return {str(PRIOR / name): dict(body=(body := (PRIOR / name).read_bytes()).decode(), identity=pin(body))
            for name in ('reader.py', 'common.py', 'native.pl')}


def main():
    declared = cases()
    epoch = programmes()
    outcomes = {}
    for row in declared:
        path = PRIOR / row['member']
        before = pin(path.read_bytes())
        pair = {}
        for role, command in (
            ('native', ['perl', str(PRIOR / 'native.pl'), str(path)]),
            ('semantic', ['python3', '-B', str(PRIOR / 'reader.py'), str(path)])):
            actual = subprocess.run(command, capture_output=True, text=True)
            result = dict(command=command, status=actual.returncode, stdout=actual.stdout, stderr=actual.stderr,
                          candidate=before, candidate_after=pin(path.read_bytes()), programmes=epoch, programmes_after=programmes())
            name = 'case-' + row['name'] + '-' + role + '.json'
            save(name, result)
            pair[role] = pin(canonical(result))
            assert result['candidate'] == result['candidate_after'] and result['programmes'] == result['programmes_after']
            if role == 'native':
                assert actual.returncode == 0 and actual.stdout == NATIVE and actual.stderr == ''
            elif row['cause'] is None:
                assert actual.returncode == 0 and actual.stdout == SEMANTIC and actual.stderr == ''
            else:
                assert actual.returncode == 1 and actual.stdout == '' and actual.stderr.endswith('ValueError: ' + row['cause'] + '\n')
        outcomes[row['name']] = pair
    save('controls-result.json', dict(cases=declared, outcomes=outcomes, programmes=epoch,
        condition='Actual unchanged complete candidate/native/source-first reader calls. Every inherited raw byte meaning passes separately before the intended semantic refusal. Original native/private classes, identities and source-model assumptions retain.'))
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
