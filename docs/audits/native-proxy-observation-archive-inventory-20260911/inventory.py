"""Capture the exact bounded source closure of the complete archive evidence."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-inventory-20260911'
SAFE_PATH = 'docs/audits/native-proxy-observation-archive-close-join-20260911/inventory.py'
_spec = importlib.util.spec_from_file_location('archive_inventory_safe', ROOT / SAFE_PATH)
SAFE = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(SAFE)
read, historical = SAFE.read, SAFE.historical


def digest(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def document(path):
    return json.loads(read(path)[0])


def tree(revision, prefix):
    return subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, '--', prefix], cwd=ROOT).decode().splitlines()


def body(raw, name):
    text = raw.decode(); marker = 'sub ' + name + ' {'
    assert text.count(marker) == 1
    text = text[text.index(marker):].split('\nsub ', 1)[0]
    return (text[:text.rindex('\n}') + 2] + '\n').encode()


def collect(plan):
    paths = set(plan['infrastructure'] + plan['extra_inputs'])
    domains = []; epochs = []; prospective = []; receipts = []
    corrections = {row['canonical']: row for row in plan['corrections']}
    for domain in plan['domains']:
        name, base = domain['name'], domain['source']
        files = tree(plan['source_revision'], base)
        assert files and all(path.startswith(base + '/') for path in files)
        assert files == tree(domain['completed_revision'], base)
        paths.update(files)
        domains.append(dict(name=name, source=base, files=files, completed_revision=domain['completed_revision']))
        for path in files:
            assert read(path)[0] == historical(domain['completed_revision'], path)
        child = document(base + '/plan.json'); assert child['source_revision'] == domain['source_epoch']
        for pin in child.get('inputs', []):
            paths.add(pin['path']); raw = read(pin['path'])[0]
            assert digest(raw) == {key: pin[key] for key in ('size_bytes', 'sha256')}
            assert raw == historical(domain['source_epoch'], pin['path'])
            epochs.append(dict(domain=name, source_epoch=domain['source_epoch'], path=pin['path'], **digest(raw)))
        if domain['kind'] == 'join':
            joined = document(base + '/result/source-inventory.json')
            paths.update(row['path'] for row in joined['inputs'])
        candidates = [path for path in [base + '/preflight-pins.json', base + '/result/preflight-pins.json'] if path in files]
        if candidates:
            pin_bytes = [read(path)[0] for path in candidates]; assert all(raw == pin_bytes[0] for raw in pin_bytes)
            for pin in json.loads(pin_bytes[0]):
                correction = corrections.get(pin['path']); selected = correction['original'] if correction else pin['path']
                assert selected in paths
                raw = read(selected)[0]; assert digest(raw) == {key: pin[key] for key in ('size_bytes', 'sha256')}
                prospective.append(dict(domain=name, path=pin['path'], authenticated_path=selected, **digest(raw)))
                if correction:
                    assert correction['domain'] == name
                    postrun = document(correction['postrun_pin']); assert postrun['path'] == pin['path']
                    raw = read(pin['path'])[0]; assert digest(raw) == {key: postrun[key] for key in ('size_bytes', 'sha256')}
                    prospective.append(dict(domain=name, path=pin['path'], authenticated_path=pin['path'], corrected=True, **digest(raw)))
        else:
            assert domain['kind'] == 'handoff-support'
        manifest = document(base + '/result/recovery-copies.json'); assert manifest['all_copies_byte_exact'] is True
        destinations = [row['destination'] for row in manifest['files']]
        assert len(destinations) == len(set(destinations))
        for row in manifest['files']:
            destination = row['destination']; assert destination in files and destination.startswith(base + '/result/')
            suffix = destination[len(base + '/result/'):]
            assert row['source'] == '.artifacts/logs/' + base.rsplit('/', 1)[-1] + '/' + suffix
            raw = read(destination)[0]; assert digest(raw) == {key: row[key] for key in ('size_bytes', 'sha256')}
            receipts.append(dict(domain=name, **row))
    assert len(paths) <= plan['input_limits']['files']
    inputs = []
    for path in sorted(paths):
        raw, identity = read(path, plan['input_limits']['file_bytes'])
        assert raw == historical(plan['source_revision'], path)
        inputs.append(dict(path=path, **identity))
    assert sum(row['size_bytes'] for row in inputs) <= plan['input_limits']['total_bytes']
    handoff = next(row for row in plan['domains'] if row['kind'] == 'handoff-support')
    functions = []
    for selected in plan['handoff_functions']:
        path, name = selected['path'], selected['function']; assert path in paths
        current = body(read(path)[0], name)
        assert current == body(historical(handoff['completed_revision'], path), name)
        functions.append(dict(**selected, source_epoch=handoff['completed_revision'], **digest(current)))
    return dict(schema='fsmgen.inactive_archive_complete_inventory.v1', source_revision=plan['source_revision'],
                domains=domains, inputs=inputs, source_epochs=epochs, prospective=prospective, recovery_receipts=receipts,
                handoff_functions=functions, total_bytes=sum(row['size_bytes'] for row in inputs))


def pins():
    rows = document(str((BASE / 'preflight-pins.json').relative_to(ROOT)))
    assert [row['path'] for row in rows] == [str((BASE / name).relative_to(ROOT)) for name in ['plan.json', 'inventory.py', 'audit.py']]
    for row in rows:
        assert digest(read(row['path'])[0]) == {key: row[key] for key in ('size_bytes', 'sha256')}
    return rows


if __name__ == '__main__':
    pins(); plan = document(str((BASE / 'plan.json').relative_to(ROOT)))
    assert LOG.is_dir() and not LOG.is_symlink() and LOG.stat().st_dev == ROOT.stat().st_dev
    result = collect(plan)
    with (LOG / 'inventory.json').open('x') as stream:
        stream.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(domains=len(result['domains']), files=len(result['inputs']), bytes=result['total_bytes'],
                         source_epochs=len(result['source_epochs']), prospective=len(result['prospective']),
                         recovery_receipts=len(result['recovery_receipts']), handoff_functions=len(result['handoff_functions'])), sort_keys=True))
