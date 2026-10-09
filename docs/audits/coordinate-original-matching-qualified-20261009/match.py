"""Apply already declared statement alternatives to complete admitted originals."""
import hashlib
import json
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-original-matching-qualified-20261009'
INTAKE = A / 'coordinate-original-intake-20261009'
CLASS = A / 'record-value-class-frame-join-20261006'
PHASES = A / 'coordinate-refusal-phases-20261009'
READER = A / 'coordinate-original-intake-checks-20261009/verify_intake.py'
EXPRESSION = A / 'coordinate-expression-alternatives-20261009'
EXPRESSION_READER = A / 'coordinate-expression-alternative-checks-20261009/verify_alternatives.py'
OBSERVER = A / 'coordinate-observer-caller-20261009'
OBSERVER_READER = A / 'coordinate-observer-caller-checks-20261009/verify_callers.py'
REVISION = 'c8fe740b93f6be988d74729d0baf4b11fabda96a'
ROLE = 'Dated complete own original source-coordinate matching; external framework, private formatter/toolchain/identity, address and alias meanings remain unmeasured.'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def identity(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def fixed(path):
    root = Path.cwd().resolve(); full = root / path
    need(full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
         'plain same-volume fixed matching input')
    for parent in full.parents:
        if parent == root:
            break
        need(not (parent / '.git').exists(), 'own fixed matching input repository boundary')
    run = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)], capture_output=True)
    need(run.returncode == 0 and not run.stderr and path.read_bytes() == run.stdout,
         'whole fixed coordinate-matching input: ' + str(path))
    return run.stdout


