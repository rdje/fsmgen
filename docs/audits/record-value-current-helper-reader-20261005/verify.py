"""Authenticate frozen publication, then qualify only relevant current helper inputs."""
import argparse
import copy
import hashlib
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-current-helper-reader-20261005')
PUBLICATION = Path('docs/audits/record-value-helper-topic-publication-20261005')
CORE = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
TOPIC = 'docs/knowledge/record-value-original-observer-helper-paths.md'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec); spec.loader.exec_module(result)
    return result


scope = module('helper_source_metadata', Path('docs/audits/knowledge-card-rollover-20261005/verify.py'))


def relevant_rows(text):
    rows = []
    ids = {'record-value-finite-copy-probe-reader', 'record-value-original-observer-helper-paths'}
    for row in text.splitlines():
        fields = row.split('\t'); assert len(fields) == 3, 'actual public query row grammar'
        if ids.intersection(fields[1].split(',')): rows.append(row)
    return '\n'.join(sorted(rows))+'\n'


def expected_rows(transform):
    return scope.allocation({p: transform['after'][p].encode() for p in (CORE, TOPIC)})['rows']


def check_live(transform, cards, queries, chapter):
    assert cards == {p: transform['after'][p] for p in (CORE, TOPIC)}, 'whole current helper/core source, roles, questions and reader routes'
    expected = expected_rows(transform)
    for receipt in queries.values():
        assert same(receipt['status'], 0), 'actual successful query retains producer integer kind'
        assert relevant_rows(receipt['stdout']) == expected, 'complete current target question/ID/path allocation'
    assert chapter.count(transform['reader_marker']) == 1 and chapter[chapter.index(transform['reader_marker']):].startswith(transform['reader_section']), 'complete unique advertised helper reader command/context/source meaning'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--current', action='store_true', help='qualify relevant live source/reader routes (default)')
    group.add_argument('--snapshot', action='store_true', help='authenticate immutable source/transform/control evidence only')
    args = parser.parse_args()
    source = json.loads((BASE / 'source.json').read_text()); transform = json.loads((BASE / 'transform.json').read_text())
    for p, body in source['before'].items():
        assert subprocess.check_output(['git', 'show', source['revision']+':'+p]).decode() == body, 'complete actual committed source boundary'
    for p, pin in source['publication_pins'].items():
        raw = Path(p).read_bytes()
        assert same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}), 'whole original publication programme/proof/source/receipt identity'
    before, after = transform['before'], transform['after']
    assert same(before, source['before']) and after[CORE] == before[CORE]
    assert after[TOPIC] == before[TOPIC].replace(transform['old_reader'], transform['new_reader']), 'only declared live topic reverify adaptation'
    assert scope.metadata(after[TOPIC].encode()) == scope.metadata(before[TOPIC].encode()), 'stable complete ordered helper ID/questions'
    assert after[CHAPTER] == before[CHAPTER].replace(transform['old_command'], transform['new_command']).replace(transform['anchor'], transform['anchor']+transform['block']), 'only meaningful scoped current reader guidance'
    marker = 'The finite-copy core keeps its original fact ID and direct path.'
    assert transform['reader_marker'] == marker and transform['reader_section'] == after[CHAPTER][after[CHAPTER].index(marker):after[CHAPTER].index(transform['block'])+len(transform['block'])], 'whole independently delimited advertised reader section'
    old_registry = list(map(json.loads, before['doctrine/live_document_size/surfaces.jsonl'].splitlines()))
    new_registry = list(map(json.loads, after['doctrine/live_document_size/surfaces.jsonl'].splitlines()))
    old_change = next(r for r in old_registry if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    new_change = next(r for r in new_registry if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    old_change.update(new_change); assert same(old_registry, new_registry), 'only book authority changes; collection allowance unchanged'
    blobs = scope.git_blobs(source['revision'], transform['book_paths'])
    def aggregate(values): return {k:v for k,v in scope.metrics(values).items() if k in ('files','lines_total','bytes_total')}
    assert same(aggregate(blobs), transform['book_before']); blobs[CHAPTER] = after[CHAPTER].encode()
    assert same(aggregate(blobs), transform['book_after'])
    assert same(transform['book_delta'], {k:transform['book_after'][k]-transform['book_before'][k] for k in transform['book_before']})
    assert same(new_change['baseline'], transform['book_before']) and same(new_change['delta'], transform['book_delta']) and new_change['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.73.2.3.1'
    command = [sys.executable, '-B', str(PUBLICATION / 'verify.py')]
    history = subprocess.run(command, capture_output=True, text=True)
    assert history.returncode == 0, 'original frozen publication replay still passes: '+history.stderr[-1000:]
    baseline = {'direct': {'status': 0, 'stdout': expected_rows(transform)}, 'cached': {'status': 0, 'stdout': expected_rows(transform)}}
    cards = {p: after[p] for p in (CORE, TOPIC)}
    check_live(transform, cards, baseline, after[CHAPTER])
    controls = []
    for name in ('lost-source-role', 'lost-question', 'wrong-core-route', 'wrong-query-owner', 'Boolean-query-status', 'float-query-status', 'lost-reader-guidance', 'relocated-reader-command'):
        a, b, c = copy.deepcopy(cards), copy.deepcopy(baseline), after[CHAPTER]
        if name == 'lost-source-role': a[TOPIC] = a[TOPIC].replace('identity is unmeasured', 'identity is established')
        elif name == 'lost-question': a[TOPIC] = a[TOPIC].replace('  - "are all original helper input and callback paths joined?"\n', '')
        elif name == 'wrong-core-route': a[CORE] = a[CORE].replace('record-value-original-observer-helper-paths.md', 'missing.md')
        elif name == 'wrong-query-owner':
            b['direct']['stdout'] = b['direct']['stdout'].replace('record-value-original-observer-helper-paths\t', 'record-value-finite-copy-probe-reader\t', 1)
        elif name == 'Boolean-query-status': b['direct']['status'] = False
        elif name == 'float-query-status': b['cached']['status'] = 0.0
        elif name == 'lost-reader-guidance': c = c.replace(transform['block'], '')
        else: c = c.replace(transform['new_command'], 'python3 -B missing-reader.py', 1)+'\n'+transform['new_command']+'\n'
        try: check_live(transform, a, b, c)
        except AssertionError as error: controls.append({'control': name, 'refusal': str(error)})
        else: raise AssertionError('false-green relevant current helper input: '+name)
    if not args.snapshot:
        actual = {}
        for kind, options in (('direct', ['--all','--no-cache']), ('cached', ['--all'])):
            r = subprocess.run(['knowledge-map/scripts/query_knowledge_map.sh', *options], capture_output=True, text=True)
            actual[kind] = {'status': r.returncode, 'stdout': r.stdout, 'stderr': r.stderr}
        check_live(transform, {p:Path(p).read_text() for p in (CORE,TOPIC)}, actual, Path(CHAPTER).read_text())
    proof = {'revision': source['revision'], 'controls': controls, 'target_rows': expected_rows(transform),
             'scope': 'Whole relevant current core/helper source, role/question/route and unique book reader block. Complete original publication remains authenticated at its snapshot. Unrelated book/registry/card state is not a helper semantic prerequisite.'}
    target = BASE / 'proofs.json'
    if target.exists(): assert same(json.loads(target.read_text()), proof)
    else: target.write_text(json.dumps(proof, sort_keys=True, indent=2)+'\n')
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for p,pin in json.loads(manifest.read_text()).items():
            raw = Path(p).read_bytes(); assert same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
        delivery = module('scoped_helper_native_delivery', BASE / 'qualify_delivery.py')
        delivery.main()
        unrelated = json.loads((BASE / 'unrelated-publication-probe.json').read_text())
        assert same(unrelated['status'], 0) and unrelated['additions'], 'actual unrelated current qualifier success with meaningful source changes'
        assert all(unrelated['candidates'][p] == unrelated['before'][p]+v for p,v in unrelated['additions'].items())
        assert unrelated['candidates']['doctrine/live_document_size/surfaces.jsonl'] != unrelated['before']['doctrine/live_document_size/surfaces.jsonl']
    print('PASS immutable original publication and scoped live helper source/role/question/route qualification; genuine relevant-input controls reject.')


if __name__ == '__main__':
    main()
