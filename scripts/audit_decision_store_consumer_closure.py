#!/usr/bin/env python3
"""Audit fixed committed decision relocation and tracked consumer continuity.

This is a qualification tool, not a production reader or authority source.
The public reader authenticates the selected store first. Independent parsers
then compare complete question bindings and original Markdown destinations.
"""

import argparse
import hashlib
import json
import posixpath
import re
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
from decision_store_git import GitSnapshot

ROOT = Path(__file__).resolve().parent.parent
MAX_SEARCH_BYTES = 33_554_432
MAX_SEARCH_LINES = 16_384
LINK = re.compile(r'\[[^\]\n]*\]\(([^\s)]+)\)')
QUESTION = re.compile(r'^- q=(.+) · facts=(.+)$')
FACT_LINK = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(value):
    data = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()
    return hashlib.sha256(data).hexdigest()


def cached_reader(snapshot):
    cache = {}
    def read(path):
        if path not in cache:
            cache[path] = snapshot.read(path)
        return cache[path]
    return read


def visible(text):
    """Independently exclude fenced examples from actual navigation headings."""
    fence = None
    for line in text.splitlines():
        match = re.match(r'^ {0,3}(`{3,}|~{3,})(.*)$', line)
        if fence is not None:
            if match and match[1][0] == fence[0] and len(match[1]) >= len(fence) and not match[2].strip():
                fence = None
            continue
        if match:
            fence = match[1]
            continue
        yield line
    require(fence is None, 'unterminated navigation fence')


def destination(path, target):
    if re.match(r'^[A-Za-z][A-Za-z0-9+.-]*:', target) or target.startswith('/'):
        return target
    file, mark, fragment = target.partition('#')
    resolved = posixpath.normpath(posixpath.join(posixpath.dirname(path), file)) if file else path
    require(not resolved.startswith('../'), 'navigation destination escapes repository')
    return resolved + (mark + fragment if mark else '')


def inline_destinations(text, path):
    return [destination(path, target) for line in visible(text) for target in LINK.findall(line)]


def subsequence(before, after, message):
    remaining = iter(after)
    require(all(any(candidate == item for candidate in remaining) for item in before), message)


def verify_navigation(source, originals, catalog, read):
    """Check actual original headings and destinations without the renderer."""
    current = {row['id']: row for row in catalog['records']}
    original = {row['id']: row['text'] for row in originals['records']}
    require(set(original) == {row['id'] for row in source['records']}, 'original population differs')
    result = []
    for row in source['records']:
        identity, old_path = row['id'], row['path']
        headings = [line for line in visible(original[identity]) if re.match(r'^#{1,6} ', line)]
        alias = read(old_path).decode('utf-8')
        alias_headings = [line for line in visible(alias) if re.match(r'^#{1,6} ', line)]
        require(alias_headings == headings, f'compatibility heading sequence differs: {identity}')
        new_path = current[identity]['path'] if identity in current else 'docs/decisions/history/0001-0050.md'
        wanted = new_path if identity in current else new_path + '#decision-' + identity
        blocks, active = [], None
        for line in visible(alias):
            if re.match(r'^#{1,6} ', line):
                active = []
                blocks.append(active)
            for target in re.findall(r'\[Read the complete record\]\(([^)]+)\)', line):
                require(active is not None, 'forwarding link has no heading')
                active.append(destination(old_path, target))
        require(all(block == [wanted] for block in blocks), f'compatibility heading misroutes: {identity}')
        body = read(new_path).decode('utf-8')
        if identity in current:
            subsequence(headings, [line for line in visible(body) if re.match(r'^#{1,6} ', line)],
                        f'current body lost original heading: {identity}')
            old_links = inline_destinations(original[identity], old_path)
            new_links = inline_destinations(body, new_path)
            # Self-fragments move with their body. Other published repository
            # destinations remain exactly where the original authored link led.
            old_links = [new_path + link[len(old_path):] if link == old_path or link.startswith(old_path + '#')
                         else link for link in old_links]
            subsequence(old_links, new_links, f'current body changed original inline destination: {identity}')
        else:
            require(f'<a id="decision-{identity}"></a>' in body, f'sealed destination absent: {identity}')
            old_links = []  # Exact sealed body/view coverage is the public reader's separate gate.
        result.append({'id': identity, 'compatibility_path': old_path, 'destination': wanted,
                       'heading_count': len(headings), 'headings_sha256': digest(headings),
                       'retained_inline_destinations': old_links})
    return result


