"""Select recorded observer operations from source roles, then qualify callers."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-observer-caller-20261009'
REVISION = '41985a0f3e72dbfe3e4055c57f150206b29bba2f'
CLASS = A / 'record-value-class-frame-join-20261006'
PHASES = A / 'coordinate-refusal-phases-20261009/phases.json'
EXPRESSION = A / 'coordinate-expression-alternatives-20261009/alternatives.json'
READERS = (A / 'coordinate-original-intake-checks-20261009/verify_intake.py',
           A / 'coordinate-expression-alternative-checks-20261009/verify_alternatives.py')
FIXTURES = ('caller.pl', 'caller-inner-shift.pl', 'caller-outer-shift.pl')
ROLE = 'Dated complete recorded observer caller association; source operation selection precedes coordinate comparison. No original private formatter/toolchain/identity, external framework, address or alias promotion; complete original matching remains a successor.'


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def stamp(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def fixed(path):
    root = Path.cwd().resolve(); full = root / path
    need(full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
         'plain same-volume observer input')
    for parent in full.parents:
        if parent == root:
            break
        need(not (parent / '.git').exists(), 'own observer source boundary')
    run = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)], capture_output=True)
    need(run.returncode == 0 and not run.stderr and run.stdout == full.read_bytes(), 'complete fixed observer input')
    return run.stdout


def declare(models, phases, expressions):
    """Read source roles only; never read model caller values or raw coordinates."""
    phase_by_key = {(r['mode'], r['domain'], r['index']): r for r in phases['refusals']}
    recipes = {r['id']: r for r in expressions['original_recipes']['statements']}
    alternatives = {r['recipe_id']: r for r in expressions['candidates']}
    output = []
    for mode in models['modes']:
        for case in mode['cases']:
            key = mode['mode'], case['domain'], case['index']
            phase = case['phases'][-1]
            operations = phase['own']['operations']
            indices = [i for i, operation in enumerate(operations) if operation['kind'] == case['kind']]
            need(len(indices) == 1, 'unique source operation for recorded case kind')
            operation_index = indices[0]
            operation = operations[operation_index]
            need(len(operation['frames']) == 4, 'complete source observer operation frames')
            source_phase = phase_by_key[key]['phases'][phase['phase']]

            def binding(slot):
                link = ['operations', operation_index, 'frames', slot]
                rows = [r for r in source_phase['active_path_inner_to_outer'] if link in r['model_links']]
                need(len(rows) == 1 and rows[0]['role'] == 'observer', 'unique source observer binding')
                return rows[0]

            wrapper, delegate = binding(3), binding(2)
            recipe = recipes[wrapper['caller']['recipe_id']]
            delegate_recipe = recipes[delegate['caller']['recipe_id']]
            head = "return parse('source'," if case['kind'] == 'source' else "return call_api('" + case['kind'] + "',"
            need(delegate_recipe['unit'] == 'observer' and delegate_recipe['text'].startswith(head)
                 and delegate_recipe['text'].count('[caller]') == 1, 'literal recorded wrapper caller argument')
            need(recipe['unit'] in ('test', 'value'), 'finite admitted observer caller units')
            unit = expressions['source_units'][recipe['unit']]
            declarations = re.findall(r'^package\s+([A-Za-z_][A-Za-z0-9_:]*)\s*;', unit['body'], re.M)
            need(len(declarations) == (1 if recipe['unit'] == 'value' else 0), 'finite caller source package declarations')
            package = declarations[0] if declarations else 'main'
            candidate = alternatives[recipe['id']]
            output.append({'key': list(key), 'kind': case['kind'], 'phase': phase['phase'],
                'operation_index': operation_index, 'operation': operation, 'wrapper': wrapper,
                'delegate_recipe': delegate_recipe, 'caller_recipe': recipe, 'caller_package': package,
                'source_unit': unit, 'alternatives': candidate})
    need(len({tuple(r['key']) for r in output}) == len(output)
         and {tuple(r['key']) for r in output} == set(phase_by_key), 'complete source observer allocation')
    return output


def associate(raw, proofs, declarations):
    originals = {(m['mode'], d, r['index']): r for m in raw['inventories']
                 for d, values in m['domains'].items() for r in values['nonempty']}
    qualified = {(m['mode'], r['domain'], r['index']): r for m in proofs['modes'] for r in m['cases']}
    need(set(originals) == set(qualified) == {tuple(r['key']) for r in declarations}, 'whole recorded observer domain')
    output = []
    for declaration in declarations:
        key = tuple(declaration['key']); record = originals[key]
        positions = qualified[key]['phases'][declaration['phase']]['complete_own_positions']
        frames = [s for s in record['segments'] if s['kind'] == 'frame']
        index = positions['operations'][declaration['operation_index']][3]
        frame = frames[index]; candidate = declaration['alternatives']
        labels = sorted(k for k,v in candidate['line_alternatives'].items() if v == frame['line'])
        caller = [declaration['caller_package'], frame['path'], frame['line']]
        need(record['context']['kind'] == declaration['kind'] and record['context']['caller'] == caller,
             'complete original recorded operation caller')
        need(frame['path'] in candidate['filename_alternatives'] and labels
             and type(frame['line']) is int and frame['line'] > 0, 'declared original observer caller coordinate')
        outer = positions['operations'][-1][3]
        output.append({'key': list(key), 'declaration': stamp(declaration), 'whole_original': stamp(record),
            'recorded_context': record['context'], 'frame_index': index, 'whole_frame': stamp(frame),
            'matching_line_labels': labels, 'outermost_frame_index': outer,
            'old_outer_main_assumption_matches': record['context']['caller'] == ['main',frames[outer]['path'],frames[outer]['line']]})
    return output


def public(path):
    raw = path.read_bytes()
    command = ['perl', str(path)]
    run = subprocess.run(command, capture_output=True, text=True)
    need(type(run.returncode) is int and run.returncode == 0 and run.stderr == '', 'complete public caller result')
    return {'source': str(path), 'identity': pin(raw), 'command': command,
            'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr}


def main():
    need(not (BASE / 'association.json').exists() and not (BASE / 'seal.json').exists(), 'observer producer never rewrites')
    paths = [CLASS/'raw-product.json', CLASS/'proofs.json', CLASS/'source-models.json', PHASES, EXPRESSION]
    bodies = [fixed(p) for p in paths]
    raw, proofs, models, phases, expressions = map(json.loads, bodies)
    declarations = declare(models, phases, expressions)
    associations = associate(raw, proofs, declarations)
    actual = []
    for reader in READERS:
        command = ['python3', '-B', str(reader)]
        run = subprocess.run(command, capture_output=True, text=True)
        need(type(run.returncode) is int and run.returncode == 0 and not run.stderr, 'actual unchanged observer prerequisite')
        actual.append({'command': command, 'status': run.returncode, 'stdout': run.stdout,
                       'stderr': run.stderr, 'programme': pin(fixed(reader))})
    product = {'revision': REVISION, 'owner': (BASE/'scope.txt').read_text().strip(), 'role': ROLE,
        'inputs': {str(p):pin(b) for p,b in zip(paths,bodies,strict=True)}, 'original': raw,
        'declarations': declarations, 'associations': associations, 'actual_readers': actual,
        'finite_public': [public(BASE/name) for name in FIXTURES], 'unresolved': phases['unresolved'],
        'legs': {'rederive': 'derive.py complete fixed source operation and literal caller/package declarations before original-coordinate comparison; complete original context association and actual readers.',
                 'falsify': 'verify.py independent binding/operation traversal, complete original reconstruction, real public caller interventions and source/context/receipt controls; both first matcher failures reproduce.',
                 'durability': 'Whole original inventory, exact source declarations, fixed source epoch, both failed programmes/results, sealed association and public fixtures/readers, normal Git commit.'}}
    need([fixed(p) for p in paths] == bodies, 'complete observer input conservation')
    (BASE/'association.json').write_text(json.dumps(product,sort_keys=True,indent=2)+'\n')
    print('PASS complete source-selected original observer caller association; full original matching remains next.')


if __name__ == '__main__':
    main()
