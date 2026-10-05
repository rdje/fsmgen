"""Capture complete own fact population and qualify repaired public bounds."""
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-pressure-qualified-20261005')
REVISION = '82b1e964595e92a8f29fffb108fadedba61ee0ae'
AUTHORITY = [
    'knowledge-map/scripts/knowledge_map.pl',
    'knowledge-map/scripts/check_knowledge_map.sh',
    'knowledge-map/scripts/knowledge_map.conf',
    'doctrine/live_document_size/surfaces.jsonl',
    'LIVE_DOCUMENT_SIZE_CONTAINMENT.md',
    'docs/knowledge/knowledge-card-sizing-and-partition.md',
    'docs/knowledge/live-document-surface-growth-procedure.md',
    'docs/knowledge/live-document-transition-allowance-headroom.md',
    'docs/knowledge/live-document-size-containment.md',
    'docs/decisions/current/continuity/0064-live-document-growth-is-declared-measurement-with-paired-decisions.md',
    'docs/decisions/current/continuity/0070-transition-allowances-carry-one-declared-step-and-a-live-owner.md',
    'docs/audits/record-value-original-helper-join-20261005/initial-overbound-fact.txt',
    'docs/audits/record-value-original-helper-join-checks-20261005/initial-staged-doctrines-aggregate-refusal.json',
    'docs/audits/record-value-original-helper-join-20261005/verify.py',
    'docs/audits/record-value-original-helper-join-checks-20261005/initial-fact-authoring-refusal.json',
    'docs/audits/knowledge-card-pressure-checks-20261005/staged-doctrines-final.json',
    'docs/book/src/90-reference-map.md',
]


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def git_paths():
    raw = subprocess.check_output(['git', 'ls-tree', '-r', '-z', '--name-only', REVISION, '--', 'docs/knowledge', 'docs/decisions'])
    return sorted(p.decode() for p in raw.split(b'\0') if p.endswith(b'.md'))


def bulk_git(paths):
    query = ''.join(REVISION + ':' + p + '\n' for p in paths).encode()
    result = subprocess.run(['git', 'cat-file', '--batch'], input=query, capture_output=True, check=True).stdout
    data, position = {}, 0
    for path in paths:
        end = result.index(b'\n', position)
        header = result[position:end].split()
        assert len(header) == 3 and header[1] == b'blob', 'own exact Git blob: ' + path
        count = int(header[2]); position = end + 1
        data[path] = result[position:position + count]; position += count
        assert result[position:position + 1] == b'\n', 'whole Git framing'; position += 1
    assert position == len(result), 'complete Git response consumed'
    return data


def metadata(text):
    lines = text.splitlines()
    if not lines or lines[0] != '---':
        return None
    end = lines.index('---', 1)
    front = lines[1:end]
    identifiers = [line[4:].strip().strip('"') for line in front if line.startswith('id: ')]
    answers = []
    active = False
    for line in front:
        if line.startswith('answers:'):
            rest = line[len('answers:'):].strip()
            active = not rest
            if rest:
                values = json.loads(rest)
                assert isinstance(values, list) and all(isinstance(v, str) for v in values), 'independent inline answer types'
                answers.extend(values)
        elif line.startswith(' ') and active:
            match = re.fullmatch(r' +\- +(.*)', line)
            assert match, 'unqualified independent answer shape: ' + line
            answers.append(match[1].strip(" ").removeprefix('"').removesuffix('"'))
        elif not line.startswith(' '):
            active = False
    if answers:
        assert len(identifiers) == 1, 'complete independent fact identity'
    return {'id': identifiers[0], 'answers': answers} if answers else None


def capture():
    paths = git_paths()
    live = sorted(str(p) for root in ('docs/knowledge', 'docs/decisions') for p in Path(root).rglob('*.md'))
    assert paths == live, 'independent complete own scan membership'
    data = bulk_git(sorted(set(paths + AUTHORITY)))
    facts, scanned = {}, []
    for path in paths:
        p = Path(path)
        assert p.is_file() and not p.is_symlink() and p.stat().st_dev == Path('.').stat().st_dev, 'own regular same-volume source'
        assert not any((ancestor / '.git').exists() for ancestor in p.parents if ancestor != Path('.')), 'no nested repository boundary'
        raw = data[path]
        assert raw == p.read_bytes(), 'whole Git/working source equality: ' + path
        fact = metadata(raw.decode())
        scanned.append({'path': path, **identity(raw), 'fact_id': fact['id'] if fact else None})
        if fact:
            facts[path] = {'body': raw.decode(), **identity(raw), **fact}
    sources = {p: {'body': data[p].decode(), **identity(data[p])} for p in AUTHORITY}
    assert all(Path(p).read_bytes() == s['body'].encode() for p, s in sources.items()), 'whole committed authority'
    return {'revision': REVISION, 'scanned': scanned, 'facts': facts, 'sources': sources,
            'configuration': {'repo_override_exists': Path('.knowledge_map.conf').exists(),
                              'environment': {k: v for k, v in os.environ.items() if k.startswith('KM_')}},
            'scope': 'Complete own tracked docs/knowledge and docs/decisions Markdown scan at this revision, including all actual fact-bearing decision records. Direct docs/knowledge cards form the separate knowledge_cards containment cohort. External/submodule source and generated/query caches are excluded.'}


