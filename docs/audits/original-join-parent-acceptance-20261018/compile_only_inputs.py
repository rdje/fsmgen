"""Bind preparation compile inputs and discarded results without running source."""
import argparse
import ast
import builtins
import copy
import gzip
import hashlib
import json
from pathlib import Path
import sys
import types

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import fixed_input_coverage as fixed_inputs
import operand_inventory as operands
import preparation_correction as correction
import prepare
import prerequisite_inputs as prerequisite
import saved_program_input as saved

AUTHORITY = '0691a5fb19e7f43d11bd85466a9571c363609e4a'
OWNER = correction.OWNER.rsplit('.', 1)[0] + '.2'
PATH = execute.AUDIT / 'compile-only-inputs-qualified.json.gz'
BASE = 'docs/audits/original-context-cause-consumer-prerequisites-20261012'
READER = BASE + '/verify.py'
RECEIPTS = ('preparation-first', 'preparation-second')
MODEL_PATHS = (fixed_inputs.PATH, operands.INPUT, correction.PATH)
PREMISES = tuple(dict.fromkeys(('compile_only_inputs.py', *correction.PREMISES)))
CUSTODY_OWNER = operands.OWNER.rsplit('.', 3)[0] + '.3'
LIMITS = dict(original_compile_callable_qualified=False, original_stdin_observed=False,
              prelaunch_custody_qualified=False, original_execution_qualified=False,
              complete_source_allocation_qualified=False, default_reachability_qualified=False,
              effects_qualified=False, runtime_permission=False)
SCOPE = ('Complete fixed preparation compile-input and source call-use bindings only. '
         'Native versioned receipt/source bytes and the qualified no-op correction '
         'supply the data premises. Whole-source AST and separate token/site/line '
         'correspondence establish standalone expressions whose compilation results '
         'are discarded. Current builtins.compile validates syntax and filenames but '
         'never evaluates a code object or executes any historical function/source. '
         'This is conditional source semantics, not observed original compiler identity '
         'or original preparation execution. After-invocation source descriptors, '
         'actual original stdin/prelaunch gaps and every native failure retain. '
         'Python AST/token/compiler/Path/Git/hash APIs, fixed namespace resolution '
         'and archived receipt authenticity remain shared premises. Full executable '
         'allocation/default/effect/runtime/custody and native/private gates remain open.')

FIRST_LOOP = """for row, error in ((first, 'AssertionError'), (second, "NameError: name 'review' is not defined")):
    need(row['command'] == ['python3', '-B', '-'] and type(row['status']) is int and row['status'] == 1
         and row['expected_status'] is None and row['stdout'] == '' and error in row['stderr'],
         'both unwrapped preparations remain actual1 without predeclared native status')
    raw = Path(row['source']['path']).read_bytes()
    need(Path(row['source']['path']).parent == BASE and pin(raw) == {k: row['source'][k] for k in ('bytes', 'sha256')},
         'whole explicitly after-invocation preparation source reconstruction')
    compile(raw, row['source']['path'], 'exec')
"""


def original_domain(raw):
    names = {*correction.NAMES, READER, *(BASE + '/' + tag + '.json' for tag in RECEIPTS)}
    for tag in RECEIPTS:
        value = json.loads(raw[BASE + '/' + tag + '.json'])
        path = value['source']['path']
        assert type(path) is str and Path(path).parent == Path(BASE)
        prerequisite.tables.safe_name(path)
        names.add(path)
    return names


def standalone(body, statement, expected):
    """A discarded expression plus an independent unadorned token/line witness."""
    assert isinstance(statement, ast.Expr), 'compile result must be a standalone discarded expression'
    saved.equal_ast(statement, expected)
    call = statement.value
    assert isinstance(call, ast.Call)
    tokens = operands.token_sites(body)
    site = (call.lineno, call.col_offset)
    assert tokens[site] == dict(operation='compile', syntactic_role='compile-only-operand')
    line = body.decode().splitlines()[call.lineno - 1]
    assert call.lineno == call.end_lineno
    assert line.lstrip() == expected, 'whole independent unadorned compiler call line'
    return dict(line=call.lineno, column=call.col_offset,
                statement=ast.get_source_segment(body.decode(), statement),
                result_use='discarded standalone expression', namespace=None,
                original_callable_identity_qualified=False)


