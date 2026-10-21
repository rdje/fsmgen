"""Check complete compile-only role records and every pre-existing function body."""
import argparse
import ast
import copy
import gzip
import json

import compile_only_inputs as model
import qualify_compile_only_roles as wrapper
from saved_source_roles import Qualification

SELF = 'qualify_compile_only_role_records.py'
BASE = '7924366a830e2cf95b809d3711a734aaafe32a03'
PATH = model.execute.AUDIT / 'compile-only-role-record-controls-label-corrected.json.gz'


def functions(raw):
    text = raw.decode()
    return {node.name: ast.get_source_segment(text, node) for node in ast.parse(text).body
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))}


def derive():
    qualifier = Qualification(model, 'qualify_compile_only_roles.py',
                              'compile-only-source-roles-qualified.json.gz', wrapper.LINE, wrapper.SCOPE)
    raw = model.execute.read(qualifier.output)
    value = json.loads(gzip.decompress(raw))
    qualifier.review(value)
    before = model.epoch.read(BASE, str(model.execute.AUDIT / model.SELF))
    after = model.execute.read(model.execute.AUDIT / model.SELF)
    old, current = functions(before), functions(after)
    assert set(current) == set(old) | {'source_metadata'}, 'complete existing/new function population'
    model.bounded.strict_equal({name: current[name] for name in old}, old)
    outcomes = []
    cases = (
        ('borrowed-target', ('reader',), 'qualify_caller_modules.py'),
        ('changed-shared-verifier', ('sources', 'saved_source_roles.py'), model.prepare.blob(b'changed verifier\n')),
        ('omitted-original', ('reference', 'original', 'prepare.py'), None),
        ('boolean-status', ('actual', 0, 'status'), False),
        ('float-status', ('actual', 0, 'status'), 0.0),
        ('float-size', ('reference', 'metadata', 'prepare.py', 'bytes'),
         float(value['reference']['metadata']['prepare.py']['bytes'])),
        ('changed-original-proof', ('reference', 'proof', 'identity', 'sha256'), '0' * 64),
    )
    for label, path, replacement in cases:
        candidate = copy.deepcopy(value)
        parent = candidate
        for key in path[:-1]:
            parent = parent[key]
        original = parent[path[-1]]
        if label == 'omitted-original':
            del parent[path[-1]]
        else:
            parent[path[-1]] = replacement
        try:
            qualifier.review(candidate)
        except AssertionError as error:
            if label in ('boolean-status', 'float-status', 'float-size'):
                assert str(error) == 'JSON value kind', 'primitive candidate reaches typed equality'
            outcomes.append(dict(label=label, path=list(path), before=original, after=replacement,
                                 candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed compile-only role record admitted: ' + label)
    assert model.execute.read(qualifier.output) == raw, 'whole original qualification conserved'
    return dict(schema='fsmgen.compile_only_role_record_controls.v1', input=model.prepare.blob(raw),
        conservation=dict(revision=BASE, path=str(model.execute.AUDIT / model.SELF),
            before=model.prepare.blob(before), after=model.prepare.blob(after),
            functions=old, added_function='source_metadata',
            scope='Every pre-existing top-level function, including nested function bodies and derive(raw, references), remains byte-exact. CLI metadata selection and new helper are outside that equality.'),
        outcomes=outcomes,
        programmes={name: model.prepare.blob(model.execute.read(model.execute.AUDIT / name))
                    for name in (SELF, 'qualify_compile_only_roles.py', 'saved_source_roles.py')},
        scope='Current shared reviewer positive and actual complete record corruptions only. '
              'No historical source/model/recipe/cohort or helper sequence executes. '
              'Raw stderr hashes identify original bytes; retained stderr normalizes the literal root.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write:
        model.execute.save(PATH, value)
    else:
        model.bounded.strict_equal(json.loads(gzip.decompress(model.execute.read(PATH))), value)
    print('Complete compile-only role records reject genuine source/member/primitive/proof candidates; every existing function body is conserved.')
