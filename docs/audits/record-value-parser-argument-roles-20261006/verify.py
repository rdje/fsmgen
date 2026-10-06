"""Finite source-expression to visible-header roles, without encoding claims."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-argument-roles-20261006')
ORDER = Path('docs/audits/record-value-parser-function-order-20261006')
CHECKS = Path('docs/audits/parser-function-order-checks-20261006')
REVISION = '0fa36cca38bb7096dc4513e0020a6803e6aa7c8b'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.4.3.1'


def module(path):
    ns = {'__name__': 'parser_argument_roles_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


prior = module(ORDER / 'verify.py')
require, same, identity, load = (prior[key] for key in ('require', 'same', 'identity', 'load'))


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole saved argument-role product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed argument-role producer cannot publish')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER,
            'exact completed parser-order intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']])
    require(same(identity(task), binding['task_identity']), 'whole committed argument-role intake task')
    text = task.decode(); start = text.index('- ID: `' + OWNER + '`'); end = text.index('\n- ID:', start + 1)
    require(text[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in binding['owner_body'],
            'whole done parser-order owner')
    require(set(binding['archives']) == {str(ORDER), str(CHECKS)}, 'complete order and actual receipt intake')
    for directory, pins in binding['archives'].items():
        committed = prior['committed_members'](REVISION, directory)
        actual = {str(p): p.read_bytes() for p in Path(directory).iterdir()}
        require(actual == committed and same(pins, {p: identity(raw) for p, raw in actual.items()}),
                'whole committed order and actual receipt members')
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), prior['members'](BASE)), 'whole argument-role seal')
    receipts = []
    for programme in [str(ORDER / 'verify.py'), str(CHECKS / 'verify_seal.py')]:
        command = ['python3', '-B', programme]
        run = subprocess.run(command, capture_output=True, text=True)
        require(run.returncode == 0, 'complete parser-order prerequisite replay: ' + programme)
        receipts.append({'command': command, 'status': run.returncode,
                         'stdout': run.stdout, 'stderr': run.stderr})
    return receipts


def models():
    source = prior['module'](prior['MODELS'] / 'verify.py')
    inventory, authored, _ = source['inputs']()
    paths = source['model']['derive'](inventory, authored, require, identity)
    require(same(paths, load(prior['MODELS'] / 'proofs.json')['paths']), 'complete independent source argument paths')
    packages = {unit: inventory['source_units'][unit]['package'] for unit in ('facade', 'parser')}
    require(packages['parser'] + '->new(debug => $debug)' in inventory['source_units']['facade']['body']
            and 'return bless {' in inventory['source_units']['parser']['body']
            and 'my $self = bless {' in inventory['source_units']['facade']['body'],
            'whole own facade/parser constructor display-role source')
    result = []
    for path in paths:
        frames = []
        for frame in reversed(path['active_own_ancestry_outer_to_inner']):
            arguments = []
            for position, arg in enumerate(frame['supplied_arguments']):
                role = dict(arg, position=position)
                if 'reference_kind' in arg:
                    role['match'] = 'source reference role / visible kind only'
                    role['display_class'] = (packages['facade'] if arg['role'] == 'facade receiver' else
                                             packages['parser'] if arg['role'] == 'contained parser receiver' else None)
                elif arg['role'] == 'guard predicate':
                    require(type(arg['source_value']) is int and arg['source_value'] == 0,
                            'source predicate normalized logical false')
                    role['match'] = 'logical false compatible with visible false scalar; no literal or flag inference'
                    role['native_scalar_encoding'] = 'not measured'
                else:
                    require(type(arg['source_value']) in (str, int), 'finite source scalar expression kind')
                    role['match'] = 'source expression glyphs / visible scalar or proper nonempty prefix'
                    role['native_scalar_encoding'] = 'not measured'
                arguments.append(role)
            frames.append({'function': frame['function'], 'whole_source_body': frame['whole_source_body'],
                           'parameters': frame['parameters'], 'arguments': arguments})
        result.append({'parse_index': path['parse_index'], 'whole_source': path['whole_source'], 'frames': frames})
    return result


TOKEN = re.compile(r'(?:(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*=)?(?:HASH|ARRAY)\(0x[0-9a-fA-F]+\)|undef|-?[0-9]+|"(?:\\.|[^"\\])*"(?:\.\.\.)?|\.\.\.')
REFERENCE = re.compile(r'(?:(?P<class>(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*)=)?(?P<kind>HASH|ARRAY)\((?P<address>0x[0-9a-fA-F]+)\)')


def arguments(call, function):
    require(call.startswith(function + '(') and call.endswith(')'), 'finite parser argument header')
    text = call[len(function) + 1:-1]
    result, offset = [], 0
    while offset < len(text):
        token = TOKEN.match(text, offset)
        require(token is not None, 'complete finite parser visible argument grammar')
        raw = token.group()
        row = {'raw': raw, 'offset_bytes': len(text[:offset].encode())}
        ref = REFERENCE.fullmatch(raw)
        if ref:
            row.update(lexical_kind='reference', display_class=ref['class'], reference_kind=ref['kind'],
                       opaque_address_lexeme=ref['address'], referent_contents='not measured', native_identity='not measured')
        elif raw.startswith('"'):
            truncated = raw.endswith('...')
            row.update(lexical_kind='quoted scalar', display_text=json.loads(raw[:-3] if truncated else raw), truncated=truncated)
        elif raw == '...':
            row.update(lexical_kind='remaining arguments')
        else:
            row.update(lexical_kind='undef token' if raw == 'undef' else 'integer token',
                       display_text=raw, truncated=False)
        result.append(row)
        offset = token.end()
        if offset < len(text):
            require(text[offset:offset + 2] == ', ', 'finite parser argument separator')
            offset += 2
    require(', '.join(row['raw'] for row in result) == text, 'lossless entire visible parser argument header')
    return result


def footprint(got, wanted):
    require(len(got) == len(wanted), 'complete parser supplied argument membership')
    for actual, role in zip(got, wanted, strict=True):
        if 'reference_kind' in role:
            require(actual['lexical_kind'] == 'reference' and actual['reference_kind'] == role['reference_kind']
                    and actual['display_class'] == role['display_class'], 'source parser reference display role/kind')
        elif role['role'] == 'guard predicate':
            require(actual['lexical_kind'] in ('quoted scalar', 'integer token') and not actual['truncated']
                    and actual['display_text'] in ('', '0'), 'normalized false / visible false compatibility')
        else:
            require(actual['lexical_kind'] in ('quoted scalar', 'integer token'), 'source parser scalar display kind')
            value = str(role['source_value'])
            if actual['truncated']:
                require(actual['lexical_kind'] == 'quoted scalar' and 0 < len(actual['display_text']) < len(value)
                        and value.startswith(actual['display_text']), 'source parser proper visible truncation prefix')
            else:
                require(actual['display_text'] == value, 'source parser complete visible scalar role')


def check(actual_models, expected, native, original, order):
    require(same(actual_models, expected), 'whole source parser argument expression/role/kind models')
    # Function-order semantics reexecute for the supplied body. Exact original
    # body conservation follows the argument check so controls can demonstrate
    # a separating role oracle rather than merely an earlier byte-pin refusal.
    intervals = prior['check'](order, order, native, native)
    paths = {path['parse_index']: path for path in actual_models}
    observations = []
    for mode, source_mode, canonical in zip(intervals, native, original, strict=True):
        cases = []
        for case in mode['cases']:
            wanted = paths[case['index']]
            row = next(r for r in source_mode['domains']['parses']['nonempty'] if r['index'] == case['index'])
            phases = []
            for phase in case['phases']:
                headers = [row['segments'][position] for position in phase['segment_positions']]
                require(len(headers) == len(wanted['frames']), 'complete parser argument frame membership')
                visible = []
                for header, frame in zip(headers, wanted['frames'], strict=True):
                    parsed = arguments(header['call'], frame['function'])
                    footprint(parsed, frame['arguments'])
                    visible.append({'function': frame['function'], 'source_arguments': frame['arguments'], 'display': parsed})
                phases.append({'phase': phase['phase'], 'visible_source_roles': visible})
            original_row = next(r for r in canonical['domains']['parses']['nonempty'] if r['index'] == case['index'])
            require(row['body'] == original_row['body'], 'whole original argument-header/body conservation')
            cases.append({'index': case['index'], 'source': wanted['whole_source'],
                          'body': row['body_identity'], 'phases': phases})
        observations.append({'mode': mode['mode'], 'cases': cases})
    return observations


def controls(expected, original, order):
    trace = module(prior['RAW'] / 'trace_inventory.py')['inventory']

    def change(native, old, new, member=0):
        row = native[0]['domains']['parses']['nonempty'][member]
        require(row['body'].count(old) >= 1, 'actual original visible control operand')
        body = row['body'].replace(old, new, 1)
        require(body != row['body'], 'genuine native argument-body control')
        row.update(body=body, body_identity=identity(body.encode()), **trace(body))

    def same_kind_reference_swap(native):
        row = native[0]['domains']['parses']['nonempty'][0]
        frame = next(s for s in row['segments'] if s['kind'] == 'frame'
                     and s['call'].startswith('FSM::Support::ISFRecordPortContexts::_clauses('))
        tokens = arguments(frame['call'], 'FSM::Support::ISFRecordPortContexts::_clauses')
        require(tokens[1]['raw'] != tokens[2]['raw'], 'genuine distinct same-kind reference lexemes')
        body = row['body'].replace(frame['call'], frame['call'].replace(
            tokens[1]['raw'] + ', ' + tokens[2]['raw'], tokens[2]['raw'] + ', ' + tokens[1]['raw']), 1)
        require(body != row['body'], 'genuine same-kind reference display swap')
        row.update(body=body, body_identity=identity(body.encode()), **trace(body))

    changes = [
        ('lost-source-role', lambda m, n: m[0]['frames'][0]['arguments'].pop(), 'whole source parser argument expression/role/kind models'),
        ('Boolean-source-truth-kind', lambda m, n: m[0]['frames'][0]['arguments'][0].update(source_value=False), 'whole source parser argument expression/role/kind models'),
        ('invented-referent-measurement', lambda m, n: m[0]['frames'][1]['arguments'][1].update(referent_contents='measured'), 'whole source parser argument expression/role/kind models'),
        ('wrong-write-role', lambda m, n: change(n, '"write", "transaction', '"read", "transaction'), 'source parser complete visible scalar role'),
        ('wrong-operand', lambda m, n: change(n, '_assignment("value.flag", 1,', '_assignment("value.flag", 2,'), 'source parser complete visible scalar role'),
        ('wrong-reference-kind', lambda m, n: change(n, '_reference("value.flag", HASH(', '_reference("value.flag", ARRAY('), 'source parser reference display role/kind'),
        ('wrong-parser-class', lambda m, n: change(n, 'FSM::Adapter::ISF::Parser=HASH(', 'borrowed::Parser=HASH('), 'source parser reference display role/kind'),
        ('lost-option-argument', lambda m, n: change(n, '"whole_output_writes_only", 1)', '"whole_output_writes_only")'), 'complete parser supplied argument membership'),
        ('wrong-option-key', lambda m, n: change(n, '"allow_record", 1)', '"allow_aggregate", 1)', 1), 'source parser complete visible scalar role'),
        ('false-predicate-became-true', lambda m, n: change(n, '_require("",', '_require(1,'), 'normalized false / visible false compatibility'),
        ('cleared-truncation-marker', lambda m, n: change(n, 'field writes are "...', 'field writes are "'), 'source parser complete visible scalar role'),
        ('empty-truncation-prefix', lambda m, n: change(n, '"transaction \'main\' set target record output field writes are "...', '""...'), 'source parser proper visible truncation prefix'),
        ('borrowed-truncation-prefix', lambda m, n: change(n, 'field writes are "...', 'borrowed writes are "...'), 'source parser proper visible truncation prefix'),
        ('invented-remaining-arguments', lambda m, n: change(n, '_assignment("value.flag", 1,', '_assignment("value.flag", ...,'), 'source parser scalar display kind'),
        ('truth-preserving-display-change', lambda m, n: change(n, '_require("",', '_require(0,'), 'whole original argument-header/body conservation'),
        ('same-kind-reference-attribution-gap', lambda m, n: same_kind_reference_swap(n), 'whole original argument-header/body conservation'),
        ('shorter-compatible-prefix-policy-gap', lambda m, n: change(n, '"transaction \'main\' set target record output field writes are "...', '"transaction "...'), 'whole original argument-header/body conservation'),
    ]
    results = []
    for name, mutate, cause in changes:
        modeled, native = copy.deepcopy(expected), copy.deepcopy(original)
        mutate(modeled, native)
        try:
            check(modeled, expected, native, original, order)
        except ValueError as error:
            require(str(error) == cause, 'intended parser argument control: ' + name + ': ' + str(error))
            results.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green parser argument role control: ' + name)
    return results


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    receipts = authenticate()
    expected = models()
    order = prior['source_models']()
    native = load(prior['RAW'] / 'proofs.json')['inventories']
    save('proofs.json', {'models': expected, 'observations': check(expected, expected, native, native, order),
                        'controls': controls(expected, native, order),
                        'scope': 'Source expressions bind visible lexical roles only. Normalized false is not a native literal; whole referents, scalar flags, formatter, identity, coordinates and nested API/helper joins remain unmeasured or separately owned.'})
    save('prerequisite-replays.json', receipts)
    save('book-native-proof.json', module(BASE / 'book.py')['proof']((BASE / 'book-input.html').read_text()))
    if args.seal:
        save('manifest.json', prior['members'](BASE))
    print('PASS complete finite parser source-expression/visible-header roles; scalar encoding, referents and wider joins remain open.')


if __name__ == '__main__':
    main()
