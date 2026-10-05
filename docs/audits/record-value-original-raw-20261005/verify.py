"""Qualify raw capture/grammar only; semantic frame/address siblings stay open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-raw-20261005')
PRIMARY = Path('docs/audits/record-value-original-primary-20261005')
REVISION = '7812abb761715ab5df55162e824d73b3a2433ec4'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.1'
MODES = ('ordinary', 'storable', 'controls')


def module(path):
    namespace = {'__name__': 'original_raw_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


primary = module(PRIMARY / 'verify.py')
require, load, same, sealed, identity = (primary[key] for key in ('require', 'load', 'same', 'sealed', 'identity'))
trace = module(BASE / 'trace_inventory.py')['inventory']
CAPTURE = primary['result_reader']['CAPTURE']


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact completed primary intake allocation')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed raw-intake task authority')
    start = task.index('- ID: `' + OWNER + '`'); end = task.index('\n- ID:', start + 1)
    require(binding['owner_body'] == task[start:end] and '\n  Status: `done`\n' in task[start:end], 'whole completed primary owner body')
    domain = set(load(PRIMARY / 'binding.json')['archives']) | {str(PRIMARY)}
    require(set(binding['archives']) == domain, 'complete raw prerequisite archive domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole raw prerequisite archive identity')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'whole committed raw prerequisite member')
    primary['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def model(records):
    result = []
    for mode in MODES:
        native = records[mode]
        domains = {}
        for domain in ('api', 'copies', 'parses', 'test_run'):
            members = native[domain] if domain != 'test_run' else [native['test_run']]
            empty, nonempty = [], []
            for index, row in enumerate(members):
                error = row['error']
                require(type(error) is str, 'raw serialized error kind')
                if not error:
                    empty.append(index)
                    continue
                context = {key: row[key] for key in ('kind', 'caller', 'helper', 'parse') if key in row}
                nonempty.append({'index': index, 'context': context, 'wire_kind': 'string', 'body': error,
                                 'body_identity': identity(error.encode()), **trace(error)})
            domains[domain] = {'population': len(members), 'empty_string_members': empty, 'nonempty': nonempty}
        result.append({'mode': mode, 'domains': domains})
    return result


def check(inventories, records):
    require([row['mode'] for row in inventories] == list(MODES), 'complete raw mode population')
    expected = model(records)
    for actual_mode, expected_mode in zip(inventories, expected):
        require(set(actual_mode) == {'mode', 'domains'}, 'closed raw mode properties')
        require(set(actual_mode['domains']) == set(expected_mode['domains']), 'complete raw error domains')
        for domain, wanted in expected_mode['domains'].items():
            actual = actual_mode['domains'][domain]
            require(set(actual) == {'population', 'empty_string_members', 'nonempty'}, 'closed raw domain properties')
            require(type(actual['population']) is int and actual['population'] == wanted['population']
                    and same(actual['empty_string_members'], wanted['empty_string_members'])
                    and same([row['index'] for row in actual['nonempty']], [row['index'] for row in wanted['nonempty']]),
                    'complete raw empty/nonempty member allocation')
            for row, want in zip(actual['nonempty'], wanted['nonempty']):
                require(row['wire_kind'] == 'string' and type(row['body']) is str, 'raw serialized error kind')
                require(same(row['context'], want['context']), 'own complete raw source context')
                require(row['body'] == want['body'] and same(row['body_identity'], want['body_identity']), 'whole raw capture body identity')
                require(same(row['segments'], want['segments']), 'complete frame and physical line segmentation')
                require(same(row['opaque_lexemes'], want['opaque_lexemes']), 'complete opaque address lexeme inventory')
                require(set(row) == set(want), 'closed raw inventory row properties')


def controls(inventories, records):
    result = []

    def reject(name, mutate, cause):
        bad = copy.deepcopy(inventories)
        mutate(bad)
        try:
            check(bad, records)
        except ValueError as error:
            require(str(error) == cause, 'intended raw inventory control cause: ' + name)
            result.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green raw inventory control: ' + name)

    reject('omit-nonempty-member', lambda n: n[0]['domains']['api']['nonempty'].pop(), 'complete raw empty/nonempty member allocation')
    reject('omit-empty-member', lambda n: n[0]['domains']['copies']['empty_string_members'].pop(), 'complete raw empty/nonempty member allocation')
    reject('alter-wire-kind', lambda n: n[0]['domains']['api']['nonempty'][0].update(wire_kind='object'), 'raw serialized error kind')
    reject('alter-body-byte', lambda n: n[0]['domains']['api']['nonempty'][0].update(body=n[0]['domains']['api']['nonempty'][0]['body'] + '\n'), 'whole raw capture body identity')
    reject('borrow-context', lambda n: n[0]['domains']['api']['nonempty'][0]['context'].update(helper=1), 'own complete raw source context')
    reject('omit-frame', lambda n: n[0]['domains']['api']['nonempty'][0]['segments'].pop(), 'complete frame and physical line segmentation')
    reject('wrong-coordinate', lambda n: n[0]['domains']['api']['nonempty'][0]['segments'][2].update(line=1), 'complete frame and physical line segmentation')
    own_address = inventories[0]['domains']['api']['nonempty'][0]['opaque_lexemes'][0]['lexeme']
    borrowed = next(row['lexeme'] for row in inventories[1]['domains']['api']['nonempty'][0]['opaque_lexemes']
                    if row['lexeme'] != own_address)
    reject('borrow-address-lexeme', lambda n: n[0]['domains']['api']['nonempty'][0]['opaque_lexemes'][0].update(lexeme=borrowed), 'complete opaque address lexeme inventory')
    reject('address-span', lambda n: n[0]['domains']['api']['nonempty'][0]['opaque_lexemes'][0].update(start_bytes=0), 'complete opaque address lexeme inventory')
    return result


def main():
    authenticate()
    records = {mode: load(CAPTURE / (mode + '.json')) for mode in MODES}
    inventories = model(records)
    check(inventories, records)
    proof = {'inventories': inventories, 'controls': controls(inventories, records),
             'scope': 'Complete serialized raw body/context/grammar conservation only. Native exception class, frame meaning, source coordinates and address lifetimes remain unqualified.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved raw inventory proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed producer cannot publish a new proof')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete lossless original raw-error inventory and intended controls; frame/class/coordinate/address meanings remain open.')


if __name__ == '__main__':
    main()
