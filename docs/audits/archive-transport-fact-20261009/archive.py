"""Controlled Git transport permissions, independent payloads and original failure.

All masks are explicit per process; user configuration is neither assumed nor
written. Git tree modes and archive transport permissions have separate roles.
"""
import copy
import hashlib
import io
import json
import os
import subprocess
import sys
import tarfile
from pathlib import Path

REVISION = 'f5d2e81710ddbd2dd10f406551220d1a5ff2c32a'
PRIOR = Path('docs/audits/coordinate-source-hypothesis-checks-20261009')
FILES = ('docs/audits/coordinate-refusal-phases-20261009/verify.py',
         'scripts/run_with_ram_guard.sh')


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete read-only Git result')
    return result.stdout


def check(members, modes, blobs, mask):
    need(set(members) == set(modes) == set(blobs), 'complete controlled archive membership')
    for path, row in members.items():
        transport_base = 0o777 if modes[path] == '100755' else 0o666
        need(type(row['mode']) is int and row['mode'] == transport_base & ~mask,
             'explicit transport permissions')
        need(row['payload'] == pin(blobs[path]), 'complete independent Git payload')


def main():
    configuration = pin(native('config', '--local', '--null', '--list'))
    tree = native('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *FILES)
    modes, blobs = {}, {}
    for row in tree.rstrip(b'\0').split(b'\0'):
        metadata, path = row.split(b'\t', 1)
        mode, kind, oid = metadata.decode().split()
        need(kind == 'blob' and mode in ('100644', '100755'), 'own regular Git inputs')
        modes[path.decode()] = mode
        blobs[path.decode()] = native('cat-file', 'blob', oid)
    need(tuple(modes) == FILES and sorted(modes.values()) == ['100644', '100755'],
         'one genuine regular and executable Git input')
    observations = []
    for mask in (0o002, 0o022):
        # The first configuration simulates an adverse ambient policy; the final
        # explicit command policy wins. Nothing is persisted to any Git config.
        command = ['git', '--no-replace-objects', '-c', 'tar.umask=0777',
                   '-c', f'tar.umask={mask:04o}', '--literal-pathspecs',
                   'archive', '--format=tar', REVISION, '--', *FILES]
        result = subprocess.run(command, capture_output=True)
        need(result.returncode == 0 and not result.stderr, 'controlled archive process')
        members = {}
        with tarfile.open(fileobj=io.BytesIO(result.stdout)) as archive:
            for member in archive:
                if member.isdir():
                    continue
                need(member.isfile() and member.name not in members, 'unique regular tar population')
                members[member.name] = {'mode': member.mode,
                                       'payload': pin(archive.extractfile(member).read())}
        check(members, modes, blobs, mask)
        observations.append({'command': command, 'status': result.returncode,
                             'stderr': result.stderr.decode(), 'members': members})
    controls = {}
    for name, mutate, expected in (
        ('tracked-mode-equality', lambda rows: rows[FILES[0]].update(mode=0o644), 'explicit transport permissions'),
        ('borrowed-payload', lambda rows: rows[FILES[0]].update(payload=pin(blobs[FILES[1]])), 'complete independent Git payload'),
        ('missing-member', lambda rows: rows.pop(FILES[1]), 'complete controlled archive membership')):
        bad = copy.deepcopy(observations[0]['members'])
        mutate(bad)
        try:
            check(bad, modes, blobs, 0o002)
        except ValueError as error:
            need(str(error) == expected, 'intended archive control predicate')
            controls[name] = str(error)
        else:
            raise ValueError('false-green archive control: ' + name)

    # Replay the unchanged first programme with a declared per-process 0002
    # policy, so a future global tar.umask override cannot invalidate this fact.
    first = PRIOR / 'first-verify.py.txt'
    environment = dict(os.environ)
    count = int(environment.get('GIT_CONFIG_COUNT', '0'))
    need(count >= 0, 'valid inherited process configuration')
    environment.update(GIT_CONFIG_COUNT=str(count + 1))
    environment[f'GIT_CONFIG_KEY_{count}'] = 'tar.umask'
    environment[f'GIT_CONFIG_VALUE_{count}'] = '0002'
    programme = (
        'import runpy\n'
        f'n = runpy.run_path({str(first)!r})\n'
        'try: n["original"]()\n'
        'except ValueError as e:\n'
        ' if str(e) != "independent complete archive mode identity": raise\n'
        ' print(str(e))\n'
        'else: raise ValueError("first failure did not reproduce")\n'
    )
    result = subprocess.run([sys.executable, '-B', '-c', programme],
                            env=environment, capture_output=True, text=True)
    need(result.returncode == 0 and not result.stderr
         and result.stdout == 'independent complete archive mode identity\n',
         'actual original mode failure under controlled 0002')
    previous = json.loads((PRIOR / 'checks.json').read_bytes())
    need(previous['independent-preseal']['status'] == 1
         and 'independent complete archive mode identity' in previous['independent-preseal']['stderr']
         and previous['archive-repair']['status'] == 0, 'complete retained original failure/repair receipts')
    need(pin(native('config', '--local', '--null', '--list')) == configuration,
         'primary configuration conservation')
    print(json.dumps({'result': 'PASS controlled archive masks, independent Git payloads and original failure',
                      'revision': REVISION, 'observations': observations, 'controls': controls,
                      'first_programme': pin(first.read_bytes()),
                      'prior_receipts': pin((PRIOR / 'checks.json').read_bytes()),
                      'controlled_first_failure': {'status': result.returncode,
                                                   'stdout': result.stdout, 'stderr': result.stderr},
                      'local_configuration': configuration}, sort_keys=True))


if __name__ == '__main__':
    main()
