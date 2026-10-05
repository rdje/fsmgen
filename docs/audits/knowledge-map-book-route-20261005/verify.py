"""Verify the public reference repair and complete native canonical include."""
import copy
import hashlib
import json
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/knowledge-map-book-route-20261005')
MARKER = 'knowledge-map-architecture'


class Main(HTMLParser):
    def __init__(self, tail=False):
        super().__init__(); self.inside = False; self.collect = not tail; self.marker = False; self.markers = 0; self.events = []

    def handle_starttag(self, tag, attrs):
        if tag == 'main':
            self.inside = True; return
        if self.inside and tag == 'div' and dict(attrs).get('id') == MARKER:
            self.marker = True; self.markers += 1; return
        if self.inside and self.collect:
            self.events.append(('start', tag, sorted(attrs)))

    def handle_endtag(self, tag):
        if tag == 'main':
            self.inside = False; return
        if self.inside and tag == 'div' and self.marker:
            self.marker = False; self.collect = True; return
        if self.inside and self.collect:
            self.events.append(('end', tag))

    def handle_data(self, value):
        if self.inside and self.collect and value.strip():
            self.events.append(('text', value))


def main_events(body, tail=False):
    parser = Main(tail); parser.feed(body)
    if tail:
        assert parser.markers == 1, 'actual unique served anchor'
    return parser.events


def check(source, before, after, canonical):
    old, new = source['link_replacement']
    assert source['before']['docs/book/src/90-reference-map.md'].count(old) == 1
    assert source['after']['docs/book/src/90-reference-map.md'] == source['before']['docs/book/src/90-reference-map.md'].replace(old, new) + source['include_block'], 'only real link and complete native include added'
    assert source['include_block'] == '\n<div id="knowledge-map-architecture"></div>\n\n{{#include ../../../knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md}}\n', 'one canonical include at a stable book anchor'
    assert source['after']['docs/book/src/SUMMARY.md'] == source['before']['docs/book/src/SUMMARY.md'], 'complete navigation and read budget preserved'
    assert source['after']['docs/book/book.toml'] == source['before']['docs/book/book.toml'], 'book configuration unchanged'
    old_timing, new_timing = source['timing_replacement']
    assert source['after']['knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'] == source['before']['knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'].replace(old_timing, new_timing), 'only unsupported timing precision removed'
    assert old_timing == 'emitting the map. Milliseconds. The' and new_timing == 'emitting the map. The', 'no new timing claim or policy rewrite'
    assert before['entry']['status'] == 200 and before['target']['status'] == 404, 'real original entry/target separating outcome'
    assert before['link'] == '../../../knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.html', 'actual original rendered target'
    assert after['entry']['status'] == after['target']['status'] == 200, 'actual repaired public entry and target'
    assert after['link'] == '#' + MARKER and after['target']['path'] == '/90-reference-map.html' and after['target']['fragment'] == MARKER, 'actual same-book stable target'
    assert before['missing_control']['status'] == after['missing_control']['status'] == 404, 'genuine missing route still refuses'
    assert before['server_status'] is not None and after['server_status'] is not None, 'own server outcomes consumed'
    assert canonical['source'] == source['after']['knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'] and canonical['configuration'] == source['after']['docs/book/book.toml'], 'independent actual canonical-render inputs'
    actual = main_events(after['target']['body'], tail=True)
    expected = main_events(canonical['rendered'])
    assert actual == expected, 'complete actual served include matches independent canonical compilation'
    assert sum(event[:2] == ('start', 'h1') for event in actual) == 1, 'canonical heading occurs once without a wrapper duplicate'


