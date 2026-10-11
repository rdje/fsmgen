"""Qualify construction/custody only; never claim independent semantic completion."""
import argparse
import re
from common import *
import construct
import controls
import intake

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
ADMISSION = ('PASS complete dated raw-semantic admission, whole fixed/current source/native/product custody, '
             'fresh source/dated reader roles and genuine controls; full raw association/publication and original native/private scopes remain open.\n')
SUCCESS = ('PASS complete source-bound raw-body candidate construction, independent whole original body conservation '
           'and strict dated custody; independent semantic reconstruction and separating controls remain pending.\n')


def require_check(name, command, stdout=None):
    row = load('checks.json')[name]
    need(type(row.get('status')) is int and row['status'] == 0 and row['command'] == command,
         'actual complete construction check role: ' + name)
    need(row['programmes'] == programs() and row['inputs'] == row['inputs_after'] and row['epoch_conserved'] is True,
         'complete retained construction check programme epoch: ' + name)
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'] == '', 'whole actual construction check streams: ' + name)
    return row


def nodes(raw):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n.*?(?=^- ID: |\Z)', raw, re.M | re.S))
    result = {m[1].decode(): m[0] for m in matches}
    need(len(result) == len(matches), 'unique complete construction task nodes')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1] if match else None


def contracts(final):
    baseline = load('intake-before.json')['original_task']['body'].encode()
    declared = gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes())
    original, start, end = nodes(baseline), nodes(declared), nodes(final)
    parent = OWNER.rsplit('.', 1)[0]
    children = {parent + '.' + str(index) for index in range(1, 4)}
    need(set(start) == set(original) | children and set(end) == set(start), 'whole original and declared construction task population')
    for key in original:
        if key == parent:
            need(all(field(start[key], name) == field(original[key], name) for name in ('Goal', 'Acceptance'))
                 and field(original[key], 'Status') == b'pending' and field(start[key], 'Status') == b'active',
                 'unchanged full association acceptance before bounded decomposition')
            need(field(start[key], 'Children').decode().split(', ') == sorted(children), 'complete declared association child ownership')
        else:
            need(start[key] == original[key], 'every unrelated original task node conserved')
    for key in start:
        if key == OWNER:
            need(all(field(end[key], name) == field(start[key], name) for name in ('Goal', 'Acceptance'))
                 and field(start[key], 'Status') == b'active' and field(end[key], 'Status') == b'done',
                 'only completed construction leaf changes without narrowed acceptance')
        else:
            need(end[key] == start[key], 'every other declared task node conserved')
    return dict(original=pin(baseline), declared=pin(declared), final=pin(final), unchanged_parent_goal=field(original[parent], 'Goal').decode(),
                unchanged_parent_acceptance=field(original[parent], 'Acceptance').decode())


