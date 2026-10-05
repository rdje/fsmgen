"""Finite source/publisher exception class inference; full frames stay open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-class-20261005')
RAW = Path('docs/audits/record-value-original-raw-20261005')
REVISION = '506b80e7c59be4f5b13556c5e234b94e6c804fee'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.1'
CLASS = 'unblessed_nonreference_scalar'
GUARDS = {
    'value': ('perl/FSM/Support/ISFRecordPortValues.pm', 'Invalid ISF record value: ',
              'confess "Invalid ISF record value: $_[1]\\n" unless $_[0];'),
    'metadata': ('perl/FSM/Support/ISFInterfacePortMetadata.pm', 'Invalid ISF interface port metadata: ',
                 'confess "Invalid ISF interface port metadata: $_[1]\\n" unless $_[0];'),
    'context': ('perl/FSM/Support/ISFRecordPortContexts.pm', 'Invalid ISF record context: ',
                'confess "Invalid ISF record context: $_[1]\\n" unless $_[0];'),
    'parser': ('perl/FSM/Adapter/ISF/Parser.pm', 'Error: ',
               'confess "Error: $context references aggregate type \'$type_name\'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables and packed record actor ports\\n"'),
}


def module(path):
    namespace = {'__name__': 'original_class_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


raw = module(RAW / 'verify.py')
primary = raw['primary']
require, load, same, sealed, identity = (raw[key] for key in ('require', 'load', 'same', 'sealed', 'identity'))


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done raw owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed class-intake task authority')
    start = task.index('- ID: `' + OWNER + '`'); end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed raw owner authority')
    domain = set(load(RAW / 'binding.json')['archives']) | {str(RAW)}
    require(set(binding['archives']) == domain, 'complete class prerequisite archive domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole class prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'complete committed class prerequisite bytes')
    raw['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def source_contracts():
    sources = load(primary['result_reader']['CAPTURE'] / 'binding.json')['sources']
    return {'sources': {key: sources[path]['body'] for key, (path, _, _) in GUARDS.items()},
            'observer': (primary['result_reader']['CAPTURE'] / 'observe.pl').read_text()}


def check_sources(contracts):
    require(set(contracts['sources']) == set(GUARDS), 'complete own exception source families')
    for key, (_, _, signature) in GUARDS.items():
        source = contracts['sources'][key]
        require('use Carp qw(confess);' in source and source.count(signature) == 1, 'exact own literal-string confess guard')
    require('my $error = $@;' in contracts['sources']['value']
            and '_require($ok, "$context has invalid resolved type: $error");' in contracts['sources']['value'],
            'exact source metadata catch/string interpolation')
    observer = contracts['observer']
    require(observer.count('my $json = JSON::PP->new->canonical;') == 1
            and not any(word in observer for word in ('allow_blessed', 'convert_blessed', 'allow_tags', 'allow_bignum')),
            'original publisher default object policy')
    require(observer.count('$error = $@;') == 3 and observer.count('die $error unless $ok;') == 3,
            'exact observer exception catch/direct rethrow')
    require('(graph(\\@args), $ok ? 1 : 0, $error, $primary, \\@local_warnings,' in observer
            and '(graph(\\@inputs), $ok ? 1 : 0, $error, (split(/\\n/, $error // \'\'))[0] // \'\',' in observer,
            'exact original raw error forwarding without reference coercion')


def scalar_boundary(row):
    require(row['reference_kind'] == '' and row['blessed_class'] is None
            and row['published'] == 1 and type(row['body']) is str
            and same(json.loads(row['encoded']), {'error': row['body']}), 'original scalar exception boundary')


def check_public(probe, contracts):
    require(probe['perl'] == 'v5.34.1' and probe['json_pp'] == contracts['json_runtime_version'] == '4.06',
            'public runtime version authority, not stale POD label')
    require(probe['carp'] == '1.52' and probe['scalar_util'] == '1.55', 'exact current native public control profile')
    require(contracts['embedded_pod_version'] == '4.05' and contracts['same_loaded_document_provider'] is True,
            'exact historical POD/provider mismatch provenance')
    getters = ('get_allow_blessed', 'get_convert_blessed', 'get_allow_tags', 'get_allow_bignum')
    require(set(probe['flags']) == set(getters) and all(same(probe['flags'][key], {'raw': '', 'effective': 0}) for key in getters),
            'current native original-publisher object flags')
    names = ['literal-confess', 'literal-die', 'literal-rethrow', 'object-die', 'object-confess',
             'object-rethrow', 'object-interpolation', 'unblessed-reference']
    require([row['name'] for row in probe['cases']] == names, 'complete genuine native class control population')
    rows = {row['name']: row for row in probe['cases']}
    for row in probe['cases']:
        require(type(row['accepted']) is int and row['accepted'] == 0, 'native probe genuinely raises exception')
    for name in ('literal-confess', 'literal-die', 'literal-rethrow', 'object-interpolation'):
        scalar_boundary(rows[name])
    for name in ('object-die', 'object-confess', 'object-rethrow'):
        row = rows[name]
        require(row['reference_kind'] == row['blessed_class'] == 'ClassProbeException'
                and row['body'] == rows['literal-die']['body'] == 'class probe literal\n'
                and row['published'] == 0 and row['encoded'] is None
                and row['encoding_error'].startswith("encountered object 'class probe literal\n', but neither allow_blessed"),
                'genuine printable-match object class and publisher refusal')
    row = rows['unblessed-reference']
    require(row['reference_kind'] == 'HASH' and row['blessed_class'] is None and row['published'] == 1
            and same(json.loads(row['encoded']), {'error': {'reason': 'class probe reference'}}),
            'genuine unblessed reference publishes distinct hash wire kind')
    controls = []
    for name in ('object-die', 'object-confess', 'object-rethrow', 'unblessed-reference'):
        try:
            scalar_boundary(rows[name])
        except ValueError as error:
            require(str(error) == 'original scalar exception boundary', 'intended genuine native class rejection')
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green genuine native class control: ' + name)
    return controls


def expected_models():
    models = []
    for mode in load(primary['BASE'] / 'proofs.json')['proofs']:
        cases = []
        for domain, rows in (('api', mode['complete_source_API_primary_models']), ('parses', mode['parsers'])):
            for row in rows:
                message = row['primary']
                if message is None:
                    continue
                families = [key for key, (_, prefix, _) in GUARDS.items() if message.startswith(prefix)]
                require(len(families) == 1, 'exact source-modeled exception family')
                cases.append({'domain': domain, 'index': row['index'], 'primary': message,
                              'source_family': families[0], 'inferred_class': CLASS})
        models.append({'mode': mode['mode'], 'cases': cases})
    return models


def check_models(models, source):
    check_sources(source)
    expected = expected_models()
    inventories = load(RAW / 'proofs.json')['inventories']
    require([row['mode'] for row in models] == [row['mode'] for row in expected], 'complete source class mode population')
    for actual, wanted, captured in zip(models, expected, inventories):
        require([(r['domain'], r['index']) for r in actual['cases']] == [(r['domain'], r['index']) for r in wanted['cases']],
                'complete source exception class allocation')
        for row, want in zip(actual['cases'], wanted['cases']):
            require(row['inferred_class'] == CLASS, 'intended source scalar exception class')
            require(same(row, want), 'complete own source class/primary family')
        native = {(domain, row['index']): row for domain, rows in captured['domains'].items() for row in rows['nonempty']}
        require(set(native) == {(r['domain'], r['index']) for r in wanted['cases']}, 'all raw exceptions join source class models')
        for row in wanted['cases']:
            body = native[(row['domain'], row['index'])]['body']
            require(type(body) is str and body.splitlines()[0] == row['primary'], 'own source/raw scalar exception class join')


def main():
    authenticate()
    source = source_contracts()
    probe, contracts = load(BASE / 'native-public-probe.json'), load(BASE / 'public-contracts.json')
    genuine = check_public(probe, contracts)
    models = expected_models()
    check_models(models, source)
    controls = []
    mutations = [
        ('changed-literal-guard', lambda m, s, p, c: s['sources'].update(value=s['sources']['value'].replace(GUARDS['value'][2], 'confess $_[1];')), 'exact own literal-string confess guard'),
        ('changed-publisher-policy', lambda m, s, p, c: s.update(observer=s['observer'].replace('JSON::PP->new->canonical;', 'JSON::PP->new->canonical->allow_blessed;')), 'original publisher default object policy'),
        ('promoted-native-class', lambda m, s, p, c: m[0]['cases'][0].update(inferred_class='blessed_HASH'), 'intended source scalar exception class'),
        ('omitted-class-member', lambda m, s, p, c: m[0]['cases'].pop(), 'complete source exception class allocation'),
        ('POD-version-as-runtime', lambda m, s, p, c: c.update(json_runtime_version=c['embedded_pod_version']), 'public runtime version authority, not stale POD label'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(v) for v in (models, source, probe, contracts)]
        mutate(*changed)
        try:
            check_public(changed[2], changed[3])
            check_models(changed[0], changed[1])
        except ValueError as error:
            require(str(error) == cause, 'intended source class control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green source class control: ' + name)
    proof = {'models': models, 'genuine_native_class_controls': genuine, 'source_controls': controls,
             'source_contract_identity': identity(json.dumps(source, sort_keys=True).encode()),
             'scope': 'Finite class inference from source and original publisher; no original pre-serialization measurement or historical Carp/frame identity.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved source/publisher class proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed class producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS finite source/publisher class contracts and genuine native object refusals; full frames/coordinates/address meanings stay open.')


if __name__ == '__main__':
    main()
