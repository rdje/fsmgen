"""Diagnose the complete compile-only saved comparison without historical execution."""
import argparse
import copy
import gzip
import hashlib
import json
import sys

import diagnose_fixed_gap_sources as diagnostic
import compile_only_inputs as correction
import saved_reader_sources as source
import verify_post_preparation_capture as capture_reader

ROOT, AUDIT = correction.prepare.ROOT, correction.execute.AUDIT
BASE = '479c3ed4cfbf403e77651b0d31613fdf7c070fe3'
SELF = 'diagnose_compile_only_sources.py'
PATH = AUDIT / 'compile-only-source-diagnosis-qualified.json.gz'
FIRST_PATH = AUDIT / 'compile-only-source-diagnosis.json.gz'
FIRST_SHA256 = '629326c39f32483821c5935e15d61adbb79cc5cdf2f918ec9b27843fae8bfab6'
FAILURE_PATH = AUDIT / 'compile-only-diagnosis-first-control-failure.json.gz'
FAILURE_SHA256 = 'e45c0366ab551f83d91e27a9bb78a2d7908a293f58dd110ed5bd746e485b2ed9'
SOURCES = (SELF, 'diagnose_fixed_gap_sources.py', 'saved_reader_sources.py',
           'verify_post_preparation_capture.py')
SCOPE = ('Dated complete original/current compile-only product comparison '
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
    raw = {str(path): correction.execute.read(path) for path in correction.MODEL_PATHS}
    for name, body in raw.items():
        equal(body, correction.epoch.read(correction.AUTHORITY, name))
    names = {*correction.correction.NAMES, correction.READER,
             *(correction.BASE + '/' + tag + '.json' for tag in correction.RECEIPTS)}
    references = {}
    for name in sorted(names):
        reference = correction.prerequisite.file_reference(correction.epoch.REVISION, name)
        raw[name], references[name] = correction.prerequisite.read_reference(reference), reference
    for name in sorted(correction.original_domain(raw) - names):
        reference = correction.prerequisite.file_reference(correction.epoch.REVISION, name)
        raw[name], references[name] = correction.prerequisite.read_reference(reference), reference
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
    return dict(schema='fsmgen.compile_only_source_diagnosis.v1', scope=SCOPE,
        original_revision=source.REVISION, reader_revision=BASE,
        programmes={name: correction.prepare.blob((ROOT / AUDIT / name).read_bytes()) for name in SOURCES},
        full_helper_capture=correction.prepare.blob(correction.execute.read(capture_reader.PATH)),
        original_sources=original, original_proof=correction.prepare.blob(proof),
        saved=saved, current=current, differences=diagnostic.differences(saved, current),
        intervention=dict(reads=reads, product=intervened))


def review(value, *, producer=None):
    assert set(value) == {'schema', 'scope', 'original_revision', 'reader_revision', 'programmes',
                         'full_helper_capture', 'original_sources', 'original_proof', 'saved',
                         'current', 'differences', 'intervention'}
    equal(value['schema'], 'fsmgen.compile_only_source_diagnosis.v1')
    equal(value['scope'], SCOPE)
    equal(value['original_revision'], source.REVISION)
    equal(value['reader_revision'], BASE)
    assert set(value['programmes']) == set(SOURCES)
    equal(unpack(value['programmes'][SELF]),
          (ROOT / AUDIT / SELF).read_bytes() if producer is None else producer)
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


def first_attempt():
    """Authenticate the complete failed first tool attempt as historical data."""
    raw = correction.execute.read(FIRST_PATH)
    assert hashlib.sha256(raw).hexdigest() == FIRST_SHA256, 'complete first comparison identity'
    value = decode(raw)
    body = unpack(value['programmes'][SELF])
    assert review(value, producer=body)
    failure = correction.execute.read(FAILURE_PATH)
    assert hashlib.sha256(failure).hexdigest() == FAILURE_SHA256, 'complete first control failure identity'
    row = decode(failure)
    equal(unpack(row['programme']), body)
    equal(row['comparison'], correction.prepare.identity(raw))
    equal(row['command'], ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(AUDIT / SELF), '--write'])
    equal(row['status'], 1)
    assert row['stdout_stderr'].endswith("KeyError: 'pairs'\n")
    assert "candidate['current']['result']['pairs'].pop()" in body.decode()
    return True


def controls(value):
    outcomes = []
    for label in ('omitted_difference', 'changed_binding', 'omitted_programme', 'boolean_bytes',
                  'float_bytes', 'changed_native', 'changed_source', 'changed_capture',
                  'changed_intervention', 'omitted_read'):
        candidate = copy.deepcopy(value)
        if label == 'omitted_difference':
            candidate['differences'].pop()
        elif label == 'changed_binding':
            candidate['current']['result']['bindings'].pop()
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
    assert first_attempt()
    value = collect() if args.write else decode(correction.execute.read(PATH))
    if args.write:
        correction.execute.save(PATH, value)
    assert review(value)
    outcomes = controls(value)
    print(json.dumps(dict(changed_programmes=sorted({row[1] for row in value['differences']}),
                          controls=outcomes), sort_keys=True))
    print('Complete compile-only products differ only in native programme metadata; metadata-only intervention restores the entire original product. Historical bodies remain data.')
