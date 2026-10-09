"""Retain the complete first caller-alternative mismatch domain, without repair."""
import hashlib
import json
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-original-mismatch-20261009'
REVISION = '39249cb445399c2318275829e5c7f10e0094d0c4'
CLASS = A / 'record-value-class-frame-join-20261006'
PHASES = A / 'coordinate-refusal-phases-20261009/phases.json'


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def fixed(path):
    run = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)], capture_output=True)
    if run.returncode or run.stderr or path.read_bytes() != run.stdout:
        raise ValueError('whole fixed mismatch input')
    return run.stdout


def main():
    if (BASE / 'census.json').exists():
        raise ValueError('first mismatch census never rewrites')
    reader = A / 'coordinate-original-intake-checks-20261009/verify_intake.py'
    command = ['python3', '-B', str(reader)]
    replay = subprocess.run(command, capture_output=True, text=True)
    if replay.returncode or replay.stderr:
        raise ValueError('complete actual mismatch intake')
    paths = [CLASS / 'raw-product.json', CLASS / 'proofs.json', PHASES]
    bodies = [fixed(p) for p in paths]
    raw, prior, source = map(json.loads, bodies)
    records = {(m['mode'], d, r['index']): r for m in raw['inventories']
               for d, values in m['domains'].items() for r in values['nonempty']}
    proofs = {(m['mode'], r['domain'], r['index']): r for m in prior['modes'] for r in m['cases']}
    recipes = {r['id']: r for r in source['statements']}
    observations, mismatches = [], []

    def observe(key, phase, role, slot, recipe_id, segment):
        recipe = recipes[recipe_id]
        row = {'key': list(key), 'phase': phase, 'role': role, 'slot': slot,
               'recipe_id': recipe_id, 'statement': recipe,
               'original_segment': segment, 'original_selection': None,
               'filename_admitted': segment['path'] in recipe['filename_alternatives'],
               'matching_line_labels': sorted(k for k, v in recipe['line_alternatives'].items() if v == segment['line'])}
        observations.append(row)
        if not row['filename_admitted'] or not row['matching_line_labels']:
            mismatches.append(row)

    for refusal in source['refusals']:
        key = refusal['mode'], refusal['domain'], refusal['index']
        record = records[key]
        frames = [s for s in record['segments'] if s['kind'] == 'frame']
        origins = [i for i, s in enumerate(record['segments']) if s['kind'] == 'origin']
        for phase, proof, origin in zip(refusal['phases'], proofs[key]['phases'], origins, strict=True):
            positions = proof['complete_own_positions']
            observe(key, phase['phase'], 'origin', origin, phase['origin']['caller']['recipe_id'], record['segments'][origin])
            previous = None
            for binding in phase['active_path_inner_to_outer']:
                targets = [positions['operations'][p[1]][p[3]] if p[0] == 'operations'
                           else positions[p[0] + '_positions'][p[1]] for p in binding['model_links']]
                index = targets[0] if targets else previous + 1
                if targets and len(set(targets)) != 1:
                    raise ValueError('complete source links agree')
                previous = index
                if binding['caller']['kind'] == 'own_statement':
                    observe(key, phase['phase'], binding['role'], index, binding['caller']['recipe_id'], frames[index])
            observe(key, phase['phase'], 'load', positions['load_position'], phase['load']['caller']['recipe_id'], frames[positions['load_position']])
    if set(records) != {(r['mode'], r['domain'], r['index']) for r in source['refusals']}:
        raise ValueError('complete original mismatch domain')
    first = json.loads((A / 'coordinate-original-matching-checks-20261009/checks.json').read_bytes())['matching']
    programme = A / 'coordinate-original-matching-20261009/match.py'
    if first['status'] != 1 or first['instruments'][str(programme)] != pin(programme.read_bytes()):
        raise ValueError('exact first failed matching programme and result')
    result = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
        'role': 'Complete diagnostic census only; no alternatives widened and no original meaning selected.',
        'inputs': {str(p): pin(b) for p, b in zip(paths, bodies, strict=True)},
        'original_inventory': pin(bodies[0]), 'source_statements': source['statements'],
        'observations': observations, 'mismatches': mismatches, 'unresolved': source['unresolved'],
        'first_failure': first, 'first_programme': pin(programme.read_bytes()),
        'unexecuted_draft_verifier': pin((programme.parent / 'verify.py').read_bytes()),
        'actual_intake': {'command': command, 'status': replay.returncode, 'stdout': replay.stdout,
                          'stderr': replay.stderr, 'programme': pin(reader.read_bytes())}}
    (BASE / 'census.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({'result': 'PASS complete first mismatch census retained without repair',
                      'observations': len(observations), 'mismatches': len(mismatches),
                      'recipes': sorted({r['recipe_id'] for r in mismatches})}, sort_keys=True))


if __name__ == '__main__':
    main()
