"""Qualify the admitted raw source fact and complete current publication."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import re
import stat
import subprocess
import sys

from capture import BASE, canonical, pin, save
import publish

sys.path.insert(0, 'scripts')
import check_record_value_publication as current
import record_value_raw_fact as fact

PLAN = publish.PLAN
SUCCESS = 'PASS complete admitted raw canonical publication; full raw closure and original native/private acceptance remain separately owned.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {
    label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def need(value, message):
    if not value:
        raise ValueError(message)


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, status=0, stdout=None):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(all(row[k] == value for k, value in started.items()), 'whole native started declaration')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == status,
         'actual typed intended native terminal ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and row['programmes'] == row['programmes_after'], 'whole native command and conserved programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole recorded native programme/input identity')
        expected = (BASE / 'capture-before.py.txt').read_bytes() if label == 'gate-before' and name == str(BASE / 'capture.py') else Path(name).read_bytes()
        need(body == expected, 'whole explicit current or first dated writer programme')
    need(re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged completed RAM guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended native result ' + label)
    return pin(canonical(row))


def obligations(raw):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n', raw, re.M))
    result = {m[1].decode(): raw[m.start():matches[i+1].start() if i+1 < len(matches) else len(raw)]
              for i, m in enumerate(matches)}
    need(len(matches) == len(result), 'unique whole task population')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1] if match else None


def core():
    admitted = fact.authenticate()
    admission = read('admission.json')
    need(admission['qualification'] == admitted and admission['candidate'] == fact.admission()
         and admission['after'] == fact.published(fact.admission()), 'whole current admitted finite raw association')
    first_factory = (BASE / 'before-factory.py.txt').read_bytes()
    fixed = subprocess.run(['git', '--no-replace-objects', 'show', PLAN['revision'] + ':scripts/check_record_value_publication.py'],
                           capture_output=True)
    need(fixed.returncode == 0 and fixed.stderr == b'' and fixed.stdout == first_factory,
         'whole original current-factory source epoch before advancement')
    before_gate = gate('gate-before', ['python3', '-B', str(BASE / 'before.py')], 1,
        'REFUSED prepared finite raw update at existing target-meaning contract: complete current target meanings questions metadata and replay routes\n')
    admitted_gate = gate('gate-admission', ['python3', '-B', str(BASE / 'admit.py')], stdout=
        'PASS complete admitted raw source/body/namespace and non-growing canonical preflight; production remains unpublished.\n')
    fixture_gate = gate('gate-fixed-source', ['python3', '-B', str(BASE / 'fixed_context.py')], stdout=
        'PASS unchanged complete dated reader, genuine current-instrument refusal and exact restored source/native result.\n')
    fixture = read('fixed-source-control.json')
    need(fixture['before'] == fixture['restored'] == admitted['source']
         and fixture['original_body'].encode() == first_factory
         and fixture['current_body'].encode() == Path('scripts/check_record_value_publication.py').read_bytes()
         and fixture['original_factory'] == pin(first_factory)
         and fixture['current_factory'] == pin(fixture['current_body'].encode())
         and fixture['original_factory'] != fixture['current_factory'], 'genuine complete original/current source intervention')
    original, changed, restored = (read(label + '-result.json') for label in fixture['labels'])
    need(type(original['status']) is int and original['status'] == 0 and original['stdout'] == fact.PARENT_SUCCESS
         and original['stderr'] == '' and restored == original, 'complete successful unchanged dated native results before and after')
    need(type(changed['status']) is int and changed['status'] == 1 and changed['stdout'] == ''
         and 'whole current source equals fixed Git bytes' in changed['stderr'], 'whole genuine fixed/current-source refusal')
    canonical_sources = current.sources()
    prior = current.historical()
    record = current.current_input(prior, canonical_sources)
    current.check(record, canonical_sources, prior, current.authority(prior))
    need(Path(fact.CARD).read_bytes() == admission['after'].encode(), 'whole published canonical raw fact')
    positive = json.loads((fact.PREPARATION / 'parent-checkpoint-v3-actual.json').read_bytes())
    controls = []
    for name, mutate, cause in (
        ('Boolean native success', lambda r: r.update(status=False), 'actual admitted raw checkpoint integer success'),
        ('borrowed source role', lambda r: r.update(revision='later-live-code'), 'complete original raw checkpoint source role and command'),
        ('short native terminal', lambda r: r.update(stdout='PASS\n'), 'complete actual original raw checkpoint terminal')):
        altered = copy.deepcopy(positive)
        mutate(altered)
        try:
            fact.check_checkpoint(altered, admitted['source'])
        except ValueError as error:
            need(str(error) == cause, 'actual intended current checkpoint refusal')
            controls.append(dict(name=name, cause=str(error)))
        else:
            raise ValueError('altered admitted checkpoint accepted')
    normal = read('preparation-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'], 'complete committed preparation normal-hook prerequisite')
    return dict(owner=PLAN['owner'], admitted=admitted, admission=pin(canonical(admission)),
                before=before_gate, preflight=admitted_gate, fixed_source=fixture_gate, controls=controls,
                current_source=pin(canonical({name: pin(raw) for name, raw in canonical_sources.items()})),
                condition=PLAN['condition'], legs=dict(
                    rederive='Whole original fixed Git source bodies/modes/membership, admitted original native evidence and complete current canonical meanings/questions/source/query/capacity.',
                    falsify='Actual prior target refusal, genuine advanced-producer fixed-source refusal with exact restoration, typed original checkpoint and permanent current/native controls.',
                    durability='Complete admitted preparation, original fixed Git graph, whole original/current programmes, full actual source/control/gate terminals and exact publication snapshots; no ignored view is read here.'))


def publication():
    row = read('publication.json')
    snapshots = {}
    for name, epochs in row['snapshots'].items():
        snapshots[name] = {}
        for role, entry in epochs.items():
            body = gzip.decompress(Path(entry['snapshot']).read_bytes())
            need(pin(body) == entry['identity'], 'whole canonical publication snapshot')
            snapshots[name][role] = body
        need(Path(name).read_bytes() == snapshots[name]['after'], 'whole current canonical publication source')
    before, after = (obligations(snapshots[publish.TASK][role]) for role in ('before', 'after'))
    need(before.keys() == after.keys(), 'complete task graph conserves')
    for key in before:
        need(all(field(before[key], f) == field(after[key], f) for f in ('Goal', 'Acceptance', 'Children')),
             'every whole original task contract conserves')
        if key == PLAN['owner']:
            need(field(before[key], 'Status') == b'active' and field(after[key], 'Status') == b'done', 'only canonical publication closes')
        else:
            need(before[key] == after[key], 'every unrelated complete task node conserves')
    need(snapshots[publish.BOOK]['after'] == snapshots[publish.BOOK]['before'].replace(row['old_notice'].encode(), fact.GUIDE.encode(), 1)
         and len(snapshots[publish.BOOK]['after']) <= 292485, 'only bounded admitted raw guide changes')
    cards = {name: Path(name).read_bytes() for name in row['card_names']}
    measured = publish.metrics(cards)
    cards[fact.CARD] = snapshots[fact.CARD]['before']
    previous = publish.metrics(cards)
    need(measured == row['measured_cards'] and previous == row['previous_cards']
         and all(value <= previous[key] for key, value in measured.items()), 'complete actual canonical collection does not grow')
    old_rows = list(map(json.loads, snapshots[publish.REGISTRY]['before'].splitlines()))
    new_rows = list(map(json.loads, snapshots[publish.REGISTRY]['after'].splitlines()))
    need(len(old_rows) == len(new_rows), 'complete unchanged authority population')
    for old, new in zip(old_rows, new_rows, strict=True):
        wanted = copy.deepcopy(old)
        if old.get('surface_id') == 'task_evidence':
            for key, value in publish.metrics({n: Path(n).read_bytes() for n in row['task_names']}).items():
                need(value <= old['enforcement_ceilings'][key], 'unchanged task ceiling')
                wanted['transition']['max_growth'][key] = max(0, value + old['transition']['ratchet_step'][key] - old['baseline'][key])
        elif old.get('surface_id') == 'shipped_behavior':
            authority = new['reference_contract']['aggregate_change']
            books = {name: Path(name).read_bytes() for name in row['book_names']}
            now = publish.metrics(books)
            books[publish.BOOK] = snapshots[publish.BOOK]['before']
            former = publish.metrics(books)
            keys = ('files', 'bytes_total', 'lines_total')
            need(authority['owner'] == PLAN['owner'] and authority['authority_id'] == 'RAW-CANONICAL-PUBLICATION-20261011'
                 and authority['baseline'] == {k: former[k] for k in keys}
                 and authority['delta'] == {k: now[k] - former[k] for k in keys}, 'whole own book aggregate authority')
            wanted['reference_contract']['aggregate_change'] = authority
        need(wanted == new, 'every Knowledge Map allowance and all other authority/ceiling fields conserve')
    return {name: pin(epochs['after']) for name, epochs in snapshots.items()}


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'complete flat ordinary same-volume publication namespace')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit canonical qualification role')
    result = core()
    if args.core:
        print('PASS complete finite raw admission and current canonical core; delivery remains separate.')
        return
    result['publication'] = publication()
    commands = {
        'gate-publication': ['python3', '-B', str(BASE / 'publish.py')],
        'gate-map': ['knowledge-map/scripts/gen_knowledge_map.sh'],
        'gate-sources': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
        'root-history': ['git', 'log', '-1', '-S', 'observer_fact.cards', '--format=%H %s', '--', 'scripts/check_record_value_publication.py'],
        'focused': ['prove', '-v', 't/2066-record-value-current-publication.t', 't/2067-record-value-gate-streams.t',
                    't/1549-task-tree-integrity-doctrine.t', 't/1636-claim-verification-doctrine.t',
                    't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
        'book': ['mdbook', 'build', 'docs/book'],
        'native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
        'size': ['scripts/check_live_document_size.sh'], 'claims': ['scripts/check_claim_verification.pl'],
        'inventory-write': ['scripts/check_claim_verification_inventory.pl', '--write'],
        'inventory': ['scripts/check_claim_verification_inventory.pl']}
    result['external'] = {name: gate(name, command) for name, command in commands.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'complete actual focused regression success')
    if args.seal:
        save('proof.json', result)
        save('manifest.json', catalogue())
    else:
        need(read('proof.json') == result and read('manifest.json') == catalogue(), 'whole immutable complete canonical publication')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
