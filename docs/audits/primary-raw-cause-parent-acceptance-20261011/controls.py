"""Execute complete positive and genuine prior-preserving parent join controls."""
import copy
import subprocess
from parent_common import *
import capture
import context

SUCCESS = 'PASS complete native positive and genuine prior-preserving cause-parent composition controls.\n'


def cases():
    return [
        ('omitted-source', lambda r: r['source']['publication']['members'].pop(next(iter(r['source']['publication']['members']))),
         'whole original current source native custody join'),
        ('narrowed-goal', lambda r: r['contracts']['original_cause'].update(Acceptance='Selected errors only.'),
         'every whole unchanged original cause canonical descendant obligation'),
        ('omitted-descendant', lambda r: r['contracts']['original_prerequisites'].pop(next(iter(r['contracts']['original_prerequisites']))),
         'every whole unchanged original cause canonical descendant obligation'),
        ('omitted-address', lambda r: r['inputs']['native'].pop('address-coordinate'),
         'complete exact primary coordinate address failure and replay membership'),
        ('boolean-primary', lambda r: r['inputs']['native']['epoch_primary'].update(status=False),
         'actual typed original successes and unreclassified first failures'),
        ('borrowed-primary-command', lambda r: r['inputs']['native']['epoch_primary'].update(command=r['inputs']['native']['address-coordinate']['command']),
         'whole exact original primary coordinate address commands programmes and terminals'),
        ('reclassified-first-failure', lambda r: r['inputs']['failures']['prerequisite-first-seal'].update(status=0),
         'actual typed original successes and unreclassified first failures'),
        ('borrowed-failure', lambda r: r['inputs']['failures']['prerequisite-first-seal'].update(stderr='borrowed original diagnostic\n'),
         'whole original first failure programme command and terminal custody'),
        ('borrowed-source-role', lambda r: r['inputs']['replays']['association']['command'].append('--current'),
         'whole own dated child replays and native source roles'),
        ('borrowed-association', lambda r: r['inputs']['proofs']['association']['association']['allocation'][0].update(helpers=0),
         'complete independent association raw canonical and prerequisite meaning custody'),
        ('omitted-question', lambda r: r['canonical'].update({PLAN['target']: r['canonical'][PLAN['target']].replace(
            '  - "what qualifies finite original exception classes?"\n', '', 1)}),
         'complete current canonical facts questions evidence and probes'),
        ('boolean-current-query', lambda r: r['current']['queries']['direct'].update(status=False),
         'actual current query integer success'),
        ('native-promotion', lambda r: r['boundary'].update(assumptions='Native/private identities measured.'),
         'whole original assumptions failures native private boundary'),
    ]


def execute():
    positive = load_product('candidate.json.gz')
    rows = {}
    for label, mutate, cause in [('candidate', None, None), *cases()]:
        changed = copy.deepcopy(positive)
        if mutate:
            mutate(changed)
            need(not same(changed, positive), 'every hostile parent candidate changes a real original field')
            save_product(label + '.json.gz', changed)
        path = BASE / (label + '.json.gz')
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', path.name]
        programmes = capture.instruments(command)
        started = dict(command=command, candidate=dict(path=str(path), identity=pin(path.read_bytes())),
                       programmes=programmes, expected_status=int(mutate is not None), intended_cause=cause)
        save('control-' + label + '-started.json', started)
        folder = Path('.artifacts/primary-raw-cause-parent-acceptance-20261011/controls') / label
        folder.mkdir(parents=True, exist_ok=False)
        with (folder / 'stdout.txt').open('xb', buffering=0) as out, (folder / 'stderr.txt').open('xb', buffering=0) as err:
            result = subprocess.run(command, stdout=out, stderr=err)
        actual = dict(**started, status=result.returncode, stdout=(folder / 'stdout.txt').read_text(),
                      stderr=(folder / 'stderr.txt').read_text(), programmes_after=capture.instruments(command),
                      candidate_after=pin(path.read_bytes()))
        save('control-' + label + '-actual.json', actual)
        need(type(result.returncode) is int and result.returncode == started['expected_status']
             and actual['programmes_after'] == programmes and actual['candidate_after'] == started['candidate']['identity'],
             'actual intended native parent result and source/product conservation')
        need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n') if mutate
             else actual['stdout'] == 'PASS independent complete unchanged finite cause/canonical parent composition; all original source/native/private limits retain.\n'
                  and actual['stderr'] == '', 'whole first intended native parent control outcome')
        rows[label] = pin(canonical(actual))
    save('controls.json', dict(owner=PLAN['owner'], actuals=rows,
        condition='Every full original underlying product is retained. Only the declared parent binding changes in each complete hostile candidate; direct native reader statuses and first diagnostics retain before judgment. Qualified original child source models remain shared assumptions.'))


if __name__ == '__main__':
    execute()
    print(SUCCESS, end='')
