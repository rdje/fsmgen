"""Verify the retained read-only sweep without rescanning or deleting data."""
import copy
import hashlib
import json
import stat
import subprocess
from datetime import datetime
from pathlib import Path, PurePosixPath

BASE = Path('docs/audits/artifact-sweep-due-20261007')
REVISION = 'e0620dd2ffb04c340b91693a04f5885c8abb6595'
RUST = tuple(base + '/' + tail for base in ('target', 'rust/target')
             for tail in ('release', 'debug/incremental', 'debug/deps'))


def require(ok, cause):
    if not ok:
        raise ValueError(cause)


def check(record):
    require(record['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.77'
            and record['revision'] == REVISION, 'exact dated sweep authority')
    prior = subprocess.check_output(['git', 'show', REVISION + ':docs/ARTIFACT_CLEANUP.md'], text=True)
    require(record['prior_record'] == prior, 'whole committed prior cleanup record')
    prior_time = datetime.fromisoformat(prior.splitlines()[2].split(' — ', 1)[0])
    require((datetime.fromisoformat(record['utc']) - prior_time).total_seconds() > 86400, 'daily due interval')
    require(record['removed'] == [], 'read-only sweep cannot claim deletion')
    paths = [row['path'] for row in record['artifacts']]
    require(paths == sorted(set(paths)), 'unique ordered artifact population')
    for row in record['artifacts']:
        path = PurePosixPath(row['path'])
        require(not path.is_absolute() and '..' not in path.parts and path.suffix in ('.bin', '.log', '.pyc', '.stdout', '.stderr'),
                'repository-relative artifact scope')
        require(set(row) == {'path', 'bytes', 'device', 'inode', 'mode', 'nlink', 'mtime_ns'}
                and all(type(row[k]) is int for k in row if k != 'path')
                and stat.S_ISREG(row['mode']) and row['bytes'] >= 0 and row['nlink'] >= 1,
                'complete dated regular-node metadata')
        require(all(row['path'] != b['path'] and not row['path'].startswith(b['path'] + '/')
                    for b in record['boundaries']), 'excluded boundary membership')
    require(type(record['independent_rg']['status']) is int and record['independent_rg']['status'] in (0, 1)
            and sorted(record['independent_rg']['stdout'].splitlines()) == paths,
            'independent complete rg/os.walk membership')
    require([row['path'] for row in record['rust']] == list(RUST), 'complete conventional Rust locations')
    for row in record['rust']:
        members = [p for p in paths if p.startswith(row['path'] + '/') and p.endswith(('.bin', '.log'))]
        require(row['status'] in ('absent', 'censused') and row['retained'] == members
                and (row['status'] != 'absent' or not members), 'own complete Rust artifact membership')


def main():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    require({p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}, 'whole sweep seal membership')
    for name, expected in manifest.items():
        raw = (BASE / name).read_bytes()
        require({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()} == expected, 'whole sealed member: ' + name)
    record = json.loads((BASE / 'census.json').read_text())
    check(record)
    controls = []
    for name, mutate, cause in [
        ('Boolean-rg-status', lambda r: r['independent_rg'].update(status=True), 'independent complete rg/os.walk membership'),
        ('Boolean-node-size', lambda r: r['artifacts'][0].update(bytes=True), 'complete dated regular-node metadata'),
        ('member-omission', lambda r: r['artifacts'].pop(), 'independent complete rg/os.walk membership'),
        ('escaped-path', lambda r: r['artifacts'][0].update(path='../escape.bin'), 'repository-relative artifact scope'),
        ('fabricated-deletion', lambda r: r.update(removed=['unproved.bin']), 'read-only sweep cannot claim deletion'),
        ('non-due-time', lambda r: r.update(utc='2026-10-04T07:08:38+00:00'), 'daily due interval'),
    ]:
        bad = copy.deepcopy(record)
        mutate(bad)
        try:
            check(bad)
        except ValueError as error:
            require(str(error) == cause, 'intended sweep control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green sweep control: ' + name)
    print(json.dumps({'status': 0, 'controls': controls, 'scope': 'Dated read-only census; no artifact deletion or byte-hash claim.'}, sort_keys=True))


if __name__ == '__main__':
    main()
