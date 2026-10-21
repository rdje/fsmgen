"""Qualify complete payload role records and exact original module reconstruction."""
import argparse
import ast
import copy
import gzip
import json

import diagnose_payload_sources as diagnostic
import epoch_constraints as epoch
import payload_closure as payload
import qualify_payload_roles as wrapper
import verify_payload_role_functions as functions
from saved_source_roles import Qualification

model = payload.allocation
AUDIT = model.execute.AUDIT
SELF = 'qualify_payload_role_records.py'
BEFORE = 'e66d225600583c547e6aa864605133f0af63d7af'
REPAIR = 'de3dcc97744bab262df8490eccb4d2ab433151c6'
OUTPUT = AUDIT / 'payload-role-record-controls.json.gz'
SCOPE = ('Complete native payload role-record and source/function/module conservation '
         'with genuine record and parsed-source interventions only. Original native '
         'proof and source-model/Python/API premises retain. No target product, CLI, '
         'helper, historical candidate/model/recipe or original semantic cohort '
         'executes. Native route admission and all original runtime/custody/private/'
         'HIAL/full-CI qualifications remain separately owned.')


def equal(left, right):
    return model.bounded.strict_equal(left, right)


def node(text):
    return ast.parse(text).body[0]


def same(left, right):
    equal(ast.dump(left), ast.dump(right))


def product_assignment(main):
    matches = [item for item in main.body if isinstance(item, ast.Assign)
               and len(item.targets) == 1 and isinstance(item.targets[0], ast.Name)
               and item.targets[0].id == 'product']
    assert len(matches) == 1
    return matches[0]


def project(before, after):
    """Remove only independently declared additions; compare every remaining AST node."""
    old, current = ast.parse(before), ast.parse(after)
    declarations = {
        'SELF': node("SELF = 'payload_closure.py'"),
        'PREMISES': node('PREMISES = tuple(dict.fromkeys((SELF, *allocation.PREMISES)))'),
    }
    helper = node('''def source_metadata(*, current=False):
    return {name: allocation.prepare.blob(allocation.source.body(name, current=current))
            for name in PREMISES}
''')
    removed, kept = [], []
    for item in current.body:
        if isinstance(item, ast.Assign) and len(item.targets) == 1 and isinstance(item.targets[0], ast.Name) and item.targets[0].id in declarations:
            name = item.targets[0].id
            same(item, declarations[name]); removed.append(name)
        elif isinstance(item, ast.FunctionDef) and item.name == 'source_metadata':
            same(item, helper); removed.append('source_metadata')
        else:
            kept.append(item)
    assert sorted(removed) == sorted([*declarations, 'source_metadata']), 'exact added declaration population'
    current.body = kept
    assert isinstance(old.body[-1], ast.If) and isinstance(current.body[-1], ast.If)
    main = current.body[-1]
    guard = node("if not __debug__:\n    raise SystemExit('Acceptance assertions must be enabled.')")
    same(main.body[0], guard)
    del main.body[0]
    flag = node("parser.add_argument('--current', action='store_true')")
    flags = [i for i, item in enumerate(main.body) if ast.dump(item) == ast.dump(flag)]
    assert len(flags) == 1, 'exact new CLI flag'
    del main.body[flags[0]]
    assignment = product_assignment(main)
    original = product_assignment(old.body[-1])
    assert isinstance(assignment.value, ast.Call) and isinstance(original.value, ast.Call)
    metadata = [k for k in assignment.value.keywords if k.arg == 'programmes']
    original_metadata = [k for k in original.value.keywords if k.arg == 'programmes']
    assert len(metadata) == len(original_metadata) == 1
    same(metadata[0].value, ast.parse('source_metadata(current=args.write or args.current)', mode='eval').body)
    metadata[0].value = copy.deepcopy(original_metadata[0].value)
    same(current, old)
    return dict(removed=removed, original_module_ast=ast.dump(old), reconstructed_module_ast=ast.dump(current),
                original_metadata_ast=ast.dump(original_metadata[0].value),
                declared_current_metadata_ast='source_metadata(current=args.write or args.current)')


