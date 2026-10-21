"""Retain complete allocation products before separating their source metadata."""
import argparse
import copy
import gzip
import json

import diagnose_fixed_gap_sources as diagnostic
import epoch_constraints as epoch
import operand_allocation as allocation
import saved_reader_sources as source
import verify_post_compile_only_capture as capture_reader

ROOT, AUDIT = allocation.prepare.ROOT, allocation.execute.AUDIT
BASE = 'f219e892aa420bfebfb410ff71803f49469388c1'
SELF = 'diagnose_allocation_sources.py'
PATH = AUDIT / 'allocation-source-diagnosis.json.gz'
SOURCES = (SELF, 'diagnose_fixed_gap_sources.py', 'saved_reader_sources.py',
           'verify_post_compile_only_capture.py')
SCOPE = ('Dated complete original/current allocation product comparison and '
         'declared-source-metadata-only intervention after the retained actual '
         'whole-helper refusal. Complete fixed, reconstructed source, transformed '
         'AST and compile-only models remain shared data premises. Historical '
         'programme/model/recipe bodies remain data. No reader repair, native '
         'admission, whole-helper success, payload closure, concrete namespace/'
         'export, source/default/effect/runtime/custody/private/HIAL/full-CI '
         'qualification follows.')


def equal(left, right):
    return allocation.bounded.strict_equal(left, right)


def unpack(row):
    raw = allocation.prepare.unblob(row)
    equal(row, allocation.prepare.blob(raw))
    return raw


def decode(raw):
    return json.loads(gzip.decompress(raw))


def differences(left, right, path=()):
    """Record all typed differences, including missing members, without classifying."""
    if type(left) is not type(right):
        return [list(path)]
    if type(left) is dict:
        return [list((*path, key)) for key in sorted(left.keys() ^ right.keys())] + [
            row for key in sorted(left.keys() & right.keys())
            for row in differences(left[key], right[key], (*path, key))]
    if type(left) is list:
        common = min(len(left), len(right))
        return [row for index in range(common)
                for row in differences(left[index], right[index], (*path, index))] + [
                    list((*path, index)) for index in range(common, max(len(left), len(right)))]
    return [] if left == right else [list(path)]


def inputs():
    raw, references = {}, {}
    for path in allocation.MODEL_PATHS:
        name = str(path)
        reference = allocation.prerequisite.file_reference(allocation.AUTHORITY, name)
        body = allocation.prerequisite.read_reference(reference)
        equal(body, allocation.execute.read(path))
        raw[name], references[name] = body, reference
    return raw, references


def product(raw, references):
    models = {name: decode(body) for name, body in raw.items()}
    result = allocation.assemble(models)
    return dict(result=result, review=allocation.review(result, models),
        controls=allocation.controls(result, models),
        inputs={name: dict(reference=references[name], body=allocation.prepare.blob(body))
                for name, body in raw.items()},
        programmes={name: allocation.prepare.blob(allocation.execute.read(AUDIT / name))
                    for name in allocation.PREMISES})


def collect():
    equal((ROOT / AUDIT / 'operand_allocation.py').read_bytes(),
          epoch.read(BASE, str(AUDIT / 'operand_allocation.py')))
    raw, references = inputs()
    original = {name: source.original(name) for name in allocation.PREMISES}
    proof = allocation.execute.read(allocation.PATH)
    equal(proof, epoch.read(source.REVISION, str(allocation.PATH)))
    equal(proof, epoch.read(BASE, str(allocation.PATH)))
    saved, current = decode(proof), product(raw, references)
    images = {name: unpack(row['body']) for name, row in original.items()}
    with diagnostic.metadata_images(images) as reads:
        intervened = product(raw, references)
    return dict(schema='fsmgen.allocation_source_diagnosis.v1', scope=SCOPE,
        original_revision=source.REVISION, reader_revision=BASE,
        programmes={name: allocation.prepare.blob((ROOT / AUDIT / name).read_bytes())
                    for name in SOURCES},
        full_helper_capture=allocation.prepare.blob(allocation.execute.read(capture_reader.PATH)),
        original_sources=original, original_proof=allocation.prepare.blob(proof),
        saved=saved, current=current, differences=differences(saved, current),
        intervention=dict(reads=reads, product=intervened))


