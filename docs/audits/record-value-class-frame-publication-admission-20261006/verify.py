"""Admit the whole committed semantic/result domain before fact publication."""
import argparse
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-admission-20261006')
CHECKS = Path('docs/audits/class-frame-publication-admission-checks-20261006')
JOIN = Path('docs/audits/record-value-class-frame-join-20261006')
JOIN_CHECKS = Path('docs/audits/class-frame-join-checks-20261006')
TOOLING = Path('docs/audits/record-value-tooling-current-reader-20261006')
REVISION = '017a8f70b02490288ec87e6815eb6fdda6702061'
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.6.3.1'
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
SUCCESS = 'PASS complete committed class/frame publication admission, regenerated semantics and saved scoped executions; semantic retention and atomic current publication remain pending.\n'
FRESH_SUCCESS = 'PASS complete committed class/frame publication admission with fresh scoped reader executions; semantic retention and atomic current publication remain pending.\n'


def module(path):
    ns = {'__name__': 'class_frame_publication_intake', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


join = module(JOIN / 'verify.py')
tooling = module(TOOLING / 'verify.py')
admission = join['admission']
metadata = tooling['metadata']()
public = module(tooling['PUBLIC'] / 'verify.py')
require, same, identity, load, whole = (join[k] for k in ('require', 'same', 'identity', 'load', 'whole'))


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole immutable publication-admission product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed publication admission cannot add products')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def members():
    return {str(Path(p).relative_to(BASE)): pin for p,pin in whole(BASE).items() if Path(p) != BASE / 'manifest.json'}


def binding():
    roots = sorted({Path(p) for p in load(JOIN / 'binding.json')['inputs']} | {JOIN, JOIN_CHECKS}, key=str)
    admission['REVISION'] = REVISION
    inputs = admission['committed_inputs'](roots)
    task = subprocess.check_output(['git', 'show', REVISION + ':' + str(TASK)])
    return dict(revision=REVISION, task_identity=identity(task), owners=admission['owner_rows'](roots, task.decode()),
        inputs=inputs, original_capture=load(JOIN / 'binding.json')['original_capture'],
        scope='Complete committed finite class/frame model, semantic controls, actual-result programmes/receipts and every transitive admitted member; original native capture and identities are not recaptured.')


def check_binding(candidate, expected):
    require(candidate['revision'] == REVISION and candidate['scope'] == expected['scope'], 'publication admission revision and native scope')
    require(same(candidate['task_identity'], expected['task_identity']) and same(candidate['owners'], expected['owners']),
            'whole completed publication prerequisite task-owner authority')
    require(all(type(p['bytes']) is int and p['bytes'] >= 0 for rows in candidate['inputs'].values() for p in rows.values()),
            'publication admission discrete source member byte counts')
    require(same(candidate['inputs'], expected['inputs']), 'whole committed publication source model and result population')
    require(same(candidate['original_capture'], expected['original_capture']), 'complete original raw capture conservation')
    require(same(candidate, expected), 'closed complete publication-admission binding')


def source_snapshot():
    paths = subprocess.check_output(['git','ls-tree','-r','--name-only',REVISION,'docs/knowledge','docs/decisions'], text=True).splitlines()
    paths = sorted(p for p in paths if p.endswith('.md'))
    blobs = metadata['git_blobs'](REVISION, paths)
    require(all(Path(p).is_file() and not Path(p).is_symlink() and Path(p).stat().st_dev == Path.cwd().stat().st_dev
        and Path(p).read_bytes() == raw for p,raw in blobs.items()), 'whole immutable logical source fact and decision bytes')
    physical = {p:raw for p,raw in blobs.items() if Path(p).parent == Path('docs/knowledge')}
    current = public['cards']()
    require(current == physical, 'complete unchanged physical fact member population')
    old_registry = subprocess.check_output(['git','show',REVISION + ':' + str(REGISTRY)])
    surface = public['authority'](old_registry)
    require(same(surface, public['authority'](REGISTRY.read_bytes())), 'whole unchanged Knowledge Map capacity authority')
    budget = next(json.loads(s) for s in old_registry.decode().splitlines() if json.loads(s).get('surface_id') == 'book_source_manifest')
    current_budget = next(json.loads(s) for s in REGISTRY.read_text().splitlines() if json.loads(s).get('surface_id') == 'book_source_manifest')
    require(same(budget, current_budget), 'whole unchanged canonical source-plane budget')
    programmes = set(load(TOOLING / 'binding.json')['programmes'])
    source_programmes = metadata['git_blobs'](REVISION, sorted(programmes))
    require(all(Path(p).read_bytes() == raw for p,raw in source_programmes.items()), 'whole committed metadata query and source-view programmes')
    return dict(revision=REVISION, target_cards={p:blobs[p].decode() for p in tooling['PATHS']},
        physical_members={p:identity(raw) for p,raw in physical.items()}, census=public['metrics'](physical),
        logical_members={p:identity(raw) for p,raw in blobs.items()}, allocation=metadata['allocation'](blobs),
        surface=surface, source_budget=budget, programmes={p:identity(raw) for p,raw in source_programmes.items()},
        scope='Complete unchanged source facts/questions and exact current-reader epoch retained before semantic compaction; no new current class/frame fact is published.')


def check_snapshot(candidate, expected):
    require(candidate['target_cards'] == expected['target_cards'], 'whole prior target fact bodies identities ordered questions and routes')
    require(same(candidate['physical_members'], expected['physical_members']) and same(candidate['logical_members'], expected['logical_members']),
            'whole prior physical and logical fact member population')
    require(all(type(v) is int and v >= 0 for v in candidate['census'].values()), 'source fact census discrete capacity kinds')
    require(same(candidate['census'], expected['census']) and same(candidate['surface'], expected['surface']),
            'whole prior fact census and frozen collection authority')
    require(same(candidate['allocation'], expected['allocation']), 'complete global prior question identity path and occurrence allocation')
    require(same(candidate['source_budget'], expected['source_budget']) and same(candidate['programmes'], expected['programmes']),
            'whole unchanged query and canonical source programme budget')
    require(same(candidate, expected), 'closed pre-retention source snapshot and role')


def semantic_products():
    """Reconstruct full objects and compare full values, never hash substitutes.

    The committed prerequisite already durably retains complete model/raw
    corpora. Preserve their whole custody instead of duplicating them again.
    This product retains the full regenerated semantic join and controls.
    """
    expected = join['source_models']()
    raw = join['admission']['raw_product']()
    require(same(raw, load(JOIN / 'raw-product.json')), 'whole regenerated original raw inventory and controls')
    nested = join['public']['context']['nested_records'](expected['frame_model']['own'])
    meanings = join['check'](expected, expected, raw['inventories'], raw['inventories'], nested)
    require(same(meanings, load(JOIN / 'proofs.json')), 'whole regenerated source class/frame body phase and operand meanings')
    controls = join['controls'](expected, raw['inventories'], nested)
    require(same(controls, load(JOIN / 'controls.json')), 'whole regenerated genuine class/frame separating controls')
    book = module(JOIN / 'book.py')
    require(same(book['proof']((JOIN / 'book-input.html').read_text()), load(JOIN / 'book-proof.json')),
            'whole regenerated prerequisite native guide and scope controls')
    return dict(join=meanings, controls=controls,
        model_artifact=str(JOIN / 'source-models.json'), raw_artifact=str(JOIN / 'raw-product.json'),
        scope='Every complete source model and raw object reconstructed and compared to the immutable committed products; full semantic join/control objects retained here. Original native/private/formatter/coordinate/address gaps conserve.')


def replay_specs():
    actual = load(JOIN_CHECKS / 'independent-result.json')
    return [
        dict(name='semantic', path=str(JOIN / 'verify.py'), flags=[], stdout=join['SUCCESS'],
            role='Fresh complete committed semantic/source/raw/phase/operand/control/default execution; original capture and transitive native receipts retained.'),
        dict(name='independent_result', path=str(JOIN_CHECKS / 'verify_seal.py'), flags=[], stdout=actual['stdout'],
            role='Fresh independent complete actual semantic seal/product/control/first-failure/typed/member/borrowed-result qualification; original native captures retained.'),
        dict(name='tooling_current', path=str(TOOLING / 'verify.py'), flags=['--current'], stdout=tooling['CURRENT_SUCCESS'],
            role='Fresh current pre-publication complete core/observer/tooling facts, actual direct/cache ownership and canonical source routes; no new class/frame fact publication.')]


def instruments(bound, snapshot):
    result = {p:pin for rows in bound['inputs'].values() for p,pin in rows.items() if p.endswith(('.py','.pl','.pm','.py.txt'))}
    result.update(snapshot['programmes'])
    for p in (str(BASE / 'verify.py'), 'scripts/run_with_ram_guard.sh'):
        result[p] = identity(Path(p).read_bytes())
    return result


def check_replay(actual, spec, bound, snapshot):
    require(type(actual['status']) is int and actual['status'] == 0, 'actual publication prerequisite integer success')
    require(actual['command'] == ['python3','-B',spec['path'],*spec['flags']] and actual['stdout'] == spec['stdout']
        and actual['stderr'] == '', 'exact complete publication prerequisite command streams and role')
    require(actual['role'] == spec['role'], 'publication prerequisite fresh versus retained scope')
    require(same(actual['instruments'], instruments(bound, snapshot)) and same(actual['binding'], identity((BASE / 'binding.json').read_bytes()))
        and same(actual['snapshot'], identity((BASE / 'source-snapshot.json').read_bytes())), 'whole invocation-time publication prerequisite source and input identities')
    require(set(actual) == {'command','stdout','stderr','status','role','instruments','binding','snapshot'}, 'closed complete actual publication prerequisite receipt')


def replays(bound, snapshot, fresh):
    output = {}
    for spec in replay_specs():
        name = 'replay-' + spec['name'] + '.json'
        if fresh:
            require(not (BASE / name).exists(), 'fresh publication prerequisite cannot overwrite an actual result')
            require(same(binding(), bound) and same(source_snapshot(), snapshot), 'every complete invocation-time publication source and input byte')
            command = ['python3','-B',spec['path'],*spec['flags']]
            source = instruments(bound, snapshot)
            p = subprocess.run(command, capture_output=True)
            save(name, dict(command=command, status=p.returncode, stdout=p.stdout.decode(), stderr=p.stderr.decode(), role=spec['role'],
                instruments=source, binding=identity((BASE / 'binding.json').read_bytes()), snapshot=identity((BASE / 'source-snapshot.json').read_bytes())))
            require(same(binding(), bound) and same(source_snapshot(), snapshot), 'every complete prerequisite byte and old fact conserved after execution')
        actual = load(BASE / name); check_replay(actual, spec, bound, snapshot)
        output[spec['name']] = dict(actual=identity((BASE / name).read_bytes()), role=spec['role'], command=actual['command'], status=actual['status'])
        if fresh:
            print('Admitted fresh publication prerequisite: ' + spec['name'], flush=True)
    return output


def controls(bound, snapshot):
    result = []
    def refuse(name, candidate, predicate, cause):
        try:
            predicate(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended publication admission refusal: ' + name + ': ' + str(error))
            result.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green publication admission: ' + name)
    for name, mutate, cause in (
        ('native-scope-promotion', lambda r:r.update(scope='Original native class and formatter measured.'), 'publication admission revision and native scope'),
        ('lost-prerequisite-owner', lambda r:r['owners'].pop(next(iter(r['owners']))), 'whole completed publication prerequisite task-owner authority'),
        ('changed-prerequisite-owner', lambda r:next(iter(r['owners'].values())).update(body='borrowed done'), 'whole completed publication prerequisite task-owner authority'),
        ('lost-source-result-member', lambda r:next(iter(r['inputs'].values())).pop(next(iter(next(iter(r['inputs'].values()))))), 'whole committed publication source model and result population'),
        ('borrowed-source-model', lambda r:next(iter(next(iter(r['inputs'].values())).values())).update(sha256='borrowed'), 'whole committed publication source model and result population'),
        ('Boolean-source-count', lambda r:next(iter(next(iter(r['inputs'].values())).values())).update(bytes=True), 'publication admission discrete source member byte counts')):
        candidate = copy.deepcopy(bound); mutate(candidate)
        require(not same(candidate,bound), 'genuine publication custody intervention: ' + name)
        refuse(name,candidate,lambda r:check_binding(r,bound),cause)
    for name, mutate, cause in (
        ('lost-whole-prior-card', lambda r:r['target_cards'].pop(tooling['CORE']), 'whole prior target fact bodies identities ordered questions and routes'),
        ('lost-global-question', lambda r:r['allocation'].update(rows=r['allocation']['rows'].split('\n',1)[1]), 'complete global prior question identity path and occurrence allocation'),
        ('lost-physical-card', lambda r:r['physical_members'].pop(next(iter(r['physical_members']))), 'whole prior physical and logical fact member population'),
        ('Boolean-fact-count', lambda r:r['census'].update(files=True), 'source fact census discrete capacity kinds'),
        ('widened-card-authority', lambda r:r['surface']['transition']['max_growth'].update(files=999), 'whole prior fact census and frozen collection authority'),
        ('lost-source-budget', lambda r:r['source_budget']['targets'].clear(), 'whole unchanged query and canonical source programme budget')):
        candidate = copy.deepcopy(snapshot); mutate(candidate)
        require(not same(candidate,snapshot), 'genuine publication source-fact intervention: ' + name)
        refuse(name,candidate,lambda r:check_snapshot(r,snapshot),cause)
    spec = replay_specs()[0]; actual = load(BASE / 'replay-semantic.json')
    for status in (True,0.0,1):
        refuse('replay-status-' + repr(status), {**actual,'status':status},lambda r:check_replay(r,spec,bound,snapshot),'actual publication prerequisite integer success')
    candidate = copy.deepcopy(actual); candidate['role'] = 'Original native identities recaptured.'
    refuse('invented-native-recapture',candidate,lambda r:check_replay(r,spec,bound,snapshot),'publication prerequisite fresh versus retained scope')
    candidate = copy.deepcopy(actual); candidate['instruments'].pop(next(iter(candidate['instruments'])))
    refuse('lost-invocation-source',candidate,lambda r:check_replay(r,spec,bound,snapshot),'whole invocation-time publication prerequisite source and input identities')
    borrowed = load(BASE / 'replay-tooling_current.json')
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine current-tooling-only actual success')
    refuse('borrowed-current-tooling-success',borrowed,lambda r:check_replay(r,spec,bound,snapshot),'exact complete publication prerequisite command streams and role')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--replay', action='store_true')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    require(not (args.prepare and (args.replay or args.seal)), 'publication source preparation cannot supply actual execution or seal')
    if (BASE / 'manifest.json').exists():
        require(not args.prepare and not args.replay, 'sealed publication admission cannot recapture')
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable publication-admission manifest')
    bound = binding(); snapshot = source_snapshot()
    save('binding.json',bound); save('source-snapshot.json',snapshot)
    save('semantic-proof.json',semantic_products())
    if args.prepare:
        print('PASS whole committed publication prerequisite preparation and complete semantic regeneration; fresh actual reader executions remain required.')
        return
    check_binding(load(BASE / 'binding.json'),bound); check_snapshot(load(BASE / 'source-snapshot.json'),snapshot)
    save('replay-proof.json',replays(bound,snapshot,args.replay))
    save('controls.json',controls(bound,snapshot))
    if not args.replay:
        book = module(BASE / 'book.py'); save('book-proof.json',book['proof']((BASE / 'book-input.html').read_text()))
    if args.seal:
        save('manifest.json',members())
    print(FRESH_SUCCESS if args.replay else SUCCESS,end='')


if __name__ == '__main__':
    main()
