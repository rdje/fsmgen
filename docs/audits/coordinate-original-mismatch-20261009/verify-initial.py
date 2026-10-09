"""Independently census phase intervals and replay finite public attribution."""
import ast
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-original-mismatch-20261009'
CHECKS = A / 'coordinate-original-matching-checks-20261009'
FIRST = A / 'coordinate-original-matching-20261009'
REVISION = '39249cb445399c2318275829e5c7f10e0094d0c4'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def fixed(path):
    full = Path.cwd().resolve() / path
    need(full.resolve() == full and full.is_file() and full.stat().st_dev == Path.cwd().stat().st_dev,
         'independent plain same-volume input')
    for parent in full.parents:
        if parent == Path.cwd().resolve():
            break
        need(not (parent / '.git').exists(), 'independent own input boundary')
    run = subprocess.run(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + str(path)], capture_output=True)
    need(run.returncode == 0 and not run.stderr and run.stdout == path.read_bytes(), 'complete independent fixed mismatch source')
    return run.stdout


def observations(raw, source, prior):
    captures = {(m['mode'], d, r['index']): r for m in raw['inventories']
                for d, values in m['domains'].items() for r in values['nonempty']}
    proofs = {(m['mode'], r['domain'], r['index']): r for m in prior['modes'] for r in m['cases']}
    keys = [(r['mode'], r['domain'], r['index']) for r in source['refusals']]
    need(set(keys) == set(captures) == set(proofs) and len(keys) == len(set(keys)), 'complete independent original mismatch keys')
    recipes = {r['id']: r for r in source['statements']}
    output = []

    def append(key, phase, role, slot, recipe_id, segment):
        recipe = recipes[recipe_id]
        need(type(segment['line']) is int and segment['line'] > 0, 'independent discrete original coordinate')
        output.append({'key': list(key), 'phase': phase, 'role': role, 'slot': slot,
            'recipe_id': recipe_id, 'statement': recipe, 'original_segment': segment, 'original_selection': None,
            'filename_admitted': segment['path'] in recipe['filename_alternatives'],
            'matching_line_labels': sorted(k for k in recipe['line_alternatives'] if recipe['line_alternatives'][k] == segment['line'])})

    for refusal, key in zip(source['refusals'], keys, strict=True):
        record = captures[key]
        frames = [s for s in record['segments'] if s['kind'] == 'frame']
        origins = [i for i, s in enumerate(record['segments']) if s['kind'] == 'origin']
        cursor = 0
        for phase, proof, origin in zip(refusal['phases'], proofs[key]['phases'], origins, strict=True):
            positions = proof['complete_own_positions']
            need(cursor == positions['core_positions'][0], 'independent contiguous original phase')
            opaque = {i for i, f in enumerate(frames) if any(same(f, x) for x in positions['opaque_framework'])}
            need(len(opaque) == len(positions['opaque_framework']), 'complete independent opaque interval')
            append(key, phase['phase'], 'origin', origin, phase['origin']['caller']['recipe_id'], record['segments'][origin])
            for binding in phase['active_path_inner_to_outer']:
                while cursor in opaque:
                    cursor += 1
                frame = frames[cursor]
                name = frame['call'] if frame['call'] == 'eval {...}' else frame['call'].partition('(')[0]
                need(name == binding['callee'], 'independent complete source/callee order')
                for link in binding['model_links']:
                    target = positions['operations'][link[1]][link[3]] if link[0] == 'operations' else positions[link[0] + '_positions'][link[1]]
                    need(cursor == target, 'independent complete source/caller linkage')
                if not binding['model_links']:
                    need(binding['role'] == 'nested_capture_eval', 'independent qualified nested eval interval')
                if binding['caller']['kind'] == 'own_statement':
                    append(key, phase['phase'], binding['role'], cursor, binding['caller']['recipe_id'], frame)
                else:
                    need(binding['caller']['kind'] == 'opaque_external_framework_interval', 'independent explicit opaque caller')
                cursor += 1
            while cursor in opaque:
                cursor += 1
            need(cursor == positions['load_position'], 'independent original load interval')
            append(key, phase['phase'], 'load', cursor, phase['load']['caller']['recipe_id'], frames[cursor])
            cursor += 1
        need(cursor == len(frames) and len(origins) == len(refusal['phases']), 'independent exhaustive original frame and origin census')
    return output


