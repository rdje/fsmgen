#!/usr/bin/env python3
"""Census a fixed decision-store revision without changing paths or authority."""

import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RECORD = re.compile(r'docs/decisions/([0-9]{4})-[^/]+\.md\Z')
INDEX_ROW = re.compile(r'^\| \[([0-9]{4})\]\(([^)]+)\)', re.MULTILINE)
MAX_RECORDS = 4096
MAX_BLOB_BYTES = 4_194_304
MAX_CONSUMER_LINES = 16_384
MAX_SEARCH_BYTES = 33_554_432


def require(condition, message):
    if not condition:
        raise ValueError(message)


def git(*args, input_bytes=None):
    result = subprocess.run(['git', '-C', str(ROOT), *args], input=input_bytes,
                            capture_output=True, check=False)
    if result.returncode:
        raise ValueError(result.stderr.decode('utf-8', errors='replace').strip())
    return result.stdout


def blob(revision, path):
    data = git('show', f'{revision}:{path}')
    require(len(data) <= MAX_BLOB_BYTES, f'audit blob exceeds bound: {path}')
    return data


def dimensions(data):
    lines = data.splitlines()
    return {'bytes': len(data), 'lines': len(lines),
            'line_bytes': max(map(len, lines), default=0),
            'sha256': hashlib.sha256(data).hexdigest()}


def index_paths(text, records):
    """Compare actual identities and destinations, never just row totals."""
    rows = INDEX_ROW.findall(text)
    ids = [row[0] for row in rows]
    require(len(ids) == len(set(ids)), 'decision index duplicates an identity')
    require(set(ids) == set(records), 'decision index identity membership differs')
    for record_id, target in rows:
        require('/' not in target and '#' not in target,
                f'current flat index has an unsupported destination: {record_id}')
        require('docs/decisions/' + target == records[record_id],
                f'decision index misroutes identity: {record_id}')
    return [{'id': record_id, 'path': records[record_id]} for record_id, _ in rows]


def public_originals(revision, archive):
    """Run the pinned published CLI so later migrations cannot stale this audit."""
    parent = ROOT / '.artifacts' / 'decision-identity-audit'
    parent.mkdir(parents=True, exist_ok=True)
    originals = {}
    with tempfile.TemporaryDirectory(dir=parent) as workspace:
        root = Path(workspace)
        for path in ['docs/decisions/history/0001-0050.json', 'scripts/decision_records.py',
                     'docs/audits/decision-record-rollover-census-20260927.json']:
            target = root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(blob(revision, path))
        for record in archive['records']:
            record_id = record['id']
            public = subprocess.run([sys.executable, '-B', str(root / 'scripts/decision_records.py'),
                                     '--root', str(root), 'read', record_id], capture_output=True)
            require(public.returncode == 0, f'published reader refuses {record_id}')
            original = blob(archive['source_revision'], record['path'])
            require(public.stdout == original, f'public original differs: {record_id}')
            originals[record_id] = original
    return originals


