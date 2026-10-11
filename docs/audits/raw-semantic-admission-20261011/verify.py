"""Qualify complete admission and actual reader receipts under an explicit source condition."""
import argparse
import copy
import gzip
import re
from pathlib import Path
from common import *
import intake
import run

SUCCESS = ('PASS complete dated raw-semantic admission, whole fixed/current source/native/product custody, '
           'fresh source/dated reader roles and genuine controls; full raw association/publication and original native/private scopes remain open.\n')


def task_nodes(raw):
    marker = b'## Task Tree\n'
    need(raw.count(marker) == 1, 'unique authoritative task graph')
    section = raw.split(marker, 1)[1].split(b'\n## ', 1)[0]
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n.*?(?=^- ID: `|\Z)', section, re.M | re.S))
    result = {match[1].decode(): match[0] for match in matches}
    need(len(result) == len(matches), 'unique authoritative task identities')
    return result


def field(raw, key):
    values = re.findall(rb'^  ' + key.encode() + rb': `([^`\n]*)`$', raw, re.M)
    need(len(values) == 1, 'whole task field ' + key)
    return values[0].decode()


def contracts(source, declared, final):
    before, active, after = map(task_nodes, (source, declared, final))
    parent = OWNER.rsplit('.', 1)[0]
    new_ids = {parent + '.' + str(index) for index in range(1, 4)}
    need(set(active) == set(before) | new_ids and set(after) == set(active), 'only declared raw semantic children added')
    for name, block in before.items():
        if name == parent:
            need(all(field(active[name], key) == field(block, key) == field(after[name], key)
                     for key in ('Goal', 'Acceptance')), 'original full raw semantic parent contract conserves')
        else:
            need(active[name] == block == after[name], 'every unrelated complete task node remains exact')
    need(all(active[name] == after[name] for name in new_ids if name != OWNER), 'both semantic successors unchanged')
    need(field(after[OWNER], 'Status') == 'done' and field(after[OWNER], 'Commit') != 'pending', 'closed admission owner')
    need(final == declared.replace(active[OWNER], after[OWNER], 1), 'whole final task changes only by admission closure')
    return dict(original_task=pin(source), declared_task=pin(declared), qualified_task=pin(final),
                parent_goal=field(before[parent], 'Goal'), parent_acceptance=field(before[parent], 'Acceptance'),
                unchanged_nodes={name: pin(raw) for name, raw in before.items() if name != parent})


def catalog():
    result, directories = {}, []
    for path in sorted(BASE.rglob('*')):
        local(path, exists=False)
        if path.is_dir():
            directories.append(str(path.relative_to(BASE)))
        else:
            local(path)
            if str(path.relative_to(BASE)) not in ('manifest.json', 'checks.json'):
                result[str(path.relative_to(BASE))] = identity(path)
    return dict(members=result, directories=directories, mutable=['checks.json'])


def actual_readers():
    product = load('readers.json')
    specs = run.specifications()
    need(product['revision'] == REVISION and product['owner'] == OWNER and product['scope'] == SCOPE
         and set(product['readers']) == set(specs), 'complete fresh reader/source/role population')
    actuals = {}
    for name, spec in specs.items():
        entry = product['readers'][name]
        path = Path(entry['receipt'])
        need(path.parent == BASE and entry['specification'] == spec
             and pin(local(path).read_bytes()) == entry['identity'], 'whole own fresh actual reader receipt')
        actual = json.loads(path.read_bytes())
        run.qualify(actual, spec)
        need(actual['source_revision'] == REVISION and actual['owner'] == OWNER, 'whole fresh reader owner/source role')
        for key in ('stdout', 'stderr'):
            need(local(actual[key + '_path']).read_bytes() == actual[key].encode(), 'whole retained actual child stream bytes')
        actuals[name] = dict(receipt=str(path), identity=entry['identity'], context=spec['context'])
    return actuals


def controls(retain):
    original = load('readers.json')
    name = sorted(original['readers'])[0]
    record = json.loads(local(original['readers'][name]['receipt']).read_bytes())
    spec = run.specifications()[name]
    result = {}
    for label, mutate, cause in (
        ('Boolean-status', lambda row: row.update(status=True), 'actual integer reader success'),
        ('nonzero-status', lambda row: row.update(status=1), 'actual integer reader success'),
        ('borrowed-role', lambda row: row.update(command=['python3', '-B', 'borrowed.py']), 'exact complete reader command'),
        ('short-stream', lambda row: row.update(stdout='PASS\n'), 'complete declared source or dated reader stdout role'),
        ('missing-programme', lambda row: row.update(programs={}), 'complete own reader runner and direct instrument population'),
        ('borrowed-epoch', lambda row: row.update(epoch_conserved=False), 'whole reader programme conservation')):
        candidate = copy.deepcopy(record)
        mutate(candidate)
        diagnostic = None
        try:
            run.qualify(candidate, spec)
        except ValueError as error:
            diagnostic = str(error)
        row = dict(candidate=candidate, actual_diagnostic=diagnostic)
        if retain:
            save('control-' + label + '.json', row)
        else:
            need(load('control-' + label + '.json') == row, 'whole saved actual result-control bytes')
        need(candidate != record and diagnostic == cause, 'genuine intended actual-result refusal')
        result[label] = pin(canonical(row))
    return result


def publication(final):
    import finish
    product = load('publication.json')
    need(product['source_revision'] == REVISION, 'exact publication source revision')
    names = git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    need(product['task_names'] == task_names and product['book_names'] == book_names, 'complete dated task/book source populations')
    fixed = fixed_sources(task_names + book_names + [finish.SURFACES])
    tasks = {name: fixed[name] for name in task_names}
    tasks[TASK] = final
    need(canonical(metrics(tasks)) == canonical(load('task-census.json')), 'complete dated whole task-source census')
    before = local(BASE / 'registry-before.txt').read_bytes()
    after = local(BASE / 'registry-after.txt').read_bytes()
    book_before = gzip.decompress(local(BASE / 'book-before.md.gz').read_bytes())
    book_after = gzip.decompress(local(BASE / 'book-after.md.gz').read_bytes())
    need(before == fixed[finish.SURFACES] and book_before == fixed[finish.BOOK], 'whole original registry/book source equality')
    need(pin(before) == product['registry_before'] and pin(after) == product['registry_after']
         and pin(book_before) == product['book_before'] and pin(book_after) == product['book_after'], 'whole publication source identities')
    need(after == finish.authority(before, tasks, {name: fixed[name] for name in book_names}, book_after),
         'only exact owned measured task allowance and sole book authority change')
    return pin(canonical(product))


def native_record(native):
    native_path = Path(native['receipt'])
    need(native_path.parent == BASE, 'own complete native source census receipt')
    actual = json.loads(local(native_path).read_bytes())
    need(pin(canonical(actual)) == native['identity'] and actual['status'] == 0
         and type(actual['status']) is int and actual['stderr'] == '' and actual['epoch_conserved'] is True,
         'complete actual independent native source census')
    need(actual['command'] == ['perl', str(BASE / 'census.pl'), str(BASE / 'intake-before.json')],
         'whole independent native source census command')
    for path, row in (actual['programs'] | actual['direct_instruments']).items():
        need(pin(row['body'].encode()) == row['identity'] == actual['inputs_after'][path],
             'whole retained native census programme and input epoch')
    need(actual['direct_instruments'][str(BASE / 'census.pl')]['identity'] == pin(local(BASE / 'census.pl').read_bytes()),
         'unchanged independent native census instrument')
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    before, after = load('intake-before.json'), load('intake-after.json')
    need(canonical(before) == canonical(after) == canonical(intake.derive()), 'whole dated original/final/current input condition')
    native = load('native-census.json')
    actual = native_record(native)
    wanted = dict(members={name: dict(bytes=row['bytes'], sha256=row['sha256'], executable=row['mode'] == '100755')
                           for name, row in before['members'].items()}, directories=before['directories'])
    need(json.loads(actual['stdout']) == wanted, 'whole independent Python/Git and native filesystem source parity')
    topology = load('topology-controls.json')
    need(topology['programme'] == pin(local(BASE / 'topology.py').read_bytes())
         and set(topology['cases']) == {'positive', 'missing', 'changed-tail', 'extra-file', 'empty-directory', 'symlink', 'foreign-path'},
         'complete actual source-bound topology control population')
    for name, row in topology['cases'].items():
        need(canonical(row) == canonical(load('topology-' + name + '.json')), 'whole saved topology candidate and actual outcome')
        need(type(row['native']['status']) is int, 'native topology actual discrete status')
        if name == 'positive':
            need(row['python_diagnostic'] is None and row['native']['status'] == 0
                 and row['native']['stderr'] == '', 'whole genuine native/Python positive topology')
        else:
            need(type(row['python_diagnostic']) is str and row['native']['status'] != 0,
                 'whole genuine native/Python hostile topology')
            intended = {'changed-tail': 'complete independent whole source bytes and mode',
                'empty-directory': 'complete independent source directory population',
                'extra-file': 'complete independent source file population',
                'missing': 'complete independent source file population',
                'symlink': 'ordinary same-volume source node', 'foreign-path': 'own relative source path'}
            need(row['native']['stderr'].startswith(intended[name] + ' at '),
                 'native topology refusal reaches its intended source contract')
    declared = gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes())
    final = gzip.decompress(local(BASE / 'qualified-task.md.gz').read_bytes())
    contract = contracts(before['original_task']['body'].encode(), declared, final)
    proof = dict(owner=OWNER, revision=REVISION, scope=SCOPE, input=pin(canonical(before)),
        native=pin(canonical(native)), topology=pin(canonical(topology)), contracts=contract, publication=publication(final),
        readers=actual_readers(), controls=controls(args.seal),
        legs=dict(rederive='Whole fixed Git objects compared byte for byte with every current native/product/source member and exact directory closure.',
                  falsify='Separate native Perl filesystem/member/hash/mode/directory census, genuine typed-result and source-topology controls, actual reader executions in exact roles.',
                  durability='Full revision/object/path recovery contract, full original/declaration/final task bodies, all programmes/commands/streams and positive/hostile products under strict own seal and owning commit.'),
        condition='Default replay requires every admitted source/instrument to remain byte-identical to 3a5229ffa. Later publication changes require an explicit complete dated checkpoint; no later current/native currency is inferred.')
    if args.seal:
        save('proof.json', proof)
        save('manifest.json', catalog())
    else:
        need(canonical(load('proof.json')) == canonical(proof) and canonical(load('manifest.json')) == canonical(catalog()),
             'whole strict dated admission proof and namespace')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
