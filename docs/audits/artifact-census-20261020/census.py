"""Dated read-only artifact census and saved replay; never delete candidates."""
import argparse
import copy
from datetime import datetime, timezone
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess

ROOT = Path(__file__).resolve().parents[3]
SELF = Path(__file__).resolve().relative_to(ROOT).as_posix()
OUTPUT = Path(__file__).with_name('census.json.gz')
BASE = 'fc5962a88f1dae8b2e05f4eca3e7fa884dfd4b41'
PRIOR = 'docs/ARTIFACT_CLEANUP.md'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.87'
LOCATIONS = ['', *[base + '/' + suffix for base in ('target', 'rust/target')
                 for suffix in ('release', 'debug/incremental', 'debug/deps')]]
SCOPE = ('Dated regular log/bin path and lstat metadata census only; no content, '
         'disposal authority, physical reclamation or future absence claim. '
         'Git metadata, foreign repositories, symlinks and other volumes are excluded. '
         'Every observed candidate is retained. Saved replay never walks or deletes.')


def git(*args):
    return subprocess.check_output(['git', '--no-replace-objects', *args], cwd=ROOT)


def relative(value):
    assert type(value) is str and value and not value.startswith('/')
    assert all(part not in ('', '.', '..') for part in value.split('/'))
    return value


def failed_walk(error):
    raise error


def collect():
    assert git('rev-parse', 'HEAD').decode().strip() == BASE
    prior = (ROOT / PRIOR).read_bytes()
    assert prior == git('show', BASE + ':' + PRIOR), 'native prior cleanup record'
    previous = re.search(rb'^([0-9T:.+\-]+) ', prior, re.M)
    assert previous, 'prior UTC cleanup timestamp'
    now = datetime.now(timezone.utc)
    assert (now - datetime.fromisoformat(previous[1].decode())).total_seconds() > 86400
    device = ROOT.stat().st_dev
    candidates, exclusions = {}, []
    for directory, children, names in os.walk(ROOT, followlinks=False, onerror=failed_walk):
        parent = Path(directory)
        if parent != ROOT and ((parent / '.git').exists() or (parent / '.git').is_symlink()):
            exclusions.append(dict(path=parent.relative_to(ROOT).as_posix(), reason='foreign_repository'))
            children[:] = []
            continue
        kept = []
        for name in sorted(children):
            path = parent / name
            info = path.lstat()
            reason = ('git_metadata' if name == '.git' else
                      'symlink' if stat.S_ISLNK(info.st_mode) else
                      'other_volume' if info.st_dev != device else None)
            if reason:
                exclusions.append(dict(path=path.relative_to(ROOT).as_posix(), reason=reason))
            else:
                kept.append(name)
        children[:] = kept
        for name in sorted(names):
            if not name.endswith(('.log', '.bin')):
                continue
            path = parent / name
            info = path.lstat()
            key = path.relative_to(ROOT).as_posix()
            if not stat.S_ISREG(info.st_mode) or info.st_dev != device:
                exclusions.append(dict(path=key, reason='nonregular_or_other_volume'))
                continue
            candidates[key] = dict(bytes=info.st_size, mode=stat.S_IMODE(info.st_mode),
                                   mtime_ns=info.st_mtime_ns, disposition='retained')
    command = ['rg', '--files', '--hidden', '--no-ignore', '-g', '*.log', '-g', '*.bin']
    for row in sorted(exclusions, key=lambda row: row['path']):
        command.extend(['-g', '!' + row['path'], '-g', '!' + row['path'] + '/**'])
    observed = subprocess.run(command, cwd=ROOT, capture_output=True, check=False)
    assert observed.returncode in (0, 1) and observed.stderr == b'', 'independent rg census'
    independent = sorted(observed.stdout.decode().splitlines())
    assert independent == sorted(candidates), 'independent whole candidate membership'
    locations = []
    for name in LOCATIONS:
        members = sorted(path for path in candidates if
                         (path.count('/') == 0 if not name else path.startswith(name + '/')))
        locations.append(dict(path=name or '.', exists=(ROOT / name).exists(), candidates=members))
    return dict(schema='fsmgen.artifact_census.v1', owner=OWNER, revision=BASE,
                utc=now.isoformat(), prior=prior.decode(), source_sha256=hashlib.sha256(
                    (ROOT / SELF).read_bytes()).hexdigest(), scope=SCOPE, candidates=candidates,
                exclusions=sorted(exclusions, key=lambda row: row['path']), locations=locations,
                independent=dict(command=command, status=observed.returncode,
                                 stdout=observed.stdout.decode(), stderr=''), removed=[])


