"""Capture the first fixed-module-gap mismatch before repairing its reader."""
import argparse
import contextlib
import gzip
import json

import qualify_fixed_module_gap as gap
import saved_reader_sources as source

ROOT = gap.prepare.ROOT
AUDIT = gap.execute.AUDIT
SELF = 'diagnose_fixed_gap_sources.py'
OUTPUT = AUDIT / 'fixed-gap-source-diagnosis.json.gz'
BASE = '387d0458fcdaf135bc84b96520dddc8f263f6f9a'


def differences(left, right, path=()):
    """Report every unequal primitive, including Python numeric aliases."""
    if type(left) is not type(right):
        return [list(path)]
    if type(left) is dict:
        assert left.keys() == right.keys(), 'complete original product membership'
        return [item for key in sorted(left)
                for item in differences(left[key], right[key], (*path, key))]
    if type(left) is list:
        assert len(left) == len(right), 'complete original product arrays'
        return [item for index, (a, b) in enumerate(zip(left, right))
                for item in differences(a, b, (*path, index))]
    return [] if left == right else [list(path)]


def product():
    value = gap.derive()
    return dict(result=value, controls=gap.controls(value),
                programmes={name: gap.prepare.blob(gap.execute.read(AUDIT / name))
                            for name in gap.PREMISES})


@contextlib.contextmanager
def metadata_images(images):
    read = gap.execute.read
    names = {str(AUDIT / name): name for name in images}
    seen = []

    def supplied(path):
        name = names.get(str(path))
        if name is None:
            return read(path)
        seen.append(name)
        return images[name]

    try:
        gap.execute.read = supplied
        yield seen
    finally:
        gap.execute.read = read


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', required=True)
    parser.parse_args()
    assert gap.epoch.read(BASE, str(AUDIT / 'qualify_fixed_module_gap.py')) == (ROOT / AUDIT / 'qualify_fixed_module_gap.py').read_bytes()
    original = {name: source.original(name) for name in gap.PREMISES}
    raw = gap.execute.read(gap.PATH)
    assert raw == gap.epoch.read(source.REVISION, str(gap.PATH)), 'unchanged original proof'
    saved = json.loads(gzip.decompress(raw))
    current = product()
    delta = differences(saved, current)
    assert delta and {tuple(row[:2]) for row in delta} == {
        ('programmes', 'default_dispatch.py'), ('programmes', 'prepare.py')}
    gap.bounded.strict_equal(saved['programmes'], {name: row['body'] for name, row in original.items()})
    images = {name: gap.prepare.unblob(row['body']) for name, row in original.items()}
    with metadata_images(images) as reads:
        intervened = product()
    assert reads == list(gap.PREMISES), 'only declared metadata reads intervened'
    gap.bounded.strict_equal(saved, intervened)
    record = dict(schema='fsmgen.fixed_gap_source_diagnosis.v1',
        scope='Complete current stopped graph/control/scope proof differs only in declared source metadata. Historical bytes are supplied as metadata, never executed. No complete helper, source closure, default reachability, effects, custody or original runtime acceptance follows.',
        original_revision=source.REVISION, reader_revision=BASE,
        programme=gap.prepare.blob((ROOT / AUDIT / SELF).read_bytes()),
        original_sources=original, original_proof=gap.prepare.blob(raw),
        saved=saved, current=current, differences=delta,
        intervention=dict(reads=reads, product=intervened))
    with (ROOT / OUTPUT).open('xb') as target:
        target.write(gzip.compress((json.dumps(record, sort_keys=True) + '\n').encode(), mtime=0))
    print('Only original dispatch/preparation metadata differs; historical metadata alone restores the complete saved fixed-gap proof.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