def public_check(product, replay=True):
    need(type(product['fixtures']) is list and product['fixtures'], 'complete public fixture population')
    for row in product['fixtures']:
        path = Path(row['path']); body = path.read_bytes(); text = body.decode()
        need(row['source'] == pin(body), 'complete public source identity')
        need(len(row['actual']) == 2, 'whole public runtime/compiler pair')
        for actual, command in zip(row['actual'], (['perl', str(path)], ['perl', '-MO=Concise,-exec', str(path)]), strict=True):
            need(type(actual['status']) is int and actual['status'] == 0, 'actual public status')
            need(actual['command'] == command, 'actual public command')
            if replay:
                run = subprocess.run(command, capture_output=True, text=True)
                need(actual == {'command': command, 'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr},
                     'complete independently regenerated public result')
        runtime = json.loads(row['actual'][0]['stdout'])
        expected = []
        markers = list(re.finditer(r"\$case = '([^']+)';", text))
        lineno = lambda offset: text[:offset].count('\n') + 1
        for i, marker in enumerate(markers):
            end = markers[i+1].start() if i+1 < len(markers) else len(text)
            block = text[marker.end():end]; start = marker.end(); case = marker[1]
            if path.name.startswith('caller-'):
                helper = block.index('callsite($callback,') if case == 'named-code-reference' else block.index('qr/marker/')
                callback = block.index('callbacksite();')
                pairs = [('helper', lineno(start+helper)), ('callback', lineno(start+callback))]
            elif path.name.startswith('guard-live-'):
                expression = '    $source->{value},' if case == 'nested-live-first-argument' else '    && root('
                pairs = [('guard', lineno(start+block.index(expression)))]
            else:
                pairs = [('guard', lineno(start+block.index('guard(')))]
            for kind, line in pairs:
                expected.append({'case': case, 'kind': kind, 'package': 'main', 'file': str(path), 'line': line})
                if kind != 'callback':
                    need(re.search(r'nextstate\(main \d+ ' + re.escape(path.name) + ':' + str(line) + r'\)', row['actual'][1]['stdout']) is not None,
                         'public compiler state label joins public caller')
        need(runtime['observations'] == expected and type(runtime['perl_version']) is str,
             'independent source-only public attribution oracle')
        need(set(runtime) == {'observations', 'perl_version'} and row['actual'][0]['stderr'] == ''
             and row['actual'][1]['stderr'] == str(path) + ' syntax OK\n', 'complete public runtime/compiler streams')


def census_check(actual, expected, mismatches):
    need(same(actual['observations'], expected), 'whole independent original observations')
    need(same(actual['mismatches'], mismatches), 'whole independent original mismatches')


def main():
    census = json.loads((BASE / 'census.json').read_bytes())
    paths = [A / 'record-value-class-frame-join-20261006/raw-product.json',
             A / 'record-value-class-frame-join-20261006/proofs.json', A / 'coordinate-refusal-phases-20261009/phases.json']
    bodies = [fixed(p) for p in paths]; raw, prior, source = map(json.loads, bodies)
    expected = observations(raw, source, prior)
    mismatches = [r for r in expected if not r['filename_admitted'] or not r['matching_line_labels']]
    census_check(census, expected, mismatches)
    need(census['inputs'] == {str(p):pin(b) for p,b in zip(paths,bodies,strict=True)}
         and same(census['source_statements'], source['statements']) and same(census['unresolved'], source['unresolved']),
         'complete independent mismatch authority and opaque scope')
    need(census['first_programme'] == pin((FIRST / 'match.py').read_bytes())
         and census['unexecuted_draft_verifier'] == pin((FIRST / 'verify.py').read_bytes())
         and {p.name for p in FIRST.iterdir()} == {'match.py','verify.py','scope.txt'}, 'exact first programmes; no false matching product')
    checks = json.loads((CHECKS / 'checks.json').read_bytes())
    need(census['first_failure'] == checks['matching'] and type(checks['matching']['status']) is int
         and checks['matching']['status'] == 1 and checks['matching']['stderr'].endswith('ValueError: declared own caller coordinate: helper-invocation/0\n')
         and checks['matching']['instruments'][str(FIRST / 'match.py')] == census['first_programme'], 'complete actual first matching refusal')
    original_checks = json.loads(fixed(A / 'coordinate-original-intake-checks-20261009/checks.json'))
    intake = census['actual_intake']
    need(type(intake['status']) is int and intake['status'] == 0 and intake['stdout'] == original_checks['published']['stdout']
         and intake['stderr'] == '' and intake['command'] == ['python3','-B',str(A / 'coordinate-original-intake-checks-20261009/verify_intake.py')]
         and intake['programme'] == pin(fixed(A / 'coordinate-original-intake-checks-20261009/verify_intake.py')), 'complete actual sealed intake result and dated reference')
    first_public = (BASE / 'public-first.py').read_bytes()
    first_ast = ast.parse(first_public)
    needle = next(ast.literal_eval(n.value) for n in ast.walk(first_ast) if isinstance(n, ast.Assign)
                  and any(isinstance(t, ast.Name) and t.id == 'needle' for t in n.targets))
    need((BASE / 'caller-fixture.pl').read_bytes().count(needle) == 2
         and checks['public-attribution']['status'] == 1
         and checks['public-attribution']['instruments'][str(BASE / 'public.py')] == pin(first_public)
         and checks['public-attribution']['stderr'].endswith('ValueError: unique controlled first fixture call\n'), 'actual first ambiguous selector failure retained and explained')
    products = [json.loads((BASE / name).read_bytes()) for name in ('public.json','guard-live.json')]
    names = {'caller-fixture.pl','caller-pattern-shift.pl','caller-label-shift.pl','guard-fixture.pl','guard-expression-shift.pl','guard-message-shift.pl','guard-live-fixture.pl','guard-live-operand-shift.pl','guard-live-message-shift.pl'}
    need({Path(r['path']).name for p in products for r in p['fixtures']} == names, 'complete independently declared public fixtures')
    for product, programme in zip(products, ('public.py','guard_live.py'), strict=True):
        need(product['owner'] == (BASE / 'scope.txt').read_text().strip() and product['programme'] == pin((BASE / programme).read_bytes()), 'whole public producer identity')
        public_check(product)
    controls = {}
    for name, key in (('lost-observation','observations'),('lost-mismatch','mismatches')):
        bad = copy.deepcopy(census); bad[key].pop()
        try:
            census_check(bad, expected, mismatches)
        except ValueError as error:
            controls[name] = str(error)
        else:
            raise ValueError('false-green whole mismatch control')
    for name, mutate, why in (
        ('false-green-status',lambda p:p['fixtures'][0]['actual'][0].update(status=True),'actual public status'),
        ('borrowed-command',lambda p:p['fixtures'][0]['actual'][0]['command'].append('--foreign'),'actual public command'),
        ('borrowed-source',lambda p:p['fixtures'][0]['source'].update(bytes=1),'complete public source identity'),
        ('wrong-caller-line',lambda p:p['fixtures'][0]['actual'][0].update(stdout=p['fixtures'][0]['actual'][0]['stdout'].replace('"line":18','"line":1',1)), 'independent source-only public attribution oracle')):
        bad=copy.deepcopy(products[0]); mutate(bad); need(not same(bad,products[0]), 'genuine public control')
        try:
            public_check(bad,replay=False)
        except ValueError as error:
            need(str(error) == why, 'intended public attribution control'); controls[name]=str(error)
        else:
            raise ValueError('false-green public attribution control')
    need([fixed(p) for p in paths] == bodies, 'whole original mismatch source conservation')
    print(json.dumps({'result':'PASS complete independent original mismatch census and public/compiler diagnosis',
        'observations':len(expected),'mismatches':len(mismatches),'recipes':sorted({r['recipe_id'] for r in mismatches}),
        'controls':controls,'original_inventory':pin(bodies[0]),
        'scope':'No original alternative widened; constant-only guards retain as counterexamples, live operands reproduce the interior labels. Superseding source qualification remains owned next.'},sort_keys=True))


if __name__ == '__main__':
    main()
