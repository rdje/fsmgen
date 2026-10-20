"""Reconstruct genuine full-record refusals for operand source-role evidence."""
import argparse
import copy
import gzip
import json

import bounded_runtime_inventory as bounded
import execute
import prepare
import qualify_operand_roles as wrapper
from saved_source_roles import Qualification

SELF = 'qualify_operand_role_records.py'
PATH = execute.AUDIT / 'operand-role-record-controls.json.gz'


def derive():
    qualifier = Qualification(wrapper.operands, 'qualify_operand_roles.py',
                              'operand-source-roles-qualified.json.gz', wrapper.LINE, wrapper.SCOPE)
    raw = execute.read(qualifier.output)
    value = json.loads(gzip.decompress(raw))
    qualifier.review(value)
    original = copy.deepcopy(value)
    cases = (
        ('borrowed-target', ('reader',), 'qualify_caller_modules.py'),
        ('changed-shared-verifier', ('sources', 'saved_source_roles.py'), prepare.blob(b'changed verifier\n')),
        ('omitted-original', ('reference', 'original', 'prepare.py'), None),
        ('boolean-status', ('actual', 0, 'status'), False),
        ('float-status', ('actual', 0, 'status'), 0.0),
        ('float-size', ('reference', 'metadata', 'prepare.py', 'bytes'),
         float(value['reference']['metadata']['prepare.py']['bytes'])),
        ('changed-original-proof', ('reference', 'proof', 'identity', 'sha256'), '0' * 64),
    )
    outcomes = []
    for label, path, after in cases:
        candidate = copy.deepcopy(value)
        parent = candidate
        for key in path[:-1]:
            parent = parent[key]
        before = parent[path[-1]]
        if label == 'omitted-original':
            del parent[path[-1]]
        else:
            parent[path[-1]] = after
        try:
            qualifier.review(candidate)
        except AssertionError as error:
            outcomes.append(dict(label=label, path=list(path), before=before, after=after,
                                 candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed operand role record admitted: ' + label)
    bounded.strict_equal(value, original)
    assert execute.read(qualifier.output) == raw, 'complete original qualification record conserved'
    return dict(schema='fsmgen.operand_role_record_controls.v1',
                input=prepare.blob(raw), outcomes=outcomes,
                programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in
                            (SELF, 'qualify_operand_roles.py', 'saved_source_roles.py')},
                scope='Actual shared reviewer positive and genuine complete record refusals only. '
                      'No historical source, original producer/model/recipe/cohort or helper sequence executes. '
                      'Raw stderr hashes identify captured bytes; only literal-root-normalized stderr is retained.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    result = derive()
    if args.write:
        execute.save(PATH, result)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), result)
    print('Complete operand source-role record and genuine target/source/member/primitive/proof refusals pass.')
