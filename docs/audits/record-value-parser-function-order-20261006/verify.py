"""Join source-selected own parser order with complete retained raw refusals.

Argument displays, coordinates and opaque outer frames are conserved bytes,
not qualified meanings. This reader never starts an original native capture.
"""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-function-order-20261006')
MODELS = Path('docs/audits/record-value-parser-path-models-20261006')
RAW = Path('docs/audits/record-value-original-raw-20261005')
OBSERVER = Path('docs/audits/record-value-original-observer-boundaries-20261005')
REVISION = '179476c834e64e85fca5be4044a47fda87ddbd7d'
PREFIX = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2'
PREREQUISITES = {str(MODELS): PREFIX + '.4.2', str(RAW): 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.1',
                 str(OBSERVER): PREFIX + '.3.2'}
OWN_PACKAGES = ('FSM::Adapter::ISF::', 'FSM::Support::ISFRecordPortContexts::')


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(path.read_bytes())


def module(path):
    namespace = {'__name__': 'parser_function_order_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def members(directory):
    require(all(p.is_file() and not p.is_symlink() for p in directory.iterdir()),
            'regular complete own audit members')
    return {p.name: identity(p.read_bytes()) for p in directory.iterdir()
            if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole saved parser function-order product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed function-order producer cannot publish')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def committed_members(revision, directory):
    raw = subprocess.check_output(['git', 'archive', revision, directory])
    with tarfile.open(fileobj=io.BytesIO(raw), mode='r:') as archive:
        return {entry.name: archive.extractfile(entry).read() for entry in archive.getmembers()
                if entry.isfile() and str(Path(entry.name).parent) == directory}


def authenticate():
    binding = load(BASE / 'binding.json')
    revision = subprocess.check_output(['git', 'rev-parse', REVISION], text=True).strip()
    require(binding['revision'] == revision and set(binding['archives']) == set(PREREQUISITES),
            'exact complete committed function-order prerequisite domain')
    task = subprocess.check_output(['git', 'show', revision + ':' + binding['task_path']])
    require(same(identity(task), binding['task_identity']), 'whole committed intake task identity')
    for directory, owner in PREREQUISITES.items():
        start = task.decode().index('- ID: `' + owner + '`')
        end = task.decode().index('\n- ID:', start + 1)
        require(task.decode()[start:end] == binding['owners'][owner]
                and '\n  Status: `done`\n' in binding['owners'][owner],
                'exact done source/raw/observer prerequisite owner')
        committed = committed_members(revision, directory)
        actual = {str(p): p.read_bytes() for p in Path(directory).iterdir()}
        require(actual == committed and same({p: identity(raw) for p, raw in actual.items()},
                                            binding['archives'][directory]),
                'whole committed prerequisite membership and bytes')
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members(BASE)), 'whole function-order seal')
    # Each exact reader reexecutes its finite source/capture chain. Native
    # bodies cannot select the intended source ancestry in the new join.
    receipts = []
    for directory in PREREQUISITES:
        command = ['python3', '-B', directory + '/verify.py']
        run = subprocess.run(command, capture_output=True, text=True)
        require(run.returncode == 0, 'complete source/raw/observer replay: ' + directory)
        receipts.append({'command': command, 'status': run.returncode,
                         'stdout': run.stdout, 'stderr': run.stderr})
    return receipts


def source_models():
    reader = module(MODELS / 'verify.py')
    inventory, authored, _ = reader['inputs']()
    paths = reader['model']['derive'](inventory, authored, require, identity)
    require(same(paths, load(MODELS / 'proofs.json')['paths']), 'whole regenerated source ancestry')
    observer = module(OBSERVER / 'verify.py')
    modes = observer['expected_models'](observer['sources']())
    source = {path['parse_index']: path for path in paths}
    result = []
    for mode in modes:
        require([case['index'] for case in mode['parses']] == list(source),
                'complete independently selected source parser refusal population')
        cases = []
        for case in mode['parses']:
            path = source[case['index']]
            require(len(case['boundaries']) == 1, 'source single parser operation phase')
            functions = [frame['function'] for frame in
                         reversed(path['active_own_ancestry_outer_to_inner'])]
            require(functions[-1] == 'FSM::Adapter::ISF::parse_source', 'source facade outer boundary')
            cases.append({'index': case['index'], 'context': {'kind': case['kind'],
                          'caller': case['caller_context'], 'helper': case['helper']},
                          'source': path['whole_source'], 'functions_inner_to_outer': functions,
                          'phases': len(case['boundaries'])})
        result.append({'mode': mode['mode'], 'cases': cases})
    return result


