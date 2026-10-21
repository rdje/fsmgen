"""Check complete dependent role records and whole-module semantic conservation."""
import argparse
import ast
import copy
import gzip
import json

import epoch_constraints as epoch
import qualify_allocation_data_roles as wrapper

shared, reader = wrapper.shared, wrapper.reader
SELF = 'qualify_allocation_data_role_records.py'
BEFORE = 'c0e54679651f2f067f8b67c1998651c5809e11b1'
REPAIR = '139f8a2ad4661d30a479dc9f718c43f7c1fbc69f'
PATH = shared.AUDIT / 'allocation-data-role-record-controls.json.gz'
HELPER = '''def source_metadata(*, current=False):
    return {str(allocation.execute.AUDIT / name):
            allocation.prepare.blob(source.body(name, current=current)) for name in PREMISES}
'''
ADDITIONS = ("import saved_reader_sources as source", "SELF = 'qualify_operand_allocation.py'",
             "PREMISES = (SELF, 'operand_allocation.py')", HELPER)
MAIN_ADDITIONS = ("if not __debug__:\n    raise SystemExit('Acceptance assertions must be enabled.')",
    "parser.add_argument('--current', action='store_true', help='compare installed qualifier/allocation source metadata')",
    "if args.write or args.current:\n    product['programmes'] = source_metadata(current=True)")


def dump(node):
    return ast.dump(node, include_attributes=False)


def one_function(tree, name):
    matches = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == name]
    assert len(matches) == 1
    return matches[0]


def metadata_expression(function):
    assert isinstance(function.body[-1], ast.Return)
    call = function.body[-1].value
    assert isinstance(call, ast.Call) and isinstance(call.func, ast.Name) and call.func.id == 'dict'
    matches = [keyword for keyword in call.keywords if keyword.arg == 'programmes']
    assert len(matches) == 1
    return matches[0]


def remove_exact(nodes, declarations):
    result = list(nodes)
    for text in declarations:
        expected = dump(ast.parse(text).body[0])
        matches = [index for index, node in enumerate(result) if dump(node) == expected]
        assert len(matches) == 1, 'exact unique declared metadata addition'
        del result[matches[0]]
    return result


def conserve(before, after):
    old_text, current_text = before.decode(), after.decode()
    old, current = ast.parse(old_text), ast.parse(current_text)
    old_function, current_function = one_function(old, 'qualify'), one_function(current, 'qualify')
    old_value = metadata_expression(old_function).value
    current_value = metadata_expression(current_function).value
    shared.equal(dump(current_value), dump(ast.parse('source_metadata()', mode='eval').body))
    old_expression = ast.get_source_segment(old_text, old_value)
    current_expression = ast.get_source_segment(current_text, current_value)
    current_body = ast.get_source_segment(current_text, current_function)
    assert current_body.count(current_expression) == 1
    restored_body = current_body.replace(current_expression, old_expression, 1)
    shared.equal(restored_body, ast.get_source_segment(old_text, old_function))
    projected = copy.deepcopy(current)
    metadata_expression(one_function(projected, 'qualify')).value = copy.deepcopy(old_value)
    projected.body = remove_exact(projected.body, ADDITIONS)
    old_main = [node for node in old.body if isinstance(node, ast.If)]
    new_main = [node for node in projected.body if isinstance(node, ast.If)]
    assert len(old_main) == len(new_main) == 1
    shared.equal(dump(old_main[0].test), dump(new_main[0].test))
    new_main[0].body = remove_exact(new_main[0].body, MAIN_ADDITIONS)
    shared.equal(dump(projected), dump(old))
    return dict(original_function=ast.get_source_segment(old_text, old_function),
        original_metadata_expression=old_expression, current_metadata_expression=current_expression,
        declared_module_additions=list(ADDITIONS), declared_cli_additions=list(MAIN_ADDITIONS),
        whole_module_ast=shared.prepare.identity(dump(old).encode()),
        scope='The complete original module AST and exact qualify() text reconstruct outside only declared metadata additions/selection. Nested controls, API signature, sources/inputs, writes and every other statement remain unchanged.')


