"""Replay unchanged source-plane history with an explicit helper snapshot role.

This command does not qualify current cards, queries, source assets or reader
guidance. Their separately owned current reader must accompany publication.
"""
import argparse
import hashlib
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')
PLANE = Path('docs/audits/book-source-plane-20261005/verify.py')
HELPER = 'docs/audits/record-value-current-helper-reader-20261005/verify.py'
REVISION = 'ebd3df0c21d2e8383e179cf88a81f0c780568e14'


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def authenticate(binding):
    require(binding['revision'] == REVISION, 'exact historical adapter revision')
    require(set(binding['archives']) == {'docs/audits/book-source-plane-20261005',
                                       'docs/audits/record-value-current-helper-reader-20261005',
                                       'docs/audits/record-value-own-subtest-boundaries-20261005'},
            'complete historical adapter archive domain')
    for directory, members in binding['archives'].items():
        require(set(members) == {path.name for path in Path(directory).iterdir()}, 'whole historical adapter archive membership')
        for name, pin in members.items():
            path = Path(directory) / name
            raw = path.read_bytes()
            require(same(identity(raw), pin), 'whole historical adapter archive identity')
            require(raw == subprocess.check_output(['git', 'show', REVISION + ':' + str(path)]),
                    'whole committed historical adapter archive bytes')
    if (BASE / 'manifest.json').exists():
        manifest = json.loads((BASE / 'manifest.json').read_text())
        require(set(manifest) == {path.name for path in BASE.iterdir()} - {'manifest.json'}, 'whole role adapter seal membership')
        for name, pin in manifest.items():
            require(same(identity((BASE / name).read_bytes()), pin), 'whole role adapter seal identity')


class HistoricalSubprocess:
    """Conserve all calls except the exact declared historical helper role."""
    def __init__(self, runner=subprocess.run):
        self.runner = runner
        self.calls = []

    def __getattr__(self, name):
        return getattr(subprocess, name)

    def run(self, command, *args, **kwargs):
        if HELPER in command:
            expected = [sys.executable, '-B', HELPER, '--current']
            require(command == expected and not self.calls, 'exact single original historical helper invocation')
            adapted = [sys.executable, '-B', HELPER, '--snapshot']
            result = self.runner(adapted, *args, **kwargs)
            require(type(result.returncode) is int and result.returncode == 0, 'successful actual historical helper snapshot')
            self.calls.append({'original': ['runtime-python', '-B', HELPER, '--current'],
                               'adapted': ['runtime-python', '-B', HELPER, '--snapshot'],
                               'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr})
            return result
        return self.runner(command, *args, **kwargs)

    def complete(self):
        require(len(self.calls) == 1, 'complete single historical helper role adaptation')


def replay():
    authenticate(json.loads((BASE / 'binding.json').read_text()))
    spec = importlib.util.spec_from_file_location('unchanged_historical_source_plane', PLANE)
    plane = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(plane)
    proxy = HistoricalSubprocess()
    plane.subprocess = proxy
    original_argv = sys.argv
    try:
        sys.argv = [str(PLANE)]
        plane.main()
    finally:
        sys.argv = original_argv
    proxy.complete()
    return proxy.calls


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', action='store_true', help='replay immutable history (also the default); never current qualification')
    parser.parse_args()
    calls = replay()
    proof = {'calls': calls,
             'scope': 'Exact original source-plane predicates and products at their historical boundary; one old helper call uses its existing snapshot mode. Current semantic currency is not established.'}
    target = BASE / 'proofs.json'
    if target.exists():
        require(same(json.loads(target.read_text()), proof), 'whole saved historical role-adapter proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed historical adapter cannot publish')
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS unchanged historical source-plane predicates with exact helper snapshot role; current semantic/source currency remains separately required.')


if __name__ == '__main__':
    main()