def review(value):
    assert set(value) == {'schema', 'owner', 'revision', 'utc', 'prior', 'source_sha256',
                          'scope', 'candidates', 'exclusions', 'locations', 'independent', 'removed'}
    assert value['schema'] == 'fsmgen.artifact_census.v1' and value['owner'] == OWNER
    assert value['revision'] == BASE and value['scope'] == SCOPE
    assert value['source_sha256'] == hashlib.sha256((ROOT / SELF).read_bytes()).hexdigest()
    assert value['prior'].encode() == git('show', BASE + ':' + PRIOR)
    previous = re.search(r'^([0-9T:.+\-]+) ', value['prior'], re.M)
    assert previous and (datetime.fromisoformat(value['utc']) -
                         datetime.fromisoformat(previous[1])).total_seconds() > 86400
    assert type(value['candidates']) is dict
    for path, row in value['candidates'].items():
        relative(path)
        assert path.endswith(('.log', '.bin'))
        assert set(row) == {'bytes', 'mode', 'mtime_ns', 'disposition'}
        assert all(type(row[key]) is int and row[key] >= 0 for key in ('bytes', 'mode', 'mtime_ns'))
        assert row['disposition'] == 'retained'
    exclusions = value['exclusions']
    assert type(exclusions) is list and len({row['path'] for row in exclusions}) == len(exclusions)
    for row in exclusions:
        assert set(row) == {'path', 'reason'}
        relative(row['path'])
        assert row['reason'] in ('git_metadata', 'foreign_repository', 'symlink',
                                 'other_volume', 'nonregular_or_other_volume')
    receipt = value['independent']
    assert set(receipt) == {'command', 'status', 'stdout', 'stderr'}
    expected = ['rg', '--files', '--hidden', '--no-ignore', '-g', '*.log', '-g', '*.bin']
    for row in exclusions:
        expected.extend(['-g', '!' + row['path'], '-g', '!' + row['path'] + '/**'])
    assert receipt['command'] == expected and receipt['stderr'] == ''
    assert type(receipt['status']) is int and receipt['status'] == (0 if value['candidates'] else 1)
    assert sorted(receipt['stdout'].splitlines()) == sorted(value['candidates'])
    assert len(value['locations']) == len(LOCATIONS)
    for name, row in zip(LOCATIONS, value['locations']):
        assert set(row) == {'path', 'exists', 'candidates'} and row['path'] == (name or '.')
        assert type(row['exists']) is bool
        assert row['candidates'] == sorted(path for path in value['candidates'] if
                                          (path.count('/') == 0 if not name else path.startswith(name + '/')))
    assert type(value['removed']) is list and value['removed'] == []


def controls(value):
    for kind in ('missing_member', 'unsafe_path', 'boolean_size', 'invented_removal'):
        candidate = copy.deepcopy(value)
        if kind == 'invented_removal':
            candidate['removed'] = ['unqualified.log']
        elif kind == 'unsafe_path':
            candidate['candidates']['../unqualified.log'] = dict(bytes=0, mode=420, mtime_ns=0, disposition='retained')
        elif kind == 'missing_member':
            if candidate['candidates']:
                del candidate['candidates'][next(iter(candidate['candidates']))]
            else:
                candidate['independent']['stdout'] = 'unqualified.log\n'
        else:
            candidate['candidates']['type-control.log'] = dict(bytes=True, mode=420, mtime_ns=0, disposition='retained')
        try:
            review(candidate)
        except AssertionError:
            continue
        raise AssertionError('bad saved census admitted: ' + kind)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else json.loads(gzip.decompress(OUTPUT.read_bytes()))
    review(value)
    controls(value)
    if args.write:
        with OUTPUT.open('xb') as target:
            target.write(gzip.compress(json.dumps(value, sort_keys=True).encode(), mtime=0))
    print('Dated artifact census and independent membership verify; all candidates retained, no deletion performed.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Census assertions must be enabled.')
    main()
