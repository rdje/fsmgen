"""Qualify exact semantic partition, query delta and unchanged collection authority."""
import copy
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-topic-publication-20261005')
HELPER = Path('docs/audits/record-value-original-helper-join-20261005')


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    return module


scope = load_module('rollover_source_algorithms', Path('docs/audits/knowledge-card-rollover-20261005/verify.py'))
kinds = load_module('recorded_metadata_kinds', Path('docs/audits/knowledge-card-rollover-kinds-20261005/verify.py'))


def check(transform, core, destination):
    assert core == transform['core_after'] and destination == transform['destination_after'], 'whole exact semantic partition'
    current = transform['before']
    for question in transform['moved_questions']:
        assert current.count(question + '\n') == 1
        current = current.replace(question + '\n', '')
    assert current.count(transform['moved_body']) == 1
    assert core == current.replace(transform['moved_body'], transform['route']), 'only declared question/body movement'
    start = transform['before'].index('Own\nobserver/callback source roles')
    end = transform['before'].index('Full observer/display/frame/coordinate/address', start)
    assert transform['moved_body'] == transform['before'][start:end], 'complete independently delimited current helper body'
    old = json.loads(transform['archived_template'])
    expected = old['destination_after'].replace(old['moved_body'].replace('Own\nobserver', 'Own observer'), transform['before'][start:end].rstrip('\n').replace('Own\nobserver', 'Own observer') + '\n')
    expected += '\nThe finite-copy core retains the original broader open boundary:\n\n' + transform['original_open_boundary'] + '\n\nRelated: [[record-value-finite-copy-probe-reader]].\n'
    expected = expected.replace(transform['destination_reader_before'], transform['destination_reader_after'])
    assert destination == expected, 'whole archived topic template with only declared current-body/open-boundary/reader adaptation'
    assert transform['normalized_moved_body'] in destination, 'entire original helper meaning with declared LF normalization'
    assert transform['original_open_boundary'] in core and transform['original_open_boundary'] in destination, 'whole original broader open boundary retained'
    assert 'Related: [[record-value-finite-copy-probe-reader]].' in destination and transform['destination_path'].split('/')[-1] in core, 'two-way canonical source routes'
    assert 'identity is unmeasured' in destination and 'identity and full formatting remain open' in destination and 'raw coordinates' in destination, 'missing identity/format/coordinate legs remain explicit'
    for body in (core, destination):
        raw = body.encode(); lines = raw.split(b'\n')
        assert len(raw) <= 32768 and len(lines)-int(raw.endswith(b'\n')) <= 512 and max(map(len, lines)) <= 819, 'actual public default card bounds'
    old_id, old_questions = scope.metadata(transform['before'].encode())
    core_id, core_questions = scope.metadata(core.encode())
    new_id, new_questions = scope.metadata(destination.encode())
    assert core_id == old_id == 'record-value-finite-copy-probe-reader' and new_id == 'record-value-original-observer-helper-paths'
    moved = [json.loads(row[4:]) for row in transform['moved_questions']]
    added = ['are all original helper input and callback paths joined?']
    assert core_questions == [q for q in old_questions if q not in moved]
    assert new_questions == moved + added, 'complete explicit redistributed/new question population'
    return moved, added