def function(segment):
    return segment['call'].split('(', 1)[0]


def check(models, expected, inventories, canonical):
    require(same(models, expected), 'complete source-selected function-order models')
    require(same([mode['mode'] for mode in inventories], [mode['mode'] for mode in models]),
            'complete native parser mode identity')
    trace = module(RAW / 'trace_inventory.py')['inventory']
    observations = []
    for model, inventory, original in zip(models, inventories, canonical, strict=True):
        domain = inventory['domains']['parses']
        require(same(domain['population'], original['domains']['parses']['population'])
                and same(domain['empty_string_members'], original['domains']['parses']['empty_string_members'])
                and same([row['index'] for row in domain['nonempty']], [case['index'] for case in model['cases']]),
                'complete native parser member and kind population')
        cases = []
        for case, row in zip(model['cases'], domain['nonempty'], strict=True):
            require(same(row['context'], case['context']), 'source parser member context identity')
            require(type(row['body']) is str and row['wire_kind'] == 'string'
                    and same(row['body_identity'], identity(row['body'].encode()))
                    and same({key: row[key] for key in ('segments', 'opaque_lexemes')}, trace(row['body'])),
                    'complete raw parser body and lossless grammar')
            frames = [(position, segment) for position, segment in enumerate(row['segments'])
                      if segment['kind'] == 'frame']
            anchors = [i for i, (_, frame) in enumerate(frames)
                       if function(frame) == case['functions_inner_to_outer'][-1]]
            require(len(anchors) == case['phases'], 'complete source-derived parser throw phases')
            owned = [i for i, (_, frame) in enumerate(frames)
                     if function(frame).startswith(OWN_PACKAGES)]
            selected, phases = [], []
            for phase, anchor in enumerate(anchors):
                start = anchor + 1 - len(case['functions_inner_to_outer'])
                require(start >= 0, 'complete contiguous own parser interval')
                interval = frames[start:anchor + 1]
                require([function(frame) for _, frame in interval] == case['functions_inner_to_outer'],
                        'source-derived native parser function order')
                selected.extend(range(start, anchor + 1))
                positions = [position for position, _ in interval]
                phases.append({'phase': phase, 'segment_positions': positions,
                               'whole_own_segments': row['segments'][positions[0]:positions[-1] + 1],
                               'opaque_before': row['segments'][:positions[0]],
                               'opaque_after': row['segments'][positions[-1] + 1:]})
            require(owned == selected, 'complete own parser frame population')
            original_row = next(r for r in original['domains']['parses']['nonempty'] if r['index'] == case['index'])
            require(row['body'] == original_row['body'], 'whole original parser body conservation')
            cases.append({'index': case['index'], 'context': case['context'], 'source': case['source'],
                          'body': row['body'], 'body_identity': row['body_identity'], 'phases': phases})
        observations.append({'mode': model['mode'], 'cases': cases})
    return observations


