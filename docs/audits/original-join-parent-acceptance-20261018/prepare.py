"""Inventory the complete original acceptance; never execute its producers."""
import argparse
import base64
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

if not __debug__:
    raise SystemExit('Acceptance assertions must be enabled.')
ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/original-join-parent-acceptance-20261018')
PUBLICATION = Path('docs/audits/original-join-canonical-publication-20261017')
CLOSEOUT = Path('docs/audits/original-join-publication-closeout-20261017')
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
REVISION = '9c34775378ca325bb4e66bccb8502ee37f1a49a9'
PLAN_PATH = PUBLICATION / 'plan.json'
SCOPE = ('Validate every unchanged original obligation through complete qualified saved semantic '
         'readers and current publication checks. Preserve source-model/shared-premise/native/private '
         'assumptions, all first failures/repairs and dated execution roles. No subset or passed flag '
         'supplies truth. Preparation does not execute acceptance cohorts or close a parent.')


def encoded(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False) + '\n').encode()


def identity(body):
    return {'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest()}


def blob(body):
    return dict(identity(body), body_base64=base64.b64encode(body).decode())


def unblob(row):
    body = base64.b64decode(row['body_base64'], validate=True)
    assert identity(body) == {key: row[key] for key in ('bytes', 'sha256')}
    return body


def fixed(path):
    return subprocess.check_output(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)],
                                   cwd=ROOT, timeout=30)


def nodes(body):
    starts = list(re.finditer(rb'^- ID: `([^`]+)`\n', body, re.M))
    rows = {match[1].decode(): body[match.start():starts[i + 1].start() if i + 1 < len(starts) else len(body)]
            for i, match in enumerate(starts)}
    assert len(rows) == len(starts)
    return rows


