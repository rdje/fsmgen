"""Qualify the actual coupling and historical-only adapter contracts."""
import copy
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


adapter = module('historical_reader_role_adapter', BASE / 'adapter.py')
old = module('unchanged_old_helper_predicate', Path(adapter.HELPER))


def check_coupling(record):
    proposal_path = 'docs/audits/record-value-own-subtest-boundaries-20261005/pending-fact.txt'
    proposal = subprocess.check_output(['git', 'show', adapter.REVISION + ':' + proposal_path], text=True)
    topic = old.TOPIC
    before = subprocess.check_output(['git', 'show', adapter.REVISION + ':' + topic], text=True)
    addition = '\n## Qualified own source boundaries\n\n' + proposal.split('\n\n', 1)[1]
    adapter.require(record['revision'] == adapter.REVISION and record['topic'] == topic and
                    record['source_proposal'] == proposal and record['before'] == before and
                    record['addition'] == addition and record['candidate'] == before + addition,
                    'whole independently source-qualified coupling input')
    adapter.require(type(record['status']) is int and record['status'] == 1 and record['restored'] is True and
                    record['command'] == ['python3', '-B', str(adapter.PLANE)] and
                    'whole current helper/core source, roles, questions and reader routes' in record['stderr'],
                    'actual original current-card coupling failure and restoration')
    adapter.require(set(record['programme_pins']) == {str(adapter.PLANE), adapter.HELPER}, 'complete actual coupling programme domain')
    for path, pin in record['programme_pins'].items():
        adapter.require(adapter.same(adapter.identity(Path(path).read_bytes()), pin), 'unchanged actual coupling programmes')
    transform = json.loads((old.BASE / 'transform.json').read_text())
    cards = {path: transform['after'][path] for path in (old.CORE, old.TOPIC)}
    adapter.require(cards[topic] == before, 'exact old whole-card epoch')
    queries = {name: {'status': 0, 'stdout': old.expected_rows(transform)} for name in ('direct', 'cached')}
    old.check_live(transform, cards, queries, transform['after'][old.CHAPTER])
    cards[topic] = record['candidate']
    try:
        old.check_live(transform, cards, queries, transform['after'][old.CHAPTER])
    except AssertionError as error:
        adapter.require(str(error) == 'whole current helper/core source, roles, questions and reader routes',
                        'exact original coupling predicate cause')
    else:
        raise ValueError('false-green original coupling predicate')


