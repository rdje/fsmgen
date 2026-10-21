"""Retain complete first payload products, then separate declared source metadata."""
import argparse
import ast
import copy
import gzip
import json
import os
from pathlib import Path
import sys

import diagnose_allocation_sources as comparison
import diagnose_fixed_gap_sources as intervention
import epoch_constraints as epoch
import payload_closure as payload
import saved_reader_sources as source
import verify_post_allocation_capture as capture

allocation = payload.allocation
ROOT, AUDIT = allocation.prepare.ROOT, allocation.execute.AUDIT
BASE = '567b83070319835174fd3f705eecf698a742fc1b'
SELF = 'diagnose_payload_sources.py'
TARGET = 'payload_closure.py'
FIRST = AUDIT / 'payload-source-first-products.json.gz'
OUTPUT = AUDIT / 'payload-source-diagnosis.json.gz'
NAMES = tuple(dict.fromkeys((TARGET, *allocation.PREMISES)))
FUNCTIONS = ('inputs', 'derive', 'review', 'controls', 'semantic_controls', 'result_use_controls')
for name in FUNCTIONS:
    globals()[name] = getattr(payload, name)
SOURCES = (SELF, TARGET, 'diagnose_allocation_sources.py', 'diagnose_fixed_gap_sources.py',
           'saved_reader_sources.py', 'verify_post_allocation_capture.py')
SCOPE = ('Complete dated payload saved/current products and metadata-only intervention '
         'after the retained actual helper refusal. Whole native allocation, prior '
         'source/data models, Python syntax/symbol/builtin/stdlib APIs and declared '
         'compiler/namespace contracts remain shared premises. Historical programme/'
         'model/recipe bytes remain data. No saved CLI or helper repeats; no reader '
         'repair, concrete namespace/export, original callable/loader/custody, complete '
         'source/default/effect/runtime/private/HIAL/full-CI authority follows.')


def equal(left, right):
    return allocation.bounded.strict_equal(left, right)


def read(path):
    target = allocation.execute.safe(path)
    assert target.is_file() and not target.is_symlink(), 'regular same-volume diagnosis input'
    assert target.stat().st_dev == ROOT.stat().st_dev, 'regular same-volume diagnosis input'
    return target.read_bytes()


def save(path, value):
    body = gzip.compress(allocation.prepare.encoded(value), mtime=0)
    with allocation.execute.safe(path).open('xb') as stream:
        stream.write(body)
        stream.flush()
        os.fsync(stream.fileno())


def product():
    # The assignments below are checked against the complete native main assembly.
    raw, reference, prior, models = inputs()
    value = derive(prior, models)
    product = dict(result=value, review=review(value, prior, models), controls=controls(value, prior, models),
        semantic_controls=semantic_controls(prior, models), result_use_controls=result_use_controls(models),
        native_allocation=dict(reference=reference, body=allocation.prepare.blob(raw)),
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: allocation.prepare.blob(allocation.execute.read(allocation.execute.AUDIT / name))
                    for name in dict.fromkeys(('payload_closure.py', *allocation.PREMISES))})
    return product


def assembly():
    native = epoch.read(BASE, str(AUDIT / TARGET))
    module = ast.parse(native)
    main = next(node for node in module.body if isinstance(node, ast.If)
                and ast.unparse(node.test) == "__name__ == '__main__'")
    assignments = [node for node in main.body if isinstance(node, ast.Assign)]
    expected = assignments[-3:]
    assert [ast.unparse(node.targets[0]) for node in expected] == ['(raw, reference, prior, models)', 'value', 'product']
    producer = next(node for node in ast.parse(read(AUDIT / SELF)).body
                    if isinstance(node, ast.FunctionDef) and node.name == 'product')
    assert isinstance(producer.body[-1], ast.Return) and ast.unparse(producer.body[-1].value) == 'product'
    equal([ast.dump(node) for node in producer.body[:-1]], [ast.dump(node) for node in expected])
    assert all(globals()[name] is getattr(payload, name) for name in FUNCTIONS)
    return dict(native_main=[ast.get_source_segment(native.decode(), node) for node in expected],
                assignment_ast=[ast.dump(node) for node in expected],
                current_audit_functions=list(FUNCTIONS), historical_execution=False)


def collect():
    assert not allocation.execute.safe(FIRST).exists() and not allocation.execute.safe(OUTPUT).exists(), 'exclusive first product slots'
    programmes = {name: allocation.prepare.blob(read(AUDIT / name)) for name in SOURCES}
    for name in SOURCES[1:]:
        equal(read(AUDIT / name), epoch.read(BASE, str(AUDIT / name)))
    for name in NAMES:
        equal(read(AUDIT / name), epoch.read(BASE, str(AUDIT / name)))
    proof = read(payload.PATH)
    equal(proof, epoch.read(BASE, str(payload.PATH)))
    equal(proof, epoch.read(source.REVISION, str(payload.PATH)))
    original = {name: source.original(name) for name in NAMES}
    first = dict(schema='fsmgen.payload_source_first_products.v1', scope=SCOPE,
        reader_revision=BASE, original_revision=source.REVISION, programmes=programmes,
        assembly=assembly(), original_sources=original,
        original_proof=allocation.prepare.blob(proof), saved=json.loads(gzip.decompress(proof)),
        current=product(), full_helper_capture=allocation.prepare.blob(read(capture.PATH)))
    # Retain the complete first product before any difference classification or intervention.
    save(FIRST, first)
    images = {name: allocation.prepare.unblob(row['body']) for name, row in original.items()}
    with intervention.metadata_images(images) as reads:
        restored = product()
    value = dict(schema='fsmgen.payload_source_diagnosis.v1', scope=SCOPE,
        first=dict(path=str(FIRST), **allocation.prepare.identity(read(FIRST))),
        differences=comparison.differences(first['saved'], first['current']),
        intervention=dict(reads=reads, product=restored))
    # Retain complete intervention and typed differences before cause review or controls.
    save(OUTPUT, value)
    return value


