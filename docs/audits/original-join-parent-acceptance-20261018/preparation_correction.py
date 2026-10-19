"""Correct the retained preparation escape narrative without rewriting history."""
import argparse
import ast
import copy
import gzip
import hashlib
import json
import sys

import ast_model_inputs as models
import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import prepare
import prerequisite_inputs as prerequisite
import saved_program_input as saved

OWNER = models.OWNER.rsplit('.', 1)[0] + '.5.1'
PATH = execute.AUDIT / 'preparation-correction-qualified.json.gz'
BASE = 'docs/audits/primary-raw-cause-container-acceptance-20261012'
READER = BASE + '/verify.py'
CUSTODY = BASE + '/preparation-source-custody.json'
TAGS = ('preparation-first', 'preparation-anchor-read-first')
NAMES = (READER, CUSTODY, *(BASE + '/' + tag + suffix
         for tag in TAGS for suffix in ('.json', '.py.txt', '-source.txt')))
PREMISES = tuple(dict.fromkeys(('preparation_correction.py', *models.PREMISES)))
LIMITS = dict(escape_correction_observed=False, original_stdin_observed=False,
              prelaunch_custody_qualified=False, original_execution_qualified=False,
              compile_only_inputs_qualified=False, complete_source_allocation_qualified=False,
              effects_qualified=False, runtime_permission=False)
SCOPE = ('Correction of the retained preparation-source explanation only. The pinned '
         'first/corrected source pairs are identical and contain no doubled literal '
         'newline-escape replacement site. The archived replace-equality predicate '
         'therefore holds without demonstrating a correction. Complete native receipts '
         'and their after-invocation source descriptors retain; no prelaunch source census '
         'or actual original stdin observation is inferred. Whole native Git bodies, '
         'the source predicate and an independent integer-window/edit oracle establish '
         'this retained-data discrepancy. Python AST, byte/hash/Git/stdlib semantics and '
         'archived receipt authenticity remain shared premises. Sealed historical bytes '
         'are unchanged; an explicit current correction supersedes their misleading '
         'explanation. No historical source, function, preparation, reader or cohort runs. '
         'Compile-only binding and every complete allocation/default/effect/runtime/'
         'custody and native/private qualification remain separately owned.')


def recipe(body):
    fn = saved.function(ast.parse(body), 'preparation')
    loop = fn.body[2]
    assert isinstance(loop, ast.For)
    assert ast.dump(loop.target) == ast.dump(ast.Name(id='tag', ctx=ast.Store()))
    assert ast.literal_eval(loop.iter) == TAGS and not loop.orelse
    # Preserve the complete original guard; this test checks its source rule,
    # never calls the historical preparation or its need/pin/read functions.
    guard = loop.body[4]
    saved.equal_ast(guard, "need(pin(first) == custody[tag]['first_transcription'] == "
        "{key: native['stdin'][key] for key in ('bytes', 'sha256')} "
        "and pin(source) == {key: custody[tag]['corrected_source'][key] for key in ('bytes', 'sha256')} "
        "and source == first.replace(bytes([92, 92, 110]), bytes([92, 110])) "
        "and pin((BASE / (tag + '.json')).read_bytes()) == custody[tag]['native'], "
        "'whole first transcription, explicit escape correction and unchanged native terminal custody')")
    equality = guard.value.args[0].values[2]
    assert isinstance(equality, ast.Compare) and len(equality.comparators) == 1
    call = equality.comparators[0]
    old, new = (bytes(ast.literal_eval(arg.args[0])) for arg in call.args)
    return dict(whole_preparation=ast.get_source_segment(body.decode(), fn),
                predicate=ast.get_source_segment(body.decode(), guard),
                old=list(old), new=list(new), source_line=guard.lineno)


def edit_oracle(first, corrected, old, new):
    """Independent integer windows and explicit output chunks; no bytes.replace."""
    values, pattern, replacement = list(first), list(old), list(new)
    assert pattern
    starts, output, index = [], [], 0
    while index < len(values):
        if values[index:index + len(pattern)] == pattern:
            starts.append(index)
            output.extend(replacement)
            index += len(pattern)
        else:
            output.append(values[index])
            index += 1
    assert output == list(corrected), 'independent complete edit-output correspondence'
    return dict(replacement_offsets=starts, changed=first != corrected,
                correction_supported=bool(starts) and first != corrected)


