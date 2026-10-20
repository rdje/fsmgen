"""Capture the complete caller proof mismatch before its source-role repair."""
import argparse
import gzip
import json

import diagnose_fixed_gap_sources as diagnostic
import qualify_caller_modules as caller
import saved_reader_sources as source

ROOT, AUDIT = caller.prepare.ROOT, caller.execute.AUDIT
SELF = 'diagnose_caller_sources.py'
READER = 'qualify_caller_modules.py'
OUTPUT = AUDIT / 'caller-source-diagnosis.json.gz'
BASE = '89890bacf79c3f70e5efb905ff793a5ddca4ab4a'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', required=True)
    parser.parse_args()
    assert caller.epoch.read(BASE, str(AUDIT / READER)) == (ROOT / AUDIT / READER).read_bytes()
    original = {name: source.original(name) for name in caller.PREMISES}
    raw = caller.execute.read(caller.PATH)
    assert raw == caller.epoch.read(source.REVISION, str(caller.PATH)), 'unchanged original proof'
    saved = json.loads(gzip.decompress(raw))
    current = caller.derive()
    delta = diagnostic.differences(saved, current)
    assert delta and {tuple(row[:2]) for row in delta} == {
        ('programmes', 'default_dispatch.py'), ('programmes', 'prepare.py'),
        ('programmes', 'qualify_fixed_module_gap.py')}
    caller.bounded.strict_equal(saved['programmes'], {name: row['body'] for name, row in original.items()})
    images = {name: caller.prepare.unblob(row['body']) for name, row in original.items()}
    with diagnostic.metadata_images(images) as reads:
        intervened = caller.derive()
    assert reads == list(caller.PREMISES), 'only declared metadata reads intervened'
    caller.bounded.strict_equal(saved, intervened)
    record = dict(schema='fsmgen.caller_source_diagnosis.v1',
        scope='Complete current caller graph/review/control/scope product differs only in declared source metadata. Historical bytes are metadata images, never executed. No executable-data/default/effects/custody or complete-helper acceptance follows.',
        original_revision=source.REVISION, reader_revision=BASE,
        programmes={name: caller.prepare.blob((ROOT / AUDIT / name).read_bytes())
                    for name in (SELF, 'diagnose_fixed_gap_sources.py')},
        original_sources=original, original_proof=caller.prepare.blob(raw),
        saved=saved, current=current, differences=delta,
        intervention=dict(reads=reads, product=intervened))
    with (ROOT / OUTPUT).open('xb') as target:
        target.write(gzip.compress((json.dumps(record, sort_keys=True) + '\n').encode(), mtime=0))
    print('Only dispatch/preparation/fixed-gap metadata differs; historical metadata restores the entire original caller proof.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
