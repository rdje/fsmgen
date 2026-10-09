"""Independent sequential original-phase walker and matching-result controls."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-original-matching-qualified-20261009'
REVISION = 'c8fe740b93f6be988d74729d0baf4b11fabda96a'
READER = A / 'coordinate-original-intake-checks-20261009/verify_intake.py'
EXPRESSION = A / 'coordinate-expression-alternatives-20261009'
EXPRESSION_READER = A / 'coordinate-expression-alternative-checks-20261009/verify_alternatives.py'

OBSERVER = A / 'coordinate-observer-caller-20261009'
OBSERVER_READER = A / 'coordinate-observer-caller-checks-20261009/verify_callers.py'


def require(ok, why):
    if not ok:
        raise ValueError(why)


def digest(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def stamp(value):
    return digest(json.dumps(value, sort_keys=True).encode())


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def original(path):
    root = Path.cwd().resolve()
    full = root / path
    require(full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
            'plain same-volume own original source')
    for parent in full.parents:
        if parent == root:
            break
        require(not (parent / '.git').exists(), 'own original source repository boundary')
    run = subprocess.run(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + str(path)], capture_output=True)
    require(run.returncode == 0 and not run.stderr and run.stdout == full.read_bytes(),
            'complete fixed original matching source')
    return run.stdout


def reconstruct(inventory, source, qualification, expressions, observer):
    recipes = {s['id']: s for s in source['statements']}
    require(len(recipes) == len(source['statements']), 'independent unique source recipes')
    full = expressions['original_recipes']['statements']
    alternatives = expressions['candidates']
    require(len({r['id'] for r in full}) == len(full)
            and sorted(r['id'] for r in full) == sorted(r['recipe_id'] for r in alternatives),
            'independent full candidate recipe domain')
    table = {r['id']: r for r in full}
    nodes = {r['recipe_id']: r for r in alternatives}
    require(all(key in table and same(recipe, table[key]) for key,recipe in recipes.items()),
            'independent used phase recipes are exact full catalogue members')
    for candidate in alternatives:
        recipe = table[candidate['recipe_id']]
        require(candidate['whole_recipe'] == stamp(recipe)
                and same(candidate['filename_alternatives'], recipe['filename_alternatives'])
                and all(candidate['line_alternatives'].get(label) == line for label,line in recipe['line_alternatives'].items())
                and candidate['coordinate_prediction'] is False and candidate['original_selection'] is None,
                'independent complete conditional source-alternative conservation')
    captures = {(m['mode'], d, row['index']): row for m in inventory['inventories']
                for d, values in m['domains'].items() for row in values['nonempty']}
    contexts = {(m['mode'], row['domain'], row['index']): row
                for m in qualification['modes'] for row in m['cases']}
    expected_keys = [(r['mode'], r['domain'], r['index']) for r in source['refusals']]
    require(set(expected_keys) == set(captures) == set(contexts) and len(expected_keys) == len(set(expected_keys)),
            'independent complete original/source domain')

    declarations = {tuple(d['key']):d for d in observer['declarations']}
    snapshots = {tuple(d['key']):d for d in observer['associations']}
    require(len(declarations) == len(observer['declarations'])
            and len(snapshots) == len(observer['associations'])
            and set(declarations) == set(snapshots) == set(expected_keys)
            and same(observer['original'],inventory) and same(observer['unresolved'],source['unresolved']),
            'independent whole observer/source/original allocation')

    def coordinate(recipe_id, segment):
        recipe = recipes[recipe_id]
        candidate = nodes[recipe_id]
        require(type(segment['path']) is str and segment['path'] in candidate['filename_alternatives'],
                'independent declared caller filename')
        require(type(segment['line']) is int and segment['line'] > 0, 'independent discrete caller line')
        labels = sorted(k for k in candidate['line_alternatives'] if candidate['line_alternatives'][k] == segment['line'])
        require(bool(labels), 'independent declared caller line')
        return {'recipe_id': recipe_id, 'statement_identity': stamp(recipe), 'candidate_identity': stamp(candidate),
                'reported_filename': segment['path'], 'reported_line': segment['line'],
                'matching_line_labels': labels, 'equivalent_line_labels': candidate['equivalent_line_labels'],
                'all_filename_alternatives': candidate['filename_alternatives'],
                'all_line_alternatives': candidate['line_alternatives']}

    output = []
    for hypothesis, key in zip(source['refusals'], expected_keys, strict=True):
        raw, previous = captures[key], contexts[key]
        frames = [part for part in raw['segments'] if part['kind'] == 'frame']
        origins = [i for i, part in enumerate(raw['segments']) if part['kind'] == 'origin']
        require(len(origins) == len(hypothesis['phases']) == len(previous['phases']), 'independent complete phase count')
        cursor, phases = 0, []
        for h, p, origin_index in zip(hypothesis['phases'], previous['phases'], origins, strict=True):
            require(type(h['phase']) is int and h['phase'] == p['phase'] == len(phases), 'independent ordered phases')
            positions = p['complete_own_positions']
            require(cursor == positions['core_positions'][0], 'independent contiguous phase start')
            opaque_by_index = {}
            for segment in positions['opaque_framework']:
                found = [i for i, frame in enumerate(frames) if same(frame, segment)]
                require(len(found) == 1, 'independent unique opaque original')
                opaque_by_index[found[0]] = segment
            bindings, opaque = [], []

            def consume_opaque():
                nonlocal cursor
                while cursor in opaque_by_index:
                    opaque.append({'frame_index': cursor, 'whole_segment': stamp(frames[cursor]), 'selection': None,
                                   'owner': source['unresolved']['original_private_formatter_toolchain_identity']})
                    cursor += 1

            for declaration in h['active_path_inner_to_outer']:
                consume_opaque()
                require(cursor < len(frames), 'independent complete caller interval')
                frame = frames[cursor]
                function = frame['call'].partition('(')[0] if frame['call'] != 'eval {...}' else frame['call']
                require(function == declaration['callee'], 'independent ordered original callee')
                for link in declaration['model_links']:
                    target = (positions['operations'][link[1]][link[3]] if link[0] == 'operations'
                              else positions[link[0] + '_positions'][link[1]])
                    require(type(target) is int and cursor == target, 'independent source-link and sequential caller agree')
                if not declaration['model_links']:
                    require(declaration['role'] == 'nested_capture_eval' and declaration['callee'] == 'eval {...}',
                            'independent source-declared nested eval')
                caller = declaration['caller']
                if caller['kind'] == 'own_statement':
                    selection = coordinate(caller['recipe_id'], frame)
                else:
                    require(caller['kind'] == 'opaque_external_framework_interval', 'independent explicit opaque caller')
                    selection = None
                bindings.append({'frame_index': cursor, 'whole_segment': stamp(frame),
                                 'source_binding': declaration, 'selection': selection})
                cursor += 1
            consume_opaque()
            require(len(opaque) == len(opaque_by_index) and cursor == positions['load_position'],
                    'independent whole opaque and load interval')
            require(frames[cursor]['call'] == h['load']['model_marker'] and h['load']['source_operator'] == 'do',
                    'independent lexical do and reported load marker')
            phases.append({'phase': h['phase'], 'family': h['family'],
                'origin': {'segment_index': origin_index, 'whole_segment': stamp(raw['segments'][origin_index]),
                           'selection': coordinate(h['origin']['caller']['recipe_id'], raw['segments'][origin_index])},
                'callers_inner_to_outer': bindings, 'opaque_framework': opaque,
                'load': {'frame_index': cursor, 'whole_segment': stamp(frames[cursor]),
                         'source_operator': h['load']['source_operator'], 'model_marker': h['load']['model_marker'],
                         'selection': coordinate(h['load']['caller']['recipe_id'], frames[cursor])}})
            cursor += 1
        require(cursor == len(frames), 'independent exhaustive original frame traversal')
        declared, snapshot = declarations[key], snapshots[key]
        require(declared['phase'] == len(phases)-1 and declared['kind'] == raw['context']['kind'],
                'independent final recorded operation kind')
        operation_link = ['operations',declared['operation_index'],'frames',3]
        wrappers = [binding for binding in phases[-1]['callers_inner_to_outer']
                    if operation_link in binding['source_binding']['model_links']]
        require(len(wrappers) == 1 and same(wrappers[0]['source_binding'],declared['wrapper'])
                and wrappers[0]['source_binding']['role']=='observer',
                'independent sequential operation-specific observer wrapper')
        wrapper=wrappers[0]['frame_index'];recipe=declared['caller_recipe']
        require(same(recipe,recipes[recipe['id']]) and same(declared['alternatives'],nodes[recipe['id']])
                and same(wrappers[0]['selection'],coordinate(recipe['id'],frames[wrapper])),
                'independent whole observer recipe and alternative join')
        require(snapshot['frame_index']==wrapper and snapshot['whole_original']==stamp(raw)
                and snapshot['declaration']==stamp(declared) and snapshot['whole_frame']==stamp(frames[wrapper])
                and same(snapshot['recorded_context'],raw['context'])
                and same(raw['context']['caller'],[declared['caller_package'],frames[wrapper]['path'],frames[wrapper]['line']]),
                'independent whole operation-specific recorded caller')
        output.append({'mode': key[0], 'domain': key[1], 'index': key[2], 'whole_original_record': stamp(raw),
                       'phases': phases, 'observer_caller': {'context': raw['context'], 'frame_index': wrapper,
                                                            'whole_segment': stamp(frames[wrapper]),
                                                            'qualification': snapshot, 'declaration_identity':stamp(declared)}})
    return output


def check(actual, expected):
    for field in expected:
        require(field in actual and same(actual[field], expected[field]), 'complete independent matching field: ' + field)
    require(set(actual) == set(expected), 'closed complete matching product')


def main():
    paths = [A / 'record-value-class-frame-join-20261006/raw-product.json',
             A / 'record-value-class-frame-join-20261006/proofs.json', A / 'coordinate-refusal-phases-20261009/phases.json']
    bodies = [original(p) for p in paths]
    inventory, qualification, hypotheses = map(json.loads, bodies)
    admission_raw = original(A / 'coordinate-original-intake-20261009/admission.json')
    admission = json.loads(admission_raw)
    inputs = {str(p): digest(b) for p, b in zip(paths, bodies, strict=True)}
    require(all(admission['custody']['members'][p]['identity'] == v for p, v in inputs.items()), 'independent original intake membership')
    expressions_raw = original(EXPRESSION / 'alternatives.json')
    expressions = json.loads(expressions_raw)
    observer_raw = original(OBSERVER / 'association.json')
    observer = json.loads(observer_raw)
    regenerated = []
    for reader in (READER, EXPRESSION_READER, OBSERVER_READER):
        command = ['python3', '-B', str(reader)]
        replay = subprocess.run(command, capture_output=True, text=True)
        require(type(replay.returncode) is int and replay.returncode == 0 and not replay.stderr,
                'complete actually regenerated sealed original/source matching prerequisite')
        regenerated.append({'command': command, 'status': replay.returncode, 'stdout': replay.stdout,
                            'stderr': replay.stderr, 'programme': digest(original(reader))})
    actual = json.loads((BASE / 'matching.json').read_bytes())
    expected = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
        'role': 'Dated complete own original source-coordinate matching; external framework, private formatter/toolchain/identity, address and alias meanings remain unmeasured.',
        'inputs': inputs, 'intake': {'admission': digest(admission_raw),
                                   'seal': digest(original(A / 'coordinate-original-intake-20261009/seal.json'))},
        'expression_seal': digest(original(EXPRESSION / 'seal.json')),
        'observer_seal': digest(original(OBSERVER / 'seal.json')), 'actual_readers': regenerated,
        'original': inventory, 'source_phases': hypotheses, 'expression_alternatives': expressions,
        'observer_qualification': observer,
        'matches': reconstruct(inventory, hypotheses, qualification, expressions, observer), 'unresolved': hypotheses['unresolved'],
        'legs': {'rederive': 'match.py admitted source-link positions and original coordinates with all independently qualified source-expression alternatives and committed source-selected observer associations.',
                 'falsify': 'verify.py separately walks every complete original phase interval, reconstructs all used/full recipe and own/opaque allocations and actually replays sealed original/source readers; genuine caller, line, source and omission controls.',
                 'durability': 'Complete immutable original inventory, full source/recipe alternatives, fixed intake/source authorities, sealed matching programmes/products and normal Git commit.'}}
    check(actual, expected)
    controls = {}
    for name, mutate, field in (
        ('wrong-caller', lambda p:p['matches'][0]['phases'][0]['origin']['selection'].update(reported_filename='borrowed.pl'), 'matches'),
        ('wrong-line', lambda p:p['matches'][0]['phases'][0]['origin']['selection'].update(reported_line=1), 'matches'),
        ('borrowed-statement', lambda p:p['source_phases']['statements'][0].update(source_identity=next(s['source_identity'] for s in p['source_phases']['statements'] if not same(s['source_identity'], p['source_phases']['statements'][0]['source_identity']))), 'source_phases'),
        ('lost-unused-candidate', lambda p:p['expression_alternatives']['candidates'].pop(next(i for i,r in enumerate(p['expression_alternatives']['candidates']) if r['recipe_id'] not in {s['id'] for s in p['source_phases']['statements']})), 'expression_alternatives'),
        ('changed-expression-line', lambda p:next(r for r in p['expression_alternatives']['candidates'] if r['extensions'])['extensions'][0].update(line=1), 'expression_alternatives'),
        ('lost-empty', lambda p:p['original']['inventories'][0]['domains']['api']['empty_string_members'].pop(), 'original'),
        ('lost-alternative', lambda p:p['matches'][0]['phases'][0]['origin']['selection']['matching_line_labels'].pop(), 'matches'),
        ('lost-opaque', lambda p:p['matches'][0]['phases'][0]['opaque_framework'].pop(), 'matches'),
        ('private-promotion', lambda p:p['unresolved'].pop('original_private_formatter_toolchain_identity'), 'unresolved'),
        ('wrong-observer-frame', lambda p:p['matches'][0]['observer_caller'].update(frame_index=-1), 'matches'),
        ('borrowed-observer-package', lambda p:next(d for d in p['observer_qualification']['declarations'] if d['caller_package']!='main').update(caller_package='main'), 'observer_qualification'),
        ('lost-observer-context', lambda p:p['observer_qualification']['associations'].pop(), 'observer_qualification'),
        ('false-green-status', lambda p:p['actual_readers'][0].update(status=True), 'actual_readers'),
        ('borrowed-command', lambda p:p['actual_readers'][0]['command'].append('--foreign'), 'actual_readers'),
        ('borrowed-stdout', lambda p:p['actual_readers'][0].update(stdout='PASS\n'), 'actual_readers')):
        mutant = copy.deepcopy(actual); mutate(mutant)
        require(not same(mutant, actual), 'genuine independent matching control: ' + name)
        try:
            check(mutant, expected)
        except ValueError as error:
            require(str(error) == 'complete independent matching field: ' + field, 'intended independent matching control')
            controls[name] = str(error)
        else:
            raise ValueError('false-green matching control: ' + name)
    require(original(EXPRESSION / 'alternatives.json') == expressions_raw
            and original(OBSERVER / 'association.json') == observer_raw, 'whole qualified expression/observer input conservation')
    require([original(p) for p in paths] == bodies, 'whole original matching input conservation')
    phases = [phase for row in expected['matches'] for phase in row['phases']]
    bindings = [binding for phase in phases for binding in phase['callers_inner_to_outer']]
    coverage = {'nonempty_records':len(expected['matches']), 'throw_phases':len(phases),
        'own_coordinates':2*len(phases)+sum(b['selection'] is not None for b in bindings),
        'frames':sum(len(p['callers_inner_to_outer'])+len(p['opaque_framework'])+1 for p in phases),
        'opaque_bound_callers':sum(b['selection'] is None for b in bindings),
        'opaque_framework_frames':sum(len(p['opaque_framework']) for p in phases),
        'used_source_recipes':len(hypotheses['statements']), 'full_candidate_recipes':len(expressions['candidates']),
        'observer_callers':len(observer['associations'])}
    require(coverage['frames'] == sum(sum(s['kind']=='frame' for s in r['segments'])
            for mode in inventory['inventories'] for values in mode['domains'].values() for r in values['nonempty']),
            'complete independent original frame census')
    print(json.dumps({'result': 'PASS complete independent original coordinate matching and separating controls',
                      'matching_identity': stamp(expected['matches']), 'original_identity': stamp(inventory),
                      'actual_readers': expected['actual_readers'], 'coverage':coverage, 'controls': controls}, sort_keys=True))


if __name__ == '__main__':
    main()
