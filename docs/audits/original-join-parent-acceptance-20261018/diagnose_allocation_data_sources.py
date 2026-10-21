"""Retain complete dependent-qualifier products and trace current reader calls."""
import argparse
import copy
import gzip
import hashlib
import json
import os
from pathlib import Path
import tempfile

import diagnose_fixed_gap_sources as diagnostic
import epoch_constraints as epoch
import qualify_operand_allocation as qualifier
import saved_reader_sources as source
import verify_allocation_qualifier_capture as capture_reader

ROOT, AUDIT = qualifier.allocation.prepare.ROOT, qualifier.allocation.execute.AUDIT
execute, prepare, bounded = qualifier.allocation.execute, qualifier.allocation.prepare, qualifier.allocation.bounded
BASE = 'e8e1f77838cd05c0940d340350d842d5f3f8f027'
SELF = 'diagnose_allocation_data_sources.py'
PATH = AUDIT / 'allocation-data-source-diagnosis-qualified.json.gz'
FIRST_PATH = AUDIT / 'allocation-data-source-diagnosis.json.gz'
FIRST_SOURCE = AUDIT / 'diagnose_allocation_data_sources.first.py.source'
FIRST_SHA256 = '810fa1c4deaae67f9d53ae94cdf8d01e2847c9a2cf653cad761e5885183425dc'
FIRST_SOURCE_SHA256 = 'd2df300e86f21b1c4d162b9c3410bfad3631110228b44460faa0dcf05998f4fd'
TARGET = str(AUDIT / 'operand_allocation.py')
NAMES = (str(qualifier.SOURCE), TARGET)
SOURCES = (SELF, 'diagnose_fixed_gap_sources.py', 'saved_reader_sources.py',
           'verify_allocation_qualifier_capture.py')
SCOPE = ('Complete current qualifier-product rederivation in-process, then a '
         'declared-source-metadata-only intervention. Each current allocation '
         'audit-reader runpy call is traced against its physical native source. '
         'Historical images are supplied only to metadata reads and never become '
         'executed source. The original CLI comparison and whole helper do not '
         'repeat. Complete first native/current stages persist before intervention. '
         'Decoder/Git/Python/gzip and existing source/model/control semantics '
         'remain shared premises. No repair, source-role/native/runtime/custody/'
         'private/HIAL/full-CI qualification follows.')


def equal(left, right):
    return bounded.strict_equal(left, right)


def unpack(row):
    raw = prepare.unblob(row)
    equal(row, prepare.blob(raw))
    return raw


def decode(raw):
    return json.loads(gzip.decompress(raw))


def physical_source(name):
    assert type(name) is str and not Path(name).is_absolute() and '..' not in Path(name).parts
    path = execute.safe(ROOT / name)
    assert path.is_file() and not path.is_symlink(), 'regular physical source leaf required'
    assert path.stat().st_dev == ROOT.stat().st_dev, 'physical source stays on repository volume'
    return path.read_bytes()


def differences(left, right, path=()):
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


def stage(path, value):
    with execute.safe(path).open('xb') as stream:
        stream.write(gzip.compress(prepare.encoded(value), mtime=0))
        stream.flush()
        os.fsync(stream.fileno())
    print(str(path.relative_to(ROOT)), flush=True)


def product():
    previous = qualifier.runpy.run_path
    calls = []

    def current_reader(path, *args, **kwargs):
        equal(path, TARGET)
        equal(args, ())
        equal(kwargs, dict(run_name='__main__'))
        # Physical source reads bypass the separate metadata-only intervention.
        physical = physical_source(path)
        equal(physical, epoch.read(BASE, path))
        row = dict(path=path, args=list(args), kwargs=kwargs,
                   argv=list(qualifier.sys.argv), physical_source=prepare.identity(physical))
        calls.append(row)
        try:
            result = previous(path, *args, **kwargs)
        except AssertionError as error:
            row['outcome'] = dict(kind='AssertionError', error=str(error))
            raise
        else:
            row['outcome'] = dict(kind='returned', error=None)
            return result

    try:
        qualifier.runpy.run_path = current_reader
        value = qualifier.qualify()
    finally:
        qualifier.runpy.run_path = previous
    return value, calls