def derive(raw, hypotheses, prior, expressions, observer):
    statements = {s['id']: s for s in hypotheses['statements']}
    need(len(statements) == len(hypotheses['statements']), 'unique complete statement domain')
    catalogue = {s['id']: s for s in expressions['original_recipes']['statements']}
    candidates = {row['recipe_id']: row for row in expressions['candidates']}
    need(len(catalogue) == len(expressions['original_recipes']['statements'])
         and len(candidates) == len(expressions['candidates']) and set(candidates) == set(catalogue),
         'complete unique source expression catalogue')
    need(set(statements) <= set(catalogue)
         and all(statements[key] == catalogue[key] for key in statements),
         'every used phase recipe conserves within full expression catalogue')
    for key, candidate in candidates.items():
        recipe = catalogue[key]
        need(candidate['whole_recipe'] == identity(recipe)
             and candidate['filename_alternatives'] == recipe['filename_alternatives']
             and all(candidate['line_alternatives'].get(k) == v for k,v in recipe['line_alternatives'].items())
             and candidate['coordinate_prediction'] is False and candidate['original_selection'] is None,
             'complete old recipe and conditional expression alternatives conserve')
    originals = {(m['mode'], d, r['index']): r for m in raw['inventories']
                 for d, rows in m['domains'].items() for r in rows['nonempty']}
    associated = {(m['mode'], r['domain'], r['index']): r for m in prior['modes'] for r in m['cases']}
    keys = [(r['mode'], r['domain'], r['index']) for r in hypotheses['refusals']]
    need(len(set(keys)) == len(keys) and set(keys) == set(originals) == set(associated),
         'complete disjoint original-coordinate refusal allocation')

    declarations = {tuple(row['key']): row for row in observer['declarations']}
    callers = {tuple(row['key']): row for row in observer['associations']}
    need(len(declarations) == len(observer['declarations'])
         and len(callers) == len(observer['associations']) and set(declarations) == set(callers) == set(keys)
         and observer['original'] == raw and observer['unresolved'] == hypotheses['unresolved'],
         'complete qualified observer and original allocation')

    def select(recipe_id, segment):
        recipe = statements[recipe_id]
        candidate = candidates[recipe_id]
        need(type(segment['line']) is int and segment['line'] > 0,
             'original coordinate line is a positive integer')
        labels = sorted(k for k, v in candidate['line_alternatives'].items() if v == segment['line'])
        need(segment['path'] in candidate['filename_alternatives'] and labels,
             'declared own caller coordinate: ' + recipe_id)
        return {'recipe_id': recipe_id, 'statement_identity': identity(recipe), 'candidate_identity': identity(candidate),
                'reported_filename': segment['path'], 'reported_line': segment['line'],
                'matching_line_labels': labels,
                'equivalent_line_labels': candidate['equivalent_line_labels'],
                'all_filename_alternatives': candidate['filename_alternatives'],
                'all_line_alternatives': candidate['line_alternatives']}

    results = []
    for hypothesis, key in zip(hypotheses['refusals'], keys, strict=True):
        record, proved = originals[key], associated[key]
        frames = [s for s in record['segments'] if s['kind'] == 'frame']
        origins = [i for i, s in enumerate(record['segments']) if s['kind'] == 'origin']
        need(len(origins) == len(hypothesis['phases']) == len(proved['phases']), 'complete original throw-phase origins')
        used, phases = set(), []
        for phase, qualification, origin_index in zip(hypothesis['phases'], proved['phases'], origins, strict=True):
            positions = qualification['complete_own_positions']
            need(phase['phase'] == qualification['phase'] == len(phases), 'ordered original coordinate phases')
            bindings = []
            for binding in phase['active_path_inner_to_outer']:
                targets = []
                for link in binding['model_links']:
                    if link[0] == 'operations':
                        need(link[2] == 'frames', 'qualified operation link kind')
                        targets.append(positions['operations'][link[1]][link[3]])
                    else:
                        targets.append(positions[link[0] + '_positions'][link[1]])
                if not targets:
                    need(binding['role'] == 'nested_capture_eval' and bindings,
                         'only declared nested capture eval lacks a prior link')
                    targets = [bindings[-1]['frame_index'] + 1]
                need(len(set(targets)) == 1, 'all original source links select one frame')
                index = targets[0]
                need(type(index) is int and index not in used and 0 <= index < len(frames),
                     'unique complete original caller frame')
                used.add(index)
                segment = frames[index]
                function = segment['call'] if segment['call'] == 'eval {...}' else segment['call'].split('(', 1)[0]
                need(function == binding['callee'], 'qualified original callee at caller coordinate')
                caller = binding['caller']
                selection = select(caller['recipe_id'], segment) if caller['kind'] == 'own_statement' else None
                need(selection is not None or caller['kind'] == 'opaque_external_framework_interval',
                     'explicit original coordinate ownership')
                bindings.append({'frame_index': index, 'whole_segment': identity(segment),
                                 'source_binding': binding, 'selection': selection})
            opaque = []
            for segment in positions['opaque_framework']:
                frame_indexes = [i for i, row in enumerate(frames) if row == segment]
                need(len(frame_indexes) == 1 and frame_indexes[0] not in used, 'unique complete opaque framework frame')
                used.add(frame_indexes[0]); opaque.append({'frame_index': frame_indexes[0], 'whole_segment': identity(segment),
                    'selection': None, 'owner': hypotheses['unresolved']['original_private_formatter_toolchain_identity']})
            load_index = positions['load_position']
            need(load_index not in used and frames[load_index]['call'] == phase['load']['model_marker'],
                 'complete original lexical-load and model-marker association')
            used.add(load_index)
            phases.append({'phase': phase['phase'], 'family': phase['family'],
                'origin': {'segment_index': origin_index, 'whole_segment': identity(record['segments'][origin_index]),
                           'selection': select(phase['origin']['caller']['recipe_id'], record['segments'][origin_index])},
                'callers_inner_to_outer': bindings, 'opaque_framework': opaque,
                'load': {'frame_index': load_index, 'whole_segment': identity(frames[load_index]),
                         'source_operator': phase['load']['source_operator'], 'model_marker': phase['load']['model_marker'],
                         'selection': select(phase['load']['caller']['recipe_id'], frames[load_index])}})
        need(used == set(range(len(frames))), 'every original frame is matched or explicitly opaque')
        declaration, qualified_caller = declarations[key], callers[key]
        need(declaration['phase'] == phases[-1]['phase'] and declaration['kind'] == record['context']['kind'],
             'qualified recorded source operation and final phase')
        wrappers = [b for b in phases[-1]['callers_inner_to_outer']
                    if b['source_binding'] == declaration['wrapper']]
        need(len(wrappers) == 1 and wrappers[0]['source_binding']['role'] == 'observer',
             'complete qualified caller wrapper joins matched source binding')
        wrapper = wrappers[0]['frame_index']
        recipe_id = declaration['caller_recipe']['id']
        need(declaration['caller_recipe'] == statements[recipe_id]
             and declaration['alternatives'] == candidates[recipe_id]
             and wrappers[0]['selection'] == select(recipe_id, frames[wrapper]),
             'complete observer recipe and coordinate alternatives join')
        need(qualified_caller['frame_index'] == wrapper
             and qualified_caller['whole_original'] == identity(record)
             and qualified_caller['declaration'] == identity(declaration)
             and qualified_caller['whole_frame'] == identity(frames[wrapper])
             and qualified_caller['recorded_context'] == record['context']
             and record['context']['caller'] == [declaration['caller_package'], frames[wrapper]['path'], frames[wrapper]['line']],
             'whole qualified observer context joins operation-specific caller')
        results.append({'mode': key[0], 'domain': key[1], 'index': key[2],
                        'whole_original_record': identity(record), 'phases': phases,
                        'observer_caller': {'context': record['context'], 'frame_index': wrapper,
                                            'whole_segment': identity(frames[wrapper]),
                                            'qualification': qualified_caller, 'declaration_identity': identity(declaration)}})
    return results