def review(value):
    assert set(value) == {'schema', 'scope', 'original_revision', 'reader_revision',
        'programmes', 'full_helper_capture', 'original_sources', 'original_proof',
        'saved', 'current', 'differences', 'intervention'}
    equal(value['schema'], 'fsmgen.allocation_source_diagnosis.v1')
    equal(value['scope'], SCOPE)
    equal(value['original_revision'], source.REVISION)
    equal(value['reader_revision'], BASE)
    assert set(value['programmes']) == set(SOURCES)
    equal(unpack(value['programmes'][SELF]), (ROOT / AUDIT / SELF).read_bytes())
    for name in SOURCES[1:]:
        equal(unpack(value['programmes'][name]), epoch.read(BASE, str(AUDIT / name)))
    capture = unpack(value['full_helper_capture'])
    equal(capture, epoch.read(BASE, str(capture_reader.PATH)))
    assert capture_reader.review(capture_reader.captured(capture))
    original = {name: source.original(name) for name in allocation.PREMISES}
    equal(value['original_sources'], original)
    proof = unpack(value['original_proof'])
    equal(proof, epoch.read(source.REVISION, str(allocation.PATH)))
    equal(proof, epoch.read(BASE, str(allocation.PATH)))
    saved = decode(proof)
    equal(value['saved'], saved)
    equal(saved['programmes'], {name: row['body'] for name, row in original.items()})
    current = value['current']
    equal(current['programmes'], {name: allocation.prepare.blob(epoch.read(BASE, str(AUDIT / name)))
                                   for name in allocation.PREMISES})
    delta = differences(saved, current)
    equal(value['differences'], delta)
    assert delta, 'actual complete comparison must differ'
    assert all(row[0] == 'programmes' for row in delta), 'metadata-only complete difference'
    assert set(value['intervention']) == {'reads', 'product'}
    equal(value['intervention']['reads'], list(allocation.PREMISES))
    restored = dict(current, programmes=saved['programmes'])
    equal(restored, saved)
    equal(value['intervention']['product'], restored)
    assert allocation.prepare.encoded(restored) == allocation.prepare.encoded(saved)
    assert allocation.prepare.encoded(value['intervention']['product']) == allocation.prepare.encoded(saved)
    return True


def controls(value):
    outcomes = []
    for label in ('omitted_difference', 'changed_binding', 'omitted_programme',
                  'boolean_bytes', 'float_bytes', 'changed_native', 'changed_source',
                  'changed_capture', 'changed_intervention', 'omitted_read'):
        bad = copy.deepcopy(value)
        if label == 'omitted_difference':
            bad['differences'].pop()
        elif label == 'changed_binding':
            bad['current']['result']['bindings'].pop()
        elif label == 'omitted_programme':
            bad['current']['programmes'].pop(allocation.PREMISES[0])
        elif label in ('boolean_bytes', 'float_bytes'):
            row = bad['programmes'][SELF]
            row['bytes'] = True if label == 'boolean_bytes' else float(row['bytes'])
        elif label == 'changed_native':
            bad['reader_revision'] = '0' * 40
        elif label == 'changed_source':
            bad['current']['programmes'][allocation.PREMISES[0]] = allocation.prepare.blob(b'changed source\n')
        elif label == 'changed_capture':
            bad['full_helper_capture'] = allocation.prepare.blob(b'changed helper evidence\n')
        elif label == 'changed_intervention':
            bad['intervention']['product']['result']['runtime_permission'] = 0
        else:
            bad['intervention']['reads'].pop()
        try:
            review(bad)
        except AssertionError as error:
            if label == 'float_bytes':
                assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, refusal=str(error)))
        else:
            raise AssertionError('changed complete allocation diagnosis admitted: ' + label)
    return outcomes


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else decode(allocation.execute.read(PATH))
    if args.write:
        # Preserve the first whole products before cause classification or controls.
        allocation.execute.save(PATH, value)
    assert review(value)
    outcomes = controls(value)
    print(json.dumps(dict(changed_programmes=sorted({row[1] for row in value['differences']}),
                          controls=outcomes), sort_keys=True))
    print('Complete allocation products differ only in declared native programme metadata; metadata-only intervention restores the entire original product. Historical bodies remain data.')
