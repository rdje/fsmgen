"""Publish complete source-hypothesis custody, without original-coordinate intake."""
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-source-hypotheses-20261009')
REVISION = 'f5d2e81710ddbd2dd10f406551220d1a5ff2c32a'
AUDITS = Path('docs/audits')
FOLDERS = ('coordinate-source-admission-20261008', 'coordinate-source-sites-20261008',
           'coordinate-source-sites-checks-20261008', 'coordinate-refusal-path-inputs-20261009',
           'coordinate-refusal-path-input-checks-20261009', 'coordinate-statement-recipes-20261009',
           'coordinate-statement-recipe-checks-20261009', 'coordinate-refusal-phases-20261009',
           'coordinate-refusal-phase-checks-20261009', 'record-value-coordinate-source-catalog-20261007',
           'record-value-coordinate-public-reference-20261008', 'coordinate-public-final-replay-20261008',
           'record-value-coordinate-public-qualification-20261008')
SOURCE = AUDITS / 'record-value-class-frame-join-20261006/source-models.json'
READERS = (
    ('source', 'coordinate-source-admission-20261008/verify.py'),
    ('public', 'record-value-coordinate-public-reference-20261008/verify.py'),
    ('sites', 'coordinate-source-sites-checks-20261008/verify_sites.py'),
    ('paths', 'coordinate-refusal-path-inputs-20261009/verify.py'),
    ('path_actual', 'coordinate-refusal-path-input-checks-20261009/consume_actual.py'),
    ('statements', 'coordinate-statement-recipe-checks-20261009/verify_recipes.py'),
    ('statement_actual', 'coordinate-statement-recipe-checks-20261009/consume_published.py'),
    ('phases', 'coordinate-refusal-phase-checks-20261009/verify_phases.py'),
    ('phase_actual', 'coordinate-refusal-phase-checks-20261009/consume_actual.py'))
ROLE = 'Complete dated own-source coordinate hypotheses and finite-public examples; original coordinate selections and private runtime meanings remain unmeasured.'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def identity(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def native(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], cwd=ROOT, capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'whole committed source-publication input')
    return run.stdout


