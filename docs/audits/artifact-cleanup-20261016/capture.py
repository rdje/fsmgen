"""Retain native fixed cleanup actions and declared source/input boundaries."""
from pathlib import Path
import argparse
import base64
import gzip
import hashlib
import json
import subprocess

BASE = Path('docs/audits/artifact-cleanup-20261016')
SCRIPT = (BASE / 'cleanup.py').as_posix()
COMMANDS = {
    'inspect': ['python3', '-B', SCRIPT, 'inspect'],
    'apply': ['python3', '-B', SCRIPT, 'apply'],
    'inspect-repaired': ['python3', '-B', SCRIPT, 'inspect'],
    'apply-repaired': ['python3', '-B', SCRIPT, 'apply'],
    'verify': ['python3', '-B', SCRIPT, 'verify'],
    'omit-member': ['python3', '-B', SCRIPT, 'verify', '--omit-member'],
    'alter-byte': ['python3', '-B', SCRIPT, 'verify', '--alter-byte'],
    'alter-protection': ['python3', '-B', SCRIPT, 'verify', '--alter-protection'],
    'book': ['mdbook', 'build', 'docs/book', '-d', '.artifacts/artifact-cleanup-20261016/book'],
    'knowledge': ['knowledge-map/scripts/check_knowledge_map.sh'],
    'inventory': ['scripts/check_claim_verification_inventory.pl', '--write'],
    'staged': ['scripts/check_doctrines.sh'],
}


def record(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def inputs():
    paths = set(BASE.glob('*.py'))
    paths.update(Path(name) for name in [
        'scripts/run_with_ram_guard.sh', 'scripts/check_doctrines.sh',
        'doctrine/live_document_size/surfaces.jsonl', 'MEMORY.md',
        'docs/ARTIFACT_CLEANUP.md', 'docs/TASK_TREE.md',
        'docs/tasks/ARTIFACT-CLEANUP-20261016.md',
        'docs/book/src/10-errors-strict-mode-and-troubleshooting.md'])
    return {path.as_posix(): record(path.read_bytes()) for path in sorted(paths)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=sorted(COMMANDS))
    args = parser.parse_args()
    expected = 1 if args.action in ('omit-member', 'alter-byte', 'alter-protection') else 0
    folder = Path('.artifacts/artifact-cleanup-20261016/checks') / args.action
    folder.mkdir(parents=True, exist_ok=False)
    before = inputs()
    command = ['scripts/run_with_ram_guard.sh', '--', *COMMANDS[args.action]]
    start = dict(owner='ARTIFACT-CLEANUP-20261016.1', command=command,
                 expected_status=expected, before=before,
                 boundary='Complete owned programmes and enumerated delivery inputs; '
                          'not an undeclared full transitive repository-input census. '
                          'Apply intentionally overwrites only the latest cleanup record.')
    with (BASE / (args.action + '-started.json.gz')).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(start, sort_keys=True).encode(), mtime=0))
    with (folder / 'stdout').open('xb') as out, (folder / 'stderr').open('xb') as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    after = inputs()
    changed = sorted(name for name in before if before[name] != after[name])
    assert set(before) == set(after)
    actual = dict(**start, status=result.returncode, after=after, changed_inputs=changed,
                  streams={name: record((folder / name).read_bytes()) for name in ['stdout', 'stderr']})
    with (BASE / (args.action + '-actual.json.gz')).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(actual, sort_keys=True).encode(), mtime=0))
    print(args.action, 'native', result.returncode, 'expected', expected,
          'changed declared inputs', changed, flush=True)
    assert result.returncode == expected
    assert changed == (['docs/ARTIFACT_CLEANUP.md'] if args.action in ('apply', 'apply-repaired') else [])


if __name__ == '__main__':
    main()