def derive():
    qualifier = Qualification(payload, 'qualify_payload_roles.py',
        'payload-source-roles-qualified.json.gz', wrapper.LINE, wrapper.SCOPE)
    raw = diagnostic.read(qualifier.output)
    equal(raw, epoch.read(REPAIR, str(qualifier.output)))
    value = json.loads(gzip.decompress(raw))
    qualifier.review(value)
    before = epoch.read(BEFORE, str(AUDIT / payload.SELF))
    after = diagnostic.read(AUDIT / payload.SELF)
    equal(after, epoch.read(REPAIR, str(AUDIT / payload.SELF)))
    old, current = functions.functions(before), functions.functions(after)
    assert set(current) == set(old) | {'source_metadata'}
    equal({name: current[name] for name in old}, old)
    projection = project(before, after)
    prior_raw = diagnostic.read(functions.OUTPUT)
    equal(prior_raw, epoch.read(REPAIR, str(functions.OUTPUT)))
    prior = json.loads(gzip.decompress(prior_raw))
    equal(prior['role_proof'], model.prepare.blob(raw))
    equal(prior['conservation']['before'], model.prepare.blob(before))
    equal(prior['conservation']['after'], model.prepare.blob(after))
    records = []
    cases = (
        ('borrowed-target', ('reader',), 'operand_allocation.py'),
        ('borrowed-scope', ('scope',), 'borrowed allocation scope'),
        ('changed-verifier', ('sources','saved_source_roles.py'), model.prepare.blob(b'changed verifier\n')),
        ('omitted-original', ('reference','original','prepare.py'), None),
        ('boolean-status', ('actual',0,'status'), False),
        ('float-status', ('actual',0,'status'), 0.0),
        ('float-size', ('reference','metadata','prepare.py','bytes'), float(value['reference']['metadata']['prepare.py']['bytes'])),
        ('changed-proof', ('reference','proof','identity','sha256'), '0' * 64),
    )
    for label, path, replacement in cases:
        candidate = copy.deepcopy(value)
        parent = candidate
        for key in path[:-1]: parent = parent[key]
        original = parent[path[-1]]
        if label == 'omitted-original': del parent[path[-1]]
        else: parent[path[-1]] = replacement
        try:
            qualifier.review(candidate)
        except AssertionError as error:
            if label in ('boolean-status','float-status','float-size'):
                assert str(error) == 'JSON value kind', 'primitive reaches typed equality'
            records.append(dict(label=label, path=list(path), before=original, after=replacement,
                                candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed payload role record admitted: ' + label)
    source_controls = []
    candidates = (
        ('weakened-namespace', "assert set(keys) <= set(syntax['module_bindings'])", 'assert True'),
        ('weakened-exclusion', 'assert isinstance(statement, ast.Expr) and statement.value is call', 'assert True'),
        ('changed-metadata-default', 'def source_metadata(*, current=False):', 'def source_metadata(*, current=True):'),
        ('lost-current-role', 'source_metadata(current=args.write or args.current)', 'source_metadata(current=args.write)'),
        ('wrong-native-allocation', "AUTHORITY = '14237e63cb12c8b0ce43251772cfdac17d5d084f'", "AUTHORITY = '" + '0' * 40 + "'"),
        ('hidden-write', '    args = parser.parse_args()', '    args = parser.parse_args()\n    args.write = True'),
    )
    for label, old_text, new_text in candidates:
        text = after.decode()
        assert text.count(old_text) == 1, 'unique genuine source control'
        changed = text.replace(old_text, new_text).encode()
        ast.parse(changed)
        try:
            project(before, changed)
        except AssertionError as error:
            source_controls.append(dict(label=label, candidate=model.prepare.blob(changed), refusal=str(error), executed=False))
        else:
            raise AssertionError('changed payload semantic module admitted: ' + label)
    equal(diagnostic.read(qualifier.output), raw)
    return dict(schema='fsmgen.payload_role_record_controls.v1', scope=SCOPE,
        input=model.prepare.blob(raw), prior_function_record=model.prepare.blob(prior_raw),
        conservation=dict(before_revision=BEFORE, after_revision=REPAIR,
            path=str(AUDIT / payload.SELF), before=model.prepare.blob(before), after=model.prepare.blob(after),
            functions=old, added_function='source_metadata', module_projection=projection),
        record_controls=records, source_controls=source_controls,
        programmes={name: model.prepare.blob(diagnostic.read(AUDIT / name))
                    for name in (SELF, 'qualify_payload_roles.py', 'saved_source_roles.py', 'verify_payload_role_functions.py')})


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write:
        diagnostic.save(OUTPUT, value)
    else:
        equal(json.loads(gzip.decompress(diagnostic.read(OUTPUT))), value)
    print('Complete payload role-record corruptions refuse; exact original function/module reconstruction and genuine parsed namespace/exclusion/metadata/write controls qualify without executing candidate code.')
