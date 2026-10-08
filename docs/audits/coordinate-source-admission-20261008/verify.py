"""Independently consume whole source-only admission and genuine hostile inputs."""
import ast
import base64
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-admission-20261008')
REVISION = 'cd5021fab917166edc79b9317bb072ace82d952e'
CATALOG = 'docs/audits/record-value-coordinate-source-catalog-20261007'
PUBLIC = 'docs/audits/record-value-coordinate-public-reference-20261008'
FINAL = 'docs/audits/coordinate-public-final-replay-20261008'
ROOTS = [CATALOG, PUBLIC, FINAL]
ROLE = 'Complete qualified own source/catalog/custody and finite-public input admission only; source hypotheses and original coordinate intake remain successor-owned.'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete independent committed native input')
    return result.stdout


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def fixed(path):
    return native('show', REVISION + ':' + path)


def expected():
    raw = native('--literal-pathspecs', 'ls-tree', '-r', '--full-tree', '-z', REVISION, '--', *ROOTS)
    rows, members = {}, {}
    for record in raw.rstrip(b'\0').split(b'\0'):
        header, name = record.split(b'\t', 1); mode, kind, oid = header.decode().split()
        need(kind == 'blob' and mode in ('100644', '100755'), 'own regular source input kinds')
        path = name.decode(); rows[path] = {'mode': mode, 'oid': oid}
        members[path] = pin(native('cat-file', 'blob', oid))
    source = json.loads(fixed(CATALOG + '/inputs.json'))
    # Source-unit bytes come from their independent original commit authority,
    # not from the saved catalogue's claims about its own body identities.
    original = source['source_authority']['original_revision']
    for unit, row in source['units'].items():
        body = native('show', original + ':' + row['path']) if unit != 'observer' else row['body'].encode()
        need(row['body'].encode() == body and same(row['identity'], pin(body)), 'whole original own source unit bytes: ' + unit)
    transform = source['transform']; body = transform['before']
    need(native('show', source['source_authority']['capture_revision'] + ':' + transform['source_path']).decode() == body,
         'independent original observer beforeimage authority')
    for before, after in transform['replacements']:
        need(body.count(before) == 1, 'unique original ordered generation replacement')
        body = body.replace(before, after)
    need(body == transform['after'] == source['units']['observer']['body'], 'whole generated observer reconstruction')
    catalog = json.loads(fixed(CATALOG + '/catalog.json'))
    for unit, value in catalog['units'].items():
        body = source['units'][unit]['body'].encode()
        for span in value['named'] + value['guard_calls']:
            actual = body[span['offset_bytes']:span['offset_bytes'] + span['bytes']]
            need(actual == span['text'].encode() and same(pin(actual), span['identity']), 'whole independent lexical source range')
            need(body[:span['offset_bytes']].count(b'\n') + 1 == span['start_line']
                 and body[:span['offset_bytes'] + len(actual.rstrip(b'\n'))].count(b'\n') + 1 == span['end_line'],
                 'whole independent lexical source line endpoints')
    for span in catalog['qualified_lexical_spans']:
        body = source['units'][span['unit']]['body'].encode()
        actual = body[span['offset_bytes']:span['offset_bytes'] + span['bytes']]
        need(actual == span['text'].encode() and same(pin(actual), span['identity']), 'whole independent qualified source range')
        need(body[:span['offset_bytes']].count(b'\n') + 1 == span['start_line']
             and body[:span['offset_bytes'] + len(actual.rstrip(b'\n'))].count(b'\n') + 1 == span['end_line'],
             'whole independent qualified source line endpoints')
    checks = json.loads(fixed(FINAL + '/checks.json'))
    current = {name: checks[name] for name in ('current-native-rebuilt', 'copied-source-final', 'focused', 'staged-doctrines')}
    successes = {}
    for root in ROOTS:
        values = [node.value.value for node in ast.parse(fixed(root + '/verify.py')).body
                  if isinstance(node, ast.Assign) and isinstance(node.value, ast.Constant)
                  and any(isinstance(target, ast.Name) and target.id == 'SUCCESS' for target in node.targets)]
        if values:
            need(len(values) == 1, 'unique saved source reader success')
            successes[root] = values[0]
        else:
            successes[root] = 'PASS complete unchanged dated public route/reference/qualification, whole source and primary-Git conservation and independent hostile controls; original identities remain unmeasured.\n'
    return {'custody': {'revision': REVISION, 'roots': ROOTS, 'metadata': base64.b64encode(raw).decode(),
                       'rows': rows, 'members': members},
            'inputs': {'source': source, 'catalog': catalog}, 'public': json.loads(fixed(PUBLIC + '/recipes.json')),
            'prior_current_results': current, 'successes': successes}