def collect():
    for name in NAMES:
        equal(physical_source(name), epoch.read(BASE, name))
    original = {name: source.original(Path(name).name) for name in NAMES}
    proof = execute.read(qualifier.PATH)
    equal(proof, epoch.read(source.REVISION, str(qualifier.PATH)))
    equal(proof, epoch.read(BASE, str(qualifier.PATH)))
    saved = decode(proof)
    parent = ROOT / '.artifacts/tmp/tests'
    execute.safe(parent / 'allocation-data-diagnostic-directory-check')
    directory = Path(tempfile.mkdtemp(prefix='allocation-data-diagnosis-', dir=parent))
    value = dict(schema='fsmgen.allocation_data_source_diagnosis.v1', scope=SCOPE,
        original_revision=source.REVISION, reader_revision=BASE,
        programmes={name: prepare.blob(physical_source(str(AUDIT / name))) for name in SOURCES},
        full_capture=prepare.blob(execute.read(capture_reader.PATH)),
        original_sources=original, original_proof=prepare.blob(proof), saved=saved,
        partial_directory=str(directory.relative_to(ROOT)))
    stage(directory / 'original.json.gz', value)
    current, calls = product()
    stage(directory / 'current.json.gz', dict(product=current, reader_calls=calls))
    images = {Path(name).name: unpack(row['body']) for name, row in original.items()}
    with diagnostic.metadata_images(images) as reads:
        intervened, intervention_calls = product()
    stage(directory / 'intervention.json.gz', dict(product=intervened, reader_calls=intervention_calls, reads=reads))
    value.update(current=current, reader_calls=calls, differences=differences(saved, current),
                 intervention=dict(reads=reads, product=intervened, reader_calls=intervention_calls))
    return value


def review_calls(rows):
    identity = prepare.identity(epoch.read(BASE, TARGET))
    expected = [dict(path=TARGET, args=[], kwargs=dict(run_name='__main__'),
        argv=[TARGET], physical_source=identity, outcome=dict(kind=kind, error=error))
        for kind, error in (('returned', None), ('AssertionError', 'exact scalar'))]
    equal(rows, expected)


def review(value, *, producer=None):
    assert set(value) == {'schema', 'scope', 'original_revision', 'reader_revision', 'programmes',
        'full_capture', 'original_sources', 'original_proof', 'saved', 'partial_directory',
        'current', 'reader_calls', 'differences', 'intervention'}
    equal(value['schema'], 'fsmgen.allocation_data_source_diagnosis.v1')
    equal(value['scope'], SCOPE)
    equal(value['original_revision'], source.REVISION)
    equal(value['reader_revision'], BASE)
    assert set(value['programmes']) == set(SOURCES)
    equal(unpack(value['programmes'][SELF]),
          physical_source(str(AUDIT / SELF)) if producer is None else producer)
    for name in SOURCES[1:]:
        equal(unpack(value['programmes'][name]), epoch.read(BASE, str(AUDIT / name)))
    full_capture = unpack(value['full_capture'])
    equal(full_capture, epoch.read(BASE, str(capture_reader.PATH)))
    assert capture_reader.review(capture_reader.captured(full_capture))
    original = {name: source.original(Path(name).name) for name in NAMES}
    equal(value['original_sources'], original)
    proof = unpack(value['original_proof'])
    equal(proof, epoch.read(source.REVISION, str(qualifier.PATH)))
    equal(proof, epoch.read(BASE, str(qualifier.PATH)))
    saved = decode(proof)
    equal(value['saved'], saved)
    equal(saved['programmes'], {name: row['body'] for name, row in original.items()})
    path = Path(value['partial_directory'])
    assert path.parent == Path('.artifacts/tmp/tests') and path.name.startswith('allocation-data-diagnosis-')
    current = value['current']
    equal(current['programmes'], {name: prepare.blob(epoch.read(BASE, name)) for name in NAMES})
    review_calls(value['reader_calls'])
    delta = differences(saved, current)
    equal(value['differences'], delta)
    assert delta and all(row[0] == 'programmes' for row in delta), 'metadata-only complete difference'
    assert set(value['intervention']) == {'reads', 'product', 'reader_calls'}
    equal(value['intervention']['reads'], [Path(name).name for name in NAMES])
    review_calls(value['intervention']['reader_calls'])
    restored = dict(current, programmes=saved['programmes'])
    equal(restored, saved)
    equal(value['intervention']['product'], restored)
    assert prepare.encoded(restored) == prepare.encoded(saved)
    assert prepare.encoded(value['intervention']['product']) == prepare.encoded(saved)
    return True


