"""Whole nested error-variable conservation; inherited stack meanings stay open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-forwarding-20261005')
NESTED = Path('docs/audits/record-value-original-nested-inputs-20261005')
REVISION = '1ef164a17571bc071e8efd919bd0d8d898dfa3eb'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.2.3.1'


def module(path):
    namespace = {'__name__': 'forwarding_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


nested = module(NESTED / 'verify.py')
primary = nested['primary']
require, load, same, sealed = (nested[key] for key in ('require', 'load', 'same', 'sealed'))
identity = primary['result_reader']['identity']
CONTRACTS = {
    'capture_eval': '$ok = eval {$result = $operation->(@args); 1}; $error = $@;',
    'capture_publish': '(graph(\\@args), $ok ? 1 : 0, $error, $primary, \\@local_warnings,',
    'capture_rethrow': 'die $error unless $ok;',
    'value_eval': "my $ok = eval {\n        capture_interface_port_metadata({inputs => [{name => 'value', type => 'resolved_value',\n            width => $checked->{width}, type_spec => $checked}], outputs => []});\n        1;\n    };",
    'value_catch': 'my $error = $@;',
    'value_forward': '_require($ok, "$context has invalid resolved type: $error");',
    'value_continue': '_closed_type($spec, $context);',
    'value_throw': 'confess "Invalid ISF record value: $_[1]\\n" unless $_[0];',
}


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done nested-input owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed forwarding intake task')
    start = task.index('- ID: `' + OWNER + '`'); end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed nested-input owner')
    require(set(binding['archives']) == set(load(NESTED / 'binding.json')['archives']) | {str(NESTED)},
            'complete forwarding prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole forwarding prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed forwarding prerequisite bytes')
    nested['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def check_sources(source):
    nested['check_sources'](source)
    observer = source['observer']
    observer = observer[observer.index('sub call_api {'):observer.index('sub copy_value {')]
    value = source['value']
    validate = value[value.index('sub _validate_type {'):value.index('sub _closed_type {')]
    guard = value[value.index('sub _require {'):]
    for key, statement in CONTRACTS.items():
        body = observer if key.startswith('capture_') else guard if key == 'value_throw' else validate
        require(body.count(statement) == 1, 'exact source catch/forward/new-throw contract')
    require(observer.index(CONTRACTS['capture_eval']) < observer.index(CONTRACTS['capture_publish'])
            < observer.index(CONTRACTS['capture_rethrow']), 'capture eval/publish/direct-rethrow ordering')
    require([validate.index(CONTRACTS[key]) for key in ('value_eval', 'value_catch', 'value_forward', 'value_continue')]
            == sorted(validate.index(CONTRACTS[key]) for key in ('value_eval', 'value_catch', 'value_forward', 'value_continue')),
            'Value eval/catch/forward/continuation ordering')


def public_check(probe):
    require({key: probe[key] for key in ('perl', 'carp', 'json_pp')}
            == {'perl': 'v5.34.1', 'carp': '1.52', 'json_pp': '4.06'}, 'current public probe runtime profile')
    cases = {row['name']: row for row in probe['cases']}
    require(len(cases) == len(probe['cases']) == 6 and set(cases) == {
        'newline-string', 'no-newline-string', 'explicit-rethrow', 'implicit-rethrow',
        'interpolated-outer', 'altering-die-hook'}, 'complete public forwarding probe domain')
    require(all(row['accepted'] == 0 and row['reference_kind'] == '' for row in cases.values()),
            'actual public probe failures remain scalar')
    inner = probe['inner']
    require(type(inner) is str and inner.startswith('forward probe inner\n') and inner.endswith('\n'),
            'public probe whole nonempty newline inner value')
    require(cases['newline-string']['error'] == 'forward probe literal\n'
            and cases['explicit-rethrow']['error'] == inner, 'explicit newline/rethrow preserves entire operand')
    require(cases['no-newline-string']['error'].startswith('forward probe literal at ')
            and cases['implicit-rethrow']['error'].startswith(inner + '\t...propagated at ')
            and cases['altering-die-hook']['error'] == 'forward probe hook changed\n',
            'genuine missing-newline/implicit/hook countercases')
    prefix = 'forward probe outer: ' + inner + '\n'
    require(cases['interpolated-outer']['error'].startswith(prefix)
            and len(cases['interpolated-outer']['error']) > len(prefix), 'public new throw conserves interpolated whole operand')
    return {'cases': list(cases), 'explicit_rethrow': 'whole operand equal',
            'new_throw': 'whole interpolated operand prefix',
            'countercases': ['missing newline adds location', 'implicit rethrow adds propagation', 'die hook replaces operand'],
            'scope': 'Current public interpreter behavior; original hook state/provider bytes were not measured.'}


def expected_models(source, records):
    check_sources(source)
    models = []
    for modeled in load(NESTED / 'proofs.json')['models']:
        pairs = []
        for pair in modeled['pairs']:
            inner = records[modeled['mode']]['api'][pair['capture_api']]['error']
            require(type(inner) is str and inner.startswith(pair['metadata_primary'] + '\n') and inner.endswith('\n'),
                    'whole qualified source inner error-variable value')
            prefix = 'Invalid ISF record value: ' + pair['context'] + ' has invalid resolved type: ' + inner + '\n'
            pairs.append({'scope_api': pair['scope_api'], 'capture_api': pair['capture_api'],
                          'helper': pair['helper'], 'context': pair['context'], 'metadata_primary': pair['metadata_primary'],
                          'inner_value': inner, 'inner_identity': identity(inner.encode()),
                          'outer_prefix': prefix, 'prefix_identity': identity(prefix.encode()),
                          'phases': ['capture failed eval/raw publish', 'explicit whole-string rethrow',
                                     'Value failed eval/catch', 'context interpolation', 'new literal Value confess']})
        models.append({'mode': modeled['mode'], 'pairs': pairs})
    return models


def check(models, expected, records, source):
    check_sources(source)
    require(same(models, expected), 'complete source forwarding pair/context/value/phase models')
    proof = []
    for modeled in models:
        rows = []
        for pair in modeled['pairs']:
            inner, outer = (records[modeled['mode']]['api'][pair[key]] for key in ('capture_api', 'scope_api'))
            require(inner['kind'] == 'capture' and outer['kind'] == 'scope'
                    and inner['accepted'] == outer['accepted'] == 0 and inner['helper'] == outer['helper'] == pair['helper'],
                    'actual failed nested forwarding allocation')
            require(type(inner['error']) is str and inner['error'] == pair['inner_value'], 'whole actual inner error-variable conservation')
            require(type(outer['error']) is str and outer['error'].startswith(pair['outer_prefix']),
                    'entire source inner operand/context conserved in new outer prefix')
            suffix = outer['error'][len(pair['outer_prefix']):]
            require(bool(suffix), 'new outer throw has separate nonempty trace suffix')
            rows.append({'scope_api': pair['scope_api'], 'capture_api': pair['capture_api'],
                         'inner': identity(inner['error'].encode()), 'outer': identity(outer['error'].encode()),
                         'prefix': pair['prefix_identity'], 'unqualified_outer_suffix': identity(suffix.encode())})
        proof.append({'mode': modeled['mode'], 'pairs': rows})
    return proof


def main():
    authenticate()
    source = nested['sources']()
    capture = primary['result_reader']['CAPTURE']
    records = {mode: load(capture / (mode + '.json')) for mode in ('ordinary', 'storable', 'controls')}
    expected = expected_models(source, records)
    observed = check(expected, expected, records, source)
    public = public_check(load(BASE / 'native-public-probe.json'))
    fresh = subprocess.run(['perl', str(BASE / 'public_probe.pl')], capture_output=True, text=True)
    require(fresh.returncode == 0 and fresh.stderr == '', 'fresh public probe completes without warnings')
    require(same(public_check(json.loads(fresh.stdout)), public), 'fresh public forwarding semantics conserve')
    controls = []
    mutations = [
        ('implicit-source-rethrow', lambda m, n, s: s.update(observer=s['observer'].replace(CONTRACTS['capture_rethrow'], 'die unless $ok;', 1)), 'exact source catch/forward/new-throw contract'),
        ('changed-Value-forward', lambda m, n, s: s.update(value=s['value'].replace(CONTRACTS['value_forward'], '_require($ok, "$context has invalid resolved type");')), 'exact source catch/forward/new-throw contract'),
        ('changed-new-throw', lambda m, n, s: s.update(value=s['value'].replace(CONTRACTS['value_throw'], 'die $_[1] unless $_[0];')), 'exact source catch/forward/new-throw contract'),
        ('borrowed-pair-value', lambda m, n, s: m[0]['pairs'][0].update(inner_value=m[0]['pairs'][1]['inner_value']), 'complete source forwarding pair/context/value/phase models'),
        ('wrong-context-model', lambda m, n, s: m[0]['pairs'][0].update(context="root 'held'"), 'complete source forwarding pair/context/value/phase models'),
        ('omitted-pair', lambda m, n, s: m[0]['pairs'].pop(), 'complete source forwarding pair/context/value/phase models'),
        ('wrong-phase-order', lambda m, n, s: m[0]['pairs'][0]['phases'].reverse(), 'complete source forwarding pair/context/value/phase models'),
        ('changed-inner-body', lambda m, n, s: n['ordinary']['api'][m[0]['pairs'][0]['capture_api']].update(error=m[0]['pairs'][0]['inner_value'] + 'changed\n'), 'whole actual inner error-variable conservation'),
        ('borrowed-outer-body', lambda m, n, s: n['ordinary']['api'][m[0]['pairs'][0]['scope_api']].update(error=n['ordinary']['api'][m[0]['pairs'][1]['scope_api']]['error']), 'entire source inner operand/context conserved in new outer prefix'),
        ('omitted-inner-tail', lambda m, n, s: n['ordinary']['api'][m[0]['pairs'][0]['scope_api']].update(error=m[0]['pairs'][0]['outer_prefix'].replace(m[0]['pairs'][0]['inner_value'], m[0]['pairs'][0]['metadata_primary'] + '\n') + 'trace'), 'entire source inner operand/context conserved in new outer prefix'),
        ('wrong-outer-context', lambda m, n, s: n['ordinary']['api'][m[0]['pairs'][0]['scope_api']].update(error=n['ordinary']['api'][m[0]['pairs'][0]['scope_api']]['error'].replace("root 'packet'", "root 'held'", 1)), 'entire source inner operand/context conserved in new outer prefix'),
        ('missing-new-throw-suffix', lambda m, n, s: n['ordinary']['api'][m[0]['pairs'][0]['scope_api']].update(error=m[0]['pairs'][0]['outer_prefix']), 'new outer throw has separate nonempty trace suffix'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, records, source)]; mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended forwarding control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green whole nested forwarding control: ' + name)
    proof = {'models': expected, 'forwarding': observed, 'public_contract': public, 'controls': controls,
             'scope': 'Entire inner scalar is a source-variable operand, not intended authority for its full stack meaning. New outer trace remains unqualified.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved nested forwarding proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed forwarding producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS whole finite nested catch/explicit-rethrow/interpolation/new-throw prefix conservation; inherited/full trace meanings remain open.')


if __name__ == '__main__':
    main()