def core():
    before, after = load('intake-before.json'), load('intake-after.json')
    need(before == after == intake.derive(), 'whole fixed/current construction input and directory epoch')
    admission = require_check('admission', ['python3', '-B', str(PRIOR / 'verify.py')], ADMISSION)
    native = require_check('native-census', ['perl', str(BASE / 'native.pl')])
    need(native['stderr'] == '' and json.loads(native['stdout']) == load('native-census.json'), 'whole actual independent native body census')
    data, registry = construct.inputs()
    candidate = product('candidate.json.gz')
    need(canonical(candidate) == canonical(construct.derive(data, registry)), 'complete deterministic construction from every admitted role')
    for mode, actual in zip(load('native-census.json')['modes'], candidate['modes'], strict=True):
        need(mode['mode'] == actual['mode'], 'independent original candidate mode order')
        for name, domain in mode['domains'].items():
            own = actual['domains'][name]
            need(type(own['population']) is int and own['population'] == domain['population']
                 and own['empty_string_members'] == domain['empty_string_members']
                 and [r['original']['index'] for r in own['records']] == [r['index'] for r in domain['nonempty']],
                 'independent complete original body member allocation')
            for source, record in zip(domain['nonempty'], own['records'], strict=True):
                need(source['body'].encode() == record['original']['body'].encode()
                     and source['body_identity'] == record['original']['body_identity'], 'independent complete original UTF-8 body bytes')
    declared = controls.cases()
    saved = load('body-controls.json')
    need([r['name'] for r in saved['cases']] == [r[0] for r in declared], 'complete genuine body control population')
    for row, (name, mutation, diagnostic) in zip(saved['cases'], declared, strict=True):
        actual = load(row['actual'])
        command = ['perl', str(BASE / 'native.pl'), str(BASE / row['member'])]
        need(actual['command'] == command and actual['programmes'] == programs()
             and all(actual['inputs_after'][p] == v['identity'] for p, v in programs().items()),
             'whole actual independent body control command/programme epoch')
        need(local(actual['stdout_path']).read_bytes() == actual['stdout'].encode()
             and local(actual['stderr_path']).read_bytes() == actual['stderr'].encode(), 'whole durable actual body control streams')
        raw = local(BASE / row['member']).read_bytes()
        need(actual['candidate'] == pin(raw), 'whole genuine body candidate before judgement')
        hostile = product(row['member'])
        expected = product('candidate.json.gz')
        if mutation is not None:
            mutation(expected)
        need(canonical(hostile) == canonical(expected), 'complete exact positive/hostile candidate intervention')
        if diagnostic is None:
            need(type(actual['status']) is int and actual['status'] == 0 and actual['stdout'] == controls.SUCCESS
                 and actual['stderr'] == '', 'whole independent original positive body result')
        else:
            need(type(actual['status']) is int and actual['status'] != 0 and actual['stdout'] == ''
                 and actual['stderr'].startswith(diagnostic + ' at ' + str(BASE / 'native.pl') + ' line '),
                 'whole actual intended body control refusal')
    need(load('control-source-before.json') == load('control-source-after.json') == before,
         'every inherited source/native/product meaning conserved across actual controls')
    return dict(scope=SCOPE, input=pin(canonical(before)), admission=pin(canonical(admission)), native=pin(canonical(native)),
                candidate=pin(canonical(candidate)), body_controls=pin(canonical(saved)),
                independence='Constructor and deterministic replay share qualified source models. The separate Perl reader independently extracts complete original captured body bytes and allocation. Full semantic independence and prior-preserving semantic controls remain .5.2.2.2; no native class/identity inference.')


def publication():
    import publish
    sources = load('publication.json')
    tasks = fixed_sources(sources['task_names'])
    task = gzip.decompress(local(BASE / 'qualified-task.md.gz').read_bytes())
    tasks[TASK] = task
    need(load('task-census.json') == metrics(tasks), 'whole exact task collection and measured debt')
    books = fixed_sources(sources['book_names'])
    before = gzip.decompress(local(BASE / 'book-before.md.gz').read_bytes())
    after = gzip.decompress(local(BASE / 'book-after.md.gz').read_bytes())
    need(before == books[BOOK] and after == before.replace(publish.MARKER, publish.ADDITION + publish.MARKER, 1),
         'complete construction-only book addition without semantic promotion')
    registry = fixed_sources([SURFACES])[SURFACES]
    need(local(BASE / 'registry-before.txt').read_bytes() == registry
         and local(BASE / 'registry-after.txt').read_bytes() == publish.authority(registry, tasks, books, after),
         'complete exact measured publication authority without ceiling or Knowledge Map widening')
    return dict(contracts=contracts(task), book_before=pin(before), book_after=pin(after), registry=pin(local(BASE / 'registry-after.txt').read_bytes()))


def catalog():
    files, directories = {}, []
    for path in sorted(BASE.rglob('*')):
        local(path, exists=False)
        if path.is_dir():
            directories.append(str(path.relative_to(BASE)))
        else:
            local(path)
            relative = str(path.relative_to(BASE))
            if relative not in ('manifest.json', 'checks.json'):
                files[relative] = identity(path)
    return dict(files=files, directories=directories)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    proof = dict(owner=OWNER, revision=REVISION, scope=SCOPE, construction=core(), publication=publication(),
        legs=dict(rederive='Whole fixed/current Git bytes and deterministic complete construction from qualified source models.',
                  falsify='Separate Perl original body/allocation/UTF-8 reader and genuine complete byte-conservation candidate controls. Full semantic falsification is explicitly pending .5.2.2.2.',
                  durability='Whole source/capture Git recovery, complete candidate/control bodies, commands/programmes/streams, task contracts and strict namespace in the owning commit.'),
        condition='Dated construction replay requires all admitted source/instruments byte-identical to cb5d85b9. Later changes need a separately qualified complete dated checkpoint; no later current/native currency.')
    if args.seal:
        save('proof.json', proof)
        save('manifest.json', catalog())
    else:
        need(load('proof.json') == proof and load('manifest.json') == catalog(), 'whole sealed dated construction proof and namespace')
    print(SUCCESS, end='')