def derive(raw, references):
    assert set(raw) == set(references) == set(NAMES), 'complete fixed discrepancy input domain'
    for name, body in raw.items():
        reference = references[name]
        assert reference['revision'] == epoch.REVISION and reference['path'] == name
        assert reference['retention_contract'] == 'fsmgen_required_history'
        assert len(body) == reference['bytes'] and reference['oid'] == hashlib.sha1(
            b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest(), 'whole native fixed source/data binding: ' + name
    rule = recipe(raw[READER])
    old, new = bytes(rule['old']), bytes(rule['new'])
    custody = json.loads(raw[CUSTODY])
    assert set(custody) == set(TAGS)
    pairs = []
    for tag in TAGS:
        prefix = BASE + '/' + tag
        native = json.loads(raw[prefix + '.json'])
        first, corrected = raw[prefix + '.py.txt'], raw[prefix + '-source.txt']
        row = custody[tag]
        assert row['corrected_source']['path'] == prefix + '-source.txt'
        assert row['first_transcription'] == prepare.identity(first)
        assert {key: native['stdin'][key] for key in ('bytes', 'sha256')} == prepare.identity(first)
        assert native['stdin']['path'] == prefix + '.py.txt'
        assert {key: row['corrected_source'][key] for key in ('bytes', 'sha256')} == prepare.identity(corrected)
        assert row['native'] == prepare.identity(raw[prefix + '.json'])
        assert native['command'] == ['python3', '-B', '-'] and type(native['status']) is int and native['status'] == 1
        assert native['expected_status'] is None and 'after invocation' in native['condition']
        assert 'doubled literal newline escapes' in row['condition'] and 'it was never executed' in row['condition']
        legacy_equality = corrected == first.replace(old, new)
        oracle = edit_oracle(first, corrected, old, new)
        assert legacy_equality and first == corrected and not oracle['replacement_offsets']
        assert oracle['changed'] is False and oracle['correction_supported'] is False
        pairs.append(dict(tag=tag, first_source=prepare.blob(first), corrected_source=prepare.blob(corrected),
            native_receipt=native, custody=row, oracle=oracle, legacy_equality_holds=legacy_equality,
            retained_correction='no-op; identical retained source bodies and no replacement site',
            archived_explanation_supported=False, original_stdin_observed=False))
    return dict(schema='fsmgen.preparation_correction.v1', owner=OWNER, scope=SCOPE, rule=rule,
        pairs=pairs, correction=('For the retained pinned sources, the stated escape correction is a no-op. '
            'The replacement equality cannot establish that any escape was corrected. The after-invocation '
            'native receipts and source descriptors are preserved; an earlier different transcription or '
            'actual original stdin cannot be reconstructed from these retained pairs alone.'),
        historical_attribution_gap_owner=OWNER.rsplit('.', 1)[0] + '.2', **LIMITS)


def review(value, raw, references):
    assert all(value[key] is False for key in LIMITS), 'exact false correction/custody/execution boundaries'
    assert {row['tag'] for row in value['pairs']} == set(TAGS) and len(value['pairs']) == len(TAGS)
    assert all(row['archived_explanation_supported'] is False and row['original_stdin_observed'] is False
               for row in value['pairs']), 'no archived narrative or original-input promotion'
    bounded.strict_equal(value, derive(raw, references))
    return True


def controls(expected, raw, references):
    result = []
    for label in ('changed_first', 'changed_corrected', 'changed_native', 'changed_condition', 'missing_input'):
        candidate = dict(raw)
        name = BASE + '/preparation-first'
        if label == 'changed_first': candidate[name + '.py.txt'] += b'\n# changed retained source\n'
        elif label == 'changed_corrected': candidate[name + '-source.txt'] += b'\n# changed retained source\n'
        elif label == 'changed_native':
            value = json.loads(candidate[name + '.json']); value['status'] = True
            candidate[name + '.json'] = prepare.encoded(value)
        elif label == 'changed_condition':
            value = json.loads(candidate[CUSTODY]); value[TAGS[0]]['condition'] = 'prelaunch source census qualified'
            candidate[CUSTODY] = prepare.encoded(value)
        else: del candidate[name + '.py.txt']
        try: derive(candidate, references)
        except AssertionError as error:
            result.append(dict(label=label, inputs={name: prepare.blob(body) for name, body in candidate.items()
                if body != raw[name]}, omitted=sorted(set(raw) - set(candidate)), refusal=str(error)))
        else: raise AssertionError('changed historical discrepancy input admitted: ' + label)
    altered = raw[READER].replace(b'first.replace(bytes([92, 92, 110]), bytes([92, 110]))',
                                b'first.replace(bytes([92, 110]), bytes([92, 92, 110]))', 1)
    assert altered != raw[READER]
    try: recipe(altered)
    except AssertionError as error:
        result.append(dict(label='changed_recipe_grammar', source=prepare.blob(altered), refusal=str(error)))
    else: raise AssertionError('changed source correction rule admitted')
    for label in ('missing_pair', 'borrowed_correction', 'numeric_correction', 'borrowed_prelaunch', 'false_narrative'):
        candidate = copy.deepcopy(expected)
        if label == 'missing_pair': candidate['pairs'].pop()
        elif label == 'borrowed_correction': candidate['escape_correction_observed'] = True
        elif label == 'numeric_correction': candidate['escape_correction_observed'] = 0
        elif label == 'borrowed_prelaunch': candidate['prelaunch_custody_qualified'] = True
        else: candidate['pairs'][0]['archived_explanation_supported'] = True
        try: review(candidate, raw, references)
        except AssertionError as error:
            result.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else: raise AssertionError('false correction or custody claim admitted')
    # Known-bad whole outputs reach the independent edit oracle, without the
    # source identity check, primary replacement predicate or result reviewer.
    for tag in TAGS:
        first = raw[BASE + '/' + tag + '.py.txt']
        candidate = first + b'\n# not the original output\n'
        try: edit_oracle(first, candidate, bytes(expected['rule']['old']), bytes(expected['rule']['new']))
        except AssertionError as error:
            result.append(dict(label='oracle_wrong_output_' + tag, candidate=prepare.blob(candidate), refusal=str(error)))
        else: raise AssertionError('independent wrong output admitted')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw, references = {}, {}
    for name in NAMES:
        reference = prerequisite.file_reference(epoch.REVISION, name)
        body = prerequisite.read_reference(reference)
        assert body == epoch.read(epoch.REVISION, name)
        raw[name], references[name] = body, reference
    value = json.loads(prepare.encoded(derive(raw, references)))
    assert review(value, raw, references)
    product = dict(result=value, controls=controls(value, raw, references), references=references,
        inputs={name: prepare.blob(body) for name, body in raw.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Retained preparation correction is explicitly qualified as a no-op: whole first/corrected bodies agree and no replacement site exists. Archived explanation is superseded, native failures and historical attribution gaps retain; no original execution or compile-input qualification follows.')