def main():
    need(not (BASE / 'matching.json').exists() and not (BASE / 'seal.json').exists(), 'original matching producer never rewrites')
    actual_readers = []
    for reader in (READER, EXPRESSION_READER, OBSERVER_READER):
        command = ['python3', '-B', str(reader)]
        run = subprocess.run(command, capture_output=True, text=True)
        need(type(run.returncode) is int and run.returncode == 0 and not run.stderr,
             'complete actual sealed matching prerequisite')
        actual_readers.append({'command': command, 'status': run.returncode, 'stdout': run.stdout,
                               'stderr': run.stderr, 'programme': pin(fixed(reader))})
    intake = json.loads(fixed(INTAKE / 'admission.json'))
    paths = [CLASS / 'raw-product.json', CLASS / 'proofs.json', PHASES / 'phases.json']
    bodies = [fixed(p) for p in paths]
    inputs = {str(p): pin(b) for p,b in zip(paths,bodies,strict=True)}
    need(all(intake['custody']['members'][p]['identity'] == v for p, v in inputs.items()),
         'original matching inputs belong to complete admitted custody')
    raw, prior, hypotheses = map(json.loads, bodies)
    expression_raw = fixed(EXPRESSION / 'alternatives.json')
    observer_raw = fixed(OBSERVER / 'association.json')
    expressions, observer = json.loads(expression_raw), json.loads(observer_raw)
    product = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(), 'role': ROLE,
        'inputs': inputs, 'intake': {'admission': pin(fixed(INTAKE / 'admission.json')), 'seal': pin(fixed(INTAKE / 'seal.json'))},
        'expression_seal': pin(fixed(EXPRESSION / 'seal.json')),
        'observer_seal': pin(fixed(OBSERVER / 'seal.json')), 'actual_readers': actual_readers,
        'original': raw, 'source_phases': hypotheses, 'expression_alternatives': expressions,
        'observer_qualification': observer,
        'matches': derive(raw, hypotheses, prior, expressions, observer), 'unresolved': hypotheses['unresolved'],
        'legs': {'rederive': 'match.py admitted source-link positions and original coordinates with all independently qualified source-expression alternatives and committed source-selected observer associations.',
                 'falsify': 'verify.py separately walks every complete original phase interval, reconstructs all used/full recipe and own/opaque allocations and actually replays sealed original/source readers; genuine caller, line, source and omission controls.',
                 'durability': 'Complete immutable original inventory, full source/recipe alternatives, fixed intake/source authorities, sealed matching programmes/products and normal Git commit.'}}
    need([fixed(p) for p in paths] == bodies
         and fixed(EXPRESSION / 'alternatives.json') == expression_raw
         and fixed(OBSERVER / 'association.json') == observer_raw, 'whole original matching source conservation')
    (BASE / 'matching.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete original own coordinate matching; alternatives and opaque/private owners conserved.')


if __name__ == '__main__':
    main()