def candidates(raw, fixed):
    first_body, second_body = raw[READER], raw[correction.READER]
    first = saved.function(ast.parse(first_body), 'preparation')
    saved.equal_ast(first.body[0], "first, second = read('preparation-first.json'), read('preparation-second.json')")
    saved.equal_ast(first.body[1], FIRST_LOOP)
    first_site = standalone(first_body, first.body[1].body[-1], "compile(raw, row['source']['path'], 'exec')")
    second = saved.function(ast.parse(second_body), 'preparation')
    correction.recipe(second_body)
    second_site = standalone(second_body, second.body[2].body[5],
                            "compile(source, str(BASE / (tag + '-source.txt')), 'exec')")
    for reader, base in ((READER, BASE), (correction.READER, correction.BASE)):
        assert fixed['exports'][reader]['BASE'] == base
        assert raw[reader] == prepare.unblob(fixed['sources'][reader]['body'])
    rows = []
    for tag in RECEIPTS:
        receipt_name = BASE + '/' + tag + '.json'
        receipt = json.loads(raw[receipt_name])
        source_name = receipt['source']['path']
        body = raw[source_name]
        assert {key: receipt['source'][key] for key in ('bytes', 'sha256')} == prepare.identity(body)
        assert receipt['command'] == ['python3', '-B', '-'] and type(receipt['status']) is int and receipt['status'] == 1
        assert receipt['expected_status'] is None and receipt['stdout'] == ''
        error = 'AssertionError' if tag == RECEIPTS[0] else "NameError: name 'review' is not defined"
        assert error in receipt['stderr']
        rows.append(dict(context='prerequisites:' + tag, reader=READER, site=first_site,
            source_path=source_name, logical_name=str(Path(source_name)), payload=prepare.blob(body),
            original_receipt=receipt, original_descriptor=receipt['source'],
            source_role='explicit after-invocation source reconstruction; actual original stdin unobserved'))
    qualified = json.loads(gzip.decompress(raw[str(correction.PATH)]))
    assert correction.review(qualified['result'], {name: raw[name] for name in correction.NAMES},
                             qualified['references'])
    for pair in qualified['result']['pairs']:
        source_name = pair['custody']['corrected_source']['path']
        logical = str(Path(correction.BASE) / (pair['tag'] + '-source.txt'))
        assert source_name == logical and raw[source_name] == prepare.unblob(pair['corrected_source'])
        assert pair['archived_explanation_supported'] is False
        rows.append(dict(context='container:' + pair['tag'], reader=correction.READER, site=second_site,
            source_path=source_name, logical_name=logical, payload=prepare.blob(raw[source_name]),
            original_receipt=pair['native_receipt'], original_descriptor=pair['custody'],
            source_role='after-invocation reconstruction; retained escape correction is a no-op',
            correction_identity=bounded.identity(pair)))
    return rows


