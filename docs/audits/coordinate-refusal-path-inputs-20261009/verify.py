"""Independent fixed-source path allocation and actual hostile candidate controls.

This reader does not import the producer. Existing qualified source models are
shared semantic inputs; independent original byte and role allocation detects
new joining mistakes, not defects shared by those predecessor cause models.
"""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-refusal-path-inputs-20261009')
BANK = Path('docs/audits/coordinate-source-sites-20261008')
REVISION = 'f263d5c8a13b9a31da2b633a103f4575b17ef41c'
FAMILIES = (
    ('helper', 'record-value-original-helper-join-20261005'),
    ('value', 'record-value-original-value-frames-20261005'),
    ('metadata', 'record-value-original-metadata-frames-20261005'),
    ('observer', 'record-value-original-observer-boundaries-20261005'),
    ('subtest', 'record-value-own-subtest-boundaries-20261005'),
    ('classes', 'record-value-original-class-20261005'),
)


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def equal(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(path, revision=REVISION):
    result = subprocess.run(['git', '--no-replace-objects', 'show', revision + ':' + str(path)],
                            cwd=ROOT, capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'independent complete fixed source result')
    return result.stdout


def expectation():
    models, authorities = {}, {}
    for family, folder in FAMILIES:
        path = Path('docs/audits', folder, 'proofs.json')
        raw = git(path)
        need(path.read_bytes() == raw, 'whole independent unchanged model input')
        models[family] = json.loads(raw)['models']
        authorities[str(path)] = pin(raw)
    bank_raw, seal_raw = git(BANK / 'sites.json'), git(BANK / 'seal.json')
    for name, expected in json.loads(seal_raw).items():
        raw = git(BANK / name)
        need(pin(raw) == expected and (BANK / name).read_bytes() == raw,
             'independent complete sealed bank source identity')
    authorities[str(BANK / 'sites.json')] = pin(bank_raw)
    authorities[str(BANK / 'seal.json')] = pin(seal_raw)
    bank = json.loads(bank_raw)
    test_site = next(row for row in bank['sites'] if row['role'] == 'helper_callback')
    test_bytes = git(test_site['source_path'], bank['generation']['source_authority']['original_revision'])
    need(pin(test_bytes) == test_site['source_identity'], 'whole independent original test byte identity')
    by_mode = {family: {row['mode']: row for row in rows}
               for family, rows in models.items() if family != 'subtest'}
    subtests = {row['mode']: row for row in models['subtest']['modes']}
    expected = {}
    order = []
    for mode in ('ordinary', 'storable', 'controls'):
        helpers = by_mode['helper'][mode]
        cases = {(row['domain'], row['index']): row for row in helpers['cases']}
        classes = {(row['domain'], row['index']): row for row in by_mode['classes'][mode]['cases']}
        boundaries = {(row['domain'], row['index']): row for row in subtests[mode]['cases']}
        need(len(cases) == len(helpers['cases']) and set(cases) == set(classes) == set(boundaries),
             'independent complete refusal population')
        order.extend((mode, row['domain'], row['index']) for row in helpers['cases'])
        for key, boundary in boundaries.items():
            case = cases[key]
            helper_rows = [row for row in helpers['helpers'] if row['index'] == boundary['helper']]
            need(len(helper_rows) == 1, 'independent exact helper allocation')
            helper = helper_rows[0]
            site_rows = [row for row in bank['sites'] if row['role'] == 'helper_callback'
                         and row['span']['index'] == helper['index']]
            need(len(site_rows) == 1, 'independent source callback index identity')
            callback = site_rows[0]
            need(callback['span']['text'] == helper['source_statement']
                 and callback['lexical_owner']['name'] == boundary['name'],
                 'independent complete callback body and subtest ownership')
            body_rows = [row for row in bank['sites'] if row['role'] == 'named_subtest_body'
                         and row['span']['name'] == boundary['name']]
            need(len(body_rows) == 1 and body_rows[0]['span']['text'] == boundary['body'],
                 'independent exact named-subtest body identity')
            for row in (callback, body_rows[0]):
                span = row['span']
                begin, size = span['offset_bytes'], span['bytes']
                need(type(begin) is int and type(size) is int
                     and test_bytes[begin:begin + size] == span['text'].encode()
                     and pin(span['text'].encode()) == span['identity'], 'independent original binary body allocation')
            operations = by_mode['observer'][mode]['api' if key[0] == 'api' else 'parses']
            rows = [row for row in operations if row['index'] == key[1]]
            need(len(rows) == 1 and rows[0]['helper'] == helper['index'] == case['helper']
                 and case['phases'] == boundary['phases'] == len(case['paths']),
                 'independent full operation helper and throw-phase allocation')
            expected[(mode, *key)] = {
                'mode': mode, 'domain': key[0], 'index': key[1], 'helper': helper,
                'helper_case': case, 'subtest': boundary, 'source_class': classes[key],
                'observer_operation': rows[0], 'callback_site_id': callback['id'],
                'body_site_id': body_rows[0]['id'], 'original_selection': None,
            }
    need(len(order) == len(expected), 'complete unique ordered source path domain')
    task = git('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').decode()
    aliases = [block.split('`', 1)[0] for block in task.split('- ID: `')[1:]
               if 'Goal: `Qualify full alias-provider downstream mutations and genuine abort.`' in block]
    need(len(aliases) == 1, 'independent exact unresolved whole-alias owner')
    return {
        'role': 'Dated source-only refusal path inputs; statement alternatives, original coordinate selections and alias downstream qualification remain successor-owned.',
        'revision': REVISION, 'owner': bank['owners']['composition'] + '.1',
        'authorities': authorities, 'source_models': models,
        'allocations': [expected[key] for key in order],
        'generation': bank['generation'], 'invocations': bank['invocations'],
        'unresolved': {'statement_hypotheses': bank['owners']['composition'] + '.2',
                       'original_coordinates': bank['owners']['original_join'],
                       'original_private_formatter_toolchain_identity': bank['owners']['original_join'],
                       'addresses': bank['owners']['addresses'], 'alias_downstream': aliases[0]},
    }


def check(actual, expected):
    need(equal(actual, expected), 'complete independent source path/body/member/role/kind/owner allocation')


def authenticate():
    need(BASE.resolve() == ROOT / BASE and BASE.stat().st_dev == ROOT.stat().st_dev,
         'own regular same-volume sealed path input root')
    need(all(path.is_file() and not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
             for path in BASE.iterdir()), 'own complete regular sealed path input members')
    seal = json.loads((BASE / 'seal.json').read_bytes())
    need(equal(seal, {path.name: pin(path.read_bytes()) for path in BASE.iterdir() if path.name != 'seal.json'}),
         'complete immutable path input membership and bytes')


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke independent path input reader from repository root')
    authenticate()
    expected = expectation()
    actual = json.loads((BASE / 'paths.json').read_bytes())
    need((BASE / 'scope.txt').read_text().strip() == expected['owner'], 'exact current source admission owner')
    check(actual, expected)
    controls = (
        ('lost-refusal', lambda p: p['allocations'].pop()),
        ('duplicate-refusal', lambda p: p['allocations'].append(copy.deepcopy(p['allocations'][0]))),
        ('borrowed-mode', lambda p: p['allocations'][0].update(mode='alias')),
        ('Boolean-index', lambda p: p['allocations'][0].update(index=True)),
        ('wrong-helper', lambda p: p['allocations'][0]['helper'].update(index=42)),
        ('borrowed-callback-label', lambda p: p['allocations'][0].update(callback_site_id=p['allocations'][1]['callback_site_id'])),
        ('borrowed-body', lambda p: p['allocations'][0]['subtest'].update(body='borrowed')),
        ('lost-phase', lambda p: p['allocations'][0]['helper_case']['paths'].pop()),
        ('lost-guard-input', lambda p: p['source_models']['metadata'].pop()),
        ('borrowed-root', lambda p: p['invocations'][0].update(fixture='borrowed')),
        ('lost-generation', lambda p: p['generation'].pop('transform')),
        ('coordinate-promotion', lambda p: p['allocations'][0].update(original_selection={'line': 1})),
        ('lost-alias-owner', lambda p: p['unresolved'].pop('alias_downstream')),
    )
    decisions = []
    for name, mutate in controls:
        bad = copy.deepcopy(actual)
        mutate(bad)
        need(not equal(bad, actual), 'genuine path input intervention: ' + name)
        try:
            check(bad, expected)
        except ValueError as error:
            decisions.append({'control': name, 'cause': str(error), 'status': 1})
        else:
            raise ValueError('false-green path input control: ' + name)
    authenticate()
    print(json.dumps({'status': 0, 'controls': decisions,
                      'scope': 'Complete source-only path allocation; no original coordinate or alias qualification.'}, sort_keys=True))


if __name__ == '__main__':
    main()
