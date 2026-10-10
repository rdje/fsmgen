"""Independently join original allocations, full semantic witnesses and actual readers."""
import hashlib
import json
import re
import runpy
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-parent-acceptance-20261010')
REVISION = '556b9d5f9cd09b981a462619701d9032e5c0657e'
SCOPE = ('Complete unchanged finite raw-address and numerical/source parent acceptance. Whole original bodies, '
         'lossless operands, source/class/frame/coordinate prerequisites, corrected holders and simultaneous '
         'source-number relations conserve. No numerical reuse across calls/captures establishes identity. '
         'Address container and governed canonical publication remain open.')
OPEN = ['native identity/payload/flags', 'provider/formatter identity', 'CODE/CODE and Regexp identity',
        'cross-call/capture numerical reuse', 'global heap census', 'cold replay', 'visual book QA',
        'governed canonical publication', 'address/lifetime container', 'HIAL/full-CI/push qualification']
FOLDERS = {'admission': 'address-raw-admission-20261010', 'operands': 'address-raw-operands-20261010',
           'holders': 'address-raw-join-20261010', 'numerical': 'address-numeric-join-20261010'}


def need(value, cause):
    if not value:
        raise ValueError(cause)


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def structured(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def fixed_inputs():
    registry = json.loads((BASE / 'inputs.json').read_bytes()); binding = json.loads((BASE / 'binding.json').read_bytes())
    need(binding['revision'] == REVISION, 'fixed whole parent revision')
    for path, identity in binding['members'].items():
        raw = subprocess.check_output(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + path])
        need(raw == Path(path).read_bytes() and pin(raw) == identity, 'whole independent parent input bytes')
    need(all(s['identity'] == binding['members'][s['path']] for s in registry.values()), 'complete parent registry membership')
    task = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
    old = subprocess.check_output(['git', '--no-replace-objects', 'show', REVISION + ':' + task]).decode()
    def nodes(text):
        matches = list(re.finditer(r'^- ID: `([^\n]+)`\n', text, re.M)); result = {}
        for a, b in zip(matches, matches[1:]):
            result[a[1]] = text[a.start():b.start()].rstrip('\n')
        return result
    original, current = nodes(old), nodes(Path(task).read_text())
    for owner, record in binding['contracts'].items():
        need(record['whole_committed_node'].rstrip('\n') == original[owner], 'whole original parent task node')
        fields = lambda text: dict(re.findall(r'^  (Goal|Acceptance|Children): `([^\n]+)`$', text, re.M))
        need(fields(original[owner]) == fields(current[owner]) == record['contract'], 'independent complete unchanged parent contracts')
    for owner, record in binding['completed'].items():
        need(record.rstrip('\n') == original[owner] and '  Status: `done`\n' in record, 'complete fixed prerequisite task closure')
    data = {n: json.loads(Path(s['path']).read_bytes()) for n, s in registry.items() if s['path'].endswith('.json')}
    for path, identity in data['admission']['allocation']['products'].items():
        need(any(s['path'] == path and s['identity'] == identity for s in registry.values()), 'complete class/frame/source/coordinate product conservation')
    for key in ('admission', 'operand', 'holder', 'numerical'):
        folder = FOLDERS[{'operand': 'operands', 'holder': 'holders'}.get(key, key)]
        for name, identity in data[key + '_proof']['programmes'].items():
            need(pin((Path('docs/audits') / folder / name).read_bytes()) == identity, 'whole qualified prerequisite programmes')
    return registry, binding, data


