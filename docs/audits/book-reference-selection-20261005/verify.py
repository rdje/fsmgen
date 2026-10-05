"""Qualify bounded delivery selection without claiming production publication."""
import copy
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/book-reference-selection-20261005')
CLASSIFIED = Path('docs/audits/book-reference-classification-20261005')


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def check(record, refreshed, advertised=False):
    assert type(record['server_status']) is int and record['server_status'] is not None, 'actual own native server outcome consumed'
    assert same(record['build']['status'], 0) and same(record['version']['status'], 0)
    assert record['version']['stdout'].strip() == 'mdbook v0.5.4', 'explicit observed tool profile'
    assert same(record['entry']['status'], 200) and same(record['missing_control']['status'], 404)
    assert set(record['sources']) == set(record['built_assets']) == set(record['served_assets']), 'complete representative source/member allocation'
    for source, row in record['sources'].items():
        raw = row['text'].encode()
        assert same({'bytes': row['bytes'], 'sha256': row['sha256']}, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}), 'complete canonical source identity'
        assert not Path(row['link']).is_absolute(), 'portable relative filesystem recipe'
        encoded = source[:-3] + '.markdown' if advertised and source.endswith('.md') else source
        assert row['asset'] == 'references/' + encoded + '.source.txt'
        if advertised:
            assert record['advertised_targets'][source] == row['asset'] and row['asset'] in record['entry']['body'], 'actual native advertised asset'
        built = record['built_assets'][source]; served = record['served_assets'][source]
        assert built['exists'] is True and built['text'] == row['text'], 'whole native built asset preserves canonical source'
        assert same(served['status'], 200) and served['body'] == row['text'] and served['content_type'].startswith('text/plain'), 'whole native served source bytes and role'
    assert same(record['refresh_before']['status'], 200) and record['refresh_before']['body'] == 'first canonical state\n'
    assert same(record['refresh_after']['status'], 200)
    assert record['refresh_after']['body'] == ('second canonical state\n' if refreshed else 'first canonical state\n'), 'observed admitted/excluded source refresh separates'
    if 'source_before_change' in record:
        assert type(record['source_before_change']['mtime_ns']) is int and type(record['source_after_change']['mtime_ns']) is int
        assert record['source_after_change']['mtime_ns'] > record['source_before_change']['mtime_ns'], 'actual source mutation after watcher admission'
        assert 'Watching for changes' in record['ready_before_change']


def main():
    names = {'default': False, 'extra-watch': False, 'qualified-extra-watch': False,
             'visible-extra-watch': True, 'visible-default': True, 'excluded-visible-extra-watch': False}
    records = {name: json.loads((BASE / (name + '-prototype.json')).read_text()) for name in names}
    for name, refreshed in names.items(): check(records[name], refreshed)
    admitted = json.loads((BASE / 'links-default-prototype.json').read_text())
    check(admitted, True, True)
    assert same(admitted['old_markdown_recipe_control']['status'], 404), 'genuine old rewritten Markdown asset URL refuses'
    assert records['excluded-visible-extra-watch']['parent_ignore'] == '*\n' and same(records['excluded-visible-extra-watch']['git_ignore']['status'], 0), 'actual separating parent-ignore control'
    assert records['visible-default']['mode'] == 'default' and 'extra-watch-dirs' not in records['visible-default']['config'], 'minimal admitted default watcher passes'
    classified = json.loads((CLASSIFIED / 'classification.json').read_text())
    selected = json.loads((BASE / 'selected-routes.json').read_text())
    expected = [{'source': r['source']['canonical'], 'asset': 'reference-source/' + (r['source']['canonical'][:-3] + '.markdown' if r['source']['canonical'].endswith('.md') else r['source']['canonical']) + '.source.txt', 'role': r['role'], 'chapter': r['chapter'], 'old_href': r['rendered_href']} for r in classified['classified_links']]
    assert same(selected['routes'], expected) and len({r['source'] for r in expected}) == len({r['asset'] for r in expected}) == len(expected), 'complete injective canonical/path/role/click route selection'
    scope = json.loads((BASE / 'reader-scope-probe.json').read_text())
    assert same(scope['snapshot']['status'], 0) and same(scope['current_outcome']['status'], 1)
    assert "authority['surface_after']" in scope['current_outcome']['traceback'], 'actual unrelated whole-registry boundary; no sealed source correction'
    controls = []
    positive = admitted
    for name in ('wrong-member-bytes', 'false-admitted-refresh', 'false-success-status-kind', 'absolute-link-recipe'):
        altered = copy.deepcopy(positive)
        if name == 'wrong-member-bytes':
            altered['served_assets']['docs/COMPOSITION_SCOPE.md'] = altered['served_assets']['MEMORY.md']
        elif name == 'false-admitted-refresh':
            altered['refresh_after'] = records['excluded-visible-extra-watch']['refresh_after']
        elif name == 'false-success-status-kind':
            altered['build']['status'] = False
        else:
            altered['sources']['MEMORY.md']['link'] = '/forbidden/machine-local/MEMORY.md'
        try: check(altered, True, True)
        except AssertionError as error: controls.append({'control': name, 'refusal': str(error)})
        else: raise AssertionError('false-green native source selection: ' + name)
    proof = {'controls': controls, 'selected_sources': len(expected),
             'profile': 'Installed mdBook0.5.4, complete representative build/serve bytes and admitted/excluded source-change observations.',
             'missing_leg': 'Complete current production source-plane generation, bounds/freshness, all served target bytes and browser/visual qualification remain unexecuted; owned by .73.2.3.2/.3 and existing visual task.'}
    target = BASE / 'proofs.json'
    if target.exists(): assert same(json.loads(target.read_text()), proof)
    else: target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, pin in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes(); assert same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    if '--current' in sys.argv:
        for path in ('docs/book/src/90-reference-map.md', 'docs/book/src/13k-isf-feature-support-matrix.md', 'docs/book/src/SUMMARY.md', 'docs/book/book.toml'):
            assert Path(path).read_bytes() == subprocess.check_output(['git', 'show', '3072ea39adfbbfd437b4897c9618df3f7dbf2d9b:' + path]), 'production source/config/navigation remain unpublished'
        assert not list(BASE.glob('prototype-*')), 'own visible/excluded fixture roots disposed after capture'
    print('PASS bounded native source-view selection, exact byte/member/role conservation and separating admitted/ignored refresh; complete production and visual legs remain explicitly owned.')


if __name__ == '__main__':
    main()
