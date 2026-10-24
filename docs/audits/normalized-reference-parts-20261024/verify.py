#!/usr/bin/env python3
"""Independently qualify a prospective semantic split and its preservation graph."""
import argparse
import copy
import gzip
import hashlib
import io
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.10.1'
CORE = 'docs/book/src/11-extensions-and-embedding.md'
API = 'docs/book/src/11a-perl-api-reference.md'
SUMMARY = 'docs/book/src/SUMMARY.md'
AUDIT = 'docs/audits/mcp-api-reference-20261023/'
TITLES = (
    'Normalized report-envelope families', 'Normalized payload and IR baseline families',
    'Normalized symbol family subjects', 'Normalized composition envelope and shallow children',
    'Normalized composition parameter-override aliases', 'Normalized composition standalone-DT children',
    'Normalized composition grouped lookups', 'Normalized shared-datapath candidate and contributor subjects',
    'Normalized shared-datapath binding and drive-intent subjects')
PROFILE_INPUTS = {
    'envelope': ('normalized-envelope-qualified.json.gz', 'verify_normalized_envelope.py', 'verify_normalized_envelope_rendered.py', []),
    'baseline': ('normalized-baseline-current-qualified.json.gz', 'verify_normalized_baseline_closure.py', 'verify_normalized_baseline_rendered.py', ['baseline']),
    'symbols': ('normalized-symbols-final-qualified.json.gz', 'verify_normalized_symbols.py', 'verify_normalized_symbols_rendered.py', []),
    'composition': ('composition-final-qualified.json.gz', 'verify_composition_closure.py', None, []),
    'shared_candidate': ('shared-candidate-qualified.json.gz', 'verify_shared_candidate.py', None, []),
    'shared_drive': ('shared-drive-final-qualified.json.gz', 'verify_shared_drive.py', None, [])}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def code(raw):
    return raw.split(b'\n__END__\n', 1)[0]


def git_file(head, path):
    return subprocess.check_output(['git', 'show', head + ':' + path], cwd=ROOT)


def outline(text):
    result, fence, offset = [], '', 0
    for line in text.splitlines(keepends=True):
        stripped = line.lstrip(' ')
        if stripped.startswith(('```', '~~~')):
            token = re.match(r'[`~]+', stripped).group()
            if not fence:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence) and not stripped[len(token):].strip():
                fence = ''
        elif not fence and line.startswith('#'):
            marks, separator, title = line.rstrip('\n').partition(' ')
            if separator and set(marks) == {'#'} and len(marks) <= 6:
                result.append((len(marks), title, offset))
        offset += len(line)
    require(not fence, 'balanced example fences')
    return result


def anchor(title):
    return ''.join(char for char in title.lower() if char.isascii() and (char.isalnum() or char in ' _-')).replace(' ', '-')


