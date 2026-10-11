"""Reconstruct the complete dated source graph; replay genuine native controls."""
import argparse
import base64
import copy
import gzip
import json
import re
import subprocess
from pathlib import Path
from common import *

NATIVE = r'''
my $input=decode_json(do {local $/; <STDIN>}); my (%members,%graphs);
my ($files,$bytes,$lines,$maxbytes,$maxlines,$maxwidth)=(0,0,0,0,0,0);
for my $name (sort keys %{$input->{sources}}) {
 my $raw=decode_base64($input->{sources}{$name}); my $n=()=$raw=~/\n/g; my $w=0;
 while ($raw=~/([^\n]*\n|[^\n]+\z)/g) {my $l=$1; $l=~s/\r?\n\z//; $w=length($l) if length($l)>$w;}
 $members{$name}={bytes=>length($raw),sha256=>sha256_hex($raw),lines=>$n,line_bytes=>$w};
 $files++;$bytes+=length($raw);$lines+=$n;
 $maxbytes=length($raw) if length($raw)>$maxbytes;$maxlines=$n if $n>$maxlines;$maxwidth=$w if $w>$maxwidth;
}
for my $name (sort keys %{$input->{graphs}}) {
 my $raw=decode_base64($input->{graphs}{$name});
 $raw=~/^## Task Tree\n(.*?)(?=^## |\z)/ms or die "missing authoritative section";
 my $section=$1; my %nodes;
 while ($section=~/^(- ID: `([^`]+)`\n.*?)(?=^- ID: `|\z)/msg) {
  die "duplicate node" if exists $nodes{$2};$nodes{$2}=encode_base64($1,'');
 }
 $graphs{$name}=\%nodes;
}
print JSON::PP->new->canonical->encode({census=>{members=>\%members,metrics=>{
 files=>$files,bytes_total=>$bytes,lines_total=>$lines,bytes_each=>$maxbytes,lines_each=>$maxlines,line_bytes_each=>$maxwidth}},graphs=>\%graphs}),"\n";
'''


def retain_first(path, raw):
    if Path(path).exists():
        need(local(path).read_bytes() == raw, 'first complete control bytes conserved')
    else:
        save(path, raw)


def independent(sources, graphs):
    payload = canonical(dict(sources={name: base64.b64encode(raw).decode() for name, raw in sources.items()},
                             graphs={name: base64.b64encode(raw).decode() for name, raw in graphs.items()}))
    command = ['perl', '-MJSON::PP', '-MMIME::Base64=decode_base64,encode_base64',
               '-MDigest::SHA=sha256_hex', '-e', NATIVE]
    actual = subprocess.run(command, input=payload, capture_output=True)
    result = dict(command=command, stdin=pin(payload), status=actual.returncode,
                  stdout=actual.stdout.decode(), stderr=actual.stderr.decode())
    need(actual.returncode == 0 and actual.stderr == b'', 'complete independent native census')
    expected = dict(census=metrics(sources), graphs={name: {key: base64.b64encode(body).decode()
                     for key, body in nodes(raw).items()} for name, raw in graphs.items()})
    need(json.loads(actual.stdout) == expected, 'independent whole-member/whole-node native parity')
    return result