def custody():
    roots = sorted([str(AUDITS / name) for name in FOLDERS] + [str(SOURCE)])
    raw = native('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *roots)
    rows = {}
    for record in raw.rstrip(b'\0').split(b'\0'):
        header, name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        need(kind == 'blob' and mode in ('100644', '100755'), 'whole own regular committed input modes')
        path = name.decode()
        body = native('cat-file', 'blob', oid)
        local = ROOT / path
        need(local.resolve() == local and local.is_file() and local.stat().st_dev == ROOT.stat().st_dev
             and local.read_bytes() == body, 'whole unchanged regular same-volume source-publication bytes')
        for parent in local.parents:
            if parent == ROOT:
                break
            need(not (parent / '.git').exists(), 'own source-publication repository boundary')
        rows[path] = {'mode': mode, 'oid': oid, 'identity': pin(body)}
    for name in FOLDERS:
        folder = AUDITS / name
        need({str(p) for p in folder.iterdir()} == {p for p in rows if Path(p).parent == folder},
             'complete unchanged source-publication input namespace')
    need(all(any(p == root or p.startswith(root + '/') for p in rows) for root in roots), 'complete declared source-publication roots')
    return {'revision': REVISION, 'roots': roots, 'members': rows}


def load(folder, name):
    return json.loads((AUDITS / folder / name).read_bytes())


def derive():
    source = load('coordinate-source-admission-20261008', 'proof.json')
    bank = load('coordinate-source-sites-20261008', 'sites.json')
    paths = load('coordinate-refusal-path-inputs-20261009', 'paths.json')
    recipes = load('coordinate-statement-recipes-20261009', 'recipes.json')
    phases = load('coordinate-refusal-phases-20261009', 'phases.json')
    owner = (BASE / 'scope.txt').read_text().strip()
    need(owner == phases['unresolved']['whole_source_publication'], 'exact source-hypothesis publication owner')
    units = source['inputs']['source']['units']
    need(bank['public_examples'] == source['public'], 'whole admitted finite-public example custody')
    need(identity(bank['generation']) == recipes['generation_custody'] == phases['generation_custody']
         and identity(bank['invocations']) == recipes['invocation_custody'] == phases['invocation_custody'],
         'complete generation and invocation hypothesis custody join')
    need(identity(bank['public_examples']) == recipes['public_examples'] == phases['public_examples'],
         'complete finite-public hypothesis custody join')
    for site in bank['sites']:
        need(site['source_identity'] == units[site['unit']]['identity'] and site['original_selection'] is None,
             'whole lexical-site own source and conditional selection scope')
    statements = {s['id']: s for s in recipes['statements']}
    need(all(s == statements[s['id']] for s in phases['statements']), 'whole used statement/recipe allocation')
    bindings = {(r['mode'], r['domain'], r['index']): r for r in phases['refusals']}
    need(len(bindings) == len(phases['refusals']) == len(paths['allocations']), 'complete distinct refusal hypothesis domain')
    joins = []
    for allocation in paths['allocations']:
        key = allocation['mode'], allocation['domain'], allocation['index']
        binding = bindings.pop(key)
        need(binding['admitted_allocation_identity'] == identity(allocation)
             and binding['helper'] == allocation['helper']['index']
             and binding['subtest'] == allocation['subtest']['name']
             and len(binding['phases']) == allocation['helper_case']['phases'], 'whole source-only refusal hypothesis join')
        joins.append({'mode': key[0], 'domain': key[1], 'index': key[2], 'helper': binding['helper'],
                      'subtest': binding['subtest'], 'admission_identity': identity(allocation),
                      'binding_identity': identity(binding), 'phases': [{
                          'phase': p['phase'], 'family': p['family'], 'identity': identity(p),
                          'origin': p['origin']['caller']['recipe_id'],
                          'callers_inner_to_outer': [f['caller'].get('recipe_id') for f in p['active_path_inner_to_outer']],
                          'original_selection': None} for p in binding['phases']], 'original_selection': None})
    need(not bindings, 'whole refusal source-only join conservation')
    unresolved = {k: v for k, v in phases['unresolved'].items() if k != 'whole_source_publication'}
    unresolved['opaque_external_framework_callers'] = unresolved['original_coordinates']
    return {'role': ROLE, 'owner': owner,
            'own_source': {'units': {k: {'path': row['path'], 'identity': row['identity']} for k, row in units.items()},
                           'source_authority': source['inputs']['source']['source_authority'],
                           'generation': bank['generation'], 'invocations': bank['invocations']},
            'domains': {name: {'path': str(AUDITS / folder / file), 'identity': pin((AUDITS / folder / file).read_bytes())}
                        for name, folder, file in (
                            ('admission', 'coordinate-source-admission-20261008', 'proof.json'),
                            ('sites', 'coordinate-source-sites-20261008', 'sites.json'),
                            ('paths', 'coordinate-refusal-path-inputs-20261009', 'paths.json'),
                            ('statements', 'coordinate-statement-recipes-20261009', 'recipes.json'),
                            ('phases', 'coordinate-refusal-phases-20261009', 'phases.json'))},
            'refusals': joins, 'finite_public': {'identity': identity(source['public']),
                'role': 'Dated public examples only; no selection for the original refusal hypotheses.',
                'runs': [{'invocation': r['invocation'], 'identity': identity(r)} for r in source['public']['runs']],
                'native_controls': [{'name': r['name'], 'identity': identity(r)} for r in source['public']['native_controls']]},
            'unresolved': unresolved}


def readers():
    actual = []
    for name, relative in READERS:
        programme = AUDITS / relative
        command = ['python3', '-B', str(programme)]
        run = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        need(run.returncode == 0 and not run.stderr, 'whole successful source-only reader: ' + name)
        actual.append({'name': name, 'command': command, 'status': run.returncode,
                       'stdout': run.stdout, 'stderr': run.stderr, 'programme': pin(programme.read_bytes())})
    return actual


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke source-hypothesis publication from repository root')
    need(not (BASE / 'seal.json').exists(), 'sealed source-hypothesis publisher never reruns')
    before = custody()
    product = derive()
    product['custody'] = before
    product['actual_readers'] = readers()
    need(custody() == before, 'whole source-publication input conservation')
    (BASE / 'qualification.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete source-hypothesis publication and actual source-only readers; original coordinates remain unmeasured.')


if __name__ == '__main__':
    main()
