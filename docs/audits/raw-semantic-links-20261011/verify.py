"""Full original semantic associations, separate body custody, and exact dated publication."""
import argparse
import gc
import subprocess
import re
from common import *
import controls
import intake
import produce
import reader

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
SUCCESS = 'PASS complete finite original raw semantic associations and genuine prior-preserving controls; original native/private and parent/publication scopes remain open.\n'


def actual(name, command):
    row = load('checks.json')[name]
    need(row['command'] == command and type(row.get('status')) is int and row['status'] == 0
         and row['programmes'] == row['programmes_after'] == programs() and row['inputs'] == row['inputs_after'] and row['epoch_conserved'] is True,
         'actual complete semantic qualification role and programme/source epoch: ' + name)
    return row


def nodes(raw):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n.*?(?=^- ID: |\Z)', raw, re.M | re.S))
    result = {m[1].decode(): m[0] for m in matches}
    need(len(result) == len(matches), 'unique complete semantic task identities')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1] if match else None


def contracts(final):
    before = git('show', REVISION + ':' + TASK)
    declared = gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes())
    repair = gzip.decompress(local(BASE / 'repair-declared-task.md.gz').read_bytes())
    old, start, fixed, end = map(nodes, (before, declared, repair, final))
    need(set(old) == set(start) and set(fixed) == set(end) == set(old) | {LEAF},
         'whole original semantic task population plus the solely owned typed repair')
    for key in old:
        if key == OWNER:
            need(all(field(old[key], k) == field(start[key], k) == field(fixed[key], k) == field(end[key], k)
                     for k in ('Goal', 'Acceptance')) and field(old[key], 'Status') == b'pending'
                 and field(start[key], 'Status') == field(fixed[key], 'Status') == b'active'
                 and field(end[key], 'Status') == b'done'
                 and field(old[key], 'Children') is None and field(start[key], 'Children') is None
                 and field(fixed[key], 'Children') == field(end[key], 'Children') == LEAF.encode(),
                 'unchanged full semantic acceptance closes only after its declared typed repair')
        else:
            need(old[key] == start[key] == fixed[key] == end[key], 'every other whole original task node conserves')
    need(all(field(fixed[LEAF], k) == field(end[LEAF], k) for k in ('Goal', 'Acceptance'))
         and field(fixed[LEAF], 'Status') == b'active' and field(end[LEAF], 'Status') == b'done',
         'complete typed repair acceptance closes without narrowing')
    return dict(original=pin(before), declared=pin(declared), repair=pin(repair), final=pin(final))