def controls(candidate, sources, retain=False):
    instrument = SCRATCH / 'instrument/checker.pl'
    local(instrument, exists=False).parent.mkdir(parents=True, exist_ok=True)
    local(instrument, exists=False).write_bytes(sources[CHECKER])
    graph = nodes(candidate)
    root = ROOTS[0]
    block = graph[root]
    mutations = {
        'positive': (candidate, None),
        'wrong-revision': (candidate.replace(block, block.replace(REVISION.encode(), b'0' * 40)),
                           'cannot retrieve exact version object'),
        'wrong-digest': (candidate.replace(block, block.replace(field(block, 'Retrieved SHA256').encode(), b'0' * 64)),
                         'retrieved digest mismatch'),
        'wrong-count': (candidate.replace(block, block.replace(
            ('  Archived node count: `' + field(block, 'Archived node count') + '`').encode(),
            ('  Archived node count: `' + str(int(field(block, 'Archived node count')) + 1) + '`').encode())),
            'does not match retrieved count'),
        'narrowed-goal': (candidate.replace(block, block.replace(field(block, 'Goal').encode(), b'Narrowed.')),
                          'Goal differs from its version object'),
        'missing-retrieval': (candidate.replace(block, block.replace(('  Retrieval path: `' + TASK + '`\n').encode(), b'')),
                              'must have exactly one Retrieval path field'),
        'missing-live-node': (candidate.replace(graph[TREE + '.82'], b''), 'lists nonexistent direct children'),
    }
    results = {}
    for name, (raw, diagnostic) in mutations.items():
        fixture = SCRATCH / 'controls' / name
        for path, body in {TASK: raw, HISTORY: sources[HISTORY], RETENTION: sources[RETENTION],
                'docs/TASK_TREE.md': ('# Fixture\n\n## Active Task Trees\n\n'
                    f'| `{TREE}` | `active` | [task]({TASK}) |\n').encode()}.items():
            target = local(fixture / path, exists=False)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(body)
        command = ['perl', str(instrument), '--root', str(fixture)]
        actual = subprocess.run(command, capture_output=True)
        row = dict(command=command, candidate=pin(raw), instrument=pin(sources[CHECKER]),
                   status=actual.returncode, stdout=actual.stdout.decode(), stderr=actual.stderr.decode(),
                   expected_diagnostic=diagnostic)
        if retain:
            retain_first(BASE / 'controls' / (name + '-task.md.gz'), gzip.compress(raw, mtime=0))
            retain_first(BASE / 'controls' / (name + '.json'), canonical(row))
        # Save the entire candidate and actual outcome before evaluating it.
        need(type(actual.returncode) is int, 'actual native exit status')
        if diagnostic is None:
            need(actual.returncode == 0 and actual.stderr == b'', 'positive native whole-graph control')
        else:
            need(raw != candidate and actual.returncode != 0 and diagnostic in row['stderr'],
                 'genuine native rejection: ' + name)
        results[name] = row
    # The task checker validates graph closure, not registry-owner eligibility.
    # Exercise that separate selection rule with a genuinely augmented corpus.
    owners = owner_census(sources)
    synthetic = dict(path='synthetic-live-registry', pointer='/owner_task', key='owner_task',
                     owner=next(key for key in nodes(sources[TASK]) if key.startswith(root + '.')))
    augmented = owners + [synthetic]
    diagnostic = None
    try:
        eligible(nodes(sources[TASK]), root, augmented)
    except ValueError as error:
        diagnostic = str(error)
    row = dict(kind='synthetic independent selection control; not a production-checker owner claim',
               original_owners=owners, augmented_owners=augmented, diagnostic=diagnostic)
    if retain:
        retain_first(BASE / 'controls/live-owner.json', canonical(row))
    need(diagnostic == 'live registry owner would be hidden', 'genuine live-owner selection refusal')
    results['live-owner'] = row
    return results