def derive(raw, references):
    originals = original_domain(raw)
    assert set(references) == originals and set(raw) == originals | {str(path) for path in MODEL_PATHS}, 'complete input-only source/data domain'
    for name in originals:
        reference, body = references[name], raw[name]
        assert reference['revision'] == epoch.REVISION and reference['path'] == name
        assert reference['retention_contract'] == 'fsmgen_required_history'
        assert len(body) == reference['bytes'] and hashlib.sha1(
            b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == reference['oid'], 'whole native input binding: ' + name
    prior = json.loads(gzip.decompress(raw[str(fixed_inputs.PATH)]))['result']
    fixed = json.loads(gzip.decompress(raw[str(operands.INPUT)]))['graph']
    assert fixed['revision'] == epoch.REVISION and fixed['runtime_permission'] is False
    sites = [row for row in prior['deferred'] if row['owner'] == OWNER.rsplit('.', 1)[0]]
    assert len(sites) == 2 and {row['site'][0] for row in sites} == {READER, correction.READER}
    by_site = {tuple(row['site']): row for row in sites}
    for row in sites:
        actual = operands.ast_sites(raw[row['site'][0]], row['site'][0])
        assert [item for item in actual if item['operation'] == 'compile'
                and item['source']['line'] == row['site'][1]] == [row['operand']]
    bindings = candidates(raw, fixed)
    seen = set()
    for row in bindings:
        identity = (row['reader'], row['site']['line'], row['site']['column'])
        assert identity in by_site
        row['original_operand'] = by_site[identity]
        body = prepare.unblob(row['payload'])
        # This is the current native compiler operating on bytes, not execution
        # of the historical compiler call or any generated code object.
        code = builtins.compile(body, row['logical_name'], 'exec')
        assert type(code) is types.CodeType and code.co_name == '<module>' and code.co_filename == row['logical_name']
        row['current_syntax_compilation'] = dict(filename=code.co_filename, mode='exec', result_type='code', code_executed=False)
        assert row['context'] not in seen
        seen.add(row['context'])
    assert seen == {'prerequisites:' + tag for tag in RECEIPTS} | {'container:' + tag for tag in correction.TAGS}
    return dict(schema='fsmgen.compile_only_inputs.v1', owner=OWNER, scope=SCOPE, bindings=bindings,
        prior_models={str(path): prepare.identity(raw[str(path)]) for path in MODEL_PATHS},
        complete_allocation_owner=fixed_inputs.direct.ALLOCATION_OWNER, historical_custody_gap_owner=CUSTODY_OWNER,
        unresolved_scope='All other preparation statements and original callable/default/effect/runtime roles remain separately owned.', **LIMITS)


def review(value, raw, references):
    assert all(value[key] is False for key in LIMITS), 'no borrowed original compiler/input/custody/execution authority'
    assert all(row['site']['original_callable_identity_qualified'] is False
               and row['current_syntax_compilation']['code_executed'] is False for row in value['bindings'])
    bounded.strict_equal(value, derive(raw, references))
    return True


def controls(expected, raw, references):
    result = []
    for label in ('missing_case', 'duplicate_case', 'wrong_name', 'wrong_role', 'wrong_source', 'wrong_context', 'executed_code', 'borrowed_runtime', 'typed_permission'):
        candidate = copy.deepcopy(expected)
        row = candidate['bindings'][0]
        if label == 'missing_case': candidate['bindings'].pop()
        elif label == 'duplicate_case': candidate['bindings'].append(copy.deepcopy(row))
        elif label == 'wrong_name': row['logical_name'] = '<foreign-preparation>'
        elif label == 'wrong_role': row['site']['result_use'] = 'executed compiler output'
        elif label == 'wrong_source': row['payload'] = prepare.blob(b'pass\n')
        elif label == 'wrong_context': row['context'] = candidate['bindings'][-1]['context']
        elif label == 'executed_code': row['current_syntax_compilation']['code_executed'] = True
        elif label == 'borrowed_runtime': candidate['runtime_permission'] = True
        else: candidate['runtime_permission'] = 0
        try: review(candidate, raw, references)
        except AssertionError as error:
            result.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else: raise AssertionError('changed input-only binding admitted: ' + label)
    source_name = expected['bindings'][0]['source_path']
    for label in ('changed_raw_source', 'changed_receipt_type', 'missing_source'):
        candidate = dict(raw)
        if label == 'changed_raw_source': candidate[source_name] += b'\n# changed input\n'
        elif label == 'changed_receipt_type':
            name = BASE + '/' + RECEIPTS[0] + '.json'
            receipt = json.loads(candidate[name]); receipt['status'] = True
            candidate[name] = prepare.encoded(receipt)
        else: del candidate[source_name]
        try: derive(candidate, references)
        except AssertionError as error:
            result.append(dict(label=label, changed_inputs={name: prepare.blob(body) for name, body in candidate.items()
                if body != raw[name]}, omitted=sorted(set(raw) - set(candidate)), refusal=str(error)))
        else: raise AssertionError('changed fixed compile source admitted')
    for label, source in (('assigned_result', "result = compile(raw, row['source']['path'], 'exec')"),
                          ('wrong_source_expression', "compile(other, row['source']['path'], 'exec')"),
                          ('wrong_name_expression', "compile(raw, 'foreign.py', 'exec')")):
        statement = ast.parse(source).body[0]
        try: standalone((source + '\n').encode(), statement, "compile(raw, row['source']['path'], 'exec')")
        except AssertionError as error:
            result.append(dict(label=label, candidate_source=source, refusal=str(error),
                               kind='independent source call-use refusal without fixed source identity or saved reviewer'))
        else: raise AssertionError('changed standalone compiler role admitted')
    expected_source = "compile(raw, row['source']['path'], 'exec')"
    for label, source in (('line_oracle_assigned_result', 'result = ' + expected_source),
                          ('token_oracle_exec_result', 'exec(' + expected_source + ')')):
        # Supply the unchanged accepted expression, as a stale/incorrect AST
        # extraction might do. Its grammar passes. The separate actual source
        # token/whole-line predicates must still reject the changed result use.
        statement = ast.parse(expected_source).body[0]
        statement.value.col_offset = source.index('compile(')
        statement.value.end_col_offset = statement.value.col_offset + len(expected_source)
        saved.equal_ast(statement, expected_source)
        try: standalone((source + '\n').encode(), statement, expected_source)
        except AssertionError as error:
            result.append(dict(label=label, candidate_source=source,
                expression=correction.models.typed(statement), refusal=str(error),
                kind='independent actual-source oracle refusal after expression grammar passes'))
        else: raise AssertionError('independent source use oracle admitted changed role')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = {str(path): execute.read(path) for path in MODEL_PATHS}
    for name, body in raw.items(): assert body == epoch.read(AUTHORITY, name)
    names = {*correction.NAMES, READER, *(BASE + '/' + tag + '.json' for tag in RECEIPTS)}
    references = {}
    for name in sorted(names):
        reference = prerequisite.file_reference(epoch.REVISION, name)
        raw[name], references[name] = prerequisite.read_reference(reference), reference
    for name in sorted(original_domain(raw) - names):
        reference = prerequisite.file_reference(epoch.REVISION, name)
        raw[name], references[name] = prerequisite.read_reference(reference), reference
    value = json.loads(prepare.encoded(derive(raw, references)))
    assert review(value, raw, references)
    product = dict(result=value, controls=controls(value, raw, references), references=references,
        inputs={name: prepare.blob(body) for name, body in raw.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Complete preparation input bytes and compilation names bind to standalone discarded compiler results; native source/data joins and genuine controls agree. Current syntax compilation executes no code; original input/callable/prelaunch and complete allocation/effect/runtime qualifications remain open.')