def field(body, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', body, re.M)
    return match[1].decode() if match else None


def premises():
    plan = json.loads(fixed(PLAN_PATH))
    proof = json.loads(gzip.decompress(fixed(PUBLICATION / 'v2-proof.json.gz')))
    assert proof['owner'] == plan['owner'] and proof['revision'] == plan['revision']
    original = proof['contracts']
    family = {name: body for name, body in original.items()
              if name == plan['family'] or name.startswith(plan['family'] + '.')}
    assert set(original) == set(family) | {plan['full_alias']}
    assert plan['acceptance'] in family
    return plan, proof, original, family


def check_contracts(current, original, plan):
    """Progress may add acceptance substeps; every original obligation remains."""
    current = nodes(current)
    for name, body in original.items():
        assert name in current, 'missing original contract: ' + name
        for key in ('Goal', 'Acceptance'):
            assert field(current[name], key) == field(body.encode(), key), (name, key)
    family_names = {name for name in current
                    if name == plan['family'] or name.startswith(plan['family'] + '.')}
    assert all(name in original or name.startswith(plan['acceptance'] + '.') for name in family_names)
    return True


def cohorts(plan):
    return {
        'prerequisites': {'command': ['python3', '-B', plan['admission'] + '/verify.py'],
                          'covers': ['context', 'cause', 'consumer'],
                          'role': 'Fresh complete saved semantic readers; original source/native epochs remain dated.'},
        'association': {'command': ['python3', '-B', plan['association'] + '/verify.py'],
                        'covers': ['join'],
                        'role': 'Complete independent source/context/cause/coordinate/typed-consumer association, controls and first failures.'},
        'publication': {'command': ['python3', '-B', str(PUBLICATION / 'verify.py')],
                        'covers': ['publication'],
                        'role': 'Frozen full v2 publication recovery; current closeout is separately bound.'},
        'current': {'command': ['python3', '-B', 'scripts/check_record_value_publication.py'],
                    'covers': ['current'], 'role': 'Current canonical facts/questions/query/source allocation and capacity.'},
        'focused': {'command': ['python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python',
                                '-p', 'test_record_value*publication.py', '-v'],
                    'covers': ['current'], 'role': 'Current permanent publication and genuine refusal controls.'},
        'book': {'command': ['mdbook', 'build', 'docs/book'], 'covers': ['current'],
                 'role': 'Refresh canonical same-volume book with staged current source views.'},
        'native_book': {'command': ['python3', '-B', 'scripts/check_record_value_publication.py',
                                    '--build', 'docs/book/book'],
                        'covers': ['current'], 'role': 'Actual copied HTML/source bytes; visual QA stays separate.'},
        'source_views': {'command': ['python3', '-B', 'scripts/book_source_references.py',
                                     '--verify-build', 'docs/book/book'],
                         'covers': ['current'], 'role': 'Complete current source/role/member/relative-endpoint/byte/ignore contracts.'}}


def groups_for(plan, family):
    groups = {role: [] for role in ('context', 'cause', 'consumer', 'join')}
    for name in family:
        role = next((role for i, role in enumerate(('context', 'cause', 'consumer'), 1)
                     if name == plan['family'] + '.' + str(i)
                     or name.startswith(plan['family'] + '.' + str(i) + '.')), 'join')
        groups[role].append(name)
    return {role: sorted(names) for role, names in groups.items()}


def anchors_for(plan):
    return [PLAN_PATH, PUBLICATION / 'v2-proof.json.gz', PUBLICATION / 'v2-manifest.json.gz',
            CLOSEOUT / 'source-and-compiled-correspondence.json.gz', CLOSEOUT / 'module-closure-current.json',
            Path(plan['admission']) / 'proof.json', Path(plan['admission']) / 'manifest.json',
            Path(plan['association']) / 'proof.json', Path(plan['association']) / 'manifest.json']


def inventory():
    plan, proof, original, family = premises()
    current = (ROOT / TASK).read_bytes()
    assert check_contracts(current, original, plan)
    bodies = {str(path): fixed(path) for path in anchors_for(plan)}
    assert all((ROOT / path).read_bytes() == body for path, body in bodies.items())
    closure = json.loads(bodies[str(CLOSEOUT / 'module-closure-current.json')])
    assert all(identity((ROOT / path).read_bytes()) == pin for path, pin in closure['modules'].items())
    return dict(schema='fsmgen.original_parent_acceptance_inventory.v1', revision=REVISION,
                owner=plan['acceptance'] + '.1', acceptance=plan['acceptance'], family=plan['family'],
                full_alias=plan['full_alias'], original_contracts=original, groups=groups_for(plan, family),
                inputs={path: blob(body) for path, body in bodies.items()},
                current_task_snapshot=blob(current), current_module_closure=closure, cohorts=cohorts(plan),
                limits=dict(original_producer_recapture=False, fresh_original_native_assurance=False,
                            original_private_identity=False, full_alias=False, visual=False,
                            hial=False, full_ci=False, push=False),
                scope=SCOPE)


def validate(row):
    plan, proof, original, family = premises()
    assert set(row) == {'schema', 'revision', 'owner', 'acceptance', 'family', 'full_alias',
                        'original_contracts', 'groups', 'inputs', 'current_task_snapshot',
                        'current_module_closure', 'cohorts', 'limits', 'scope'}
    assert row['schema'] == 'fsmgen.original_parent_acceptance_inventory.v1'
    assert row['revision'] == REVISION and row['owner'] == plan['acceptance'] + '.1'
    assert row['acceptance'] == plan['acceptance'] and row['family'] == plan['family']
    assert row['full_alias'] == plan['full_alias'] and row['original_contracts'] == original
    assert row['groups'] == groups_for(plan, family) and row['scope'] == SCOPE
    memberships = [name for names in row['groups'].values() for name in names]
    assert set(row['groups']) == {'context', 'cause', 'consumer', 'join'}
    assert len(memberships) == len(set(memberships)) and set(memberships) == set(family)
    assert row['cohorts'] == cohorts(plan)
    assert all(type(value) is bool for value in row['limits'].values())
    assert row['limits'] == dict(original_producer_recapture=False, fresh_original_native_assurance=False,
                                 original_private_identity=False, full_alias=False, visual=False,
                                 hial=False, full_ci=False, push=False)
    assert set(row['inputs']) == {str(path) for path in anchors_for(plan)}
    for name, entry in row['inputs'].items():
        assert unblob(entry) == fixed(name)
    assert row['current_module_closure'] == json.loads(unblob(row['inputs'][str(CLOSEOUT / 'module-closure-current.json')]))
    assert check_contracts(unblob(row['current_task_snapshot']), original, plan)
    return True


def controls(row):
    assert validate(row)
    for label in ('omission', 'duplicate', 'contract', 'source', 'missing_source', 'scope', 'typed_scope', 'command', 'live_contract'):
        bad = copy.deepcopy(row)
        if label == 'omission':
            bad['groups']['context'].pop()
        elif label == 'duplicate':
            bad['groups']['cause'].append(bad['groups']['context'][0])
        elif label == 'contract':
            name = next(iter(bad['original_contracts']))
            bad['original_contracts'][name] += '\n  Acceptance: `narrowed`\n'
        elif label == 'source':
            name = next(iter(bad['inputs']))
            bad['inputs'][name] = blob(unblob(bad['inputs'][name]) + b'\n')
        elif label == 'missing_source':
            del bad['inputs'][next(iter(bad['inputs']))]
        elif label == 'scope':
            bad['limits']['fresh_original_native_assurance'] = True
        elif label == 'typed_scope':
            bad['limits']['fresh_original_native_assurance'] = 0
        elif label == 'command':
            bad['cohorts']['prerequisites']['command'] = ['true']
        else:
            task = unblob(bad['current_task_snapshot'])
            goal = field(nodes(task)[row['family']], 'Goal').encode()
            assert task.count(goal) == 1
            bad['current_task_snapshot'] = blob(task.replace(goal, b'narrowed original obligation', 1))
        try:
            validate(bad)
        except (AssertionError, KeyError, ValueError):
            continue
        raise AssertionError('hostile inventory admitted: ' + label)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    roles = parser.add_mutually_exclusive_group()
    roles.add_argument('--write', action='store_true')
    roles.add_argument('--current', action='store_true')
    args = parser.parse_args()
    assert Path.cwd().resolve() == ROOT
    path = ROOT / AUDIT / 'inventory.json.gz'
    row = inventory() if args.write else json.loads(gzip.decompress(path.read_bytes()))
    controls(row)
    if args.current:
        plan, _, original, _ = premises()
        assert check_contracts((ROOT / TASK).read_bytes(), original, plan)
        assert all(identity((ROOT / name).read_bytes()) == pin
                   for name, pin in row['current_module_closure']['modules'].items())
    if args.write:
        with path.open('xb') as stream:
            stream.write(gzip.compress(encoded(row), mtime=0))
    print('Complete original acceptance inventory and hostile omission/source/scope controls pass; no acceptance cohort executes.')
