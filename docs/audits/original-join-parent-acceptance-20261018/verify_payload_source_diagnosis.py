"""Record complete payload diagnosis replay and genuine control outcomes."""
import argparse
import gzip
import json

import diagnose_payload_sources as diagnosis

SELF = diagnosis.AUDIT / 'verify_payload_source_diagnosis.py'
OUTPUT = diagnosis.AUDIT / 'payload-source-controls-qualified.json.gz'


def derive():
    raw = diagnosis.read(diagnosis.OUTPUT)
    value = json.loads(gzip.decompress(raw))
    first = diagnosis.qualify(value)
    outcomes = diagnosis.controls_record(value, first)
    return dict(schema='fsmgen.payload_source_diagnosis_controls.v1', scope=diagnosis.SCOPE,
        first=diagnosis.allocation.prepare.identity(diagnosis.read(diagnosis.FIRST)),
        diagnosis=diagnosis.allocation.prepare.identity(raw),
        programmes={str(path): diagnosis.allocation.prepare.blob(diagnosis.read(path))
                    for path in (SELF, diagnosis.AUDIT / diagnosis.SELF)},
        complete_difference_paths=value['differences'], outcomes=outcomes,
        product_collection=False, helper_execution=False, historical_execution=False)


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write:
        diagnosis.save(OUTPUT, value)
    else:
        diagnosis.equal(json.loads(gzip.decompress(diagnosis.read(OUTPUT))), value)
    print('Complete saved payload diagnosis, native main assembly and genuine full-product/source/member/type controls reproduce without collecting products or rerunning the helper.')