def controls(expected, canonical):
    trace = module(RAW / 'trace_inventory.py')['inventory']

    def body_change(native, change, member=0):
        row = native[0]['domains']['parses']['nonempty'][member]
        body = change(row['body'])
        require(body != row['body'], 'genuine raw-body mutation')
        row.update(body=body, body_identity=identity(body.encode()), **trace(body))

    def alter_line(body, change):
        lines = body.splitlines(keepends=True)
        i = next(i for i, line in enumerate(lines) if line.startswith('\tFSM::Support::ISFRecordPortContexts::_require('))
        change(lines, i)
        return ''.join(lines)

    changes = [
        ('missing-source-path', lambda m, n: m[0]['cases'].pop(), 'complete source-selected function-order models'),
        ('borrowed-source-path', lambda m, n: m[0]['cases'][0].update(functions_inner_to_outer=m[0]['cases'][1]['functions_inner_to_outer']), 'complete source-selected function-order models'),
        ('missing-native-mode', lambda m, n: n.pop(), 'complete native parser mode identity'),
        ('borrowed-native-mode', lambda m, n: n[0].update(mode=n[1]['mode']), 'complete native parser mode identity'),
        ('missing-native-member', lambda m, n: n[0]['domains']['parses']['nonempty'].pop(), 'complete native parser member and kind population'),
        ('duplicate-native-member', lambda m, n: n[0]['domains']['parses']['nonempty'].append(copy.deepcopy(n[0]['domains']['parses']['nonempty'][0])), 'complete native parser member and kind population'),
        ('wrong-native-member', lambda m, n: n[0]['domains']['parses']['nonempty'][0].update(index=3), 'complete native parser member and kind population'),
        ('float-member-kind', lambda m, n: n[0]['domains']['parses']['nonempty'][0].update(index=2.0), 'complete native parser member and kind population'),
        ('Boolean-population-kind', lambda m, n: n[0]['domains']['parses'].update(population=True), 'complete native parser member and kind population'),
        ('wrong-native-context', lambda m, n: n[0]['domains']['parses']['nonempty'][0]['context'].update(helper=42), 'source parser member context identity'),
        ('lost-raw-frame', lambda m, n: body_change(n, lambda b: alter_line(b, lambda lines, i: lines.pop(i))), 'complete contiguous own parser interval'),
        ('reordered-raw-frames', lambda m, n: body_change(n, lambda b: alter_line(b, lambda lines, i: lines.__setitem__(slice(i, i + 2), list(reversed(lines[i:i + 2]))))), 'source-derived native parser function order'),
        ('wrong-raw-function', lambda m, n: body_change(n, lambda b: b.replace('ISFRecordPortContexts::_require(', 'ISFRecordPortContexts::_port_root(', 1)), 'source-derived native parser function order'),
        ('borrowed-raw-path', lambda m, n: body_change(n, lambda b: n[0]['domains']['parses']['nonempty'][1]['body']), 'complete contiguous own parser interval'),
        ('extra-own-raw-frame', lambda m, n: body_change(n, lambda b: alter_line(b, lambda lines, i: lines.append(lines[i]))), 'complete own parser frame population'),
        ('duplicate-raw-phase', lambda m, n: body_change(n, lambda b: b + b), 'complete source-derived parser throw phases'),
        ('annotation-kind-corruption', lambda m, n: n[0]['domains']['parses']['nonempty'][0]['segments'][2].update(kind='message'), 'complete raw parser body and lossless grammar'),
        ('opaque-raw-body-change', lambda m, n: body_change(n, lambda b: b + '\n'), 'whole original parser body conservation'),
        ('opaque-byte-loss', lambda m, n: n[0]['domains']['parses']['nonempty'][0]['segments'].pop(), 'complete raw parser body and lossless grammar'),
    ]
    results = []
    for name, mutate, cause in changes:
        models, native = copy.deepcopy(expected), copy.deepcopy(canonical)
        mutate(models, native)
        require(not same(models, expected) or not same(native, canonical), 'genuine separating control: ' + name)
        try:
            check(models, expected, native, canonical)
        except ValueError as error:
            require(str(error) == cause, 'intended function-order control cause: ' + name + ': ' + str(error))
            results.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green function-order control: ' + name)
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    receipts = authenticate()
    expected = source_models()
    inventories = load(RAW / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, inventories)
    save('proofs.json', {'models': expected, 'observations': observed,
                        'controls': controls(expected, inventories),
                        'scope': 'Complete finite own parser function order only; visible arguments, outer framework, coordinates, identity and nested API/helper joins remain open.'})
    save('prerequisite-replays.json', receipts)
    save('book-native-proof.json', module(BASE / 'book.py')['proof']((BASE / 'book-input.html').read_text()))
    if args.seal:
        save('manifest.json', members(BASE))
    print('PASS complete source-selected original parser function order in every retained mode/member/phase; argument and wider joins remain open.')


if __name__ == '__main__':
    main()
