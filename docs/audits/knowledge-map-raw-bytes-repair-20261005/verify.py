"""Verify the exact own raw-byte repair, first failures and separating receipts."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/knowledge-map-raw-bytes-repair-20261005')
PREFLIGHT = Path('docs/audits/knowledge-card-pressure-preflight-20261005')
CHECKS = Path('docs/audits/knowledge-card-pressure-checks-20261005')


def verify(source, red, green, native, current=True):
    revision = source['revision']
    for path, item in source['files'].items():
        assert subprocess.check_output(['git', 'show', revision + ':' + path]) == item['before'].encode(), 'complete original source: ' + path
        if current:
            assert Path(path).read_bytes() == item['after'].encode(), 'complete current source: ' + path
    core = source['files']['knowledge-map/scripts/knowledge_map.pl']
    expected = core['before'].replace('use Encode qw(decode encode FB_CROAK);', 'use Encode qw(decode encode FB_CROAK LEAVE_SRC);')
    assert expected.count("decode('UTF-8', $bytes, FB_CROAK)") == 2, 'both actual readers'
    expected = expected.replace("decode('UTF-8', $bytes, FB_CROAK)", "decode('UTF-8', $bytes, FB_CROAK | LEAVE_SRC)")
    assert expected == core['after'], 'only byte-preserving decode repair'
    assert native['status'] == 0 and native['fixture'] == 'actual-byte-overflow', 'actual original public acceptance'
    assert '1 facts, 25 unique questions, 25 answer occurrences' in native['stderr'], 'original input route'
    assert red['status'] != 0 and 'Failed 1/5 subtests' in red['stdout'], 'real original red regression'
    for marker in ('card bytes 32769 exceed 32768', 'whole projection-byte change invalidates fingerprint', 'doesn\'t match'):
        assert marker in red['stderr'], 'actual original failure: ' + marker
    assert green['status'] == 0 and 'All tests successful.' in green['stdout'], 'actual broader green regression'
    for marker in ('ASCII exact cap checks', 'multibyte UTF-8 exact cap checks', 'invalid UTF-8 still refuses', 'whole projection-byte change invalidates fingerprint', 'byte-sensitive cache retains direct-query parity'):
        assert ' - ' + marker in green['stdout'], 'named separating public property: ' + marker
    assert 'not ok' not in green['stdout'], 'no failed property in green aggregate'
    path = 'docs/decisions/current/language-api/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md'
    decision = source['files'][path]
    citation = 'docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md; '
    assert decision['before'].count(citation) == 1 and decision['before'].replace(citation, '') == decision['after'], 'only redundant decision self-citation removed'
    raw = decision['after'].encode()
    assert len(raw) <= 32768, 'actual repaired decision encoded-byte bound'
    catalog = source['files']['docs/decisions/current/catalog.json']
    expected = json.loads(catalog['before'])
    row = next(row for row in expected['records'] if row['id'] == '0113')
    row['content'] = {'bytes': len(raw), 'lines': len(raw.splitlines()), 'line_bytes': max(map(len, raw.splitlines())), 'sha256': hashlib.sha256(raw).hexdigest()}
    assert expected == json.loads(catalog['after']), 'only exact decision catalog content updated'
    originals = source['files']['docs/decisions/history/transition-originals.json']
    assert originals['before'] == originals['after'], 'complete original decision store unchanged'
    original = next(row for row in json.loads(originals['after'])['records'] if row['id'] == '0113')
    assert citation in original['text'] and '# 0113' in original['text'], 'full original decision remains retrievable'
    test = source['files']['t/1567-knowledge-map-shards.t']
    start = test['after'].index("subtest 'raw UTF-8 byte boundaries")
    end = test['after'].index("subtest 'folded metadata", start)
    assert test['after'][:start] + test['after'][end:] == test['before'], 'only scoped regression added'


def main():
    source = json.loads((BASE / 'source.json').read_text())
    red = json.loads((CHECKS / 'red.json').read_text())
    green = json.loads((CHECKS / 'green.json').read_text())
    native = json.loads((PREFLIGHT / 'native-byte-overflow-accepted.json').read_text())
    verify(source, red, green, native)
    controls = []
    for name in ('lost-byte-preservation', 'false-native-refusal', 'borrowed-red-success', 'omitted-green-cache-property', 'lost-decision-body'):
        s, r, g, n = map(copy.deepcopy, (source, red, green, native))
        if name == 'lost-byte-preservation':
            s['files']['knowledge-map/scripts/knowledge_map.pl']['after'] = s['files']['knowledge-map/scripts/knowledge_map.pl']['after'].replace('FB_CROAK | LEAVE_SRC', 'FB_CROAK', 1)
        elif name == 'false-native-refusal':
            n['status'] = 1
        elif name == 'borrowed-red-success':
            r['status'] = 0
        elif name == 'lost-decision-body':
            key = 'docs/decisions/current/language-api/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md'
            s['files'][key]['after'] = s['files'][key]['after'].replace('## Context', '## Missing context', 1)
        else:
            g['stdout'] = g['stdout'].replace('whole projection-byte change invalidates fingerprint', 'unrelated property')
        try:
            verify(s, r, g, n, current=False)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('control accepted: ' + name)
    proof = BASE / 'controls.json'
    if proof.exists():
        assert json.loads(proof.read_text()) == controls, 'whole separating control proof'
    else:
        proof.write_text(json.dumps(controls, sort_keys=True, indent=2) + '\n')
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, record in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes()
            assert {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()} == record, 'sealed exact repair evidence: ' + path
    print('PASS whole original/repaired raw-byte source and real RED/GREEN/public-cache/encoding evidence; genuine source and receipt controls refuse; collection qualification remains open.')


if __name__ == '__main__':
    main()
