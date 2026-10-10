"""Reconstruct the entire dated proposal and falsify source/role/scope losses."""
import argparse
import copy
import hashlib
import json
import re
import runpy
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-current-preparation-20261010')
REVISION = '2bcc068255dbf6687ed92f20e8da24cf73351515'
PATHS = ('docs/knowledge/record-value-finite-copy-probe-reader.md',
         'docs/knowledge/record-value-original-observer-helper-paths.md',
         'docs/knowledge/mdbook-build-destination-locality.md',
         'docs/knowledge/isf-record-output-source-contexts.md')
QUESTION = 'what qualifies original own caller and source coordinates?'
SCOPE = 'Prospective retained source and reviewed mapping only; no current coordinate publication or fresh original recapture.'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args, data=None):
    result = subprocess.run(['git', '--no-replace-objects', *args], input=data, capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'independent complete Git source')
    return result.stdout


def objects(paths):
    raw = git('cat-file', '--batch', data=''.join(REVISION + ':' + p + '\n' for p in paths).encode())
    result, offset = {}, 0
    for path in paths:
        end = raw.index(b'\n', offset)
        _, kind, size = raw[offset:end].split()
        need(kind == b'blob', 'complete original blob kind')
        offset = end + 1
        length = int(size)
        result[path] = raw[offset:offset + length]
        need(raw[offset + length:offset + length + 1] == b'\n', 'complete original framing')
        offset += length + 1
    need(offset == len(raw), 'whole original source consumption')
    return result


def normalize(text):
    return ' '.join(text.split())


def questions(front):
    return re.findall(r'^  - "([^"\n]+)"$', front, flags=re.M)