def main():
    binding = json.loads((BASE / 'binding.json').read_text())
    adapter.authenticate(binding)
    coupling = json.loads((BASE / 'coupling.json').read_text())
    check_coupling(coupling)
    controls = []
    for name, mutate, cause in [
        ('borrowed-history-revision', lambda b: b.update(revision='borrowed'), 'exact historical adapter revision'),
        ('lost-history-archive', lambda b: b['archives'].pop('docs/audits/book-source-plane-20261005'), 'complete historical adapter archive domain'),
        ('lost-programme-member', lambda b: b['archives']['docs/audits/book-source-plane-20261005'].pop('verify.py'), 'whole historical adapter archive membership'),
        ('borrowed-programme-pin', lambda b: b['archives']['docs/audits/book-source-plane-20261005']['verify.py'].update(sha256='borrowed'), 'whole historical adapter archive identity'),
        ('float-programme-byte-kind', lambda b: b['archives']['docs/audits/book-source-plane-20261005']['verify.py'].update(bytes=float(b['archives']['docs/audits/book-source-plane-20261005']['verify.py']['bytes'])), 'whole historical adapter archive identity'),
    ]:
        changed = copy.deepcopy(binding); mutate(changed)
        try:
            adapter.authenticate(changed)
        except ValueError as error:
            adapter.require(str(error) == cause, 'intended adapter identity control cause')
            controls.append({'control': name, 'cause': str(error), 'status': 1})
        else:
            raise ValueError('false-green historical identity: ' + name)
    for name, mutate, cause in [
        ('coordinated-borrowed-current-fact', lambda r: r.update(candidate=r['candidate']+'invented callback identity\n', addition=r['addition']+'invented callback identity\n', source_proposal=r['source_proposal']+'invented callback identity\n'), 'whole independently source-qualified coupling input'),
        ('Boolean-original-failure', lambda r: r.update(status=True), 'actual original current-card coupling failure and restoration'),
        ('unfinished-live-restoration', lambda r: r.update(restored=False), 'actual original current-card coupling failure and restoration'),
        ('lost-actual-programme', lambda r: r['programme_pins'].pop(str(adapter.PLANE)), 'complete actual coupling programme domain'),
    ]:
        changed = copy.deepcopy(coupling); mutate(changed)
        try:
            check_coupling(changed)
        except ValueError as error:
            adapter.require(str(error) == cause, 'intended coupling evidence control cause')
            controls.append({'control': name, 'cause': str(error), 'status': 1})
        else:
            raise ValueError('false-green coupling evidence: ' + name)
    original = [sys.executable, '-B', adapter.HELPER, '--current']
    for name, execute, cause in [
        ('missing-helper-role', lambda p: p.complete(), 'complete single historical helper role adaptation'),
        ('wrong-original-role', lambda p: p.run(original[:-1]+['--snapshot']), 'exact single original historical helper invocation'),
        ('Boolean-snapshot-status', lambda p: p.run(original), 'successful actual historical helper snapshot'),
    ]:
        proxy = adapter.HistoricalSubprocess(runner=lambda *a, **k: subprocess.CompletedProcess(a[0], False, '', ''))
        try:
            execute(proxy)
        except ValueError as error:
            adapter.require(str(error) == cause, 'intended historical-role control cause')
            controls.append({'control': name, 'cause': str(error), 'status': 1})
        else:
            raise ValueError('false-green historical role: ' + name)
    proxy = adapter.HistoricalSubprocess(runner=lambda *a, **k: subprocess.CompletedProcess(a[0], 0, '', ''))
    proxy.run(original)
    try:
        proxy.run(original)
    except ValueError as error:
        adapter.require(str(error) == 'exact single original historical helper invocation', 'intended extra-role control cause')
        controls.append({'control': 'extra-helper-role', 'cause': str(error), 'status': 1})
    else:
        raise ValueError('false-green extra helper role')
    current = subprocess.run(['python3', '-B', str(BASE / 'adapter.py'), '--current'], capture_output=True, text=True)
    adapter.require(type(current.returncode) is int and current.returncode == 2 and
                    'unrecognized arguments: --current' in current.stderr, 'historical CLI cannot claim current role')
    controls.append({'control': 'invented-current-CLI-role', 'cause': 'historical CLI cannot claim current role', 'status': current.returncode})
    candidate = json.loads((BASE / 'candidate-adapter.json').read_text())
    adapter.require(candidate['candidate'] == coupling['candidate'] and type(candidate['status']) is int and
                    candidate['status'] == 0 and candidate['restored'] is True and
                    candidate['command'] == ['python3', '-B', str(BASE / 'adapter.py'), '--snapshot'] and
                    candidate['stdout'].endswith('PASS unchanged historical source-plane predicates with exact helper snapshot role; current semantic/source currency remains separately required.\n'),
                    'actual complete candidate historical adapter execution/restoration')
    proof = {'controls': controls,
             'scope': 'Original whole-current-card predicate reproduces the actual source-qualified progress failure. Historical adaptation conserves the old programme domain and cannot establish current currency.'}
    target = BASE / 'control-proofs.json'
    if target.exists():
        adapter.require(adapter.same(json.loads(target.read_text()), proof), 'whole saved historical-role controls')
    else:
        adapter.require(not (BASE / 'manifest.json').exists(), 'sealed role qualifier cannot publish')
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS authenticated actual coupling/original predicate and rejecting historical-role controls; current currency remains separately owned.')


if __name__ == '__main__':
    main()
