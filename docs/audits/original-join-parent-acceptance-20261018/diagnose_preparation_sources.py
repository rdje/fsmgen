"""Diagnose the complete retained preparation proof without historical execution."""
import argparse
import copy
import gzip
import json
import sys

import diagnose_fixed_gap_sources as diagnostic
import preparation_correction as correction
import saved_reader_sources as source
import verify_post_ast_input_capture as capture_reader

ROOT, AUDIT = correction.prepare.ROOT, correction.execute.AUDIT
BASE = '34548a07b68f1b97fc1520e3baa46a512e35456e'
SELF = 'diagnose_preparation_sources.py'
PATH = AUDIT / 'preparation-source-diagnosis.json.gz'
SOURCES = (SELF, 'diagnose_fixed_gap_sources.py', 'saved_reader_sources.py',
           'verify_post_ast_input_capture.py')
SCOPE = ('Dated complete original/current preparation-correction product comparison '
         'and metadata-only intervention after the retained actual full-helper refusal. '
         'Historical programme/recipe bodies remain data. No reader repair, native '
         'admission, whole-helper success, original stdin observation, complete source/'
         'default/effect/runtime/custody/private/HIAL/full-CI qualification follows.')


def equal(left, right):
    correction.bounded.strict_equal(left, right)


def unpack(row):
    raw = correction.prepare.unblob(row)
    equal(row, correction.prepare.blob(raw))
    return raw


def decode(raw):
    return json.loads(gzip.decompress(raw))


def inputs():
    raw, references = {}, {}
    for name in correction.NAMES:
        reference = correction.prerequisite.file_reference(correction.epoch.REVISION, name)
        body = correction.prerequisite.read_reference(reference)
        equal(body, correction.epoch.read(correction.epoch.REVISION, name))
        raw[name], references[name] = body, reference
    return raw, references


def product(raw, references):
    result = json.loads(correction.prepare.encoded(correction.derive(raw, references)))
    assert correction.review(result, raw, references)
    return dict(result=result, controls=correction.controls(result, raw, references),
        references=references, inputs={name: correction.prepare.blob(body) for name, body in raw.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: correction.prepare.blob(correction.execute.read(AUDIT / name))
                    for name in correction.PREMISES})


def collect():
    raw, references = inputs()
    original = {name: source.original(name) for name in correction.PREMISES}
    proof = correction.execute.read(correction.PATH)
    equal(proof, correction.epoch.read(source.REVISION, str(correction.PATH)))
    saved, current = decode(proof), product(raw, references)
    images = {name: unpack(row['body']) for name, row in original.items()}
    with diagnostic.metadata_images(images) as reads:
        intervened = product(raw, references)
    return dict(schema='fsmgen.preparation_source_diagnosis.v1', scope=SCOPE,
        original_revision=source.REVISION, reader_revision=BASE,
        programmes={name: correction.prepare.blob((ROOT / AUDIT / name).read_bytes()) for name in SOURCES},
        full_helper_capture=correction.prepare.blob(correction.execute.read(capture_reader.PATH)),
        original_sources=original, original_proof=correction.prepare.blob(proof),
        saved=saved, current=current, differences=diagnostic.differences(saved, current),
        intervention=dict(reads=reads, product=intervened))


def review(value):
    assert set(value) == {'schema', 'scope', 'original_revision', 'reader_revision', 'programmes',
                         'full_helper_capture', 'original_sources', 'original_proof', 'saved',
                         'current', 'differences', 'intervention'}
    equal(value['schema'], 'fsmgen.preparation_source_diagnosis.v1')
    equal(value['scope'], SCOPE)
    equal(value['original_revision'], source.REVISION)
    equal(value['reader_revision'], BASE)
    assert set(value['programmes']) == set(SOURCES)
    equal(unpack(value['programmes'][SELF]), (ROOT / AUDIT / SELF).read_bytes())
    for name in SOURCES[1:]:
        equal(unpack(value['programmes'][name]), correction.epoch.read(BASE, str(AUDIT / name)))
    capture = unpack(value['full_helper_capture'])
    equal(capture, correction.epoch.read(BASE, str(capture_reader.PATH)))
    assert capture_reader.review(capture_reader.captured(capture))
    original = {name: source.original(name) for name in correction.PREMISES}
    equal(value['original_sources'], original)
    proof = unpack(value['original_proof'])
    equal(proof, correction.epoch.read(source.REVISION, str(correction.PATH)))
    saved = decode(proof)
    equal(value['saved'], saved)
    equal(saved['programmes'], {name: row['body'] for name, row in original.items()})
    current = value['current']
    equal(current['programmes'], {name: correction.prepare.blob(correction.epoch.read(BASE, str(AUDIT / name)))
                                   for name in correction.PREMISES})
    delta = diagnostic.differences(saved, current)
    equal(value['differences'], delta)
    assert delta, 'actual complete comparison must differ'
    assert all(row[0] == 'programmes' for row in delta), 'metadata-only complete difference'
    assert set(value['intervention']) == {'reads', 'product'}
    equal(value['intervention']['reads'], list(correction.PREMISES))
    restored = copy.deepcopy(current)
    restored['programmes'] = copy.deepcopy(saved['programmes'])
    equal(restored, saved)
    equal(value['intervention']['product'], restored)
    # Canonical JSON is a second whole-product check that distinguishes numeric kinds.
    assert correction.prepare.encoded(restored) == correction.prepare.encoded(saved)
    assert correction.prepare.encoded(value['intervention']['product']) == correction.prepare.encoded(saved)
    return True


def controls(value):
    outcomes = []
    for label in ('omitted_difference', 'changed_pair', 'omitted_programme', 'boolean_bytes',
                  'float_bytes', 'changed_native', 'changed_source', 'changed_capture',
                  'changed_intervention', 'omitted_read'):
        candidate = copy.deepcopy(value)
        if label == 'omitted_difference':
            candidate['differences'].pop()
        elif label == 'changed_pair':
            candidate['current']['result']['pairs'].pop()
        elif label == 'omitted_programme':
            candidate['current']['programmes'].pop(correction.PREMISES[0])
        elif label in ('boolean_bytes', 'float_bytes'):
            row = candidate['programmes'][SELF]
            row['bytes'] = True if label == 'boolean_bytes' else float(row['bytes'])
        elif label == 'changed_native':
            candidate['reader_revision'] = '0' * 40
        elif label == 'changed_source':
            candidate['current']['programmes'][correction.PREMISES[0]] = correction.prepare.blob(b'changed source\n')
        elif label == 'changed_capture':
            candidate['full_helper_capture'] = correction.prepare.blob(b'changed complete helper evidence\n')
        elif label == 'changed_intervention':
            candidate['intervention']['product']['result']['runtime_permission'] = 0
        else:
            candidate['intervention']['reads'].pop()
        try:
            review(candidate)
        except AssertionError as error:
            if label == 'float_bytes':
                assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, refusal=str(error)))
        else:
            raise AssertionError('changed complete diagnostic admitted: ' + label)
    return outcomes


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else decode(correction.execute.read(PATH))
    assert review(value)
    outcomes = controls(value)
    if args.write:
        correction.execute.save(PATH, value)
    print(json.dumps(dict(changed_programmes=sorted({row[1] for row in value['differences']}),
                          controls=outcomes), sort_keys=True))
    print('Complete preparation products differ only in native programme metadata; metadata-only intervention restores the entire original product. Historical bodies remain data.')