def check(product, originals, proposed, authority):
    need(product['revision'] == REVISION and product['scope'] == SCOPE
         and set(product['cards']) == set(PATHS), 'closed complete dated proposal scope')
    need(same(product['authority'], authority), 'unchanged whole Knowledge Map authority')
    totals = {'original': {'bytes': 0, 'lines': 0}, 'proposal': {'bytes': 0, 'lines': 0}}
    for path in PATHS:
        row, old, new = product['cards'][path], originals[path], proposed[path]
        need(same(row['original'], pin(old)), 'complete original identity')
        need(same(row['proposal'], pin(new)), 'complete proposal identity')
        need(row['text'].encode() == new, 'complete proposed card bytes')
        old_front, old_body = old.decode().rsplit('---\n', 1)
        new_front, new_body = new.decode().rsplit('---\n', 1)
        old_parts, new_parts = old_body.strip().split('\n\n'), new_body.strip().split('\n\n')
        need(row['original_metadata'] == old_front + '---\n', 'whole original metadata')
        need([r['source'] for r in row['paragraphs']] == old_parts, 'complete original paragraph domain')
        need([normalize(r['proposed']) for r in row['paragraphs']] + [normalize(p) for p in row['additions']]
             == [normalize(p) for p in new_parts], 'complete reviewed proposed paragraph domain')
        wanted = questions(old_front) + ([QUESTION] if path == PATHS[0] else [])
        need(questions(new_front) == wanted, 'every ordered original and new scoped question')
        for field in ('id', 'status', 'tags'):
            pattern = '^' + field + ': (.*)$'
            need(re.findall(pattern, old_front, flags=re.M) == re.findall(pattern, new_front, flags=re.M),
                 'unchanged source identity/status/tags')
        old_evidence = old_front.split('evidence:', 1)[1].split('reverify:', 1)[0]
        new_evidence = new_front.split('evidence:', 1)[1].split('reverify:', 1)[0]
        if path == PATHS[0]:
            new_evidence = new_evidence.replace('  docs/audits/coordinate-original-hostile-20261009/scope.txt;\n', '', 1)
        need(new_evidence == old_evidence, 'every original evidence route')
        original_probe = normalize(old_front.split('reverify:', 1)[1])
        new_probe = normalize(new_front.split('reverify:', 1)[1])
        if path != PATHS[-1]:
            need(new_probe == original_probe, 'every original executable probe obligation')
        else:
            old_route = 'docs/audits/record-value-parser-path-publication-20261006/verify.py --current'
            expected = original_probe.replace(old_route, old_route.removesuffix(' --current') +
                ' && scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py')
            need(new_probe == expected and 'python3 -B ' + old_route in normalize(new_body),
                 'explicit parser historical/current probe roles')
        for role, raw in (('original', old), ('proposal', new)):
            for dimension in ('bytes', 'lines'):
                totals[role][dimension] += pin(raw)[dimension]
    need(same(product['totals'], totals) and all(totals['proposal'][k] <= totals['original'][k]
         for k in ('bytes', 'lines')), 'whole non-growing typed working set')
    core = normalize(proposed[PATHS[0]].decode())
    for marker in ('independent whole-result/ custody qualification', 'prior frame meanings before refusal',
                   'First failures/RAM stops retain non-success', 'address lifetimes remain unmeasured'):
        need(marker in core, 'complete scoped own-coordinate qualification and gaps')
    need(set(product['integration']['roles']) == {'historical', 'current', 'borrowed', 'unrelated'}
         and product['integration']['affected_cards'] == list(PATHS), 'complete affected integration roles')
    return totals


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', action='store_true', help='check dated proposal; no live-currency claim')
    args = parser.parse_args()
    extra = ['doctrine/live_document_size/surfaces.jsonl',
             'docs/audits/coordinate-original-hostile-independent-checks-20261009/checks.json']
    fixed = objects([*PATHS, *extra])
    originals = {p: fixed[p] for p in PATHS}
    product = json.loads((BASE / 'proposal.json').read_bytes())
    proposed = {p: product['cards'][p]['text'].encode() for p in PATHS}
    authority = next(r for r in map(json.loads, fixed[extra[0]].splitlines()) if r.get('surface_id') == 'knowledge_cards')
    for path in PATHS:
        need(Path(product['cards'][path]['locator']).read_bytes() == originals[path], 'exact retained complete original')
        if not args.snapshot:
            need(Path(path).read_bytes() == originals[path], 'preparation leaves every live card unchanged')
    receipt = product['qualified_receipt']
    actual = json.loads(fixed[extra[1]])['published-independent']
    need(receipt['path'] == extra[1] and same(receipt['identity'], pin(fixed[extra[1]]))
         and same(receipt['actual'], actual) and type(actual['status']) is int and actual['status'] == 0,
         'complete committed actual independent coordinate qualification')
    need(json.loads(actual['stdout'])['result'] ==
         'PASS complete independent original-coordinate hostile qualification and predecessor preservation',
         'complete committed semantic result; no fresh replay claim')
    sealed = Path('docs/audits/coordinate-original-hostile-20261009')
    published = Path('docs/audits/coordinate-original-hostile-checks-20261009/verify_hostile.py')
    need(published.read_bytes() == git('show', REVISION + ':' + str(published)),
         'unchanged published independent reader')
    runpy.run_path(str(published))['authenticate'](sealed)
    qualified = json.loads((sealed / 'qualification.json').read_bytes())
    whole = json.dumps(qualified, sort_keys=True).encode()
    need(json.loads(actual['stdout'])['whole_qualification'] ==
         {'bytes': len(whole), 'sha256': hashlib.sha256(whole).hexdigest()},
         'complete authenticated qualified original product')
    for path, expected in qualified['inputs'].items():
        raw = Path(path).read_bytes()
        need({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()} == expected
             and raw == git('show', qualified['revision'] + ':' + path),
             'whole unchanged joined source/matching/class-frame inputs')
    custody = json.loads(Path('docs/audits/coordinate-original-intake-20261009/admission.json').read_bytes())['custody']
    raw = json.dumps(custody, sort_keys=True).encode()
    need({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()} == qualified['original_custody'],
         'complete qualified original custody allocation')
    for path, member in custody['members'].items():
        raw = Path(path).read_bytes()
        need({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()} == member['identity'],
             'whole current original custody bytes')
    checks = json.loads((BASE / 'checks.json').read_bytes())
    for label in ('first', 'second', 'third', 'fourth', 'fifth'):
        stopped = checks[label + '-budget']
        raw = (BASE / (label + '-model.py.txt')).read_bytes()
        need(type(stopped['status']) is int and stopped['status'] == 1
             and 'non-growing complete proposed card bytes' in stopped['stderr']
             and stopped['instruments'][str(BASE / 'model.py')] ==
                 {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()},
             'complete retained actual draft refusal and source')
    totals = check(product, originals, proposed, authority)
    controls = {}
    cases = [
        ('lost-source', lambda p,o,n,a: o.update({PATHS[0]: o[PATHS[0]][:-1]}), 'complete original identity'),
        ('Boolean-dimension', lambda p,o,n,a: p['totals']['original'].update(bytes=True), 'whole non-growing typed working set'),
        ('promoted-current', lambda p,o,n,a: p.update(scope='current coordinates published'), 'closed complete dated proposal scope'),
        ('borrowed-authority', lambda p,o,n,a: p['authority']['transition']['max_growth'].update(bytes_total=9999999), 'unchanged whole Knowledge Map authority'),
        ('lost-proposition', lambda p,o,n,a: p['cards'][PATHS[1]]['paragraphs'][-1].update(proposed=''), 'complete reviewed proposed paragraph domain'),
        ('lost-original-question', lambda p,o,n,a: alter(p,n,PATHS[0], '  - "are the T1986 finite copy probes independently qualified?"\n', ''), 'every ordered original and new scoped question'),
        ('borrowed-probe', lambda p,o,n,a: alter(p,n,PATHS[0], 'scripts/check_record_value_publication.py', 'scripts/foreign.py'), 'every original executable probe obligation'),
        ('lost-address-gap', lambda p,o,n,a: alter_mapped(p,n,PATHS[0], 'address lifetimes remain unmeasured', 'address lifetimes are measured'), 'complete scoped own-coordinate qualification and gaps'),
    ]
    for name, mutate, cause in cases:
        changed, old, new, auth = copy.deepcopy(product), dict(originals), dict(proposed), copy.deepcopy(authority)
        mutate(changed, old, new, auth)
        need(not same(changed, product) or old != originals or new != proposed, 'genuine changed preparation control')
        try:
            check(changed, old, new, auth)
        except ValueError as error:
            need(str(error) == cause, 'intended preparation refusal: ' + name + ': ' + str(error))
            controls[name] = cause
        else:
            raise ValueError('false-green complete preparation control: ' + name)
    print(json.dumps({'result': 'PASS complete retained original sources, reviewed proposal/questions/probes, non-growing authority and genuine controls; current publication pending.',
                      'totals': totals, 'controls': controls, 'role': 'dated snapshot' if args.snapshot else 'unchanged live preparation'}, sort_keys=True))


def alter(product, proposed, path, old, new):
    need(proposed[path].count(old.encode()) == 1, 'unique genuine proposal control')
    proposed[path] = proposed[path].replace(old.encode(), new.encode(), 1)
    product['cards'][path].update(text=proposed[path].decode(), proposal=pin(proposed[path]))


def alter_mapped(product, proposed, path, old, new):
    alter(product, proposed, path, old, new)
    product['cards'][path]['additions'] = [p.replace(old, new) for p in product['cards'][path]['additions']]
    product['totals']['proposal'] = {k: sum(pin(r)[k] for r in proposed.values()) for k in ('bytes', 'lines')}


if __name__ == '__main__':
    main()
