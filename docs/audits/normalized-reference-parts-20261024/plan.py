#!/usr/bin/env python3
"""Capture a semantic API-reference split without changing the live book."""
import argparse
import gzip
import hashlib
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
SCOPES = ['docs/book/src', 'docs/knowledge', 'docs/tasks', 'docs/audits', 'scripts', 't', 'perl/FSM']
SUFFIXES = {'.md', '.py', '.pl', '.t', '.sh', '.json', '.jsonl', '.toml', '.yml', '.yaml', '.pm'}
STEMS = ('11-extensions-and-embedding', '11a-perl-api-reference')
AUDIT = 'docs/audits/mcp-api-reference-20261023/'
PROFILES = {
    'envelope': ('normalized-envelope-qualified.json.gz', 'verify_normalized_envelope.py', 'verify_normalized_envelope_rendered.py', []),
    'baseline': ('normalized-baseline-current-qualified.json.gz', 'verify_normalized_baseline_closure.py', 'verify_normalized_baseline_rendered.py', ['baseline']),
    'symbols': ('normalized-symbols-final-qualified.json.gz', 'verify_normalized_symbols.py', 'verify_normalized_symbols_rendered.py', []),
    'composition': ('composition-final-qualified.json.gz', 'verify_composition_closure.py', None, []),
    'shared_candidate': ('shared-candidate-qualified.json.gz', 'verify_shared_candidate.py', None, []),
    'shared_drive': ('shared-drive-final-qualified.json.gz', 'verify_shared_drive.py', None, [])}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def headings(text):
    """Track actual ATX headings in these sources, excluding fenced examples."""
    rows, offset, fence = [], 0, None
    for line in text.splitlines(keepends=True):
        match = re.match(r'^ {0,3}(`{3,}|~{3,})(.*)', line)
        if match:
            token, tail = match.groups()
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence) and not tail.strip():
                fence = None
        elif fence is None:
            match = re.match(r'^(#{1,6}) ([^\n]+)\n?$', line)
            if match:
                title = match[2]
                rows.append({'level': len(match[1]), 'title': title, 'start': offset,
                             'anchor': re.sub(r'[^a-z0-9 _-]', '', title.lower()).replace(' ', '-')})
        offset += len(line)
    if fence is not None:
        raise ValueError('Unclosed source fence')
    return rows


def snapshot(path):
    raw = (ROOT / path).read_bytes()
    return {'text': raw.decode(), 'sha256': sha(raw)}


def consumers(head):
    names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', '-z', head, '--', *SCOPES], cwd=ROOT).decode().split('\0')
    paths = [name for name in names if Path(name).suffix in SUFFIXES]
    rows = []
    for start in range(0, len(paths), 128):
        command = ['git', 'grep', '-n', '-I', '--null', '-e', STEMS[0], '-e', STEMS[1], head, '--', *paths[start:start + 128]]
        result = subprocess.run(command, cwd=ROOT, capture_output=True)
        if result.returncode not in (0, 1):
            raise ValueError('Baseline consumer census refused: ' + result.stderr.decode())
        for record in result.stdout.decode().splitlines():
            name, number, line = record.split('\0', 2)
            path = name.removeprefix(head + ':')
            rows.append({'path': path, 'line': int(number), 'line_sha256': sha(line.encode()),
                         'stems': [stem for stem in STEMS if stem in line]})
    return sorted(rows, key=lambda row: (row['path'], row['line']))