def main():
    transform = json.loads((BASE / 'transform.json').read_text())
    assert subprocess.check_output(['git', 'show', transform['revision'] + ':' + transform['core_path']]).decode() == transform['before'], 'whole actual committed current source'
    assert (HELPER / 'knowledge-transform.json').read_text() == transform['archived_template'], 'complete historically refused template retained'
    import hashlib
    for path, pin in transform['whole_helper_source_pins'].items():
        raw = Path(path).read_bytes()
        assert kinds.same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}) and subprocess.check_output(['git', 'show', transform['revision'] + ':' + path]) == raw, 'whole committed helper source/model/proof/programme'
    receipt = json.loads((BASE / 'helper-receipt.json').read_text())
    expected_identity = {str(HELPER / name): transform['whole_helper_source_pins'][str(HELPER / name)] for name in ('verify.py', 'proofs.json', 'manifest.json')}
    assert kinds.same(receipt['before'], expected_identity) and kinds.same(receipt['after'], expected_identity) and kinds.same(receipt['status'], 0), 'exact freshly executed helper programme/proof/seal receipt'
    assert receipt['command'][1:] == ['-B', str(HELPER / 'verify.py')] and 'PASS complete finite source helper allocation/input/default/return/throw-phase and callback/refusal path join' in receipt['stdout'], 'whole invoked helper scope and actual successful outcome'
    core, destination = transform['core_after'], transform['destination_after']
    moved, added = check(transform, core, destination)
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', transform['revision'], '--', 'docs/knowledge', 'docs/decisions'], text=True).splitlines()
    paths = sorted(p for p in paths if p.endswith('.md'))
    before = scope.git_blobs(transform['revision'], paths); after = dict(before)
    after[transform['core_path']] = core.encode(); after[transform['destination_path']] = destination.encode()
    old_all = scope.allocation(before); new_all = scope.allocation(after)
    assert all(q + '\t' not in old_all['rows'] for q in added), 'new exact question genuinely absent at committed boundary'
    assert new_all['facts'] == old_all['facts'] + 1 and new_all['unique_questions'] == old_all['unique_questions'] + len(added) and new_all['answer_occurrences'] == old_all['answer_occurrences'] + len(added), 'declared full allocation delta'
    expected_rows = old_all['rows'].splitlines()
    for question in moved:
        old_row = question + '\t' + 'record-value-finite-copy-probe-reader' + '\t' + transform['core_path']
        assert expected_rows.count(old_row) == 1, 'whole original sole-owner allocation'
        expected_rows.remove(old_row)
        expected_rows.append(question + '\t' + 'record-value-original-observer-helper-paths' + '\t' + transform['destination_path'])
    expected_rows.extend(q + '\t' + 'record-value-original-observer-helper-paths' + '\t' + transform['destination_path'] for q in added)
    assert new_all['rows'] == '\n'.join(sorted(expected_rows)) + '\n', 'all non-target source/question allocations byte exact'
    before_public = json.loads((BASE / 'before-query.json').read_text()); after_public = json.loads((BASE / 'after-query.json').read_text())
    assert kinds.same([before_public['status'], after_public['direct']['status'], after_public['cached']['status']], [0, 0, 0])
    assert before_public['stdout'] == old_all['rows'] and after_public['direct']['stdout'] == after_public['cached']['stdout'] == new_all['rows'], 'complete actual public direct/cache allocation matches source'
    before_physical = scope.metrics({p: raw for p, raw in before.items() if Path(p).parent == Path('docs/knowledge')})
    after_physical = scope.metrics({p: raw for p, raw in after.items() if Path(p).parent == Path('docs/knowledge')})
    authority = json.loads((BASE / 'book-authority.json').read_text())
    registry = list(map(json.loads, authority['surface_before'].splitlines()))
    card_surface = next(r for r in registry if r.get('surface_id') == 'knowledge_cards')
    assert all(after_physical[k] <= card_surface['baseline'][k] + card_surface['transition']['max_growth'][k] and after_physical[k] <= card_surface['enforcement_ceilings'][k] for k in after_physical), 'unchanged card collection bounds admit owned semantic partition'
    controls = []
    for name in ('lost-question', 'lost-source-meaning', 'wrong-route', 'invented-parser-identity', 'lost-open-boundary', 'extra-allocation'):
        a, b = core, destination
        if name == 'lost-question': b = b.replace(transform['moved_questions'][0] + '\n', '', 1)
        elif name == 'lost-source-meaning': b = b.replace('complete source graphs', 'missing source graphs', 1)
        elif name == 'wrong-route': a = a.replace('record-value-original-observer-helper-paths.md', 'missing.md', 1)
        elif name == 'invented-parser-identity': b = b.replace('identity is unmeasured', 'identity is established', 1)
        elif name == 'lost-open-boundary': b = b.replace(transform['original_open_boundary'], '', 1)
        else: b = b.replace('date: 2026-10-05', '  - "an undeclared helper question?"\ndate: 2026-10-05', 1)
        try:
            check(transform, a, b)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('false-green source/role/query partition: ' + name)
    book_before = scope.git_blobs(transform['revision'], authority['paths']); book_after = dict(book_before)
    book_after['docs/book/src/13k-isf-feature-support-matrix.md'] = authority['chapter_after'].encode()
    def aggregate(blobs):
        return {k: v for k, v in scope.metrics(blobs).items() if k in ('files', 'lines_total', 'bytes_total')}
    assert kinds.same(authority['before'], aggregate(book_before)) and kinds.same(authority['after'], aggregate(book_after))
    assert kinds.same(authority['delta'], {k: authority['after'][k] - authority['before'][k] for k in authority['before']})
    assert book_before['docs/book/src/13k-isf-feature-support-matrix.md'].decode() == authority['chapter_before']
    assert authority['chapter_after'] == authority['chapter_before'].replace(authority['anchor'], authority['anchor'] + authority['block']), 'only meaningful helper topic reader guidance'
    assert subprocess.check_output(['git', 'show', transform['revision'] + ':doctrine/live_document_size/surfaces.jsonl']).decode() == authority['surface_before']
    next_registry = list(map(json.loads, authority['surface_after'].splitlines()))
    change = next(r for r in registry if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    new_change = next(r for r in next_registry if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    assert kinds.same(new_change['baseline'], authority['before']) and kinds.same(new_change['delta'], authority['delta']) and new_change['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.72.3.2'
    change.update(new_change); assert kinds.same(registry, next_registry), 'only book aggregate authority changes; no card allowance increase'
    if '--current' in sys.argv:
        assert Path(transform['core_path']).read_text() == core and Path(transform['destination_path']).read_text() == destination
        assert sorted([p for p in paths if Path(p).parent == Path('docs/knowledge')] + [transform['destination_path']]) == sorted(str(p) for p in Path('docs/knowledge').glob('*.md')), 'complete current physical member closure'
        assert Path('doctrine/live_document_size/surfaces.jsonl').read_text() == authority['surface_after']
        assert Path('docs/book/src/13k-isf-feature-support-matrix.md').read_text() == authority['chapter_after']
        actual = {str(p): p.read_bytes() for p in Path('docs/knowledge').glob('*.md')}
        assert kinds.same(scope.metrics(actual), after_physical), 'complete actual current collection dimensions'
        for command in (['knowledge-map/scripts/query_knowledge_map.sh', '--all', '--no-cache'], ['knowledge-map/scripts/query_knowledge_map.sh', '--all']):
            result = subprocess.run(command, capture_output=True, text=True)
            assert result.returncode == 0 and result.stdout == new_all['rows'], 'actual current direct/cache allocation closure'
    delivery = load_module('helper_publication_delivery', BASE / 'verify_delivery.py')
    delivery.main(old_all['rows'], new_all['rows'])
    proof = {'revision': transform['revision'], 'before': before_physical, 'after': after_physical,
             'old_allocation': {k: v for k, v in old_all.items() if k != 'rows'}, 'new_allocation': {k: v for k, v in new_all.items() if k != 'rows'},
             'moved_questions': moved, 'added_questions': added, 'controls': controls,
             'scope': 'Exact owned semantic topic partition and allocation delta; whole helper models already qualify source paths. Full framework/display/coordinate/address/native identity and collection rollover debt remain open.'}
    file = BASE / 'proofs.json'
    if file.exists(): assert kinds.same(json.loads(file.read_text()), proof)
    else: file.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, pin in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes(); assert kinds.same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    print('PASS complete finite-copy/helper source conservation, declared question allocation delta and actual query parity within unchanged card bounds; genuine source/route/identity/open-leg controls refuse.')


if __name__ == '__main__':
    main()
