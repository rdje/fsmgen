"""Classify actual served links against independent complete source provenance."""
import hashlib
import html
import json
import posixpath
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit

BASE = Path('docs/audits/book-reference-classification-20261005')


def source_rows(source):
    rows = []
    for path, body in source['sources'].items():
        if not path.endswith('.md') or path.endswith('SUMMARY.md'):
            continue
        for match in re.finditer(r'\[[^\]]+\]\(([^)\s]+)\)', body):
            href = match[1]; parsed = urlsplit(href)
            canonical = None
            if not parsed.scheme and parsed.path:
                canonical = posixpath.normpath(posixpath.join(posixpath.dirname(path), unquote(parsed.path)))
            rows.append({'source': path, 'line': body[:match.start()].count('\n')+1,
                         'href': href, 'rendered_href': re.sub(r'\.md(?=$|[?#])', '.html', href), 'canonical': canonical})
    return rows


def role(path):
    if path.startswith('docs/audits/'):
        return 'retained-engineering-evidence'
    if path.startswith('docs/tasks/') or path in ('MEMORY.md', 'docs/TASK_TREE.md', 'ROADMAP_V2.md'):
        return 'operational-state-or-direction'
    if path.startswith('docs/decisions/'):
        return 'decision-reference'
    if not path.startswith('docs/') or 'LIVE_DOCUMENT_SIZE' in path:
        return 'maintainer-policy-or-review'
    return 'focused-product-or-maintainer-reference'


def classify(source, exported, native, supplemental):
    assert exported['server_stopped'] is True and type(native['server_status']) is int, 'actual own server outcomes consumed'
    assert exported['missing_control']['status'] == native['missing_control']['status'] == 404
    provenance = source_rows(source); population = []; native_controls = []
    for chapter, entry in exported['chapters'].items():
        path = '/' + chapter + '.html'
        assert entry['entry']['status'] == native['responses'][path]['status'] == 200, 'actual native chapter delivery'
        def raw_hrefs(body):
            main = body.split('<main>', 1)[1].split('</main>', 1)[0]
            return [html.unescape(m[1]) for m in re.finditer(r'<a\b[^>]*\bhref="([^"]*)"', main)]
        expected_hrefs = [row['href'] for row in entry['links']]
        assert raw_hrefs(entry['entry']['body']) == expected_hrefs == raw_hrefs(native['responses'][path]['body']), 'complete independent raw HTML/native/export body-anchor closure'
        for link in entry['links']:
            parsed = urlsplit(link['href'])
            if parsed.scheme or parsed.netloc:
                assert link['kind'] == 'remote-or-non-http'; continue
            matches = [row for row in provenance if row['rendered_href'] == link['href'] and (row['source'] == 'docs/book/src/' + chapter + '.md' or (chapter == '90-reference-map' and row['source'] == 'knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'))]
            outside = [row for row in matches if row['canonical'] and not row['canonical'].startswith('docs/book/src/')]
            response = native['responses'][link['resolved_path']]
            assert response['status'] == exported['responses'][link['resolved_path']]['status'], 'complete actual export/native target-status agreement'
            if outside:
                assert matches == outside and len(outside) == 1, 'unique complete canonical source association'
                row = outside[0]; canonical = source['canonical'].get(row['canonical']) or supplemental.get(row['canonical'])
                assert canonical and canonical['text'], 'complete canonical source exists at captured revision'
                raw = subprocess.check_output(['git', 'show', source['revision'] + ':' + row['canonical']])
                assert canonical['text'].encode() == raw and canonical['bytes'] == len(raw) and canonical['sha256'] == hashlib.sha256(raw).hexdigest(), 'exact original canonical source identity'
                assert response['status'] == 404, 'actual advertised canonical reference is absent from served book'
                population.append({'chapter': chapter, 'source': row, 'rendered_href': link['href'], 'resolved_path': link['resolved_path'], 'fragment': link['fragment'], 'role': role(row['canonical']), 'failure': 'advertised canonical reference returns404 from native book', 'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.73.2.3'})
            else:
                assert response['status'] == 200, 'native chapter control remains delivered'
                if link['fragment']:
                    assert 'id="' + html.escape(unquote(link['fragment']), quote=True) + '"' in response['body'], 'exact native anchor target exists'
                native_controls.append({'chapter': chapter, 'href': link['href'], 'path': link['resolved_path'], 'fragment': link['fragment']})
    assert any(row['href'] == '#knowledge-map-architecture' for row in native_controls), 'previously repaired architecture remains native served control'
    return {'revision': source['revision'], 'classified_links': population, 'confirmed_failed_clicks': len(population),
            'distinct_failed_urls': len({row['resolved_path'] for row in population}), 'distinct_canonical_sources': len({row['source']['canonical'] for row in population}),
            'native_controls': native_controls, 'scope': 'Only the complete actual body-anchor populations of encountered chapters90/13k; no whole-book or remote-destination defect claim.'}


def main():
    source = json.loads((BASE / 'source.json').read_text())
    exported = json.loads((BASE / 'served.json').read_text()); native = json.loads((BASE / 'native-served.json').read_text())
    supplement = {}
    for row in source_rows(source):
        path = row['canonical']
        if path and not path.startswith('docs/book/src/') and path not in source['canonical']:
            raw = subprocess.check_output(['git', 'show', source['revision'] + ':' + path])
            supplement[path] = {'text': raw.decode(), 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    target = BASE / 'provenance-supplement.json'
    if target.exists():
        assert json.loads(target.read_text()) == supplement
    else:
        target.write_text(json.dumps(supplement, sort_keys=True, indent=2) + '\n')
    proof = classify(source, exported, native, supplement)
    target = BASE / 'classification.json'
    if target.exists():
        assert json.loads(target.read_text()) == proof
    else:
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k: v for k, v in proof.items() if k in ('confirmed_failed_clicks', 'distinct_failed_urls', 'distinct_canonical_sources', 'scope')}, sort_keys=True))


if __name__ == '__main__':
    main()