def main():
    source = json.loads((BASE / 'source.json').read_text())
    before = json.loads((BASE / 'before-serve.json').read_text()); after = json.loads((BASE / 'after-serve.json').read_text())
    canonical = json.loads((BASE / 'canonical-rendered.json').read_text())
    for path, body in source['before'].items():
        assert subprocess.check_output(['git', 'show', source['revision'] + ':' + path]) == body.encode(), 'whole exact source predecessor: ' + path
    check(source, before, after, canonical)
    for response, bodies in ((before, source['before']), (after, source['after'])):
        for path, body in bodies.items():
            raw = body.encode()
            assert response['source_identity'][path] == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'actual public capture source identity'
    controls = []
    for name in ('false-original-success', 'wrong-served-anchor', 'false-missing-route-success', 'truncated-served-canonical-content', 'wrong-canonical-include', 'lost-canonical-source-policy'):
        s, b, a, c = map(copy.deepcopy, (source, before, after, canonical))
        if name == 'false-original-success':
            b['target']['status'] = 200
        elif name == 'wrong-served-anchor':
            a['target']['fragment'] = 'missing-anchor'
        elif name == 'false-missing-route-success':
            a['missing_control']['status'] = 200
        elif name == 'truncated-served-canonical-content':
            a['target']['body'] = a['target']['body'].replace('Generation cost', 'Missing generation policy', 1)
        elif name == 'wrong-canonical-include':
            s['include_block'] = s['include_block'].replace('KNOWLEDGE_MAP_ARCHITECTURE.md', 'MISSING.md')
        else:
            s['after']['knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'] = s['after']['knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'].replace('## 1. Why a derived index', '## Missing index policy', 1)
        try:
            check(s, b, a, c)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('actual route/content/source control accepted: ' + name)
    p = BASE / 'controls.json'
    if p.exists():
        assert json.loads(p.read_text()) == controls, 'whole route/source/content proof'
    else:
        p.write_text(json.dumps(controls, sort_keys=True, indent=2) + '\n')
    if '--current' in sys.argv:
        for path, body in source['after'].items():
            assert Path(path).read_bytes() == body.encode(), 'whole current own source: ' + path
        assert not Path('docs/book/src/92-knowledge-map.md').exists(), 'superseded uncommitted prototype removed'
    authority = json.loads((BASE / 'book-authority.json').read_text())
    paths = authority['paths']
    original_paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', source['revision'], '--', 'docs/book/src'], text=True).splitlines()
    assert paths == sorted(p for p in original_paths if Path(p).parent == Path('docs/book/src') and p.endswith('.md')), 'complete original book membership'
    def metrics(raws):
        return {'files': len(raws), 'lines_total': sum(raw.count(b'\n') for raw in raws), 'bytes_total': sum(map(len, raws))}
    original = {path: subprocess.check_output(['git', 'show', source['revision'] + ':' + path]) for path in paths}
    assert authority['before'] == metrics(list(original.values())), 'whole original book aggregate'
    projected = [source['after'].get(path, raw.decode()).encode() for path, raw in original.items()]
    assert authority['after'] == metrics(projected), 'whole exact include-source book aggregate'
    assert authority['delta'] == {key: authority['after'][key] - authority['before'][key] for key in authority['before']}, 'fresh exact aggregate delta'
    assert authority['surface_before'] == subprocess.check_output(['git', 'show', source['revision'] + ':doctrine/live_document_size/surfaces.jsonl'], text=True), 'complete original authority declarations'
    expected = list(map(json.loads, authority['surface_before'].splitlines()))
    change = next(row for row in expected if row.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    change.update(authority_id='KNOWLEDGE-MAP-BOOK-ROUTE-REPAIR-20261005-SHIPPED-BEHAVIOR', baseline=authority['before'], delta=authority['delta'], owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.73.1', rationale='Repair the actual served architecture reference by including complete canonical content at a stable Reference Map anchor, preserving SUMMARY and its mandatory-read budget.')
    assert expected == list(map(json.loads, authority['surface_after'].splitlines())), 'only ordinary book aggregate authority changes'
    refused = json.loads((BASE / 'initial-chapter-navigation-refusal.json').read_text())
    assert refused['lines'] > refused['mandatory_read']['lines_ceiling'], 'actual prior index-budget breach retained'
    if '--current' in sys.argv:
        assert sorted(str(path) for path in Path('docs/book/src').glob('*.md')) == paths, 'complete current book membership'
        assert metrics([Path(path).read_bytes() for path in paths]) == authority['after'], 'whole current book aggregate'
        assert Path('doctrine/live_document_size/surfaces.jsonl').read_text() == authority['surface_after'], 'complete current publication authority'
        rendered = Path('docs/book/book/90-reference-map.html').read_text()
        assert main_events(rendered, tail=True) == main_events(canonical['rendered']), 'default built book retains complete canonical content'
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, record in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes()
            assert record == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'sealed exact route evidence: ' + path
    print('PASS actual introduced404 to stable served200 anchor, complete native canonical content and unchanged navigation; genuine route/status/content/source controls refuse, own servers stopped.')


if __name__ == '__main__':
    main()
