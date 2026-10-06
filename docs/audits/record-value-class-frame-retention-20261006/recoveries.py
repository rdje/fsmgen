"""Reconstruct the complete retained drafts and independently derive their budgets."""
import json
import re
from pathlib import Path


def check(ns):
    base,checks = ns['BASE'],ns['CHECKS']
    require,same,identity,load,module = (ns[k] for k in ('require','same','identity','load','module'))
    results = {}
    guard = r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n'
    for name,programme,prepared,budget in (
        ('first',checks / 'first-prepare.py.txt','preparation.json','first-budget.json'),
        ('second',checks / 'second-prepare.py.txt','qualified-preparation.json','qualified-budget.json'),
        ('complete',base / 'prepare.py','complete-preparation.json','complete-budget.json')):
        producer = module(programme); reconstructed = {}
        producer['save'] = lambda filename,value:reconstructed.update({filename:value})
        producer['main'](quiet=True)
        proposal_path = base / 'proposal.json' if name == 'complete' else checks / (name + '-proposal.json')
        review_path = base / 'retention-map.json' if name == 'complete' else checks / (name + '-retention-map.json')
        proposal = load(proposal_path)
        require(same(reconstructed['proposal.json'],proposal) and same(reconstructed['retention-map.json'],load(review_path)),
                'whole independently reconstructed retained proposal and review: ' + name)
        preparation = load(checks / prepared)
        expected_instruments = {str(checks / 'run.py'):identity((checks / 'run.py').read_bytes()),
            str(base / 'prepare.py'):identity(programme.read_bytes()),
            'scripts/run_with_ram_guard.sh':identity(Path('scripts/run_with_ram_guard.sh').read_bytes())}
        require(type(preparation['status']) is int and preparation['status'] == 0
            and preparation['command'] == ['scripts/run_with_ram_guard.sh','--','python3','-B',str(base / 'prepare.py')]
            and preparation['stdout'] == 'Prepared complete reviewed source proposition/qualifier and unchanged metadata retention proposal; no live card changed.\n'
            and re.fullmatch(guard,preparation['stderr']) is not None and same(preparation['instruments'],expected_instruments),
            'whole retained actual preparation role and historical invocation source: ' + name)
        measure = lambda texts:dict(files=len(texts),bytes=sum(len(t.encode()) for t in texts),LF=sum(t.count('\n') for t in texts))
        before,after = measure([r['before'] for r in proposal.values()]),measure([r['after'] for r in proposal.values()])
        derived = dict(before=before,proposal=after,delta={k:after[k]-before[k] for k in before})
        actual = load(checks / budget)
        success = all(after[k] <= before[k] for k in ('bytes','LF')) and after['files'] == before['files']
        require(type(actual['status']) is int and actual['status'] == (0 if success else 1)
            and actual['command'] == ['python3','-B',str(checks / 'check_budget.py')]
            and json.loads(actual['stdout'].splitlines()[0]) == derived,
            'whole independently derived actual retained budget and failure kind: ' + name)
        require(same(actual['instruments'],{str(checks / 'run.py'):identity((checks / 'run.py').read_bytes()),
            str(checks / 'check_budget.py'):identity((checks / 'check_budget.py').read_bytes())}),
            'whole retained budget invocation programme: ' + name)
        if success:
            require(actual['stderr'] == '' and actual['stdout'].splitlines()[1:] == ['PASS complete unchanged-source non-growing retention proposal budget.'],
                    'exact actual successful retention budget scope')
        else:
            require(actual['stdout'].count('\n') == 1 and actual['stderr'].endswith('AssertionError: complete retention proposal must not grow bytes or LF\n'),
                    'actual retained first budget failure mechanism: ' + name)
        results[name] = dict(derived=derived,actual=identity((checks / budget).read_bytes()),
            producer=identity(programme.read_bytes()),proposal=identity(proposal_path.read_bytes()),review=identity(review_path.read_bytes()),
            role='Retained actual preparation/budget independently reconstructed from its whole historical producer; no new capture or source mutation.')
    return results