def knowledge_bindings(snapshot, read):
    """Recover all generated question/fact/path triples and independent fact routes."""
    questions, facts = {}, {}
    shards = sorted(path for path in snapshot.objects if re.fullmatch(r'knowledge-map/generated/[^/]+\.md', path))
    for path in shards:
        active = None
        for line in read(path).decode('utf-8').splitlines():
            match = QUESTION.fullmatch(line)
            if match:
                question = json.loads(match[1])
                require(type(question) is str and question not in questions, 'duplicate or malformed question row')
                links = FACT_LINK.findall(match[2])
                require(links and ', '.join(f'[{fact}]({target})' for fact, target in links) == match[2],
                        'malformed question fact routes')
                questions[question] = [(fact, destination(path, target)) for fact, target in links]
                require(len({fact for fact, _ in questions[question]}) == len(links), 'duplicate question fact binding')
            if line.startswith('### '):
                active = line[4:]
            if line.startswith('- **source and verification:** '):
                routes = LINK.findall(line)
                require(active is not None and active not in facts and len(routes) == 1, 'duplicate or missing fact route')
                facts[active] = destination(path, routes[0])
    triples = set()
    for question, links in questions.items():
        for fact, path in links:
            require(facts.get(fact) == path, 'question route differs from fact route')
            triples.add((question, fact, path))
    for fact, path in facts.items():
        text = read(path).decode('utf-8')
        require(re.search(r'^id: ' + re.escape(fact) + r'$', text, re.MULTILINE) is not None,
                f'fact route does not lead to its canonical identity: {fact}')
    return triples, facts, shards


def verify_bindings(before, after, relocation):
    old_triples, old_facts, _ = before
    new_triples, new_facts, _ = after
    expected = {(question, fact, relocation.get(path, path)) for question, fact, path in old_triples}
    require(expected == new_triples, 'complete question/fact/path bindings differ')
    require({fact: relocation.get(path, path) for fact, path in old_facts.items()} == new_facts,
            'complete fact/path bindings differ')
    return {'questions': len({row[0] for row in expected}), 'answer_bindings': len(expected),
            'facts': len(new_facts), 'binding_sha256': digest(sorted(expected)),
            'fact_routes_sha256': digest(new_facts)}