def measure(facts):
    members = []
    for path, fact in sorted(facts.items()):
        if Path(path).parent != Path('docs/knowledge'):
            continue
        raw = fact['body'].encode(); lines = raw.splitlines()
        members.append({'path': path, **identity(raw), 'lines': len(lines), 'line_bytes': max(map(len, lines), default=0)})
    return {'members': members, 'aggregate': {'files': len(members), 'bytes_total': sum(x['bytes'] for x in members),
            'lines_total': sum(x['lines'] for x in members), 'bytes_each': max(x['bytes'] for x in members),
            'lines_each': max(x['lines'] for x in members), 'line_bytes_each': max(x['line_bytes'] for x in members)},
            'largest_byte_members': sorted(members, key=lambda x: (-x['bytes'], x['path']))[:5]}


def public_fixtures(captured):
    root = Path('.artifacts/knowledge-card-pressure-qualified/public-fixtures'); root.mkdir(parents=True, exist_ok=True)
    tool = root / 'knowledge_map.pl'; tool.write_text(captured['sources']['knowledge-map/scripts/knowledge_map.pl']['body'])
    valid = captured['sources']['docs/audits/record-value-original-helper-join-20261005/initial-overbound-fact.txt']['body'].encode()
    assert len(valid) == 6192, 'exact actual private6144-refused input'
    residue = 32769 - len(valid)
    byte_overflow = valid + (b'x' * 99 + b'\n') * (residue // 100) + b'x' * (residue % 100 - 1) + b'\n'
    assert len(byte_overflow) == 32769 and len(byte_overflow.splitlines()) < 512 and max(map(len, byte_overflow.splitlines())) < 819
    line_overflow = valid + b'\n' * (513 - len(valid.splitlines()))
    width_overflow = valid + b'x' * 820 + b'\n'
    cases = [('valid-prior-proposal', valid, None), ('actual-byte-overflow', byte_overflow, 'card bytes 32769 exceed 32768'),
             ('actual-line-overflow', line_overflow, 'card lines 513 exceed 512'),
             ('actual-line-width-overflow', width_overflow, 'card line width 820 exceeds 819')]
    rows = []
    for name, raw, cause in cases:
        fixture = root / name; source = fixture / 'input/card.md'; source.parent.mkdir(parents=True, exist_ok=True); source.write_bytes(raw)
        env = os.environ.copy()
        assert not captured['configuration']['repo_override_exists'] and not any(k.startswith('KM_CARD_MAX') for k in captured['configuration']['environment']), 'observed effective default card profile'
        env.update(KM_ROOT=str(fixture), KM_SCAN_DIRS='input', KM_OUTPUT='KNOWLEDGE_MAP.md', KM_SHARD_DIR='generated', KM_QUERY_CACHE_DIR='query', KM_TITLE='Qualified public card limits')
        outcomes = {}
        for action in ('generate', 'check'):
            command = ['perl', str(tool), action]
            r = subprocess.run(command, env=env, capture_output=True, text=True)
            outcomes[action] = {'command': command, 'status': r.returncode, 'stdout': r.stdout, 'stderr': r.stderr}
            (fixture / (action + '-native-receipt.json')).write_text(json.dumps(outcomes[action], indent=2) + '\n')
            assert (r.returncode != 0 and cause in r.stderr) if cause else (r.returncode == 0), 'actual public boundary: ' + name + '/' + action
        rows.append({'fixture': name, 'body': raw.decode(), **identity(raw), 'intended_cause': cause, 'outcomes': outcomes})
    return rows


def allocation(facts):
    answers = {}
    for path, fact in facts.items():
        for question in fact['answers']:
            answers.setdefault(question, []).append((fact['id'], path))
    rows = ''.join(question + '\t' + ','.join(i for i, p in sorted(members)) + '\t' + ','.join(p for i, p in sorted(members)) + '\n' for question, members in sorted(answers.items()))
    return {'facts': len(facts), 'unique_questions': len(answers), 'answer_occurrences': sum(len(f['answers']) for f in facts.values()), 'rows': rows}


def main():
    p = BASE / 'capture.json'
    if not p.exists():
        p.write_text(json.dumps(capture(), sort_keys=True, indent=2) + '\n')
    c = json.loads(p.read_text())
    proof = {'census': measure(c['facts']), 'allocation': allocation(c['facts']), 'public_fixtures': public_fixtures(c)}
    q = subprocess.run(['knowledge-map/scripts/query_knowledge_map.sh', '--all', '--no-cache'], capture_output=True, text=True)
    assert q.returncode == 0 and q.stdout == proof['allocation']['rows'], 'complete independently selected question/fact/path allocation'
    proof['public_allocation'] = {'command': ['knowledge-map/scripts/query_knowledge_map.sh', '--all', '--no-cache'], 'status': q.returncode, 'stdout': q.stdout, 'stderr': q.stderr}
    p = BASE / 'proofs.json'
    if p.exists():
        assert json.loads(p.read_text()) == proof, 'whole immutable census/allocation/public control proof'
    else:
        p.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete revision-bound own fact/card census, independent whole question allocation and actual accepted6192/default byte/line/width refusal controls; semantic rollover selection remains open.')


if __name__ == '__main__':
    main()
