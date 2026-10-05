"""Qualify exact ordinary book authority and an encoding-identifier disposition."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/knowledge-map-raw-bytes-publication-20261005')


def census(raws):
    return {'files': len(raws), 'lines_total': sum(len(raw.splitlines()) for raw in raws), 'bytes_total': sum(map(len, raws))}


def check(declaration, surfaces, disposition):
    before = list(map(json.loads, declaration['surface_before'].splitlines()))
    expected = copy.deepcopy(before)
    row = next(row for row in expected if row.get('surface_id') == 'shipped_behavior')
    change = row['reference_contract']['aggregate_change']
    change.update(authority_id='KNOWLEDGE-MAP-RAW-BYTES-REPAIR-20261005-SHIPPED-BEHAVIOR', baseline=declaration['before'], delta=declaration['delta'], owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.72.1.1', rationale='Document actual encoded-byte enforcement, invalid-encoding refusal and full-byte query cache identity, keeping per-card bounds distinct from the unchanged collection allowance.')
    assert expected == surfaces, 'only fresh exact book aggregate authority changes'
    assert declaration['delta'] == {key: declaration['after'][key] - declaration['before'][key] for key in declaration['before']}, 'exact complete aggregate delta'
    assert disposition['disposition'] == 'reviewed_incidental' and disposition['reason_code'] == 'identifier_or_navigation', 'encoding identifier retains its real semantics'
    assert 'not an assertion' in disposition['reason'] and 't/1567-knowledge-map-shards.t' in disposition['reason'], 'scoped encoding meaning and checked contract'


def main():
    d = json.loads((BASE / 'book-authority.json').read_text())
    paths = sorted(str(p) for p in Path('docs/book/src').glob('*.md'))
    git_paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', d['revision'], '--', 'docs/book/src'], text=True).splitlines()
    assert paths == d['paths'] == sorted(p for p in git_paths if Path(p).parent == Path('docs/book/src') and p.endswith('.md')), 'independent complete book membership'
    assert d['before'] == census([subprocess.check_output(['git', 'show', d['revision'] + ':' + p]) for p in paths]), 'whole exact Git aggregate'
    assert d['after'] == census([Path(p).read_bytes() for p in paths]), 'whole actual book aggregate'
    surface = Path('doctrine/live_document_size/surfaces.jsonl').read_text()
    assert d['surface_before'] == subprocess.check_output(['git', 'show', d['revision'] + ':doctrine/live_document_size/surfaces.jsonl'], text=True), 'complete exact predecessor declarations'
    assert surface == d['surface_after'], 'complete publication declaration'
    rows = list(map(json.loads, surface.splitlines()))
    disposition = json.loads((BASE / 'disposition.json').read_text())
    assert disposition in list(map(json.loads, Path('doctrine/claim_verification/dispositions.jsonl').read_text().splitlines())), 'published exact reviewed disposition'
    check(d, rows, disposition)
    controls = []
    for name in ('wrong-delta', 'unrelated-card-allowance-growth', 'encoding-treated-as-fixed-byte-width'):
        bad, changed, claim = map(copy.deepcopy, (d, rows, disposition))
        if name == 'wrong-delta':
            bad['delta']['bytes_total'] += 1
        elif name == 'unrelated-card-allowance-growth':
            next(row for row in changed if row.get('surface_id') == 'knowledge_cards')['transition']['max_growth']['bytes_total'] += 1
        else:
            claim['reason_code'] = 'policy_input'
        try:
            check(bad, changed, claim)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('actual publication control accepted: ' + name)
    p = BASE / 'controls.json'
    if p.exists():
        assert json.loads(p.read_text()) == controls, 'whole publication controls'
    else:
        p.write_text(json.dumps(controls, sort_keys=True, indent=2) + '\n')
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, record in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes()
            assert record == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'sealed publication source: ' + path
    print('PASS complete exact book authority, unchanged card limits/allowance and real encoding-identifier disposition; separating controls reject.')


if __name__ == '__main__':
    main()