def audit(revision):
    revision = git('rev-parse', '--verify', revision + '^{commit}').decode().strip()
    entries = git('ls-tree', '-rz', '--full-tree', revision).split(b'\0')
    records = {}
    root_members = set()
    for entry in filter(None, entries):
        metadata, raw_path = entry.split(b'\t', 1)
        mode, kind, _ = metadata.split()
        path = raw_path.decode('utf-8')
        if path.startswith('docs/decisions/') and path.count('/') == 2 and path.endswith('.md'):
            require(kind == b'blob' and mode in (b'100644', b'100755'),
                    f'decision member is not a regular tracked file: {path}')
            root_members.add(path)
        if kind != b'blob' or mode not in (b'100644', b'100755'):
            continue  # Gitlinks and symlinks are not inspected.
        match = RECORD.fullmatch(path)
        if match:
            require(match[1] not in records, f'duplicate decision ID: {match[1]}')
            records[match[1]] = path
    require(0 < len(records) <= MAX_RECORDS, 'decision audit population exceeds bound')
    require(root_members == set(records.values()) | {'docs/decisions/INDEX.md'},
            'root rationale contains an unclassified Markdown member')
    index = blob(revision, 'docs/decisions/INDEX.md')
    routes = index_paths(index.decode('utf-8'), records)
    archive_path = 'docs/decisions/history/0001-0050.json'
    archive = json.loads(blob(revision, archive_path))
    sealed = {row['id']: row for row in archive['records']}
    require(set(sealed) == {f'{value:04}' for value in range(1, 51)},
            'published sealed-reader cohort differs')
    require(set(sealed) <= set(records), 'sealed public path is absent')
    originals = public_originals(revision, archive)
    members = []
    root_data = [index]
    for record_id, path in sorted(records.items()):
        data = blob(revision, path)
        root_data.append(data)
        row = {'id': record_id, 'path': path, **dimensions(data)}
        text = data.decode('utf-8')
        fact = re.search(r'^id: (.+)$', text, re.MULTILINE) if text.startswith('---\n') else None
        row['knowledge_id'] = fact[1] if fact else None
        if record_id in sealed:
            require(sealed[record_id]['path'] == path, 'sealed path identity differs')
            row.update(storage='sealed_forwarder', original=dimensions(originals[record_id]))
        else:
            row['storage'] = 'canonical_body'
        members.append(row)
    registry = json.loads(next(line for line in blob(
        revision, 'doctrine/live_document_size/surfaces.jsonl').splitlines()
        if json.loads(line).get('surface_id') == 'rationale'))
    require(registry['targets'] == ['docs/decisions/*.md'],
            'audit contract requires the pre-transition root collection')
    actual = {'files': len(root_data), 'bytes_total': sum(map(len, root_data)),
              'lines_total': sum(len(data.splitlines()) for data in root_data),
              'bytes_each': max(map(len, root_data)),
              'lines_each': max(len(data.splitlines()) for data in root_data),
              'line_bytes_each': max(dimensions(data)['line_bytes'] for data in root_data)}
    # Git's independent tracked-text search covers full basenames, including history
    # and generated evidence. Partial IDs and unseen external consumers are excluded.
    names = {Path(path).name: record_id for record_id, path in records.items()}
    search = subprocess.run(['git', '-C', str(ROOT), 'grep', '--no-recurse-submodules', '-n', '-I', '-F',
                             '-f', '-', revision, '--'],
                            input=('\n'.join(sorted(names)) + '\n').encode(),
                            capture_output=True)
    require(search.returncode in (0, 1), 'tracked consumer search failed')
    require(len(search.stdout) <= MAX_SEARCH_BYTES
            and len(search.stdout.splitlines()) <= MAX_CONSUMER_LINES,
            'tracked consumer population exceeds audit bound')
    consumers = []
    for raw in search.stdout.splitlines():
        _, path, line, text = raw.decode('utf-8').split(':', 3)
        matched = sorted(record_id for name, record_id in names.items() if name in text)
        category = ('body_reverify' if text.startswith('reverify:') else
                    'fact_evidence' if text.startswith('evidence:') else
                    'navigation' if '](' in text else 'identity_or_provenance')
        anchors = [{'id': record_id, 'fragment': fragment}
                   for name, record_id in sorted(names.items())
                   for fragment in re.findall(re.escape(name) + r'#([A-Za-z0-9_%:-]+)', text)]
        consumers.append({'path': path, 'line': int(line), 'ids': matched,
                          'category': category, 'source_line_sha256':
                          hashlib.sha256(text.encode()).hexdigest(),
                          'literal_fragment_references': anchors})
    target = registry['health_targets']['files']
    rollover = registry['milestones']['rollover_pct']
    generic = subprocess.run(['git', '-C', str(ROOT), 'grep', '--no-recurse-submodules', '-n', '-I', '-F',
                              'docs/decisions', revision, '--',
                              'scripts', 'knowledge-map', 'perl', 't'], capture_output=True)
    require(generic.returncode in (0, 1), 'generic code-consumer search failed')
    require(len(generic.stdout) <= MAX_SEARCH_BYTES
            and len(generic.stdout.splitlines()) <= MAX_CONSUMER_LINES,
            'generic code-consumer population exceeds audit bound')
    generic_consumers = []
    for raw in generic.stdout.splitlines():
        _, path, line, text = raw.decode('utf-8').split(':', 3)
        generic_consumers.append({'path': path, 'line': int(line),
                                  'source_line_sha256': hashlib.sha256(text.encode()).hexdigest()})
    return {'schema_version': 1, 'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.1',
            'source_revision': revision, 'members': members, 'index_routes': routes,
            'root_dimensions': actual, 'rationale_file_target': target,
            'rationale_file_ceiling': registry['enforcement_ceilings']['files'],
            'next_record_enters_rollover': (actual['files'] + 1) * 100 >= target * rollover,
            'consumer_scope': 'All tracked nonbinary root-repository text at source_revision '
                              'containing a complete current decision basename; no submodule '
                              'recursion, partial-ID enumeration or external-consumer claim.',
            'consumers': consumers,
            'generic_code_scope': 'Tracked scripts/knowledge-map/perl/t text mentioning '
                                  'docs/decisions; candidates require interface review, '
                                  'not an assertion that every dynamic path is enumerated.',
            'generic_code_consumers': generic_consumers}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--revision', required=True, help='fixed source commit')
    args = parser.parse_args()
    try:
        result = audit(args.revision)
        print(json.dumps(result, indent=2, sort_keys=True))
    except (OSError, ValueError, KeyError, TypeError, UnicodeError) as error:
        print(f'decision-identity-audit: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
