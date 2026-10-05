"""Verify the exact cohort, actual native limits and scoped collection pressure."""
import copy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-pressure-qualified-20261005')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def check(c, p, blobs):
    expected_paths = sorted(path for path in blobs if path.endswith('.md') and (path.startswith('docs/knowledge/') or path.startswith('docs/decisions/')))
    assert [row['path'] for row in c['scanned']] == expected_paths, 'complete own scanned membership'
    direct = []
    for row in c['scanned']:
        raw = blobs[row['path']]
        assert {key: row[key] for key in ('bytes', 'sha256')} == identity(raw), 'whole independent scanned source'
        assert row['lines'] == sum(byte == 10 for byte in raw), 'registered completed-newline metric'
        assert row['logical_lines'] == len(raw.split(b'\n')) - int(raw.endswith(b'\n')), 'separate logical text lines'
        assert row['line_bytes'] == max(map(len, raw.split(b'\n')), default=0), 'independent original-byte maximum line'
        if Path(row['path']).parent == Path('docs/knowledge'):
            direct.append({key: row[key] for key in ('path', 'bytes', 'sha256', 'lines', 'line_bytes')})
        fact = c['facts'].get(row['path'])
        assert (fact['id'] if fact else None) == row['fact_id'], 'scanned/fact identity allocation'
        if fact:
            assert fact['body'].encode() == raw and {key: fact[key] for key in ('bytes', 'sha256')} == identity(raw), 'whole retained fact bytes'
    assert p['census']['members'] == direct, 'physical collection includes retained non-fact members'
    aggregate = {'files': len(direct), 'lines_total': sum(x['lines'] for x in direct), 'bytes_total': sum(x['bytes'] for x in direct),
                 'lines_each': max(x['lines'] for x in direct), 'bytes_each': max(x['bytes'] for x in direct), 'line_bytes_each': max(x['line_bytes'] for x in direct)}
    assert p['census']['aggregate'] == aggregate, 'independent whole physical aggregate'
    for path, source in c['sources'].items():
        assert source['body'].encode() == blobs[path] and {key: source[key] for key in ('bytes', 'sha256')} == identity(blobs[path]), 'whole exact authority source'
    core = c['sources']['knowledge-map/scripts/knowledge_map.pl']['body']
    limits = {key: int(value.replace('_', '')) for key, value in re.findall(r"(card_lines|card_bytes|card_line_bytes)\s+=> env_positive\('[^']+', ([0-9_]+)\)", core)}
    assert limits == {'card_lines': 512, 'card_bytes': 32768, 'card_line_bytes': 819}, 'actual declared default profile'
    assert not c['configuration']['repo_override_exists'] and not any(k.startswith('KM_CARD_MAX') for k in c['configuration']['environment']), 'observed effective default profile'
    assert core.count("decode('UTF-8', $bytes, FB_CROAK | LEAVE_SRC)") == 2, 'actual repaired original-byte readers'
    cases = {row['fixture']: row for row in p['public_fixtures']}
    assert set(cases) == {'valid-prior-proposal', 'actual-byte-overflow', 'actual-line-overflow', 'actual-line-width-overflow'}, 'complete declared public controls'
    for name, row in cases.items():
        raw = row['body'].encode()
        assert {key: row[key] for key in ('bytes', 'sha256')} == identity(raw), 'whole public control input'
        lines = raw.split(b'\n')[:-1]
        if name == 'valid-prior-proposal':
            assert raw == c['sources']['docs/audits/record-value-original-helper-join-20261005/initial-overbound-fact.txt']['body'].encode() and len(raw) == 6192, 'exact actually refused authoring input'
        elif name == 'actual-byte-overflow':
            assert len(raw) == limits['card_bytes'] + 1 and len(lines) < limits['card_lines'] and max(map(len, lines)) < limits['card_line_bytes'], 'disjoint genuine byte boundary'
        elif name == 'actual-line-overflow':
            assert len(lines) == limits['card_lines'] + 1 and len(raw) < limits['card_bytes'] and max(map(len, lines)) < limits['card_line_bytes'], 'disjoint genuine line boundary'
        else:
            assert max(map(len, lines)) == limits['card_line_bytes'] + 1 and len(raw) < limits['card_bytes'] and len(lines) < limits['card_lines'], 'disjoint genuine width boundary'
        for result in row['outcomes'].values():
            if row['intended_cause']:
                assert result['status'] != 0 and row['intended_cause'] in result['stderr'], 'real public intended refusal'
            else:
                assert result['status'] == 0, 'real public accepted prior proposal'
    assert p['allocation']['facts'] == len(c['facts']) and p['allocation']['unique_questions'] == len(p['allocation']['rows'].splitlines()), 'declared actual allocation population'
    assert p['public_allocation']['status'] == 0 and p['public_allocation']['stdout'] == p['allocation']['rows'], 'complete actual public question/path allocation'
    surface = next(row for row in map(json.loads, c['sources']['doctrine/live_document_size/surfaces.jsonl']['body'].splitlines()) if row.get('surface_id') == 'knowledge_cards')
    allowance = {key: surface['baseline'][key] + surface['transition']['max_growth'][key] for key in aggregate}
    return {'revision': c['revision'], 'physical_collection': aggregate, 'fact_population': {key: p['allocation'][key] for key in ('facts', 'unique_questions', 'answer_occurrences')},
            'declared_card_defaults': limits, 'authorized_transition': allowance, 'remaining_transition': {key: allowance[key] - aggregate[key] for key in aggregate},
            'scope': 'Exact dated physical cohort and completed-newline metrics; native fact population and logical lines are separate. Existing rollover_debt remains; no semantic duplicate, healthy-state, removal count or new allowance is inferred.'}