def rederive(sources, declared, compacted, final, after_sources):
    census = json.loads(local(BASE / 'source-census.json').read_bytes())
    need(census['revision'] == REVISION, 'full pinned predecessor')
    need(census['sources'] == {name: pin(raw) for name, raw in sources.items()}, 'entire retained source boundary')
    need(sources == frozen_sources(sources), 'whole exact retained Git source equality')
    names = git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    doctrine_names = sorted(name for name in names if name.startswith('doctrine/') and name.endswith(('.json', '.jsonl')))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    need(census['task_names'] == task_names and census['doctrine_names'] == doctrine_names
         and census['book_names'] == book_names, 'complete independent fixed source populations')
    need(set(sources) == set(task_names + doctrine_names + book_names + [CARD, CHECKER, HISTORY, RETENTION]),
         'no missing or unclassified retained member')
    owners = owner_census(sources)
    need(census['owners'] == owners, 'every owner field in complete conservative doctrine corpus')
    old, start, live, done = (nodes(raw) for raw in (sources[TASK], declared, compacted, final))
    need(set(start) == set(old) | {OWNER}, 'only own declaration added before compaction')
    need(start[TREE] == old[TREE].replace(b'`\n\n', (', ' + OWNER + '`\n\n').encode(), 1),
         'root changes only by new owner edge')
    need(all(start[name] == raw for name, raw in old.items() if name != TREE), 'all other original live nodes exact')
    without_declaration = declared.replace(start[TREE], old[TREE], 1).replace(start[OWNER], b'', 1)
    need(without_declaration == sources[TASK].replace(b'Last updated: `2026-10-10`', b'Last updated: `2026-10-11`', 1),
         'whole source changes only by owner declaration and dated metadata')
    need(compacted == compact(declared, sources[TASK], owners), 'deterministic whole subtree projection')
    retained = {}
    subtrees = {}
    for root in ROOTS:
        subtree = eligible(old, root, owners)
        subtrees[root] = dict(nodes=len(subtree), bytes=sum(map(len, subtree.values())),
            lines=sum(raw.count(b'\n') for raw in subtree.values()),
            members={name: pin(raw) for name, raw in subtree.items()})
        need(live[root] == terminal(root, sources[TASK], len(subtree)), 'complete exact descriptor')
        retained.update(subtree)
    reconstructed = {name: raw for name, raw in live.items() if name not in ROOTS}
    reconstructed.update(retained)
    need(reconstructed == start, 'all original goals/acceptances/children/verification/commit bytes reconstructed')
    need(set(done) == set(live) and all(done[name] == raw for name, raw in live.items() if name != OWNER),
         'final signoff changes only this owner node')
    need(final == compacted.replace(live[OWNER], done[OWNER], 1), 'every prefix/footer/history byte conserved')
    need(field(done[OWNER], 'Status') == 'done' and field(done[OWNER], 'Commit') != 'pending', 'closed owning leaf')
    for row in owners:
        if selected(row['owner'], TREE):
            need(row['owner'] in done, 'all conservative semantic registry owners remain directly readable')
    protected = {name: pin(raw) for name, raw in old.items() if selected(name, RAW)}
    need(all(done[name] == old[name] for name in protected), 'entire raw acceptance forest unchanged')
    need(set(after_sources) == set(doctrine_names) | {TASK, BOOK, CARD, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole current registry and changed source boundary')
    for name in doctrine_names:
        if name not in (SURFACES, 'doctrine/claim_verification/inventory.jsonl'):
            need(after_sources[name] == sources[name], 'every other complete registry source unchanged')
    final_owners = owner_census(after_sources)
    need(all(not selected(row['owner'], root) for row in final_owners for root in ROOTS),
         'all current registry references remain outside archived nodes')
    need(after_sources[TASK] == final, 'saved final task identity')
    card = after_sources[CARD]
    need(len(card) <= len(sources[CARD]) and card.count(b'\n') <= sources[CARD].count(b'\n'), 'non-growing canonical card')
    old_answers = sources[CARD].split(b'answers:\n', 1)[1].split(b'date:', 1)[0]
    need(old_answers == card.split(b'answers:\n', 1)[1].split(b'date:', 1)[0], 'all ordered canonical answers preserved')
    before_rows = [json.loads(line) for line in sources[SURFACES].splitlines()]
    after_rows = [json.loads(line) for line in after_sources[SURFACES].splitlines()]
    need(len(before_rows) == len(after_rows), 'same registry membership')
    task_sources = {name: sources[name] for name in task_names}
    task_sources[TASK] = final
    actual = metrics(task_sources)
    wanted_rows = copy.deepcopy(before_rows)
    for before, row in zip(before_rows, wanted_rows):
        if row.get('surface_id') == 'task_evidence':
            for dimension, value in actual['metrics'].items():
                growth = max(0, value + row['transition']['ratchet_step'][dimension] - row['baseline'][dimension])
                need(growth <= before['transition']['max_growth'][dimension], 'no task allowance widening')
                row['transition']['max_growth'][dimension] = growth
                need(value <= row['enforcement_ceilings'][dimension], 'all unchanged ceilings')
        elif row.get('surface_id') == 'shipped_behavior':
            baseline = metrics({name: sources[name] for name in book_names})['metrics']
            current = {name: sources[name] for name in book_names}
            current[BOOK] = after_sources[BOOK]
            measured = metrics(current)['metrics']
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='TASK-TERMINAL-ROLLOVER-20261011',
                owner=OWNER, baseline={key: baseline[key] for key in keys},
                delta={key: measured[key] - baseline[key] for key in keys},
                rationale='Describe exact completed-subtree version objects and replay, preserving active raw contracts and all live registry owners; no product behavior or ceilings change.')
    need(after_rows == wanted_rows, 'only exact measured task ratchet and sole book authority change')
    need(after_sources[BOOK] != sources[BOOK], 'book reflects actual live/version-object boundary')
    native = independent(task_sources, dict(original=sources[TASK], declared=declared, compacted=compacted, final=final))
    return dict(owner=OWNER, source_revision=REVISION, complete_source=dict(
        members=census['sources'], task_source_metrics=metrics({name: sources[name] for name in task_names})['metrics'],
        conservative_owner_fields=len(owners), owner_task_fields=sum(row['key'] == 'owner_task' for row in owners)),
        semantic_closure=dict(subtrees=subtrees, reconstructed_nodes=len(reconstructed),
                              original_nodes=len(old), protected_raw_members=protected),
        live_working_set=dict(nodes=len(done), task_metrics=actual, current_sources={name: pin(raw) for name, raw in after_sources.items()}),
        unretained_residue=dict(original_node_ids=[], original_node_bytes=0,
            note='Every original node body is either byte-identical live or retrieved whole from the exact predecessor. Complete source and semantic products overlap; counts are not additive.'),
        independent_native=native, legs=dict(
            rederive='Whole fixed Git task/doctrine/book sources, authoritative graph expansion and exact per-node byte equality.',
            falsify='Separate Perl whole-node/member census, genuine native revision/digest/count/goal/missing-node controls and synthetic live-owner selection rejection.',
            durability='Complete before/declaration/compacted/final source bodies, all actual controls, strict namespace seal, production gates and owning Git commit.'))


def catalog(namespace):
    local(namespace, exists=False)
    members = {}
    directories = []
    for path in sorted(namespace.rglob('*')):
        if path.is_file():
            local(path)
            relative = str(path.relative_to(namespace))
            if relative not in ('manifest.json', 'checks.json'):
                members[relative] = pin(path.read_bytes())
        elif path.is_dir():
            local(path, exists=False)
            directories.append(str(path.relative_to(namespace)))
        else:
            need(False, 'ordinary complete namespace entry')
    return dict(schema=1, mutable=['checks.json'], directories=directories, members=members)


def verify_namespace(namespace, expected):
    need(expected == canonical(catalog(namespace)), 'strict complete namespace membership seal')


def seal_controls(retain):
    # Exercise the actual namespace validator on a complete isolated source.
    fixture = SCRATCH / 'seal-controls'
    raw = b'exact source\n'
    expected = canonical(dict(schema=1, mutable=['checks.json'], directories=[], members={'source.txt': pin(raw)}))
    cases = ('positive', 'missing', 'tail', 'extra-file', 'empty-directory', 'symlink', 'wrong-schema-type', 'mutable-root-files')
    result = {}
    for name in cases:
        root = fixture / name
        local(root, exists=False).mkdir(parents=True, exist_ok=True)
        # Replay restores only these explicitly owned fixture entries.
        for part in (root / 'source.txt', root / 'extra.txt', root / 'empty', root / 'checks.json', root / 'manifest.json'):
            local(part, exists=False)
            if part.is_dir():
                part.rmdir()
            elif part.exists():
                part.unlink()
        target = root / 'source.txt'
        target.write_bytes(raw)
        test_manifest = expected
        if name == 'missing':
            target.unlink()
        elif name == 'tail':
            target.write_bytes(raw + b'changed\n')
        elif name == 'extra-file':
            (root / 'extra.txt').write_bytes(b'unlisted\n')
        elif name == 'empty-directory':
            (root / 'empty').mkdir()
        elif name == 'symlink':
            target.unlink()
            target.symlink_to('../positive/source.txt')
        elif name == 'wrong-schema-type':
            value = json.loads(expected)
            value['schema'] = True
            test_manifest = canonical(value)
        elif name == 'mutable-root-files':
            (root / 'checks.json').write_bytes(b'{"mutable":"actual checks"}\n')
            (root / 'manifest.json').write_bytes(expected)
        diagnostic = None
        try:
            verify_namespace(root, test_manifest)
        except ValueError as error:
            diagnostic = str(error)
        row = dict(case=name, manifest=test_manifest.decode(), diagnostic=diagnostic,
                   source=(target.read_bytes().decode() if target.exists() else None),
                   entries=[dict(path=str(p.relative_to(root)), symlink=p.is_symlink(), directory=p.is_dir())
                            for p in sorted(root.rglob('*'))])
        if name == 'mutable-root-files':
            row['mutable_members'] = {p.name: p.read_bytes().decode()
                                      for p in (root / 'checks.json', root / 'manifest.json')}
        # Remove our intentional symlink before the next replay's strict preflight.
        if target.is_symlink():
            target.unlink()
        if retain:
            retain_first(BASE / 'controls' / ('seal-' + name + '.json'), canonical(row))
        else:
            need(local(BASE / 'controls' / ('seal-' + name + '.json')).read_bytes() == canonical(row),
                 'complete saved genuine namespace control replay')
        need((diagnostic is None) == (name in ('positive', 'mutable-root-files')), 'genuine namespace control result')
        result[name] = row
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    sources = unpack(local(BASE / 'complete-source.json.gz').read_bytes())
    declared = gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes())
    compacted = gzip.decompress(local(BASE / 'compacted-task.md.gz').read_bytes())
    after = unpack(local(BASE / 'qualified-source.json.gz').read_bytes())
    proof = rederive(sources, declared, compacted, after[TASK], after)
    if args.seal:
        retain_first(BASE / 'proof.json', canonical(proof))
    else:
        need(local(BASE / 'proof.json').read_bytes() == canonical(proof), 'complete independently rederived dated proof')
    actual = controls(compacted, sources, retain=args.seal)
    seal_controls(args.seal)
    if not args.seal:
        for name, row in actual.items():
            need(local(BASE / 'controls' / (name + '.json')).read_bytes() == canonical(row), 'whole saved actual control replay')
            if name != 'live-owner':
                candidate = gzip.decompress(local(BASE / 'controls' / (name + '-task.md.gz')).read_bytes())
                need(pin(candidate) == row['candidate'], 'whole saved genuine candidate')
    if args.current:
        need(all(local(name).read_bytes() == raw for name, raw in after.items()), 'entire current changed-source epoch')
        need(local(CHECKER).read_bytes() == sources[CHECKER], 'unchanged production checker instrument')
        for name, raw in sources.items():
            if name not in after:
                need(local(name).read_bytes() == raw, 'entire unchanged current source membership')
    if args.seal:
        save(BASE / 'manifest.json', canonical(catalog(BASE)))
    else:
        verify_namespace(BASE, local(BASE / 'manifest.json').read_bytes())
    print('PASS exact dated task containment: complete source, semantic closure, live working set and zero unretained node residue; independent native census and genuine controls pass.')


if __name__ == '__main__':
    main()
