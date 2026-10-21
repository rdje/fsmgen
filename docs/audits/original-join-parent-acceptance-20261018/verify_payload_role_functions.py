"""Check payload source-role evidence and exact pre-existing function conservation."""
import argparse
import ast
import gzip
import json

import epoch_constraints as epoch
import payload_closure as payload
import qualify_payload_roles as wrapper
from saved_source_roles import Qualification

SELF = 'verify_payload_role_functions.py'
BASE = 'e66d225600583c547e6aa864605133f0af63d7af'
OUTPUT = payload.allocation.execute.AUDIT / 'payload-role-functions-qualified.json.gz'


def functions(raw):
    text = raw.decode()
    return {node.name: ast.get_source_segment(text, node) for node in ast.parse(text).body
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))}


def derive():
    model = payload.allocation
    qualifier = Qualification(payload, 'qualify_payload_roles.py',
                              'payload-source-roles-qualified.json.gz', wrapper.LINE, wrapper.SCOPE)
    raw = model.execute.read(qualifier.output)
    qualifier.review(json.loads(gzip.decompress(raw)))
    before = epoch.read(BASE, str(model.execute.AUDIT / payload.SELF))
    after = model.execute.read(model.execute.AUDIT / payload.SELF)
    old, current = functions(before), functions(after)
    assert set(current) == set(old) | {'source_metadata'}, 'complete function membership'
    model.bounded.strict_equal({name: current[name] for name in old}, old)
    original = epoch.read(model.source.REVISION, str(payload.PATH))
    assert model.execute.read(payload.PATH) == original, 'entire original payload proof unchanged'
    return dict(schema='fsmgen.payload_role_functions.v1',
        scope='Complete saved/current/disabled source-role record and exact pre-existing function text only. Full role-record/module intervention and native admission remain separately owned; no target product collection, saved CLI or helper repeats.',
        role=qualifier.reader.SELF, role_proof=model.prepare.blob(raw),
        original_proof=model.prepare.identity(original),
        conservation=dict(revision=BASE, path=str(model.execute.AUDIT / payload.SELF),
            before=model.prepare.blob(before), after=model.prepare.blob(after),
            functions=old, added_function='source_metadata'),
        programmes={name: model.prepare.blob(model.execute.read(model.execute.AUDIT / name))
                    for name in (SELF, 'qualify_payload_roles.py', 'saved_source_roles.py')})


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    model = payload.allocation
    if args.write:
        model.execute.save(OUTPUT, value)
    else:
        model.bounded.strict_equal(json.loads(gzip.decompress(model.execute.read(OUTPUT))), value)
    print('Complete payload source roles qualify; every pre-existing input/derive/review/control/namespace function body and the original proof remain byte-exact.')