def controls(value):
    outcomes = []
    for label in ('omitted-difference', 'changed-candidate', 'omitted-programme', 'changed-native',
                  'changed-source', 'changed-capture', 'omitted-reader-call', 'historical-code-promotion',
                  'changed-intervention', 'omitted-metadata-read', 'boolean-source-size', 'float-source-size'):
        bad = copy.deepcopy(value)
        if label == 'omitted-difference':
            bad['differences'].pop()
        elif label == 'changed-candidate':
            bad['current']['candidate'] = prepare.blob(b'changed candidate data\n')
        elif label == 'omitted-programme':
            del bad['current']['programmes'][NAMES[0]]
        elif label == 'changed-native':
            bad['reader_revision'] = '0' * 40
        elif label == 'changed-source':
            bad['current']['programmes'][NAMES[0]] = prepare.blob(b'changed source\n')
        elif label == 'changed-capture':
            bad['full_capture'] = prepare.blob(b'changed first result\n')
        elif label == 'omitted-reader-call':
            bad['reader_calls'].pop()
        elif label == 'historical-code-promotion':
            bad['intervention']['reader_calls'][0]['physical_source'] = prepare.identity(unpack(bad['original_sources'][TARGET]['body']))
        elif label == 'changed-intervention':
            bad['intervention']['product']['original_programme_execution'] = 0
        elif label == 'omitted-metadata-read':
            bad['intervention']['reads'].pop()
        else:
            row = bad['programmes'][SELF]
            row['bytes'] = True if label == 'boolean-source-size' else float(row['bytes'])
        try:
            review(bad)
        except AssertionError as error:
            if label == 'float-source-size':
                assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, refusal=str(error)))
        else:
            raise AssertionError('changed complete dependent diagnosis admitted: ' + label)
    return outcomes


def first_attempt():
    raw = execute.read(FIRST_PATH)
    assert hashlib.sha256(raw).hexdigest() == FIRST_SHA256, 'immutable complete first diagnostic identity'
    body = execute.read(FIRST_SOURCE)
    assert hashlib.sha256(body).hexdigest() == FIRST_SOURCE_SHA256, 'immutable first producer source identity'
    value = decode(raw)
    equal(unpack(value['programmes'][SELF]), body)
    assert review(value, producer=body)
    return value


def conserve_first(value, first):
    projected = copy.deepcopy(value)
    projected['programmes'][SELF] = first['programmes'][SELF]
    projected['partial_directory'] = first['partial_directory']
    equal(projected, first)
    assert prepare.encoded(projected) == prepare.encoded(first)


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    first = first_attempt()
    if args.write:
        assert not execute.safe(PATH).exists(), 'corrected exclusive diagnostic slot is already spent'
    value = collect() if args.write else decode(execute.read(PATH))
    if args.write:
        execute.save(PATH, value)
    assert review(value)
    conserve_first(value, first)
    outcomes = controls(value)
    print(json.dumps(dict(changed_programmes=sorted({row[1] for row in value['differences']}), controls=outcomes), sort_keys=True))
    print('Complete dependent qualifier products differ only in declared source metadata; native metadata alone restores the whole original product. Traced physical current audit readers execute; historical images remain metadata.')