def check(proof, expectation):
    need(proof['role'] == ROLE, 'source-only admission preserves successor and private scope')
    need(proof['programmes'] == {name: (BASE / name).read_text() for name in ('qualify.py', 'verify.py')},
         'complete actual source admission programmes')
    need(same(proof['custody'], expectation['custody']), 'complete native source input custody and membership')
    need(same(proof['inputs'], expectation['inputs']), 'whole original source/catalog/generation/invocation inputs')
    need(same(proof['public'], expectation['public']), 'complete dated public recipe and refusal allocation')
    need(same(proof['prior_current_results'], expectation['prior_current_results']) and all(
         type(row['status']) is int and row['status'] == 0 for row in proof['prior_current_results'].values()),
         'complete committed final current/native/focused/doctrine results')
    need(len(proof['actual_readers']) == len(ROOTS), 'whole fresh unchanged reader population')
    for result, root in zip(proof['actual_readers'], ROOTS):
        need(result['command'] == ['python3', '-B', root + '/verify.py'] and type(result['status']) is int
             and result['status'] == 0 and result['stderr'] == '' and result['stdout'] == expectation['successes'][root],
             'complete typed actual source/public reader result')


def main():
    proof = json.loads((BASE / 'proof.json').read_bytes()); expectation = expected(); check(proof, expectation)
    controls = (
        ('lost-member', lambda p: p['custody']['members'].pop(CATALOG + '/catalog.json'), 'complete native source input custody and membership'),
        ('borrowed-source', lambda p: p['inputs']['source']['units']['value'].update(body=p['inputs']['source']['units']['metadata']['body']), 'whole original source/catalog/generation/invocation inputs'),
        ('Boolean-line', lambda p: p['inputs']['catalog']['units']['value']['guard_calls'][0].update(start_line=True), 'whole original source/catalog/generation/invocation inputs'),
        ('lost-origin', lambda p: p['inputs']['catalog']['qualified_lexical_spans'].pop(), 'whole original source/catalog/generation/invocation inputs'),
        ('foreign-invocation-root', lambda p: p['inputs']['source']['modes'][0].update(fixture='../foreign'), 'whole original source/catalog/generation/invocation inputs'),
        ('lost-public-refusal', lambda p: p['public']['native_controls'].pop(), 'complete dated public recipe and refusal allocation'),
        ('borrowed-current-only-result', lambda p: p['actual_readers'][0].update(stdout=p['prior_current_results']['current-native-rebuilt']['stdout']), 'complete typed actual source/public reader result'),
        ('Boolean-status', lambda p: p['actual_readers'][0].update(status=False), 'complete typed actual source/public reader result'),
        ('original-identity-promotion', lambda p: p.update(role='All original coordinates and private identities qualified.'), 'source-only admission preserves successor and private scope'),
    )
    for name, mutate, cause in controls:
        candidate = copy.deepcopy(proof); mutate(candidate)
        need(not same(candidate, proof), 'genuine independent source admission control')
        try:
            check(candidate, expectation)
        except ValueError as error:
            need(str(error) == cause, 'intended source admission refusal: ' + name)
        else:
            raise ValueError('false-green source admission control: ' + name)
    print('PASS complete independent source-only/catalog/custody/public admission and genuine controls; source hypotheses/original coordinates remain successor-owned.')


if __name__ == '__main__':
    main()
