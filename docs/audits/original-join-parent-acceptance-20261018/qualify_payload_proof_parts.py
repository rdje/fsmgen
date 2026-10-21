"""Qualify complete byte-part recovery and genuine manifest/physical-leaf refusals."""
import argparse
import copy
import gzip
import json
from types import SimpleNamespace

import payload_proof_parts as parts

SELF = parts.AUDIT + 'qualify_payload_proof_parts.py'
OUTPUT = parts.AUDIT + 'payload-proof-parts-qualified.json.gz'
SCOPE = ('Complete fixed original compressed-byte recovery, manifest membership/order/path/'
         'size/hash/primitive controls and controlled Path-interface leaf probes only. '
         'No real invalid path I/O, historical code, listed reader or helper executes. '
         'This qualifies current delivery; original runtime/custody/HIAL/full-CI gaps remain.')


class Probe:
    def __init__(self, case):
        self.case, self.reads = case, 0

    def is_file(self):
        return self.case != 'non-file'

    def is_symlink(self):
        return self.case == 'symlink'

    def stat(self):
        return SimpleNamespace(st_dev=parts.card.ROOT.stat().st_dev + (self.case == 'foreign-volume'))

    def read_bytes(self):
        self.reads += 1
        return b'controlled ordinary source'


def physical(case):
    probe = Probe(case)
    previous = parts.card.safe
    try:
        parts.card.safe = lambda name: probe
        try:
            body = parts.read_regular(parts.MANIFEST)
        except AssertionError as error:
            result = dict(case=case, accepted=False, error=str(error), reads=probe.reads)
        else:
            assert body == b'controlled ordinary source'
            result = dict(case=case, accepted=True, reads=probe.reads)
    finally:
        parts.card.safe = previous
    assert result['accepted'] is (case == 'regular')
    assert probe.reads == (1 if case == 'regular' else 0), 'invalid leaf rejected before bytes'
    return result


def derive():
    manifest = json.loads(parts.read_regular(parts.MANIFEST))
    recovered = parts.read()
    # A separate concatenation and hash, without the recovery function, checks all bytes.
    independent = b''.join(parts.read_regular(row['path']) for row in manifest['parts'])
    assert independent == recovered and parts.identity(independent) == parts.EXPECTED
    del independent
    cases = (
        ('missing-part', lambda v: v['parts'].pop()),
        ('extra-part', lambda v: v['parts'].append(copy.deepcopy(v['parts'][0]))),
        ('reordered-parts', lambda v: v['parts'].reverse()),
        ('duplicated-part', lambda v: v['parts'].__setitem__(1, copy.deepcopy(v['parts'][0]))),
        ('absolute-path', lambda v: v['parts'][0].__setitem__('path', '/' + v['parts'][0]['path'])),
        ('parent-escape', lambda v: v['parts'][0].__setitem__('path', '../' + v['parts'][0]['path'])),
        ('borrowed-path', lambda v: v['parts'][0].__setitem__('path', parts.RAW)),
        ('boolean-index', lambda v: v['parts'][0].__setitem__('index', False)),
        ('float-index', lambda v: v['parts'][0].__setitem__('index', 0.0)),
        ('boolean-part-size', lambda v: v['parts'][0].__setitem__('bytes', True)),
        ('float-part-size', lambda v: v['parts'][0].__setitem__('bytes', float(v['parts'][0]['bytes']))),
        ('float-whole-size', lambda v: v['identity'].__setitem__('bytes', float(v['identity']['bytes']))),
        ('boolean-capacity', lambda v: v.__setitem__('chunk_bytes', True)),
        ('float-capacity', lambda v: v.__setitem__('chunk_bytes', float(parts.CHUNK))),
        ('wrong-part-size', lambda v: v['parts'][0].__setitem__('bytes', 1)),
        ('wrong-part-digest', lambda v: v['parts'][0].__setitem__('sha256', '0' * 64)),
        ('wrong-whole-digest', lambda v: v['identity'].__setitem__('sha256', '0' * 64)),
        ('wrong-logical-path', lambda v: v.__setitem__('logical_path', parts.MANIFEST)),
        ('extra-field', lambda v: v.__setitem__('extra', False)),
    )
    controls = []
    for label, mutate in cases:
        value = copy.deepcopy(manifest); mutate(value)
        reads = []
        def reader(path):
            reads.append(path)
            return parts.read_regular(path)
        try:
            parts.recover(value, reader)
        except AssertionError as error:
            controls.append(dict(label=label, candidate=value, refusal=str(error), read_paths=reads))
        else:
            raise AssertionError('changed manifest admitted: ' + label)
    for label in ('missing-physical-part', 'changed-physical-bytes'):
        def changed(path):
            body = parts.read_regular(path)
            if path == manifest['parts'][0]['path']:
                if label == 'missing-physical-part':
                    raise FileNotFoundError('controlled missing fixed part')
                return bytes([body[0] ^ 1]) + body[1:]
            return body
        try:
            parts.recover(manifest, changed)
        except (AssertionError, FileNotFoundError) as error:
            controls.append(dict(label=label, candidate=manifest, refusal=str(error)))
        else:
            raise AssertionError('changed physical delivery admitted: ' + label)
    assert not parts.card.safe(parts.RAW).exists(), 'committed-parts-only recovery; raw archive absent'
    return dict(schema='fsmgen.payload_proof_parts_qualification.v1', scope=SCOPE,
        manifest=manifest, identity=parts.identity(recovered), raw_archive_absent=True,
        controls=controls, physical=[physical(case) for case in ('regular','non-file','symlink','foreign-volume')],
        programmes={name: parts.card.blob(parts.read_regular(name)) for name in (SELF, parts.SELF)})


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write:
        parts.card.save_record(OUTPUT, value)
    else:
        parts.card.strict_equal(json.loads(gzip.decompress(parts.read_regular(OUTPUT))), value)
    print('Complete original archive recovers without its raw file; genuine manifest, byte and physical-leaf controls qualify.')
