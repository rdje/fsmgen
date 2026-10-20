"""Retain the complete operand-inventory mismatch before repairing its reader."""
import argparse
import gzip
import json

import diagnose_fixed_gap_sources as diagnostic
import operand_inventory as operands
import saved_reader_sources as source

ROOT, AUDIT = operands.prepare.ROOT, operands.execute.AUDIT
SELF = 'diagnose_operand_inventory_sources.py'
READER = 'operand_inventory.py'
OUTPUT = AUDIT / 'operand-inventory-source-diagnosis.json.gz'
BASE = '6ae155c308f6552d85a7ed40725fc8c5d3e53364'


def product():
    result = operands.derive()
    controls = operands.controls(result)
    operands.replay(result, controls)
    return dict(result=result, controls=controls,
                programmes={name: operands.prepare.blob(operands.execute.read(AUDIT / name))
                            for name in operands.PREMISES})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', required=True)
    parser.parse_args()
    assert operands.epoch.read(BASE, str(AUDIT / READER)) == (ROOT / AUDIT / READER).read_bytes()
    original = {name: source.original(name) for name in operands.PREMISES}
    raw = operands.execute.read(operands.PATH)
    assert raw == operands.epoch.read(source.REVISION, str(operands.PATH)), 'unchanged original proof'
    saved = json.loads(gzip.decompress(raw))
    current = product()
    delta = diagnostic.differences(saved, current)
    assert delta and {tuple(row[:2]) for row in delta} == {
        ('programmes', 'default_dispatch.py'), ('programmes', 'prepare.py'),
        ('programmes', 'qualify_fixed_module_gap.py'), ('programmes', 'qualify_caller_modules.py')}
    operands.bounded.strict_equal(saved['programmes'], {name: row['body'] for name, row in original.items()})
    images = {name: operands.prepare.unblob(row['body']) for name, row in original.items()}
    with diagnostic.metadata_images(images) as reads:
        intervened = product()
    assert reads == list(operands.PREMISES), 'only declared metadata reads intervened'
    operands.bounded.strict_equal(saved, intervened)
    record = dict(schema='fsmgen.operand_inventory_source_diagnosis.v1',
        scope='Complete original/current syntax inventory, token census, controls and scope differ only in declared programme metadata. Original native bodies are supplied as metadata, never executed. No reader repair, native admission, complete helper, source/data/default/effect/runtime/custody or original cohort acceptance follows.',
        original_revision=source.REVISION, reader_revision=BASE,
        programmes={name: operands.prepare.blob((ROOT / AUDIT / name).read_bytes())
                    for name in (SELF, 'diagnose_fixed_gap_sources.py')},
        original_sources=original, original_proof=operands.prepare.blob(raw),
        saved=saved, current=current, differences=delta,
        intervention=dict(reads=reads, product=intervened))
    with (ROOT / OUTPUT).open('xb') as target:
        target.write(gzip.compress((json.dumps(record, sort_keys=True) + '\n').encode(), mtime=0))
    print('Only dispatch/preparation/fixed-gap/caller metadata differs; original native metadata restores the complete unchanged operand inventory proof.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