def census(snapshot, names, generic=False):
    arguments = ['git', '--no-replace-objects', '-C', str(ROOT), 'grep', '--no-recurse-submodules', '-n', '-I', '-F']
    arguments += ['docs/decisions'] if generic else ['-f', '-']
    arguments += [snapshot.revision, '--']
    if generic:
        arguments += ['scripts', 'knowledge-map', 'perl', 't']
    process = subprocess.Popen(arguments, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # Output bounds are enforced during collection, not only after allocation.
    try:
        if not generic:
            process.stdin.write(('\n'.join(sorted(names)) + '\n').encode())
        process.stdin.close()
        output = process.stdout.read(MAX_SEARCH_BYTES + 1)
        require(len(output) <= MAX_SEARCH_BYTES, 'consumer search exceeds byte bound')
        require(process.wait() in (0, 1), 'tracked consumer search failed')
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        process.stdout.close()
    lines = output.decode('utf-8').splitlines()
    require(len(lines) <= MAX_SEARCH_LINES, 'consumer search exceeds row bound')
    rows = []
    for line in lines:
        require(line.startswith(snapshot.revision + ':'), 'consumer search revision differs')
        path, number, text = line[len(snapshot.revision) + 1:].split(':', 2)
        require(path in snapshot.objects and snapshot.objects[path][0] in ('100644', '100755'),
                'consumer is not a root-repository regular blob')
        category = ('immutable_history' if path.startswith(('docs/audits/', 'docs/decisions/history/')) else
                    'fixture_or_test' if path.startswith('t/') else
                    'current_body_search' if text.startswith('reverify:') else
                    'canonical_body' if path.startswith('docs/decisions/current/') else
                    'generated_question_route' if text.startswith('- q=') else
                    'literal_navigation' if '](' in text else 'identity_or_code_candidate')
        row = {'path': path, 'line': int(number), 'category': category,
               'source_line_sha256': hashlib.sha256(text.encode()).hexdigest()}
        if not generic:
            row['ids'] = sorted(identity for name, identity in names.items() if name in text)
            row['literal_fragments'] = [{'id': identity, 'fragment': fragment}
                                       for name, identity in sorted(names.items())
                                       for fragment in re.findall(re.escape(name) + r'#([A-Za-z0-9_%:-]+)', text)]
        rows.append(row)
    return rows


def interface_review(paths):
    """Closed review of this selected cohort; unknown code candidates refuse."""
    groups = {
        'exported_identifiers': [
            'perl/FSM/VIAL/ArchitectureScaleCalibrationDisposition.pm',
            'perl/FSM/VIAL/ArchitectureScaleCapConsistency.pm',
            'perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm',
            'perl/FSM/VIAL/ArchitectureScaleRuntimeStream.pm',
            'perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm'],
        'bootstrap_presence_and_routing': [
            'scripts/check_memory_architecture.sh', 'scripts/check_project_data_locality.sh',
            'scripts/check_readme_entrypoint.sh'],
        'historical_provenance': ['scripts/check_knowledge_card_history.pl',
                                  'scripts/audit_decision_identity_capacity.py'],
        'authenticated_store_interfaces': [
            'scripts/decision_catalog.py', 'scripts/decision_records.py', 'scripts/decision_store.py',
            'scripts/decision_store_git.py', 'scripts/prepare_decision_store_rollover.py',
            'scripts/check_live_document_ceiling_authority.pl'],
        'current_body_reader': ['t/1809-vial-v2-portable-sv-lifecycle-contract.t'],
        'presence_and_export_controls': [
            't/1553-readme-routed-destination-pressure.t', 't/1560-live-document-ceiling-authority.t',
            't/1685-vial-architecture-scale-cap-policy.t', 't/1763-vial-architecture-scale-cap-consistency.t'],
        'recursive_knowledge_map_and_verified_question_routes': [
            'knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md', 'knowledge-map/install.sh',
            'knowledge-map/generated/isf-aggregate.md', 'knowledge-map/generated/live-document.md',
            'knowledge-map/generated/public-regression.md', 'knowledge-map/generated/push-cadence.md',
            'knowledge-map/scripts/check_knowledge_map.sh', 'knowledge-map/scripts/gen_knowledge_map.sh',
            'knowledge-map/scripts/knowledge_map.conf', 'knowledge-map/scripts/knowledge_map.pl',
            'knowledge-map/scripts/query_knowledge_map.sh'],
        'literal_or_selected_source_fixture_controls': [
            't/python/test_decision_catalog.py', 't/python/test_decision_ceiling_stores.py',
            't/python/test_decision_hostile_boundaries.py', 't/python/test_decision_identity_audit.py',
            't/python/test_decision_identity_modes.py', 't/python/test_decision_production_rollover.py',
            't/python/test_decision_reader_snapshots.py', 't/python/test_decision_reader_stores.py',
            't/python/test_decision_records.py', 't/python/test_decision_store.py',
            't/python/test_decision_store_git.py'],
    }
    selected = {}
    for path in sorted(set(paths)):
        group = next((name for name, members in groups.items() if path in members), None)
        require(group is not None, f'generic code candidate needs explicit interface review: {path}')
        selected[path] = group
    return selected


def audit(revision):
    require(re.fullmatch(r'[0-9a-f]{40}', revision) is not None, 'exact audit commit is required')
    current = GitSnapshot(ROOT, revision)
    read = cached_reader(current)
    source = json.loads(read('docs/audits/decision-store-transition-census.json'))
    prior = GitSnapshot(ROOT, source['source_revision'])
    catalog = json.loads(read('docs/decisions/current/catalog.json'))
    originals = json.loads(read('docs/decisions/history/transition-originals.json'))
    public = subprocess.run([sys.executable, '-B', str(ROOT / 'scripts/decision_records.py'),
                             '--snapshot', revision, '--prior-snapshot', prior.revision, 'check-continuity'],
                            capture_output=True, timeout=60)
    require(public.returncode == 0, 'public initial-adoption check failed: ' + public.stderr.decode(errors='replace'))
    require(json.loads(public.stdout) == {'catalog': True, 'fresh_ids': [], 'resolved': []},
            'selected revision is not the exact initial adoption')
    navigation = verify_navigation(source, originals, catalog, read)
    before = knowledge_bindings(prior, cached_reader(prior))
    after = knowledge_bindings(current, read)
    source_paths = {row['id']: row['path'] for row in source['records']}
    relocation = {source_paths[row['id']]: row['path'] for row in catalog['records']}
    binding = verify_bindings(before, after, relocation)
    known = []
    for identity in ('0062', '0091'):
        path = relocation[source_paths[identity]]
        line = next(line for line in read(path).decode().splitlines() if line.startswith('reverify:'))
        require(path in line and source_paths[identity] not in line, 'self-search still selects a compatibility page')
        known.append({'id': identity, 'kind': 'current_self_search', 'path': path, 'line_sha256': digest(line)})
    test = 't/1809-vial-v2-portable-sv-lifecycle-contract.t'
    target = relocation[source_paths['0100']]
    require(f"my $decision_rel = '{target}';" in read(test).decode(), 'T1809 does not select canonical current body')
    known.append({'id': '0100', 'kind': 'current_body_reader', 'consumer': test, 'path': target})
    names = {Path(row['path']).name: row['id'] for row in source['records']}
    generic_before, generic_after = census(prior, names, True), census(current, names, True)
    reviewed = interface_review(row['path'] for row in generic_before + generic_after)
    # These APIs export stable provenance identifiers, not current decision text.
    # Preserve their complete source bytes independently of navigation relocation.
    for path, group in reviewed.items():
        if group == 'exported_identifiers':
            require(prior.read(path) == read(path), f'exported provenance changed: {path}')
    return {'schema_version': 1, 'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.1.2',
            'revision': revision, 'source_revision': prior.revision, 'public_initial_adoption': True,
            'knowledge_bindings': binding, 'navigation': navigation, 'known_body_consumers': known,
            'source_consumers': census(prior, names), 'current_consumers': census(current, names),
            'source_generic_code_candidates': generic_before,
            'current_generic_code_candidates': generic_after, 'generic_interface_review': reviewed,
            'scope': 'Complete tracked nonbinary full-basename lines and separate literal docs/decisions code candidates; '
                     'no submodule recursion. Historical exports and fixture provenance retain their published identifiers. '
                     'Heading sequence/forwarding and authored inline destination preservation are distinct from byte authentication. '
                     'Generic candidates require interface review; partial IDs, dynamic/external consumers and HDL runtime are not qualified.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--revision', required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(audit(args.revision), ensure_ascii=False, indent=2, sort_keys=True))
    except (OSError, ValueError, KeyError, TypeError, UnicodeError, subprocess.TimeoutExpired) as error:
        print(f'decision-consumer-closure: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
