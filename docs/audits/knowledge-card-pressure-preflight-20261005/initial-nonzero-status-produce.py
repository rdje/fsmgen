"""Capture exact card/authority inputs and qualify public per-file controls."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-pressure-preflight-20261005')
REVISION = '8fd0685838cf080f9f4e196b69116f0f667e7e81'
AUTHORITY = (
    'knowledge-map/scripts/knowledge_map.pl',
    'knowledge-map/scripts/check_knowledge_map.sh',
    'knowledge-map/scripts/knowledge_map.conf',
    'doctrine/live_document_size/surfaces.jsonl',
    'LIVE_DOCUMENT_SIZE_CONTAINMENT.md',
    'docs/knowledge/knowledge-card-sizing-and-partition.md',
    'docs/knowledge/live-document-surface-growth-procedure.md',
    'docs/knowledge/live-document-transition-allowance-headroom.md',
    'docs/knowledge/live-document-size-containment.md',
    'docs/audits/record-value-original-helper-join-20261005/initial-overbound-fact.txt',
    'docs/audits/record-value-original-helper-join-checks-20261005/initial-staged-doctrines-aggregate-refusal.json',
    'docs/audits/isf-sync-checklist-checks-20261005/staged-doctrines.json',
)


def version(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + path])


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def capture():
    git_paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--', 'docs/knowledge'], text=True).splitlines()
    paths = [path for path in git_paths if Path(path).parent == Path('docs/knowledge') and path.endswith('.md')]
    live_paths = sorted(str(path) for path in Path('docs/knowledge').glob('*.md'))
    assert sorted(paths) == live_paths, 'independent complete own card membership'
    cards = {}
    for path in paths:
        p = Path(path)
        assert p.is_file() and not p.is_symlink() and p.stat().st_dev == Path('.').stat().st_dev, 'regular same-volume card'
        raw = version(path)
        assert raw == p.read_bytes(), 'whole Git/working source identity'
        cards[path] = {'body': raw.decode('utf-8'), **identity(raw)}
    sources = {path: {'body': version(path).decode('utf-8'), **identity(version(path))} for path in AUTHORITY}
    assert all(Path(path).read_bytes() == source['body'].encode() for path, source in sources.items()), 'complete committed authority bytes'
    return {'revision': REVISION, 'sources': sources, 'cards': cards,
            'configuration': {'repo_override_exists': Path('.knowledge_map.conf').exists(),
                              'card_limit_environment': {k: v for k, v in os.environ.items() if k.startswith('KM_CARD_MAX')}},
            'scope': 'Exact own tracked direct docs/knowledge Markdown cohort at the named revision; decision cards, nested history, external repositories and working/generated query caches are excluded.'}


def measure(capture):
    rows = []
    for path, card in capture['cards'].items():
        raw = card['body'].encode()
        lines = raw.splitlines()
        rows.append({'path': path, **identity(raw), 'lines': len(lines), 'line_bytes': max(map(len, lines), default=0)})
    return {'members': rows, 'aggregate': {'files': len(rows), 'lines_total': sum(row['lines'] for row in rows),
                                         'bytes_total': sum(row['bytes'] for row in rows),
                                         'lines_each': max(row['lines'] for row in rows),
                                         'bytes_each': max(row['bytes'] for row in rows),
                                         'line_bytes_each': max(row['line_bytes'] for row in rows)},
            'largest_byte_members': sorted(rows, key=lambda row: (-row['bytes'], row['path']))[:5]}


def fixtures(capture):
    root = Path('.artifacts/knowledge-card-pressure/public-fixtures')
    root.mkdir(parents=True, exist_ok=True)
    tool = root / 'knowledge_map.pl'
    tool.write_text(capture['sources']['knowledge-map/scripts/knowledge_map.pl']['body'])
    valid = capture['sources']['docs/audits/record-value-original-helper-join-20261005/initial-overbound-fact.txt']['body'].encode()
    assert len(valid) == 6192, 'exact actual previously refused authoring proposal'
    assert not capture['configuration']['repo_override_exists'] and not capture['configuration']['card_limit_environment'], 'observed effective default per-card profile'
    # Pad with finite ASCII lines so byte, line and width controls remain disjoint.
    def pad(raw, total):
        residue = total - len(raw)
        return raw + (b'x' * 99 + b'\n') * (residue // 100) + (b'x' * (residue % 100 - 1) + b'\n' if residue % 100 else b'')
    bad_bytes = pad(valid, 32769)
    assert len(bad_bytes) == 32769 and len(bad_bytes.splitlines()) < 512 and max(map(len, bad_bytes.splitlines())) < 819
    bad_lines = valid + b'\n' * (513 - len(valid.splitlines()))
    assert len(bad_lines.splitlines()) == 513 and len(bad_lines) < 32768
    bad_width = valid + b'x' * 820 + b'\n'
    cases = [('valid-prior-proposal', valid, 0, None),
             ('actual-byte-overflow', bad_bytes, None, 'card bytes 32769 exceed 32768'),
             ('actual-line-overflow', bad_lines, None, 'card lines 513 exceed 512'),
             ('actual-line-width-overflow', bad_width, None, 'card line width 820 exceeds 819')]
    result = []
    for name, raw, status, cause in cases:
        case_root = root / name
        source = case_root / 'input/card.md'
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(raw)
        env = os.environ.copy()
        env.update(KM_ROOT=str(case_root), KM_SCAN_DIRS='input', KM_OUTPUT='KNOWLEDGE_MAP.md',
                   KM_SHARD_DIR='generated', KM_QUERY_CACHE_DIR='query', KM_TITLE='Public card limit probe')
        command = ['perl', str(tool), 'generate']
        completed = subprocess.run(command, env=env, capture_output=True, text=True)
        native_receipt = {'fixture': name, 'command': command, 'status': completed.returncode,
                          'stdout': completed.stdout, 'stderr': completed.stderr}
        (case_root / 'native-receipt.json').write_text(json.dumps(native_receipt, indent=2) + '\n')
        assert (completed.returncode == 0 if status == 0 else completed.returncode != 0), 'intended actual public fixture status: ' + name
        if cause:
            assert cause in completed.stderr, 'intended actual public fixture cause: ' + name
        else:
            check = subprocess.run(['perl', str(tool), 'check'], env=env, capture_output=True, text=True)
            assert check.returncode == 0 and 'knowledge-map: OK' in check.stderr, 'full public generate/check positive'
        row = {'fixture': name, 'input': raw.decode(), 'identity': identity(raw), 'command': command,
               'environment': {key: env[key] for key in ('KM_ROOT', 'KM_SCAN_DIRS', 'KM_OUTPUT', 'KM_SHARD_DIR', 'KM_QUERY_CACHE_DIR', 'KM_TITLE')},
               'status': completed.returncode, 'stdout': completed.stdout, 'stderr': completed.stderr, 'intended_cause': cause}
        if not cause:
            row['check'] = {'status': check.returncode, 'stdout': check.stdout, 'stderr': check.stderr}
        result.append(row)
    return result


def main():
    path = BASE / 'capture.json'
    if path.exists():
        saved = json.loads(path.read_text())
        assert all(version(p) == s['body'].encode() for p, s in saved['sources'].items()), 'whole pinned authority source'
        assert all(version(p) == s['body'].encode() for p, s in saved['cards'].items()), 'whole pinned card source'
    else:
        saved = capture()
        path.write_text(json.dumps(saved, sort_keys=True, indent=2) + '\n')
    proof = {'census': measure(saved), 'public_fixtures': fixtures(saved),
             'scope': 'Dated exact cohort pressure and actual default public per-card profile; private6144 authoring assertion is not the enforced byte bound. No semantic duplicate or rollover classification is inferred.'}
    path = BASE / 'proofs.json'
    if path.exists():
        assert json.loads(path.read_text()) == proof, 'whole saved source/census/public control proof'
    else:
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS exact revision-bound card/source census and public prior-proposal/byte/line/width controls; collection rollover and semantic classification remain open.')


if __name__ == '__main__':
    main()