def independent_consumers(head):
    scopes = ('docs/book/src/', 'docs/knowledge/', 'docs/tasks/', 'docs/audits/', 'scripts/', 't/', 'perl/FSM/')
    suffixes = {'.md', '.py', '.pl', '.t', '.sh', '.json', '.jsonl', '.toml', '.yml', '.yaml', '.pm'}
    names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', '-z', head], cwd=ROOT).decode().split('\0')
    paths = [path for path in names if path.startswith(scopes) and Path(path).suffix in suffixes]
    # Stream one object at a time. Neither aggregate bodies nor long lines are
    # retained; only matching compact result rows survive the independent scan.
    rows = []
    process = subprocess.Popen(['git', 'cat-file', '--batch'], cwd=ROOT,
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    try:
        for path in paths:
            require('\n' not in path, 'portable batch source path')
            process.stdin.write((head + ':' + path + '\n').encode())
            process.stdin.flush()
            header = process.stdout.readline(512)
            require(header.endswith(b'\n'), 'bounded complete object header')
            fields = header.split()
            require(len(fields) == 3 and fields[1] == b'blob', 'owned baseline blob')
            rows.extend(scan_body(process.stdout, int(fields[2]), path))
            require(process.stdout.read(1) == b'\n', 'complete object separator')
        process.stdin.close()
        require(process.wait() == 0, 'complete object batch consumed')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        if not process.stdin.closed:
            process.stdin.close()
        process.stdout.close()
    return sorted(rows, key=lambda row: (row['path'], row['line']))


def scan_body(stream, size, path, chunk_bytes=65536):
    stems = ('11-extensions-and-embedding', '11a-perl-api-reference')
    encoded = {stem: stem.encode() for stem in stems}
    overlap = max(map(len, encoded.values())) - 1
    rows, number, binary = [], 1, False
    digest, pending, tail, matches, present = hashlib.sha256(), b'', b'', set(), False

    def fragment(piece):
        nonlocal pending, tail, present
        present = present or bool(piece)
        data = pending + piece
        if data:
            digest.update(data[:-1])
            pending = data[-1:]
        window = tail + piece
        matches.update(stem for stem, token in encoded.items() if token in window)
        tail = window[-overlap:]

    def finish():
        nonlocal number, digest, pending, tail, matches, present
        if pending != b'\r':
            digest.update(pending)
        if matches:
            rows.append({'path': path, 'line': number, 'line_sha256': digest.hexdigest(),
                         'stems': [stem for stem in stems if stem in matches]})
        number += 1
        digest, pending, tail, matches, present = hashlib.sha256(), b'', b'', set(), False

    remaining = size
    while remaining:
        chunk = stream.read(min(chunk_bytes, remaining))
        require(chunk, 'complete streamed object body')
        remaining -= len(chunk)
        binary = binary or b'\0' in chunk
        pieces = chunk.split(b'\n')
        for piece in pieces[:-1]:
            fragment(piece)
            finish()
        fragment(pieces[-1])
    if present:
        finish()
    return [] if binary else rows


def stream_controls():
    class BoundedRead(io.BytesIO):
        def read(self, size=-1):
            require(0 <= size <= 17, 'fixed fixture read bound')
            return super().read(size)

    cases = {
        'cross_chunk': b'prefix 11-extensions-and-embedding suffix\n',
        'long_line': b'x' * 131073 + b'11a-perl-api-reference tail\n',
        'both_stems': b'11a-perl-api-reference and 11-extensions-and-embedding\n',
        'crlf': b'\r\n11a-perl-api-reference\r\n',
        'no_final_lf': b'first\n11-extensions-and-embedding',
        'binary': b'11a-perl-api-reference\nignored\0binary',
        'empty': b'',
    }
    for name, raw in cases.items():
        expected = []
        if b'\0' not in raw:
            for number, line in enumerate(raw.split(b'\n'), 1):
                line = line.removesuffix(b'\r')
                stems = [stem for stem in ('11-extensions-and-embedding', '11a-perl-api-reference') if stem.encode() in line]
                if stems:
                    expected.append({'path': name, 'line': number, 'line_sha256': sha(line), 'stems': stems})
        require(scan_body(BoundedRead(raw), len(raw), name, 17) == expected, 'stream boundary/control: ' + name)
    return {'cases': sorted(cases), 'max_fixture_read_bytes': 17, 'production_chunk_bytes': 65536}


def read_gzip(path):
    return json.loads(gzip.decompress((ROOT / path).read_bytes()))


def live_runtime_bytes(path):
    return (ROOT / path).read_bytes()


def verify(packet, current_inputs=False, consumer_rows=None):
    require(packet['schema'] == 'fsmgen.normalized_reference_partition.v1' and packet['owner'] == OWNER, 'contract identity')
    if 'qualification_refresh' in packet:
        refresh = packet['qualification_refresh']
        origin_path = BASE.relative_to(ROOT).as_posix() + '/partition-contract.json.gz'
        require(refresh['source_packet'] == origin_path and refresh['source_sha256'] == sha((ROOT / origin_path).read_bytes()), 'completed producer packet identity')
        origin = read_gzip(origin_path)
        path = BASE.relative_to(ROOT).as_posix() + '/verify.py'
        restored = copy.deepcopy(packet)
        restored.pop('qualification_refresh')
        restored['instruments'][path] = origin['instruments'][path]
        require(restored == origin, 'only explicit verifier instrument refresh; complete producer data conserved')
        instrument = refresh['instrument']
        require(instrument['path'] in {BASE.relative_to(ROOT).as_posix() + '/' + name for name in ('refresh.py', 'refresh_final.py')}
                and sha(instrument['text'].encode()) == instrument['sha256']
                and (ROOT / instrument['path']).read_text() == instrument['text'], 'exact refresh instrument')
    head = packet['baseline_head']; require(re.fullmatch('[0-9a-f]{40}', head), 'baseline Git identity')
    require(set(packet['inputs']) == {CORE, API, SUMMARY}, 'complete baseline source population')
    for path, saved in packet['inputs'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'] and raw == git_file(head, path), 'committed complete baseline bytes')
        if current_inputs:
            require((ROOT / path).read_bytes() == raw, 'live source changed before migration')
    core, api, summary = (packet['inputs'][path]['text'] for path in (CORE, API, SUMMARY))
    rows = outline(core)
    selected = [row for row in rows if row[0] == 3 and row[1].startswith('Normalized ')]
    require(tuple(row[1] for row in selected) == TITLES, 'complete independently reviewed semantic family allocation')
    require([row['title'] for row in packet['blocks']] == list(TITLES), 'complete block order/population')
    expected_routes, original_blocks = [], []
    for title, block in zip(TITLES, packet['blocks']):
        start = next(position for level, name, position in selected if name == title)
        end = next(position for level, name, position in rows if position > start and level <= 3)
        original = core[start:end]; original_blocks.append(original)
        require(block == {'title': title, 'anchor': anchor(title), 'text': original, 'sha256': sha(original.encode()),
                          'source_start_byte': len(core[:start].encode()), 'source_end_byte': len(core[:end].encode())}, 'exact complete original block/span')
        expected_routes.append({'anchor': anchor(title), 'source': CORE, 'destination': API, 'title': title})
    require(packet['routes'] == expected_routes, 'exact stable old/new routes')
    candidate = packet['candidate_documents']; require(set(candidate) == {CORE, API, SUMMARY}, 'candidate source population')
    require(outline(candidate[CORE]) and outline(candidate[API]), 'candidate heading/fence structure')
    first = selected[0][2]
    last = next(position for level, name, position in rows if position > selected[-1][2] and level <= 3)
    stubs = []
    for row in expected_routes:
        stub = '### ' + row['title'] + '\n\nSee the [canonical field reference](' + Path(API).name + '#' + row['anchor'] + ').\n\n'
        stubs.append(stub)
        require(candidate[CORE].count(stub) == 1, 'one stable compatibility route per original anchor')
    require(candidate[CORE] == core[:first] + ''.join(stubs) + core[last:], 'entire unmoved core conserves')
    moved = ''.join(original_blocks)
    require(moved == core[first:last] and candidate[API].count(moved) == 1, 'unique exact canonical moved content')
    require(all(candidate[CORE].count(block) == 0 for block in original_blocks), 'no duplicate maintained field prose')
    original_anchors = {anchor(name) for level, name, position in outline(api)}
    new_anchors = [anchor(name) for level, name, position in outline(candidate[API])]
    require(original_anchors <= set(new_anchors) and len(new_anchors) == len(set(new_anchors)), 'complete existing API anchor preservation')
    for route in expected_routes:
        require(route['anchor'] in new_anchors, 'canonical routed heading exists')
    rewrite = packet['navigation_rewrite']
    require(rewrite['before'] == '''POD documents the Perl bindings. The language-neutral request/result schemas,
support boundaries and tutorials remain in
[Extensions and Embedding](11-extensions-and-embedding.md) and the
[VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md).
''', 'exact reviewed original navigation meaning')
    require(rewrite['after'] == '''POD documents the Perl bindings. The normalized semantic field reference below
complements [Extensions and Embedding](11-extensions-and-embedding.md) for
discovery, support boundaries and tutorials, and the
[VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md) for versioned VIAL models.
''', 'exact reviewed new semantic navigation meaning')
    require(api.count(rewrite['before']) == 1, 'single declared navigation paragraph')
    old_api = candidate[API].replace(moved, '', 1)
    intro = ('## Normalized Semantic Metadata Reference\n\n'
             'Use each field family with its payload subject, dedicated owner, optional or\n'
             'variant rule, and qualification limits. Begin with\n'
             '[capability discovery](11-extensions-and-embedding.md#capability-manifest-discovery)\n'
             'for the containing manifest and query workflow.\n\n')
    require(old_api.count(intro) == 1, 'one semantic reader front door')
    old_api = old_api.replace(intro, '', 1).replace('# API and Model Reference\n\n## Perl API Reference\n', '# Perl API Reference\n', 1)
    old_api = old_api.replace(rewrite['after'], rewrite['before'], 1)
    require(old_api == api, 'complete original API prose reconstructed through declared navigation rewrites')
    require('normalized semantic field reference below' in rewrite['after'] and 'versioned VIAL models' in rewrite['after'], 'truthful broadened API reference role')
    original_links = re.findall(r'\]\(([^)]+)\)', summary)
    member_paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', head, '--', 'docs/book/src'], cwd=ROOT).decode().splitlines()
    members = {Path(path).name for path in member_paths if Path(path).parent.as_posix() == 'docs/book/src' and path.endswith('.md')} - {'SUMMARY.md'}
    require(set(original_links) == members and len(original_links) == len(members), 'complete direct mandatory book index')
    require(re.findall(r'\]\(([^)]+)\)', candidate[SUMMARY]) == original_links, 'complete fixed navigation membership/order')
    require(candidate[SUMMARY] == summary.replace('[Perl API Reference](11a-perl-api-reference.md)', '[API and Model Reference](11a-perl-api-reference.md)'), 'only declared sidebar label changes')
    require(len(candidate[SUMMARY].splitlines()) <= 64 and len(candidate[SUMMARY].encode()) <= 4096, 'fixed mandatory-index bounds')
    require(all(len(candidate[path].splitlines()) <= 4728 for path in (CORE, API)), 'fixed existing per-part transition bound')
    selector = re.compile(r'\]\(perl-api/(FSM/[\w/]+)\.html\)')
    require(set(selector.findall(api)) == set(selector.findall(candidate[API])), 'unchanged selected public POD entries')
    expected_consumers = independent_consumers(head) if consumer_rows is None else consumer_rows
    require(packet['baseline_consumers'] == expected_consumers, 'complete independently enumerated baseline consumers')
    require(set(packet['reader_profiles']) == set(PROFILE_INPUTS), 'complete immutable guide-oracle profiles')
    expected_artifacts = set()
    source_variants = {}
    for name, (file, reader, rendered, container) in PROFILE_INPUTS.items():
        row = packet['reader_profiles'][name]
        require(row['packet'] == AUDIT + file and row['reader'] == AUDIT + reader
                and row['rendered_reader'] == (AUDIT + rendered if rendered else None)
                and row['document_container'] == container and row['oracle_mode'] == 'saved-only', 'exact reader role/slot identity')
        require('actual API HTML' in row['native_view'] and 'separately' in row['native_view'], 'honest native proxy role')
        expected_artifacts |= {row[key] for key in ('packet', 'reader', 'rendered_reader') if row[key]}
        old = read_gzip(row['packet'])
        for key in container:
            old = old[key]
        for path, saved in {**old['sources'], **old.get('helpers', {})}.items():
            raw = saved['text'].encode(); require(sha(raw) == saved['sha256'], 'prior source-bearing packet digest')
            source_variants.setdefault(path, set()).add(sha(code(raw)))
    expected_artifacts |= {AUDIT + name for name in ('normalized-boolean-repair-before.json.gz', 'normalized-boolean-repair-after.json.gz', 'verify_normalized_booleans.py')}
    require(packet['reader_inputs'] == {path: sha((ROOT / path).read_bytes()) for path in expected_artifacts}, 'complete immutable oracle/input identity')
    for path in expected_artifacts:
        require((ROOT / path).read_bytes() == git_file(head, path), 'prior oracle/input remains baseline Git bytes')
    report = 'perl/FSM/Support/NormalizedSemanticReport.pm'
    before = read_gzip(AUDIT + 'normalized-boolean-repair-before.json.gz')['sources'][report]['text'].encode()
    after = read_gzip(AUDIT + 'normalized-boolean-repair-after.json.gz')['sources'][report]['text'].encode()
    for path, variants in source_variants.items():
        actual = sha(code(live_runtime_bytes(path) if current_inputs else git_file(head, path)))
        if path == report:
            require(variants <= {sha(code(before)), sha(code(after))} and actual == sha(code(after)), 'only qualified current Boolean repair may differ')
        else:
            require(variants == {actual}, 'no unexplained current runtime source difference: ' + path)
    bridge = packet['bridge_contract']
    require(set(bridge) == {'documents', 'oracles', 'runtime_exception', 'native', 'limits'}, 'complete bridge obligations')
    require('saved mode only' in bridge['oracles'] and 'separately labeled' in bridge['documents']
            and 'JSON Boolean repair' in bridge['runtime_exception'] and 'actual old/new page routes' in bridge['native']
            and bridge['limits'].startswith('Plan only.'), 'no relabeled current source or native proof')
    expected_instruments = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in ('plan.py', 'verify.py')}
    require(set(packet['instruments']) == expected_instruments, 'contract instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'exact contract instrument identity')
    return {'moved_blocks': len(TITLES), 'baseline_consumer_rows': len(expected_consumers), 'oracle_profiles': len(PROFILE_INPUTS),
            'candidate_lines': {path: len(text.splitlines()) for path, text in candidate.items()}, 'limits': bridge['limits']}


def role_controls(packet, consumer_rows):
    global live_runtime_bytes
    original = live_runtime_bytes
    try:
        live_runtime_bytes = lambda path: b'changed current-code fixture\n'
        verify(packet, consumer_rows=consumer_rows)
        try:
            verify(packet, current_inputs=True, consumer_rows=consumer_rows)
        except ValueError as error:
            result = str(error)
        else:
            raise ValueError('Current mode accepted changed live code')
    finally:
        live_runtime_bytes = original
    return {'saved_mode': 'Pinned baseline code remains replayable independently of live code.',
            'current_mode_refusal': result, 'production_files': 'unchanged; only the live-code accessor was substituted and restored'}


def controls(packet, consumer_rows):
    results = {}
    for label in ('lost_block', 'changed_block', 'duplicate_canonical', 'lost_core', 'lost_api', 'misroute',
                  'lost_anchor', 'lost_summary_entry', 'lost_consumer', 'lost_reader', 'wrong_reader_role',
                  'lost_repair_bridge', 'lost_navigation_meaning', 'source_change', 'instrument_change'):
        bad = copy.deepcopy(packet)
        # Baseline verification authenticates the completed producer/refresh
        # relationship. These explicit comparison views exercise the semantic
        # predicates without being intercepted by that earlier identity gate.
        bad.pop('qualification_refresh', None)
        if label == 'lost_block': bad['blocks'].pop()
        elif label == 'changed_block': bad['blocks'][0]['text'] += '\nchanged\n'
        elif label == 'duplicate_canonical': bad['candidate_documents'][API] += bad['blocks'][0]['text']
        elif label == 'lost_core': bad['candidate_documents'][CORE] = bad['candidate_documents'][CORE].replace('## Current Philosophy\n', '')
        elif label == 'lost_api': bad['candidate_documents'][API] = bad['candidate_documents'][API].replace('## Validation and failures\n', '')
        elif label == 'misroute': bad['routes'][0]['destination'] = CORE
        elif label == 'lost_anchor': bad['candidate_documents'][API] = bad['candidate_documents'][API].replace('## Perl API Reference\n', '')
        elif label == 'lost_summary_entry': bad['candidate_documents'][SUMMARY] = '\n'.join(bad['candidate_documents'][SUMMARY].splitlines()[1:]) + '\n'
        elif label == 'lost_consumer': bad['baseline_consumers'].pop()
        elif label == 'lost_reader': bad['reader_profiles'].pop('envelope')
        elif label == 'wrong_reader_role': bad['reader_profiles']['envelope']['oracle_mode'] = 'current'
        elif label == 'lost_repair_bridge': bad['bridge_contract']['runtime_exception'] = 'Any source change is fine.'
        elif label == 'lost_navigation_meaning':
            original = bad['navigation_rewrite']['after']
            changed = original.replace('support boundaries and tutorials', 'details')
            bad['navigation_rewrite']['after'] = changed
            bad['candidate_documents'][API] = bad['candidate_documents'][API].replace(original, changed)
        elif label == 'source_change':
            bad['inputs'][CORE]['text'] += '\nchanged\n'; bad['inputs'][CORE]['sha256'] = sha(bad['inputs'][CORE]['text'].encode())
        else:
            saved = next(iter(bad['instruments'].values())); saved['text'] += '\n# changed\n'; saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad, consumer_rows=consumer_rows)
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    if 'qualification_refresh' in packet:
        bad = copy.deepcopy(packet)
        bad['qualification_refresh']['source_sha256'] = '0' * 64
        try:
            verify(bad, consumer_rows=consumer_rows)
        except ValueError as error:
            results['changed_completed_producer'] = str(error)
        else:
            raise ValueError('Accepted changed completed producer')
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--current-inputs', action='store_true')
    args = parser.parse_args()
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    streaming = stream_controls()
    consumer_rows = independent_consumers(packet['baseline_head'])
    result = verify(packet, args.current_inputs, consumer_rows)
    result['rejected_controls'] = controls(packet, consumer_rows)
    result['streaming_controls'] = streaming
    result['reader_role_controls'] = role_controls(packet, consumer_rows)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
