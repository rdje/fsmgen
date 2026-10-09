"""Apply already declared statement alternatives to complete admitted originals."""
import hashlib
import json
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-original-matching-20261009'
INTAKE = A / 'coordinate-original-intake-20261009'
CLASS = A / 'record-value-class-frame-join-20261006'
PHASES = A / 'coordinate-refusal-phases-20261009'
READER = A / 'coordinate-original-intake-checks-20261009/verify_intake.py'
REVISION = '39249cb445399c2318275829e5c7f10e0094d0c4'
ROLE = 'Dated complete own original source-coordinate matching; external framework, private formatter/toolchain/identity, address and alias meanings remain unmeasured.'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def identity(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def fixed(path):
    run = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)], capture_output=True)
    need(run.returncode == 0 and not run.stderr and path.read_bytes() == run.stdout,
         'whole fixed coordinate-matching input: ' + str(path))
    return run.stdout


def derive(raw, hypotheses, prior):
    statements = {s['id']: s for s in hypotheses['statements']}
    need(len(statements) == len(hypotheses['statements']), 'unique complete statement domain')
    originals = {(m['mode'], d, r['index']): r for m in raw['inventories']
                 for d, rows in m['domains'].items() for r in rows['nonempty']}
    associated = {(m['mode'], r['domain'], r['index']): r for m in prior['modes'] for r in m['cases']}
    keys = [(r['mode'], r['domain'], r['index']) for r in hypotheses['refusals']]
    need(len(set(keys)) == len(keys) and set(keys) == set(originals) == set(associated),
         'complete disjoint original-coordinate refusal allocation')

    def select(recipe_id, segment):
        recipe = statements[recipe_id]
        need(type(segment['line']) is int and segment['line'] > 0,
             'original coordinate line is a positive integer')
        labels = [k for k, v in recipe['line_alternatives'].items() if v == segment['line']]
        need(segment['path'] in recipe['filename_alternatives'] and labels,
             'declared own caller coordinate: ' + recipe_id)
        return {'recipe_id': recipe_id, 'statement_identity': identity(recipe),
                'reported_filename': segment['path'], 'reported_line': segment['line'],
                'matching_line_labels': labels,
                'equivalent_line_labels': recipe['equivalent_line_labels'],
                'all_filename_alternatives': recipe['filename_alternatives'],
                'all_line_alternatives': recipe['line_alternatives']}

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
                candidates = [i for i, row in enumerate(frames) if row == segment]
                need(len(candidates) == 1 and candidates[0] not in used, 'unique complete opaque framework frame')
                used.add(candidates[0]); opaque.append({'frame_index': candidates[0], 'whole_segment': identity(segment),
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
        final_positions = proved['phases'][-1]['complete_own_positions']
        wrapper = final_positions['operations'][-1][-1]
        caller = record['context']['caller']
        need(caller == ['main', frames[wrapper]['path'], frames[wrapper]['line']],
             'original observer caller snapshot joins outer operation caller')
        results.append({'mode': key[0], 'domain': key[1], 'index': key[2],
                        'whole_original_record': identity(record), 'phases': phases,
                        'observer_caller': {'context': record['context'], 'frame_index': wrapper,
                                            'whole_segment': identity(frames[wrapper])}})
    return results


def main():
    need(not (BASE / 'matching.json').exists() and not (BASE / 'seal.json').exists(), 'original matching producer never rewrites')
    command = ['python3', '-B', str(READER)]
    run = subprocess.run(command, capture_output=True, text=True)
    need(run.returncode == 0 and not run.stderr, 'complete actual sealed original intake')
    intake = json.loads(fixed(INTAKE / 'admission.json'))
    paths = [CLASS / 'raw-product.json', CLASS / 'proofs.json', PHASES / 'phases.json']
    inputs = {str(p): pin(fixed(p)) for p in paths}
    need(all(intake['custody']['members'][p]['identity'] == v for p, v in inputs.items()), 'matching inputs belong to complete admitted custody')
    raw, prior, hypotheses = (json.loads(fixed(p)) for p in paths)
    product = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(), 'role': ROLE,
        'inputs': inputs, 'intake': {'admission': pin(fixed(INTAKE / 'admission.json')), 'seal': pin(fixed(INTAKE / 'seal.json'))},
        'actual_intake': {'command': command, 'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr,
                          'programme': pin(READER.read_bytes())},
        'original': raw, 'statements': hypotheses['statements'],
        'matches': derive(raw, hypotheses, prior), 'unresolved': hypotheses['unresolved'],
        'legs': {'rederive': 'match.py admitted source-link positions and original coordinates with all declared alternatives.',
                 'falsify': 'verify.py separately walks complete original phase intervals and reconstructs every own/opaque allocation; genuine caller, line, source and omission controls.',
                 'durability': 'Complete immutable original inventory, fixed intake/source authorities, sealed matching programmes/products and normal Git commit.'}}
    (BASE / 'matching.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete original own coordinate matching; alternatives and opaque/private owners conserved.')


if __name__ == '__main__':
    main()
