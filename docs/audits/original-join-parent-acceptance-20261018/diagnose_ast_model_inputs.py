"""Diagnose the complete AST-input saved comparison without historical execution."""
import argparse
import copy
import gzip
import json
import sys

import ast_model_inputs as model
import diagnose_fixed_gap_sources as diagnostic
import saved_reader_sources as source

ROOT, AUDIT = model.prepare.ROOT, model.execute.AUDIT
BASE = '912025a6521838b62499c51ce3ad1a7f37d14845'
SELF = 'diagnose_ast_model_inputs.py'
PATH = AUDIT / 'ast-model-inputs-diagnosis.json.gz'
SCOPE = ('Dated complete original/current AST-input proof comparison and metadata-only '
         'intervention. Historical programme/model/recipe bodies remain data. No reader '
         'repair, native admission, whole-helper, complete source/default/effect/runtime/'
         'custody/private/HIAL/full-CI qualification follows.')


def equal(left, right):
    model.bounded.strict_equal(left, right)


def unpack(row):
    raw = model.prepare.unblob(row)
    equal(row, model.prepare.blob(raw))
    return raw


def decode(raw):
    return json.loads(gzip.decompress(raw))


def inputs():
    raw = {str(path): model.execute.read(path) for path in
           (model.fixed_inputs.PATH, model.operands.INPUT)}
    for name, body in raw.items():
        equal(body, model.epoch.read(model.AUTHORITY, name))
    native = {}
    names = {model.CAUSE, model.PRIMARY, *model.MODELS,
             *(name.rsplit('/', 1)[0] + '/verify.py' for name in model.MODELS)}
    for name in sorted(names):
        reference = model.prerequisite.file_reference(model.epoch.REVISION, name)
        body = model.prerequisite.read_reference(reference)
        equal(body, model.epoch.read(model.epoch.REVISION, name))
        raw[name], native[name] = body, reference
    return raw, native


def product(raw, native):
    result = json.loads(model.prepare.encoded(model.derive(raw)))
    assert model.review(result, raw)
    return dict(result=result, controls=model.controls(result, raw), native=native,
        inputs={name: model.prepare.blob(body) for name, body in raw.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: model.prepare.blob(model.execute.read(AUDIT / name))
                    for name in model.PREMISES})


def capture():
    raw, native = inputs()
    original = {name: source.original(name) for name in model.PREMISES}
    proof = model.execute.read(model.PATH)
    equal(proof, model.epoch.read(source.REVISION, str(model.PATH)))
    saved, current = decode(proof), product(raw, native)
    images = {name: unpack(row['body']) for name, row in original.items()}
    with diagnostic.metadata_images(images) as reads:
        intervened = product(raw, native)
    return dict(schema='fsmgen.ast_model_inputs_diagnosis.v1', scope=SCOPE,
        original_revision=source.REVISION, reader_revision=BASE,
        programmes={name: model.prepare.blob((ROOT / AUDIT / name).read_bytes())
                    for name in (SELF, 'diagnose_fixed_gap_sources.py', 'saved_reader_sources.py')},
        original_sources=original, original_proof=model.prepare.blob(proof),
        saved=saved, current=current, differences=diagnostic.differences(saved, current),
        intervention=dict(reads=reads, product=intervened))


def review(value):
    assert set(value) == {'schema', 'scope', 'original_revision', 'reader_revision',
                         'programmes', 'original_sources', 'original_proof', 'saved',
                         'current', 'differences', 'intervention'}
    equal(value['schema'], 'fsmgen.ast_model_inputs_diagnosis.v1')
    equal(value['scope'], SCOPE)
    equal(value['original_revision'], source.REVISION)
    equal(value['reader_revision'], BASE)
    assert set(value['programmes']) == {SELF, 'diagnose_fixed_gap_sources.py', 'saved_reader_sources.py'}
    equal(unpack(value['programmes'][SELF]), (ROOT / AUDIT / SELF).read_bytes())
    for name in ('diagnose_fixed_gap_sources.py', 'saved_reader_sources.py'):
        equal(unpack(value['programmes'][name]), model.epoch.read(BASE, str(AUDIT / name)))
    original = {name: source.original(name) for name in model.PREMISES}
    equal(value['original_sources'], original)
    proof = unpack(value['original_proof'])
    equal(proof, model.epoch.read(source.REVISION, str(model.PATH)))
    saved = decode(proof)
    equal(value['saved'], saved)
    equal(saved['programmes'], {name: row['body'] for name, row in original.items()})
    current = value['current']
    equal(current['programmes'], {name: model.prepare.blob(model.epoch.read(BASE, str(AUDIT / name)))
                                   for name in model.PREMISES})
    delta = diagnostic.differences(saved, current)
    equal(value['differences'], delta)
    assert delta, 'actual complete comparison must differ'
    assert all(row[0] == 'programmes' for row in delta), 'metadata-only complete difference'
    assert set(value['intervention']) == {'reads', 'product'}
    equal(value['intervention']['reads'], list(model.PREMISES))
    restored = copy.deepcopy(current)
    restored['programmes'] = copy.deepcopy(saved['programmes'])
    equal(restored, saved)
    equal(value['intervention']['product'], restored)
    # Canonical JSON supplies a second, whole-product typed equality check.
    assert model.prepare.encoded(restored) == model.prepare.encoded(saved)
    assert model.prepare.encoded(value['intervention']['product']) == model.prepare.encoded(saved)
    return True


def controls(value):
    outcomes = []
    for label in ('omitted_difference', 'changed_tree', 'omitted_programme',
                  'boolean_bytes', 'float_bytes', 'changed_native', 'changed_source',
                  'changed_intervention', 'omitted_read'):
        candidate = copy.deepcopy(value)
        if label == 'omitted_difference':
            candidate['differences'].pop()
        elif label == 'changed_tree':
            candidate['current']['result']['bindings'].pop()
        elif label == 'omitted_programme':
            candidate['current']['programmes'].pop(next(iter(model.PREMISES)))
        elif label in ('boolean_bytes', 'float_bytes'):
            row = candidate['programmes'][SELF]
            row['bytes'] = True if label == 'boolean_bytes' else float(row['bytes'])
        elif label == 'changed_native':
            candidate['reader_revision'] = '0' * 40
        elif label == 'changed_source':
            name = model.PREMISES[0]
            candidate['current']['programmes'][name] = model.prepare.blob(b'changed source\n')
        elif label == 'changed_intervention':
            candidate['intervention']['product']['result']['runtime_permission'] = 0
        else:
            candidate['intervention']['reads'].pop()
        try:
            review(candidate)
        except AssertionError as error:
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
    value = capture() if args.write else decode(model.execute.read(PATH))
    assert review(value)
    outcomes = controls(value)
    if args.write:
        model.execute.save(PATH, value)
    changed = sorted({row[1] for row in value['differences']})
    print(json.dumps(dict(changed_programmes=changed, controls=outcomes), sort_keys=True))
    print('Complete AST-input products differ only in native programme metadata; metadata-only intervention restores the entire original product. Historical bodies remain data.')
