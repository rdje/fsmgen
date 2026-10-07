"""Reconstruct whole dated source epochs and independently consume actual receipts."""
import copy
import json
import sys
from pathlib import Path

sys.path.insert(0, 'scripts')
import check_record_value_publication as live

BASE = Path('docs/audits/class-frame-current-repair-20261007')


def load(name):
    return json.loads((BASE / name).read_bytes())


def main():
    manifest = load('manifest.json')
    members = {p.name: live.identity(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}
    live.require(live.same(manifest, members), 'whole immutable current-repair evidence seal')
    source = load('old-current-sources.json')
    prior = live.historical()
    import subprocess
    names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', source['revision'], '--', 'docs/knowledge', 'docs/decisions'], text=True).splitlines()
    old = prior['metadata']['git_blobs'](source['revision'], sorted(p for p in names if p.endswith('.md')))
    raw = Path(source['proposal']['path']).read_bytes()
    live.require(live.same(live.identity(raw), source['proposal']['identity']), 'complete retained proposal identity')
    old['docs/knowledge/decision-record-exact-retrieval.md'] = raw
    live.require(live.same(source['members'], {p: live.identity(v) for p, v in old.items()}), 'whole fixed old-role logical source epoch')
    old_input = load('old-current-input.json')
    live.require(old_input['cards'] == prior['model']['cards'](), 'whole original target facts and current routes')
    live.require(set(old_input['queries']) == {'direct', 'cached'}, 'complete old-role actual query population')
    for role, actual in old_input['queries'].items():
        command = ['knowledge-map/scripts/query_knowledge_map.sh', '--all'] + (['--no-cache'] if role == 'direct' else [])
        live.require(type(actual['status']) is int and actual['status'] == 0 and actual['command'] == command
            and not actual['stderr'] and actual['stdout'] == prior['metadata']['allocation'](old)['rows'],
            'whole actual source-derived old-role query allocation')
    live.require(live.same(old_input['physical_members'], {p: live.identity(v) for p, v in old.items()
        if Path(p).parent == Path('docs/knowledge')}), 'whole old-role physical population')
    live.require(live.same(old_input['census'], prior['public']['metrics']({p: v for p, v in old.items()
        if Path(p).parent == Path('docs/knowledge')})), 'whole old-role physical census')
    declared = live.authority(prior)
    live.require(live.same(old_input['surface'], declared['surface'])
        and live.same(old_input['source_budget'], declared['source_budget']), 'whole old-role unchanged capacity/source authority')
    try:
        prior['check_current'](old_input)
    except ValueError as error:
        live.require(str(error) == 'whole current physical member and non-target source conservation', 'intended legitimate old-role refusal')
    else:
        raise ValueError('old reader unexpectedly permits the unrelated source epoch')

    namespace = {'__name__': 'saved_current_checker', '__file__': 'scripts/check_record_value_publication.py'}
    programme = (BASE / 'current-checker.py.txt').read_bytes()
    exec(compile(programme, namespace['__file__'], 'exec'), namespace)
    canonical = {**old, **{p: t.encode() for p, t in namespace['expected_cards'](prior).items()}}
    current_input = load('current-input.json')
    namespace['check'](current_input, canonical, prior, namespace['authority'](prior))
    namespace['check_native']((BASE / 'native-input.html').read_text(), prior)

    def receipt(actual, role):
        if role == 'current':
            command = ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', '.artifacts/class-frame-current-book']
            stdout, stderr, status = namespace['SUCCESS'], '', 0
            instrument = live.identity(programme)
        else:
            command = ['python3', '-B', str(live.HISTORICAL / 'verify.py'), '--current']
            stdout, stderr, status = '', load('old-current-actual.json')['stderr'], 1
            instrument = live.identity((live.HISTORICAL / 'verify.py').read_bytes())
        live.require(set(actual) == {'command', 'status', 'stdout', 'stderr', 'input_identity', 'programme'}
            and type(actual['status']) is int and actual['status'] == status and actual['command'] == command
            and actual['stdout'] == stdout and actual['stderr'] == stderr,
            'whole typed actual ' + role + ' command and streams')
        live.require(live.same(actual['programme'], instrument) and live.same(actual['input_identity'],
            live.identity((BASE / (role + '-input.json' if role == 'current' else 'old-current-input.json')).read_bytes())),
            'whole actual ' + role + ' input and instrument binding')
    old_actual, current_actual = load('old-current-actual.json'), load('current-actual.json')
    live.require(old_actual['stderr'].endswith('ValueError: whole current physical member and non-target source conservation\n'),
                'actual old current predicate failure locus')
    receipt(old_actual, 'old'); receipt(current_actual, 'current')
    controls = []
    for role, original in (('old', old_actual), ('current', current_actual)):
        for status in (True, 0.0, 2):
            candidate = copy.deepcopy(original); candidate['status'] = status
            try:
                receipt(candidate, role)
            except ValueError as error:
                live.require(str(error) == 'whole typed actual ' + role + ' command and streams', 'intended receipt kind/status refusal')
                controls.append([role, repr(status), str(error)])
            else:
                raise ValueError('invalid actual status accepted')
    candidate = copy.deepcopy(current_actual)
    candidate['programme'] = old_actual['programme']
    try:
        receipt(candidate, 'current')
    except ValueError as error:
        live.require(str(error) == 'whole actual current input and instrument binding', 'intended borrowed programme refusal')
        controls.append(['current', 'borrowed historical instrument', str(error)])
    else:
        raise ValueError('borrowed historical success accepted')
    print(json.dumps(dict(scope='Complete saved source/query/target/native epoch and actual receipts regenerate; no later current currency or visual/native-original claims.',
        old_members=len(old), current_members=len(canonical), controls=controls), sort_keys=True))


if __name__ == '__main__':
    main()