def main():
    c = json.loads((BASE / 'capture.json').read_text()); p = json.loads((BASE / 'proofs.json').read_text())
    git_paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', c['revision'], '--', 'docs/knowledge', 'docs/decisions'], text=True).splitlines()
    paths = sorted(set([path for path in git_paths if path.endswith('.md')] + list(c['sources'])))
    query = ''.join(c['revision'] + ':' + path + '\n' for path in paths).encode()
    output = subprocess.check_output(['git', 'cat-file', '--batch'], input=query)
    blobs = {}; position = 0
    for path in paths:
        end = output.index(b'\n', position); header = output[position:end].split(); assert header[1] == b'blob'
        position = end + 1; size = int(header[2]); blobs[path] = output[position:position + size]; position += size + 1
    assert position == len(output), 'whole exact Git authority domain'
    pressure = check(c, p, blobs)
    controls = []
    for name in ('omitted-physical-readme', 'logical-lines-borrowed-as-containment', 'lost-question-row', 'wrong-public-byte-refusal', 'private-cap-promoted-to-profile'):
        bad, proof = copy.deepcopy(c), copy.deepcopy(p)
        if name == 'omitted-physical-readme':
            proof['census']['members'] = [r for r in proof['census']['members'] if r['path'] != 'docs/knowledge/README.md']
        elif name == 'logical-lines-borrowed-as-containment':
            row = next(r for r in bad['scanned'] if r['path'] == 'docs/knowledge/nexsim-semantic-api-mcp-agent-consumer-requirements.md'); row['lines'] = row['logical_lines']
        elif name == 'lost-question-row':
            proof['public_allocation']['stdout'] = proof['public_allocation']['stdout'].split('\n', 1)[1]
        elif name == 'wrong-public-byte-refusal':
            next(row for row in proof['public_fixtures'] if row['fixture'] == 'actual-byte-overflow')['outcomes']['generate']['status'] = 0
        else:
            bad['configuration']['environment']['KM_CARD_MAX_BYTES'] = '6144'
        try:
            check(bad, proof, blobs)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('actual qualification control accepted: ' + name)
    for name, value in [('pressure.json', pressure), ('controls.json', controls)]:
        path = BASE / name
        if path.exists():
            assert json.loads(path.read_text()) == value, 'whole qualified product: ' + name
        else:
            path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    if '--current' in sys.argv:
        current_paths = sorted(str(path) for root in ('docs/knowledge', 'docs/decisions') for path in Path(root).rglob('*.md'))
        assert current_paths == [row['path'] for row in c['scanned']], 'current complete own scan domain'
        assert all(Path(path).read_bytes() == blobs[path] for path in current_paths), 'current complete own source bytes'
        current_core = Path('knowledge-map/scripts/knowledge_map.pl').read_bytes()
        assert current_core == blobs['knowledge-map/scripts/knowledge_map.pl'], 'current actual public programme'
        current_surface = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()) if row.get('surface_id') == 'knowledge_cards')
        old_surface = next(row for row in map(json.loads, c['sources']['doctrine/live_document_size/surfaces.jsonl']['body'].splitlines()) if row.get('surface_id') == 'knowledge_cards')
        assert current_surface == old_surface, 'current card authority unchanged'
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, record in json.loads(manifest.read_text()).items():
            assert identity(Path(path).read_bytes()) == record, 'sealed exact qualification evidence: ' + path
    print('PASS independent complete physical/fact domains, original-byte/LF pressure and actual default/public question/control proof; snapshot scope and remaining rollover are explicit.')


if __name__ == '__main__':
    main()