def core():
    old_native = local(CONSTRUCTION / 'native.pl').read_bytes()
    new_native = local(BASE / 'native.pl').read_bytes()
    need(new_native == old_native.replace(
        b"my $base = 'docs/audits/raw-semantic-association-product-20261011';",
        b"my $base = 'docs/audits/raw-semantic-links-20261011';", 1), 'whole original native body predicate with sole explicit own candidate-namespace relocation')
    before = load('intake-before.json')
    need(before == load('intake-after.json') == intake.derive(), 'whole fixed/current semantic source/native/product directory and byte custody')
    for prefix in ('before', 'after'):
        for role, root, success in (
            ('construction', CONSTRUCTION, 'PASS complete source-bound raw-body candidate construction, independent whole original body conservation and strict dated custody; independent semantic reconstruction and separating controls remain pending.\n'),
            ('custody', PRIOR, 'PASS complete required archive and whole construction/repair Git custody; original semantic/native/private scopes conserve.\n')):
            row = actual('bounded-' + prefix + '-' + role, ['python3', '-B', str(root / 'verify.py')])
            need(row['stdout'] == success and row['stderr'] == '', 'fresh whole unchanged predecessor/default role')
    history = actual('bounded-root-history', ['git', 'log', '-1', '-S', 'semantic_qualification', '--format=%H %s', '--', str(CONSTRUCTION / 'construct.py')])
    need(history['stdout'].startswith('8bdb1878533486e5e1887720d6ca671cdef0dc3c ') and history['stderr'] == '',
         'actual source-history locus of the construction-only semantic gap')
    candidate, base = product('candidate.json.gz'), inherited()
    need(reader.same(candidate, dict(base, semantic_links=produce.propose(base))), 'whole deterministic link proposal replay')
    proof = reader.qualify(candidate)
    need(proof == load('independent-bounded.json'), 'whole independent source-first complete reconstruction replay')
    saved = load('bounded-controls.json')
    declared = controls.cases()
    need([r['name'] for r in saved['cases']] == [r[0] for r in declared], 'complete genuine separating semantic control population')
    del candidate, base
    gc.collect()
    audits = []
    for row, (name, mutation, cause) in zip(saved['cases'], declared, strict=True):
        command = ['python3', '-B', str(BASE / 'bounded.py'), '--audit-case', name]
        result = subprocess.run(command, capture_output=True)
        actual_audit = dict(command=command, status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode())
        need(type(actual_audit['status']) is int and actual_audit['status'] == 0 and actual_audit['stderr'] == ''
             and actual_audit['stdout'] == 'PASS current bounded complete candidate and result ' + name + '\n',
             'actual fresh complete bounded intervention/result replay: ' + name)
        audits.append(actual_audit)
    need(load(saved['source_before']) == load(saved['source_after']) == before,
         'every complete inherited source/native/product meaning conserves across separating controls')
    first = load('boolean-phase-first-semantic-actual.json')
    first_native = load('boolean-phase-first-native-actual.json')
    changed = product('boolean-phase-first.json.gz'); wanted = product('candidate.json.gz')
    wanted['semantic_links']['records'][0]['phases'][0]['domain'][3] = False
    need(reader.same(changed, wanted) and type(first['status']) is int and first['status'] == 0
         and first['stdout'] == reader.SUCCESS and first['stderr'] == ''
         and first['programmes'] == first['programmes_after']
         and first['candidate'] == identity(BASE / 'boolean-phase-first.json.gz')
         and type(first_native['status']) is int and first_native['status'] == 0
         and first_native['stdout'] == controls.NATIVE_SUCCESS and first_native['stderr'] == '',
         'whole first Boolean false green and prior body acceptance retained in their original programme epoch')
    del changed, wanted
    gc.collect()
    correction = load('typed-correction.json')
    need(correction['first_programmes'] == first['programmes']
         and correction['qualified_programmes'] == load('bounded-correction.json')['first_programmes']
         and load('bounded-correction.json')['qualified_programmes'] == programs(), 'whole first and corrected typed programme epochs retain')
    typed_positive = actual('bounded-typed-positive', ['perl', str(BASE / 'typed.pl'), str(BASE / 'candidate.json.gz')])
    need(typed_positive['stdout'] == 'PASS independent semantic JSON integer record and phase coordinates.\n'
         and typed_positive['stderr'] == '', 'actual independent native positive JSON coordinate kinds')
    typed_negative = load('checks.json')['bounded-typed-boolean']
    need(typed_negative['command'] == ['perl', str(BASE / 'typed.pl'), str(BASE / 'boolean-phase-first.json.gz')]
         and type(typed_negative['status']) is int and typed_negative['status'] != 0
         and typed_negative['stdout'] == ''
         and typed_negative['stderr'].startswith('semantic phase coordinate requires a JSON integer at ' + str(BASE / 'typed.pl') + ' line ')
         and typed_negative['programmes'] == typed_negative['programmes_after'] == programs()
         and typed_negative['inputs'] == typed_negative['inputs_after'] and typed_negative['epoch_conserved'] is True,
         'actual intended independent native Boolean wire-kind refusal')
    focused = actual('bounded-focused', ['prove', '-v', 't/1549-task-tree-integrity-doctrine.t',
        't/1636-claim-verification-doctrine.t', 't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'])
    need('All tests successful.' in focused['stdout'] and focused['stderr'] == '', 'actual final-epoch focused regressions')
    return dict(scope=SCOPE, source=pin(canonical(before)), independent=proof, controls=pin(canonical(saved)), current_bounded_audits=audits,
        typed=dict(first=pin(canonical(first)), correction=pin(canonical(correction)), positive=pin(canonical(typed_positive)), negative=pin(canonical(typed_negative))),
        legs=dict(rederive='Separate candidate-derived proposal and source-first reconstruction of every complete raw/class/frame/header/argument/coordinate/address and nested cause association.',
                  falsify='Whole new-link interventions preserve exact inherited components and actual prior native body acceptance, then reach actual intended independent semantic refusals.',
                  durability='Whole fixed Git/source custody, complete positive/hostile products, programmes, commands and streams retain in the owning commit. Original native/private gaps remain explicit.'))


def publication():
    import publish
    record = load('publication.json')
    tasks = fixed_sources(record['task_names']); task = gzip.decompress(local(BASE / 'qualified-task.md.gz').read_bytes()); tasks[TASK] = task
    need(metrics(tasks) == load('task-census.json'), 'complete measured semantic task collection')
    books = fixed_sources(record['book_names'])
    before = gzip.decompress(local(BASE / 'book-before.md.gz').read_bytes())
    after = gzip.decompress(local(BASE / 'book-after.md.gz').read_bytes())
    need(before == books[BOOK] and after == before.replace(publish.MARKER, publish.ADDITION + publish.MARKER, 1), 'whole exact finite semantic book addition')
    registry = fixed_sources([SURFACES])[SURFACES]
    need(local(BASE / 'registry-before.txt').read_bytes() == registry
         and local(BASE / 'registry-after.txt').read_bytes() == publish.authority(registry, tasks, books, after), 'unchanged document ceilings and exact measured semantic authority')
    return dict(contracts=contracts(task), book=pin(after), registry=pin(local(BASE / 'registry-after.txt').read_bytes()))


def catalog():
    rows = {}
    for path in sorted(BASE.iterdir()):
        local(path)
        if path.name not in ('checks.json', 'manifest.json'):
            rows[path.name] = identity(path)
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    proof = dict(owner=LEAF, revision=REVISION, scope=SCOPE, semantic=core(), publication=publication(),
                 condition='All admitted source/native/instrument members remain whole byte-identical to the fixed d73200628 checkpoint. Original source models are shared assumptions; this is finite semantic association, not original native recapture or parent/canonical publication.')
    if args.seal:
        save('proof.json', proof); save('manifest.json', catalog())
    else:
        need(load('proof.json') == proof and load('manifest.json') == catalog(), 'whole strict semantic proof and complete own namespace')
    print(SUCCESS, end='')
