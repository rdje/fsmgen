"""Capture the real scoped reader against the immutable stock diagnosis inputs."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path.cwd()
BASE = Path('docs/audits/decision-index-repair-20261008')
OLD = Path('docs/audits/decision-index-scope-20261008')
sys.path[:0] = [str(ROOT / 'scripts'), str(ROOT / 't/python')]
import decision_records as published
import decision_store_git as selected
from test_decision_production_growth import ProductionFixture, REGISTRY, AUTHORITIES


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def receipt(result):
    command = [str(value).replace(str(ROOT) + '/', '') for value in result.args]
    return {'command': command, 'status': result.returncode,
            'stdout': result.stdout.decode(), 'stderr': result.stderr.decode()}


def parse(raw, tree):
    need(raw.endswith(b'\0'), 'complete native inventory frame')
    result = {}
    for record in raw.split(b'\0')[:-1]:
        header, name = record.split(b'\t', 1)
        fields = header.decode().split()
        mode, oid = fields[0], fields[2] if tree else fields[1]
        need(name.decode() not in result, 'unique native path')
        result[name.decode()] = [mode, oid]
    return result


def main():
    diagnosis = subprocess.run([sys.executable, '-B', str(OLD / 'verify.py')], capture_output=True)
    need(diagnosis.returncode == 0 and not diagnosis.stderr, 'immutable whole stock diagnosis qualification')
    prior = json.loads((OLD / 'proof.json').read_bytes())
    paths = [f'scripts/{name}.py' for name in
             ('decision_records', 'decision_store_git', 'decision_catalog', 'decision_store')]
    paths += ['t/python/test_decision_store_git.py', 't/python/test_decision_production_growth.py',
              str(BASE / 'qualify.py'), str(BASE / 'verify.py')]
    sources = {name: {'source': Path(name).read_text(), 'identity': pin(Path(name).read_bytes())}
               for name in paths}
    fixture = ProductionFixture()
    try:
        for path in paths[:4]:
            fixture.write(path, Path(path).read_bytes())
        fixture.git('add', 'scripts')
        fixture.git('commit', '-q', '-m', 'fixture complete current scoped reader')
        data = {name: (fixture.root / name).read_bytes() for name in fixture.original_products}
        changed = {'scripts/decision_records.py', 'scripts/decision_store_git.py'}
        need(set(data) == set(prior['complete_before']), 'complete unchanged input membership')
        need(all(pin(raw) == prior['complete_before'][name] for name, raw in data.items()
                 if name not in changed), 'complete non-repair source conservation')
        need(all(pin(data[name]) != prior['complete_before'][name] for name in changed),
             'genuine exact two-source repair')
        payload = b'opaque unrelated qualification data\n'
        oid = subprocess.check_output(['git', '-C', str(fixture.root), 'hash-object', '-w', '--stdin'], input=payload).decode().strip()
        names = ['unrelated/' + 'x' * 160 + f'{i:05}.bin' for i in range(20_001)] + ['λ']
        update = subprocess.run(['git', '-C', str(fixture.root), 'update-index', '--index-info'],
                                input=''.join(f'100644 {oid}\t{name}\n' for name in names).encode(), capture_output=True)
        need(update.returncode == 0 and not update.stdout and not update.stderr, 'real unchanged native opaque population')
        fixture.git('commit', '-q', '-m', 'fixture exact stock inventory population')
        revision = fixture.git('rev-parse', 'HEAD').decode().strip()
        results = []
        for selector in ('index', revision):
            tree = selector != 'index'
            command = ['ls-tree', '-r', '--full-tree', '-z', selector] if tree else ['ls-files', '--stage', '-z']
            wire = fixture.git(*command)
            complete = parse(wire, tree)
            wanted = dict(prior['results'][int(tree)]['complete'])
            for name in changed:
                raw = data[name]
                wanted[name] = ['100644', hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()]
            need(complete == wanted, 'independent exact prior population with two repaired objects')
            canonical_bytes = sum(len(mode) + 1 + len(object_id) + 3 + len(name.encode()) + 1
                                  for name, (mode, object_id) in complete.items())
            need(canonical_bytes > selected.MAX_INVENTORY_BYTES, 'same genuine native inventory overflow')
            try:
                selected.GitSnapshot(fixture.root, selector)
            except ValueError as error:
                need(str(error) == 'Git output exceeds selected snapshot bound', 'default full API keeps its refusal')
                default_refusal = {'status': 1, 'cause': str(error)}
            else:
                raise ValueError('default full inventory falsely accepted overflow')
            snapshot = published.selected_snapshot(fixture.root, selector,
                                                    bindings=(REGISTRY, AUTHORITIES, 'λ/registry.json'))
            need(snapshot.objects == {p: tuple(v) for p, v in prior['results'][int(tree)]['selected'].items()},
                 'real constructor exactly matches complete independently qualified source domain')
            prepared = published.selected_store(fixture.root, snapshot, False,
                                                published.STORE_SOURCE_SHA256, published.STORE_INDEX_SHA256)
            need(prepared == prior['results'][int(tree)]['prepared'], 'complete old semantic products conserve')
            public = fixture.public('check', selector=selector, installed=True)
            need(public.returncode == 0 and not public.stderr and public.stdout ==
                 b'decision-records: authenticated originals, current records, compatibility and indexes verified\n',
                 'complete repaired installed public result')
            controls = []
            for name, cause in [('λ/registry.json', 'selected source has a nondirectory ancestor: λ/registry.json'),
                                (names[0], 'selected source is outside declared scope: ' + names[0])]:
                try:
                    snapshot.read(name)
                except ValueError as error:
                    need(str(error) == cause, 'actual intended scoped read refusal')
                    controls.append({'path': name, 'status': 1, 'cause': cause})
                else:
                    raise ValueError('false green actual scoped read control')
            results.append({'selector': selector, 'native_command': command, 'complete_wire': wire.decode(),
                            'canonical_bytes': canonical_bytes, 'objects': snapshot.objects,
                            'selected_bytes': snapshot.inventory_bytes, 'prepared': prepared,
                            'public': receipt(public), 'default_refusal': default_refusal, 'controls': controls})
        need(all((fixture.root / name).read_bytes() == raw for name, raw in data.items()),
             'complete before/after source conservation')
        proof = {'diagnosis': {'identity': pin((OLD / 'proof.json').read_bytes()), 'actual': receipt(diagnosis)},
                 'sources': sources, 'inputs': {name: raw.decode() for name, raw in data.items()},
                 'results': results, 'native_update': receipt(update),
                 'limits': {'inventory': selected.MAX_INVENTORY_BYTES, 'paths': selected.MAX_TRACKED_PATHS,
                            'document': selected.catalog_api.MAX_DOCUMENT_BYTES,
                            'scope_declarations': selected.catalog_api.MAX_SOURCE_RECORDS},
                 'role': 'Real production constructor and installed public reader on the exact dated stock population; integration closure remains SEM.78.3-owned.'}
    finally:
        fixture.close()
    need(not fixture.root.exists(), 'owned disposable fixture consumed')
    (BASE / 'proof.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS real production scope and complete unchanged stock population/products; default overflow and scoped read controls refuse.')


if __name__ == '__main__':
    main()