def source_controls(before, after):
    cases = (
        ('changed-namespace', "namespace['__name__'] = '__main__'", "namespace['__name__'] = 'borrowed'"),
        ('weakened-refusal', "assert refusal and not output.getvalue(), 'reader refuses before printing success'", "assert True, 'reader refuses before printing success'"),
        ('changed-metadata-default', 'def source_metadata(*, current=False):', 'def source_metadata(*, current=True):'),
        ('hidden-write', '    original = allocation.execute.read(allocation.PATH)',
         '    allocation.execute.save(PATH, {})\n    original = allocation.execute.read(allocation.PATH)'),
    )
    outcomes = []
    text = after.decode()
    for label, old, new in cases:
        assert text.count(old) == 1
        candidate = text.replace(old, new, 1).encode()
        try:
            conserve(before, candidate)
        except AssertionError as error:
            outcomes.append(dict(label=label, candidate=shared.prepare.blob(candidate), refusal=str(error)))
        else:
            raise AssertionError('changed semantic/module source admitted: ' + label)
    return outcomes


def derive():
    qualification = wrapper.Qualification()
    raw = shared.execute.read(qualification.output)
    shared.equal(raw, epoch.read(REPAIR, str(qualification.output)))
    value = json.loads(gzip.decompress(raw))
    qualification.review(value)
    name = str(shared.AUDIT / reader.SELF)
    before, after = epoch.read(BEFORE, name), shared.execute.read(name)
    shared.equal(after, epoch.read(REPAIR, name))
    conservation = conserve(before, after)
    key = str(shared.AUDIT / reader.SELF)
    cases = (
        ('borrowed-target', ('reader',), 'operand_allocation.py'),
        ('changed-shared-verifier', ('sources', 'saved_source_roles.py'), shared.prepare.blob(b'changed verifier\n')),
        ('omitted-original', ('reference', 'original', reader.SELF), None),
        ('boolean-status', ('actual', 0, 'status'), False),
        ('float-status', ('actual', 0, 'status'), 0.0),
        ('float-source-size', ('reference', 'metadata', key, 'bytes'), float(value['reference']['metadata'][key]['bytes'])),
        ('changed-original-proof', ('reference', 'proof', 'identity', 'sha256'), '0' * 64),
        ('borrowed-scope', ('scope',), 'original runtime execution qualified'),
    )
    outcomes = []
    for label, path, replacement in cases:
        candidate = copy.deepcopy(value)
        parent = candidate
        for member in path[:-1]:
            parent = parent[member]
        if label == 'omitted-original':
            del parent[path[-1]]
        else:
            parent[path[-1]] = replacement
        try:
            qualification.review(candidate)
        except AssertionError as error:
            if label in ('boolean-status', 'float-status', 'float-source-size'):
                assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed complete dependent role record admitted: ' + label)
    for label in ('short-key-borrowing', 'invented-prepare-premise'):
        candidate = copy.deepcopy(value)
        if label == 'short-key-borrowing':
            candidate['reference']['metadata'][reader.SELF] = candidate['reference']['metadata'].pop(key)
        else:
            candidate['reference']['original']['prepare.py'] = shared.source.original('prepare.py')
        try:
            qualification.review(candidate)
        except AssertionError as error:
            outcomes.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('borrowed source metadata contract admitted: ' + label)
    shared.equal(shared.execute.read(qualification.output), raw)
    return dict(schema='fsmgen.allocation_data_role_record_controls.v1', input=shared.prepare.blob(raw),
        conservation=dict(before_revision=BEFORE, repaired_revision=REPAIR, path=name,
            before=shared.prepare.blob(before), after=shared.prepare.blob(after), result=conservation),
        source_controls=source_controls(before, after), outcomes=outcomes,
        programmes={name: shared.prepare.blob(shared.execute.read(shared.AUDIT / name))
                    for name in (SELF, wrapper.SELF, 'saved_source_roles.py')},
        scope='Actual shared reviewer and closed two-key adapter against complete candidate records, exact native source/module conservation and parsed-only source interventions. No candidate source, current product rederivation, original semantic/model/recipe/cohort or whole helper executes.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write:
        shared.execute.save(PATH, value)
    else:
        shared.equal(json.loads(gzip.decompress(shared.execute.read(PATH))), value)
    print('Complete dependent role records reject genuine source/member/primitive/proof/contract candidates; the entire original module and exact control function conserve outside declared metadata changes.')