def build():
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
    inputs = {path: snapshot(path) for path in (CORE, API, SUMMARY)}
    for path, saved in inputs.items():
        original = subprocess.check_output(['git', 'show', head + ':' + path], cwd=ROOT)
        if original.decode() != saved['text']:
            raise ValueError('Baseline book must be committed: ' + path)
    core, api, summary = (inputs[path]['text'] for path in (CORE, API, SUMMARY))
    all_headings = headings(core)
    selected = [row for row in all_headings if row['level'] == 3 and row['title'].startswith('Normalized ')]
    blocks = []
    for row in selected:
        following = next(item for item in all_headings if item['start'] > row['start'] and item['level'] <= 3)
        text = core[row['start']:following['start']]
        blocks.append({'title': row['title'], 'anchor': row['anchor'], 'text': text,
                       'sha256': sha(text.encode()), 'source_start_byte': len(core[:row['start']].encode()),
                       'source_end_byte': len(core[:following['start']].encode())})
    first, last = selected[0]['start'], following['start']
    moved = core[first:last]
    if ''.join(block['text'] for block in blocks) != moved:
        raise ValueError('Selected family blocks must be contiguous')
    routes = [{'anchor': block['anchor'], 'source': CORE, 'destination': API,
               'title': block['title']} for block in blocks]
    stubs = ''.join('### ' + row['title'] + '\n\nSee the [canonical field reference]('
                    + Path(API).name + '#' + row['anchor'] + ').\n\n' for row in routes)
    proposed_core = core[:first] + stubs + core[last:]
    old_nav = '''POD documents the Perl bindings. The language-neutral request/result schemas,
support boundaries and tutorials remain in
[Extensions and Embedding](11-extensions-and-embedding.md) and the
[VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md).
'''
    new_nav = '''POD documents the Perl bindings. The normalized semantic field reference below
complements [Extensions and Embedding](11-extensions-and-embedding.md) for
discovery, support boundaries and tutorials, and the
[VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md) for versioned VIAL models.
'''
    if api.count(old_nav) != 1:
        raise ValueError('Exact existing API navigation paragraph required')
    proposed_api = api.replace('# Perl API Reference\n', '# API and Model Reference\n\n## Perl API Reference\n', 1).replace(old_nav, new_nav)
    intro = ('## Normalized Semantic Metadata Reference\n\n'
             'Use each field family with its payload subject, dedicated owner, optional or\n'
             'variant rule, and qualification limits. Begin with\n'
             '[capability discovery](11-extensions-and-embedding.md#capability-manifest-discovery)\n'
             'for the containing manifest and query workflow.\n\n')
    if proposed_api.count('## Build and preview\n') != 1:
        raise ValueError('Exact API build boundary required')
    proposed_api = proposed_api.replace('## Build and preview\n', intro + moved + '## Build and preview\n', 1)
    proposed_summary = summary.replace('[Perl API Reference](11a-perl-api-reference.md)', '[API and Model Reference](11a-perl-api-reference.md)')
    profile_rows = {name: {'packet': AUDIT + packet, 'reader': AUDIT + reader,
                         'rendered_reader': AUDIT + rendered if rendered else None,
                         'document_container': container, 'oracle_mode': 'saved-only',
                         'native_view': 'actual API HTML copied into an owned same-volume legacy-name proxy; original native page/links checked separately'}
                    for name, (packet, reader, rendered, container) in PROFILES.items()}
    artifacts = {row[key] for row in profile_rows.values() for key in ('packet', 'reader', 'rendered_reader') if row[key]}
    artifacts |= {AUDIT + name for name in ('normalized-boolean-repair-before.json.gz', 'normalized-boolean-repair-after.json.gz', 'verify_normalized_booleans.py')}
    prefix = BASE.relative_to(ROOT).as_posix() + '/'
    return {'schema': 'fsmgen.normalized_reference_partition.v1', 'owner': OWNER, 'baseline_head': head,
        'inputs': inputs, 'blocks': blocks, 'routes': routes,
        'candidate_documents': {CORE: proposed_core, API: proposed_api, SUMMARY: proposed_summary},
        'navigation_rewrite': {'before': old_nav, 'after': new_nav},
        'baseline_consumers': consumers(head), 'reader_profiles': profile_rows,
        'reader_inputs': {path: sha((ROOT / path).read_bytes()) for path in sorted(artifacts)},
        'bridge_contract': {
            'documents': 'Authenticate actual core/API bytes, unique canonical blocks and stable root stubs; reconstruct a separately labeled semantic comparison view by replacing stubs with exact canonical blocks.',
            'oracles': 'Use immutable old oracles in saved mode only; refresh explicitly declared document/POD comparison slots, preserve fields/delegations/input/instrument identities, and prove current code/docs/runtime separately.',
            'runtime_exception': 'NormalizedSemanticReport.pm may differ from its original source only by the exact retained before/after JSON Boolean repair; verify that authenticated bridge without rerunning original producers.',
            'native': 'Check actual old/new page routes and all anchors first; hash-bound legacy-name proxies may feed frozen rendered oracles without changing actual build output.',
            'limits': 'Plan only. Candidate block/link/source conservation is not migrated native delivery, full grammar/source availability, original compiler/backend execution or whole-book browser signoff.'},
        'instruments': {prefix + name: snapshot(prefix + name) for name in ('plan.py', 'verify.py')},
        'evidence_legs': {
            'rederive': 'Capture committed source bytes, complete baseline reference census, exact normalized blocks and prospective destination/routing graph.',
            'falsify': 'Independent block/title/order/source reconstruction, whole-tree byte/line census, complete candidate anchor/link/entrypoint preservation and omission/duplicate/misroute/reader/source controls.',
            'durability': 'Retain baseline Git identity, full source/candidate texts, exact moved-origin spans, consumer/input/instrument identities and replayable contract checks.'}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new contract-directory file')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote prospective semantic split; independent contract verification required.')


if __name__ == '__main__':
    main()