def reconstruct(data):
    parsed = {(m['mode'], name, r['index']): r for m in data['operands']['modes'] for name, d in m['domains'].items() for r in d['records']}
    sources = {tuple(v['domain']): v for m in data['source']['modes'] for v in m['views']}
    holders = {tuple(v['domain']): v for m in data['holders']['modes'] for v in m['views']}
    numerical = {tuple(v['domain']): v for v in data['numerical']['views']}
    phase_at = {tuple(p['domain']): p for r in parsed.values() for p in r['phases']}
    records, views, seen = [], [], set()
    counts = {'empty_records': 0, 'nonempty_records': 0, 'body_bytes': 0, 'views': 0, 'visible_reference_operands': 0}
    for mode in ('ordinary', 'storable', 'controls'):
        original = data['original_' + mode]; domains = {}
        for name in ('api', 'copies', 'parses', 'test_run'):
            events = [original[name]] if name == 'test_run' else original[name]
            empty, nonempty = [], []
            for index, event in enumerate(events):
                if event['error'] == '':
                    empty.append(index); counts['empty_records'] += 1; continue
                key = (mode, name, index); record = parsed[key]; body = event['error'].encode()
                need(body == ''.join(s['raw'] for s in record['segments']).encode() and pin(body) == record['body_identity'],
                     'whole original parent body and lossless segmentation')
                keys = [tuple(p['domain']) for p in record['phases']]
                need(set(keys) == {k for k in sources if k[:3] == key}, 'complete original parent source phase association')
                nonempty.append({'index': index, 'body': pin(body), 'whole_parsed_record': structured(record),
                                 'forwarded': record['forwarded'], 'source_domains': [list(k) for k in keys]})
                for domain in keys:
                    source, held, phase, numbers = sources[domain], holders[domain], phase_at[domain], numerical[domain]
                    need(numbers['whole_source_view'] == held['whole_prior_view'] == phase['whole_source_view'] == structured(source)
                         and numbers['whole_holder_view'] == structured(held) and numbers['whole_parsed_phase'] == structured(phase),
                         'complete source holder numerical phase linkage')
                    # Every source occurrence appears exactly once as an addressed
                    # or unaddressed slot. Numerical semantics come from the fresh
                    # complete qualified numerical reader, not matching totals.
                    all_slots = [r['source'] for r in numbers['references']] + [r['source'] for r in numbers['unaddressed_source_operands']]
                    need(sorted(map(lambda x: json.dumps(x, sort_keys=True), all_slots)) ==
                         sorted(map(lambda x: json.dumps(x, sort_keys=True), source['occurrences'])), 'complete parent source operand partition')
                    frames = {s['frame_index']: s for s in record['segments'] if s['kind'] == 'frame'}
                    for row in numbers['references']:
                        token = frames[row['frame_index']]['arguments'][row['source']['argument']]
                        need(token['raw'] == row['raw'] == body[row['span'][0]:row['span'][1]].decode()
                             and token['hex'] == row['hex'] and token['reference_kind'] == row['reference_kind'],
                             'complete parent original visible operand association')
                    views.append({'domain': list(domain), 'whole_original_body': pin(body), 'whole_source': structured(source),
                                  'whole_holders': structured(held), 'whole_phase': structured(phase), 'whole_numerical': structured(numbers),
                                  'source_operands': numbers['references'], 'unaddressed': numbers['unaddressed_source_operands'],
                                  'hidden': numbers['hidden_arguments']})
                    seen.add(domain); counts['views'] += 1; counts['visible_reference_operands'] += len(numbers['references'])
                counts['nonempty_records'] += 1; counts['body_bytes'] += len(body)
            domains[name] = {'population': len(events), 'empty': empty, 'nonempty': nonempty}
        records.append({'mode': mode, 'domains': domains})
    need(seen == set(sources) == set(holders) == set(numerical) == set(phase_at), 'complete parent simultaneous view population')
    need(set(parsed) == {(m['mode'], name, r['index']) for m in records for name, d in m['domains'].items() for r in d['nonempty']},
         'complete parent original parsed population')
    controls = {key: data[key + '_proof']['controls'] for key in ('admission', 'operand', 'holder', 'numerical')}
    for key, values in controls.items():
        need(len({v['name'] for v in values}) == len(values) and all(v['refusal'] and v['whole_candidate'] for v in values),
             'complete prerequisite genuine-control identities')
        counts[key + '_controls'] = len(values)
    return records, views, controls, counts


def reader(actual, name):
    path = Path('docs/audits') / FOLDERS[name] / 'verify.py'
    expected = runpy.run_path(str(path))['SUCCESS']
    need(set(actual) == {'command', 'status', 'stdout', 'stderr', 'instruments'}, 'closed complete actual parent prerequisite result')
    need(type(actual['status']) is int and actual['status'] == 0, 'actual parent prerequisite integer success')
    need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(path)], 'exact actual parent prerequisite command')
    need(actual['stdout'] == expected, 'complete actual parent prerequisite stdout')
    paths = (BASE / 'checks.py', path, Path('scripts/run_with_ram_guard.sh'))
    need(actual['instruments'] == {str(p): pin(p.read_bytes()) for p in paths}, 'complete actual parent prerequisite instruments')
    need(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', actual['stderr']),
         'complete actual parent prerequisite guard stream')


def qualify(p, registry, binding, records, views, controls, actual):
    need(set(p) == {'owner', 'scope', 'open', 'inputs', 'binding', 'contracts', 'completed', 'original_allocation', 'views', 'controls', 'actual_readers'},
         'closed complete parent witness')
    need(p['owner'] == (BASE / 'scope.txt').read_text().strip() and p['scope'] == SCOPE and same(p['open'], OPEN), 'exact finite parent and remaining scopes')
    need(same(p['inputs'], registry) and p['binding'] == pin((BASE / 'binding.json').read_bytes()), 'whole parent input identity')
    need(same(p['contracts'], binding['contracts']) and same(p['completed'], binding['completed']), 'complete unchanged parent and prerequisite contracts')
    need(same(p['original_allocation'], records), 'complete original parent record body phase allocation')
    need(len(p['views']) == len(views), 'complete parent view population')
    for a, b in zip(p['views'], views):
        need(set(a) == set(b), 'closed complete parent source view')
        need(same({k: a[k] for k in a if k not in ('source_operands', 'unaddressed', 'hidden')},
                  {k: b[k] for k in b if k not in ('source_operands', 'unaddressed', 'hidden')}), 'whole parent original source holder numerical association')
        need(same(a['source_operands'], b['source_operands']), 'complete parent visible source numerical operands')
        need(same(a['unaddressed'], b['unaddressed']) and same(a['hidden'], b['hidden']), 'complete parent unaddressed and hidden conservation')
    need(same(p['controls'], controls), 'complete prior semantic separating controls')
    need(set(p['actual_readers']) == set(FOLDERS), 'complete actual parent prerequisite population')
    for name, result in p['actual_readers'].items():
        reader(result, name)
        need(same(result, actual[name]), 'whole current actual parent prerequisite receipt')
    return True
