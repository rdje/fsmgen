"""Qualify reviewed zero-growth tooling question/fact retention and source epochs."""
import hashlib
import json
import subprocess
import sys
from types import SimpleNamespace
from pathlib import Path

sys.path.insert(0, 'scripts')
import check_record_value_publication as current

BASE = Path('docs/audits/record-value-coordinate-epoch-publication-20261007')
REVISION = 'f7bcdaf5e9c2b831b79497dbe7c704dd1fd0c1d9'


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def load(path):
    return json.loads(path.read_bytes())


def derive():
    prior = current.historical()
    names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--',
        'docs/knowledge', 'docs/decisions'], text=True).splitlines()
    sources = prior['metadata']['git_blobs'](REVISION, sorted(p for p in names if p.endswith('.md')))
    proposal = load(BASE / 'proposal.json')
    path = proposal['path']
    require(path == prior['TOOLING'] and sources[path].decode() == proposal['before'], 'whole fixed tooling predecessor')
    checker = frozen_checker()
    require(proposal['after'] == checker['epoch_fact'].extend(proposal['before']), 'whole reviewed source transformation')
    require(proposal['after'] == checker['expected_cards'](prior)[path], 'whole atomic current target expectation')
    for target in prior['PATHS']:
        if target != path:
            require(sources[target].decode() == checker['expected_cards'](prior)[target], 'complete unchanged core and observer meanings')
    before_id, before_questions = prior['metadata']['metadata'](sources[path])
    after_id, after_questions = prior['metadata']['metadata'](proposal['after'].encode())
    require(before_id == after_id and after_questions == [*before_questions, current.epoch_fact.QUESTION],
            'whole original ordered questions and exactly one new owned question')
    changed = {**sources, path: proposal['after'].encode()}
    physical = lambda values:{p:raw for p, raw in values.items() if Path(p).parent == Path('docs/knowledge')}
    before, after = prior['public']['metrics'](physical(sources)), prior['public']['metrics'](physical(changed))
    require(before['bytes_total'] == after['bytes_total'], 'complete zero-growth physical collection')
    prior['public']['within'](after, current.authority(prior)['surface'])
    old_rows, new_rows = (prior['metadata']['allocation'](values)['rows'] for values in (sources, changed))
    expected_row = current.epoch_fact.QUESTION + '\t' + before_id + '\t' + path
    require(new_rows == '\n'.join(sorted([*old_rows.splitlines(), expected_row])) + '\n',
            'complete original global allocation plus independently spelled sole owner')
    first = load(BASE / 'first-over-capacity-proposal.json')
    invalid = {**physical(sources), path:first['after'].encode()}
    try:
        prior['public']['within'](prior['public']['metrics'](invalid), current.authority(prior)['surface'])
    except ValueError as error:
        require(str(error) == 'physical capacity kind/allowance: bytes_total', 'intended first candidate capacity refusal')
    else:
        raise ValueError('first growing proposal unexpectedly admissible')
    return dict(revision=REVISION, source_members={p:identity(raw) for p, raw in sources.items()},
        before=before, after=after, before_allocation=old_rows, after_allocation=new_rows,
        new_question=expected_row, target_before=identity(sources[path]), target_after=identity(changed[path]),
        scope='Exact source/questions/allocation/capacity derivation; semantic prose equivalence is the explicit clause review, not unrestricted language proof.')


def frozen_checker():
    namespace = {'__name__': 'saved_epoch_publication_checker', '__file__': 'scripts/check_record_value_publication.py'}
    exec(compile((BASE / 'current-checker.py.txt').read_bytes(), namespace['__file__'], 'exec'), namespace)
    helper = {'__name__': 'saved_epoch_fact', '__file__': 'scripts/record_value_epoch_fact.py'}
    exec(compile((BASE / 'epoch-fact.py.txt').read_bytes(), helper['__file__'], 'exec'), helper)
    namespace['epoch_fact'] = SimpleNamespace(**helper)
    return namespace


def saved_current(proof, actual=None):
    prior = current.historical()
    names = sorted(proof['source_members'])
    canonical = prior['metadata']['git_blobs'](REVISION, names)
    proposal = load(BASE / 'proposal.json')
    canonical[proposal['path']] = proposal['after'].encode()
    checker = frozen_checker()
    record = load(BASE / 'current-input.json')
    checker['check'](record, canonical, prior, checker['authority'](prior))
    checker['check_native']((BASE / 'native-input.html').read_text(), prior)
    actual = load(BASE / 'current-actual.json') if actual is None else actual
    require(set(actual) == {'command', 'status', 'stdout', 'stderr', 'instruments', 'input', 'role'}
        and actual['role'] == 'Fresh complete current tooling/source/query/census/native and committed historical epoch qualification; original evidence retained.',
        'closed complete actual epoch domain and original evidence scope')
    require(type(actual['status']) is int and actual['status'] == 0 and actual['command'] ==
        ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', '.artifacts/coordinate-epoch-publication-book']
        and actual['stdout'] == checker['SUCCESS'] and actual['stderr'] == '', 'whole typed current epoch command and streams')
    require(current.same(actual['input'], identity((BASE / 'current-input.json').read_bytes()))
        and current.same(actual['instruments']['scripts/check_record_value_publication.py'], identity((BASE / 'current-checker.py.txt').read_bytes()))
        and current.same(actual['instruments']['scripts/record_value_epoch_fact.py'], identity((BASE / 'epoch-fact.py.txt').read_bytes())),
        'whole actual source/helper/input instrument identities')


def controls(proof):
    original = load(BASE / 'current-actual.json')
    result = []
    for name, change, cause in (
        ('Boolean-status', {'status': True}, 'whole typed current epoch command and streams'),
        ('float-status', {'status': 0.0}, 'whole typed current epoch command and streams'),
        ('native-promotion', {'role': 'Original private toolchain/coordinate identity measured.'}, 'closed complete actual epoch domain and original evidence scope'),
        ('borrowed-current-only-command', {'command': ['python3', '-B', 'scripts/check_record_value_publication.py']}, 'whole typed current epoch command and streams')):
        changed = {**original, **change}
        require(not current.same(changed, original), 'genuine saved epoch result intervention')
        try:
            saved_current(proof, changed)
        except ValueError as error:
            require(str(error) == cause, 'intended saved epoch result refusal: ' + name)
            result.append(dict(control=name, cause=cause))
        else:
            raise ValueError('false-green saved epoch result: ' + name)
    return result


def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    proof = derive()
    path = BASE / 'source-proof.json'
    if path.exists():
        require(current.same(load(path), proof), 'whole immutable retained source proof')
    else:
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    if args.prepare:
        print('PASS complete zero-growth source/question/allocation/capacity preparation; actual current/native result remains required.')
        return
    saved_current(proof)
    checked = controls(proof)
    control_path = BASE / 'controls.json'
    if control_path.exists():
        require(current.same(load(control_path), checked), 'whole immutable saved epoch result controls')
    else:
        control_path.write_text(json.dumps(checked, sort_keys=True, indent=2) + '\n')
    members = {p.name:identity(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}
    if args.seal:
        require(not (BASE / 'manifest.json').exists(), 'epoch publication seal cannot overwrite evidence')
        (BASE / 'manifest.json').write_text(json.dumps(members, sort_keys=True, indent=2) + '\n')
    require(current.same(load(BASE / 'manifest.json'), members), 'whole immutable epoch publication seal')
    print('PASS complete saved zero-growth epoch fact/source/question/native/actual-result proof; no later current currency or coordinate meaning.')


if __name__ == '__main__':
    main()
