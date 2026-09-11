"""Inventory the local sources used by the selected inert evidence oracles."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import re
import types

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-observation-acquisition-join-20260911'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def relative(path):
    path = Path(path).resolve()
    return path.relative_to(ROOT).as_posix()


def direct_bytes(path):
    path = ROOT/path
    assert path.is_file() and path.stat().st_dev == ROOT.stat().st_dev
    cursor = path
    while cursor != ROOT:
        assert not cursor.is_symlink()
        cursor = cursor.parent
    return path.read_bytes()


def pin(path):
    raw = direct_bytes(path)
    return dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def python_sources(root_module):
    queue = [root_module]; seen = set(); files = set(); external = set()
    while queue:
        value = queue.pop()
        if id(value) in seen: continue
        seen.add(id(value)); assert len(seen) <= 1024
        name = getattr(value, '__file__', None)
        if not name: continue
        try: path = relative(name)
        except ValueError:
            external.add(value.__name__); continue
        files.add(path)
        parent = (ROOT/path).parent
        # These are the canonical static data inputs of this audit family.
        # Runtime receipts under LOG are separately authenticated by the join.
        for name in ('plan.json','vectors.json','contract.json'):
            if (parent/name).is_file(): files.add(relative(parent/name))
        for item in vars(value).values():
            if isinstance(item, types.ModuleType): queue.append(item)
            elif isinstance(item, Path) and item.is_file():
                try: path = relative(item)
                except ValueError: continue
                if not path.startswith('.artifacts/') and '/result/' not in path: files.add(path)
    return sorted(files), sorted(external)


def perl_sources(plan):
    previous = json.loads(direct_bytes('docs/audits/native-proxy-observation-remaining-close-20260911/result/preflight-pins.json'))
    selected = {row['path'] for row in previous if row['path'].endswith('.pm')}
    selected.update(['perl/FSM/ProjectDataLocality.pm','t/lib/FSM/Test/ProcessSupervisor.pm',
        'docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm',
        'docs/audits/native-proxy-cleanup-receipts-20260910/CleanupReceipts.pm'])
    known = {Path(path).stem:path for path in selected if path.startswith('docs/audits/')}
    external = set()
    # Check named project dependencies in the declared source/producer set.
    # This is a static source applicability census, not loaded-image attestation.
    for path in sorted(selected | {c['source']+'/qualify.t' for c in plan['components']}):
        for name in re.findall(r'^\s*(?:use|require)\s+([A-Za-z_][A-Za-z0-9_:]*)\b', direct_bytes(path).decode(), re.M):
            candidates = ['perl/'+name.replace('::','/')+'.pm','t/lib/'+name.replace('::','/')+'.pm']
            found = [candidate for candidate in candidates if (ROOT/candidate).is_file()]
            if name in known: found.append(known[name])
            if found:
                assert len(set(found)) == 1, (path,name,'ambiguous local dependency')
                assert found[0] in selected, (path,name,'undeclared local dependency')
            else:
                assert not name.startswith('FSM::'), (path,name,'missing project dependency')
                external.add(name)
    return sorted(selected), sorted(external)


def build(plan):
    components = []
    all_files = set()
    perl, perl_external = perl_sources(plan)
    all_files.update(perl)
    for component in plan['components']:
        oracle = module('join_inventory_'+component['name'], ROOT/component['source']/'audit.py')
        files, external = python_sources(oracle)
        files = sorted(set(files) | {component['source']+'/qualify.t',component['source']+'/plan.json'})
        all_files.update(files)
        components.append(dict(name=component['name'], source_epoch=component['source_epoch'],
            local_oracle_producer_inputs=files, external_python_modules=external))
    return dict(schema='fsmgen.inactive_acquisition_source_inventory.v1',
        components=components, declared_perl_sources=perl, named_external_perl_dependencies=perl_external,
        source_pins=[pin(path) for path in sorted(all_files)],
        limits='Reachable local Python module objects, their canonical static plan/vector/contract inputs and declared Perl producer/runtime sources. Named Perl project dependencies must resolve uniquely inside the declared set. Installed interpreter/standard-library/toolchain dependencies are required read-only external inputs; no project data is written there. This is static source applicability, not native loaded-image or arbitrary dynamic-import attestation.')


if __name__ == '__main__':
    result = build(json.loads((BASE/'plan.json').read_bytes()))
    (LOG/'source-inventory.json').write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
    print(json.dumps(dict(local_source_inputs=len(result['source_pins']),
        declared_perl_sources=len(result['declared_perl_sources']),
        components={c['name']:len(c['local_oracle_producer_inputs']) for c in result['components']}),sort_keys=True))
