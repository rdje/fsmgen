"""Exercise real generated-plane refusal and write-locality boundaries."""
import copy
import importlib.util
import json
import os
import shutil
from pathlib import Path

BASE = Path('docs/audits/book-source-plane-20261005')
FIXTURE = BASE / 'plane-controls'


def main():
    spec = importlib.util.spec_from_file_location('native_source_plane', 'scripts/book_source_references.py')
    plane = importlib.util.module_from_spec(spec); spec.loader.exec_module(plane)
    original_root = plane.ROOT
    assert not FIXTURE.exists(); FIXTURE.mkdir()
    plane.ROOT = FIXTURE.resolve(); canonical = FIXTURE / 'canonical'; canonical.mkdir()
    sources = {'canonical/one.txt':'first canonical source\n', 'canonical/two.txt':'other canonical source\n'}
    rows = [{'chapter':'90-reference-map', 'role':'retained-engineering-evidence', 'source':p, 'asset':plane.asset_for(p)} for p in sorted(sources)]
    for p, text in sources.items(): (FIXTURE / p).write_text(text)
    plane.write(rows); plane.check(rows)
    manifest = FIXTURE / plane.MANIFEST; baseline_manifest = manifest.read_bytes()
    first = FIXTURE / 'docs/book/src' / rows[0]['asset']; endpoint = os.readlink(first)
    controls = []
    def reject(name, operation):
        try: operation()
        except ValueError as error: controls.append({'control':name,'refusal':str(error)})
        else: raise AssertionError('false-green plane control: '+name)
    for name, change in (
        ('lost-member', lambda r:r.pop()),
        ('wrong-source-role', lambda r:r[0].update(role='operational-state-or-direction')),
        ('wrong-source', lambda r:r[0].update(source='canonical/two.txt')),
    ):
        candidate = copy.deepcopy(rows); change(candidate)
        manifest.write_bytes(b'\n'.join(json.dumps(r,sort_keys=True,separators=(',',':')).encode() for r in candidate)+b'\n')
        reject(name, lambda:plane.check(rows)); manifest.write_bytes(baseline_manifest)
    first.unlink(); first.symlink_to(os.path.relpath(FIXTURE.resolve()/'canonical/two.txt',first.parent.resolve()))
    reject('wrong-endpoint', lambda:plane.check(rows)); first.unlink(); first.symlink_to(endpoint)
    extra = FIXTURE / plane.PLANE / 'unexpected.source.txt'; extra.write_text('unexpected\n')
    reject('extra-member', lambda:plane.check(rows)); extra.unlink()
    for name, value in (('absolute-source','/private/tmp/foreign.txt'), ('escaping-source','../foreign.txt'), ('Boolean-source',True)):
        candidate = copy.deepcopy(rows); candidate[0]['source'] = value
        reject(name, lambda:plane.validate_rows(candidate))
    candidate = copy.deepcopy(rows); candidate[1]['asset'] = candidate[0]['asset']
    reject('colliding-address', lambda:plane.validate_rows(candidate))
    marker = canonical / '.git'; marker.mkdir()
    reject('foreign-repository-parent', lambda:plane.source_bytes('canonical/one.txt')); marker.rmdir()
    blocked = FIXTURE / 'blocked-parent'; blocked.symlink_to('canonical', target_is_directory=True)
    reject('symlink-output-parent-before-write', lambda:plane.create_parents(FIXTURE.resolve()/'blocked-parent/new/asset'))
    assert not (canonical / 'new').exists(); blocked.unlink()
    ignore = canonical / '.gitignore'; ignore.write_text('*\n')
    reject('ignored-source', lambda:plane.check(rows)); ignore.unlink()
    output = FIXTURE / 'built'; output.mkdir()
    for row in rows:
        path = output / row['asset']; path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes((FIXTURE/row['source']).read_bytes())
    (output / 'reference-source/routes.jsonl').write_bytes(baseline_manifest)
    plane.check(rows, 'built')
    (canonical / 'one.txt').write_text('changed canonical source\n'); plane.check(rows)
    reject('stale-native-copy', lambda:plane.check(rows,'built'))
    (output / rows[0]['asset']).write_bytes((canonical / 'one.txt').read_bytes()); plane.check(rows,'built')
    record = {'baseline_rows':rows, 'baseline_sources':sources, 'manifest':baseline_manifest.decode(),
              'source_change':'changed canonical source\n','controls':controls,
              'positive':'Current source endpoint survives meaningful source update; old native copied bytes reject, updated copied bytes pass.',
              'scope':'Actual real filesystem fixture within the owning repository, no separate Git repository or production source/asset mutation.'}
    target=BASE/'plane-control-proofs.json'; assert not target.exists()
    target.write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
    plane.ROOT = original_root; plane.check(plane.expected_rows())
    assert FIXTURE.parent == BASE and FIXTURE.name == 'plane-controls'; shutil.rmtree(FIXTURE)
    assert not FIXTURE.exists()
    print('PASS actual source-plane member/source/role/path/endpoint/ignore/write-locality/stale controls reject; updated current native bytes pass.')


if __name__ == '__main__': main()