def qualify_first(first):
    assert set(first) == {'schema','scope','reader_revision','original_revision','programmes',
        'assembly','original_sources','original_proof','saved','current','full_helper_capture'}
    equal(first['schema'], 'fsmgen.payload_source_first_products.v1')
    equal(first['scope'], SCOPE)
    equal(first['reader_revision'], BASE)
    equal(first['original_revision'], source.REVISION)
    assert set(first['programmes']) == set(SOURCES)
    equal(first['programmes'][SELF], allocation.prepare.blob(read(AUDIT / SELF)))
    for name in SOURCES[1:]:
        equal(first['programmes'][name], allocation.prepare.blob(epoch.read(BASE, str(AUDIT / name))))
    equal(first['assembly'], assembly())
    raw_capture = comparison.unpack(first['full_helper_capture'])
    equal(raw_capture, epoch.read(BASE, str(capture.PATH)))
    assert capture.review(capture.captured(raw_capture))
    original = {name: source.original(name) for name in NAMES}
    equal(first['original_sources'], original)
    raw = comparison.unpack(first['original_proof'])
    equal(raw, epoch.read(BASE, str(payload.PATH)))
    equal(raw, epoch.read(source.REVISION, str(payload.PATH)))
    equal(first['saved'], json.loads(gzip.decompress(raw)))
    equal(first['saved']['programmes'], {name: row['body'] for name, row in original.items()})
    equal(first['current']['programmes'], {name: allocation.prepare.blob(epoch.read(BASE, str(AUDIT / name))) for name in NAMES})
    return True


def qualify(value, candidate_first=None):
    assert set(value) == {'schema','scope','first','differences','intervention'}
    equal(value['schema'], 'fsmgen.payload_source_diagnosis.v1')
    equal(value['scope'], SCOPE)
    raw = read(FIRST)
    equal(value['first'], dict(path=str(FIRST), **allocation.prepare.identity(raw)))
    first = json.loads(gzip.decompress(raw)) if candidate_first is None else candidate_first
    assert qualify_first(first)
    saved, current = first['saved'], first['current']
    delta = comparison.differences(saved, current)
    equal(value['differences'], delta)
    assert delta, 'actual complete product comparison differs'
    assert all(row[0] == 'programmes' for row in delta), 'metadata-only complete difference'
    expected = dict(current, programmes=saved['programmes'])
    equal(expected, saved)
    assert set(value['intervention']) == {'reads','product'}
    equal(value['intervention']['reads'], list(NAMES))
    equal(value['intervention']['product'], expected)
    assert allocation.prepare.encoded(expected) == allocation.prepare.encoded(saved)
    assert allocation.prepare.encoded(value['intervention']['product']) == allocation.prepare.encoded(saved)
    return first


def controls_record(value, first):
    outcomes = []
    cases = ('omitted-difference','changed-payload','omitted-semantic-control','changed-python',
        'omitted-programme','boolean-size','float-size','changed-native','changed-source',
        'changed-capture','changed-intervention','omitted-read','borrowed-first-reference')
    for label in cases:
        bad, changed = copy.deepcopy(value), copy.deepcopy(first)
        if label == 'omitted-difference': bad['differences'].pop()
        elif label == 'changed-payload': changed['current']['result']['payloads'].pop()
        elif label == 'omitted-semantic-control': changed['current']['semantic_controls'].pop()
        elif label == 'changed-python': changed['current']['native_python']['implementation'] = 'borrowed'
        elif label == 'omitted-programme': changed['current']['programmes'].pop(NAMES[0])
        elif label in ('boolean-size','float-size'):
            row = changed['current']['programmes'][NAMES[0]]
            row['bytes'] = True if label == 'boolean-size' else float(row['bytes'])
        elif label == 'changed-native': changed['reader_revision'] = '0' * 40
        elif label == 'changed-source': changed['current']['programmes'][NAMES[0]] = allocation.prepare.blob(b'changed source\n')
        elif label == 'changed-capture': changed['full_helper_capture'] = allocation.prepare.blob(b'changed capture\n')
        elif label == 'changed-intervention': bad['intervention']['product']['result']['runtime_permission'] = 0
        elif label == 'omitted-read': bad['intervention']['reads'].pop()
        else: bad['first']['path'] = str(payload.PATH)
        try:
            qualify(bad, changed)
        except AssertionError as error:
            if label == 'float-size': assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, refusal=str(error),
                candidate_first=allocation.bounded.identity(changed),
                candidate_diagnosis=allocation.bounded.identity(bad)))
        else:
            raise AssertionError('changed complete payload diagnosis admitted: ' + label)
    return outcomes


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else json.loads(gzip.decompress(read(OUTPUT)))
    first = qualify(value)
    outcomes = controls_record(value, first)
    print('Complete payload products differ only in declared programme metadata; metadata-only intervention restores every original field and canonical byte. Full source/main-assembly/native/capture/member/type/product controls qualify; historical code and the helper do not execute.')
