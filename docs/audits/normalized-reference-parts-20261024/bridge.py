#!/usr/bin/env python3
"""Qualify canonical book parts through explicitly derived legacy guide views."""
import argparse
import copy
import gzip
import hashlib
from html.parser import HTMLParser
import importlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.10.2'
CORE = 'docs/book/src/11-extensions-and-embedding.md'
API = 'docs/book/src/11a-perl-api-reference.md'
SUMMARY = 'docs/book/src/SUMMARY.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
REPORT = 'perl/FSM/Support/NormalizedSemanticReport.pm'
AUDIT = ROOT / 'docs/audits/mcp-api-reference-20261023'
PLAN = BASE / 'partition-contract-final-qualified.json.gz'
sys.path.insert(0, str(AUDIT))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def snapshot(path):
    raw = (ROOT / path).read_bytes()
    return {'text': raw.decode(), 'sha256': sha(raw)}


def read(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def code(raw):
    return raw.split(b'\n__END__\n', 1)[0]


def contract_module():
    spec = importlib.util.spec_from_file_location('reference_split_contract', BASE / 'verify.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def original_views(plan):
    return {name: read(ROOT / row['packet']) for name, row in plan['reader_profiles'].items()}


def target(view, row):
    for key in row['document_container']:
        view = view[key]
    return view


def make_views(plan, originals, semantic, pod):
    views = copy.deepcopy(originals)
    documents = {CORE: {'text': semantic, 'sha256': sha(semantic.encode())}, POD: pod}
    for name, view in views.items():
        scoped = target(view, plan['reader_profiles'][name])
        scoped['documents'] = copy.deepcopy(documents)
        scoped['sources'][POD] = copy.deepcopy(pod)
        if name == 'composition':
            for cohort in scoped['cohorts'].values():
                cohort['documents'] = copy.deepcopy(documents)
                cohort['sources'][POD] = copy.deepcopy(pod)
    return views


def semantic_view(documents, plan):
    core, api = documents[CORE]['text'], documents[API]['text']
    origins = []
    for block in plan['blocks']:
        stub = ('### ' + block['title'] + '\n\nSee the [canonical field reference]('
                + Path(API).name + '#' + block['anchor'] + ').\n\n')
        require(core.count(stub) == 1, 'unique real compatibility route')
        require(api.count(block['text']) == 1, 'unique exact real canonical block')
        core = core.replace(stub, block['text'], 1)
        offset = api.index(block['text'])
        origins.append({'title': block['title'], 'anchor': block['anchor'],
                        'actual_source': API, 'sha256': block['sha256'],
                        'start_byte': len(api[:offset].encode()),
                        'end_byte': len(api[:offset + len(block['text'])].encode())})
    require(core == plan['inputs'][CORE]['text'], 'derived semantic view reconstructs complete original core')
    return core, origins


def stripped(view, row, name):
    result = copy.deepcopy(view)
    scoped = target(result, row)
    scoped.pop('documents')
    scoped['sources'].pop(POD)
    if name == 'composition':
        for cohort in scoped['cohorts'].values():
            cohort.pop('documents')
            cohort['sources'].pop(POD)
    return result


def source_population(plan, originals):
    variants = {}
    for name, original in originals.items():
        scoped = target(original, plan['reader_profiles'][name])
        for path, saved in {**scoped['sources'], **scoped.get('helpers', {})}.items():
            require(sha(saved['text'].encode()) == saved['sha256'], 'original source-bearing digest')
            variants.setdefault(path, set()).add(sha(code(saved['text'].encode())))
    return variants


def build():
    plan = read(PLAN)
    originals = original_views(plan)
    documents = {path: snapshot(path) for path in (CORE, API, SUMMARY, POD)}
    semantic, origins = semantic_view(documents, plan)
    prefix = BASE.relative_to(ROOT).as_posix() + '/'
    return {'schema': 'fsmgen.normalized_reference_migration.v1', 'owner': OWNER,
        'plan_sha256': sha(PLAN.read_bytes()), 'documents': documents,
        'semantic_view': {'kind': 'derived_semantic_comparison', 'logical_old_path': CORE,
                          'text': semantic, 'sha256': sha(semantic.encode()), 'origins': origins},
        'legacy_views': make_views(plan, originals, semantic, documents[POD]),
        'legacy_modes': {name: 'saved-only' for name in originals},
        'runtime_sources': {path: snapshot(path) for path in sorted(source_population(plan, originals))},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'instruments': {prefix + name: snapshot(prefix + name) for name in ('apply.py', 'bridge.py')},
        'evidence_legs': {
            'rederive': 'Capture actual canonical parts, exact moved source origins, explicit semantic comparison text and current source/instrument identities.',
            'falsify': 'Reconstruct complete original core, preserve all old packet fields except declared document/POD views, invoke six frozen independent oracles in saved mode, prove only the qualified Boolean code exception and reject source/origin/mode/doc losses.',
            'durability': 'Retain complete source-bearing migration packet, qualified plan identity, old packet recovery, saved/current modes and actual-native/proxy-separated content checks.'},
        'limits': 'Selected canonical migration/current-source/content proof only. No original source/compiler/backend epoch, full expression models, publication or whole-manual browser signoff.'}


def live_bytes(path):
    return (ROOT / path).read_bytes()


def verify(packet, current=False):
    require(packet['schema'] == 'fsmgen.normalized_reference_migration.v1' and packet['owner'] == OWNER, 'migration identity')
    require(packet['plan_sha256'] == sha(PLAN.read_bytes()), 'qualified plan identity')
    plan = read(PLAN)
    contract = contract_module()
    contract.verify(plan, consumer_rows=plan['baseline_consumers'])
    require(set(packet['documents']) == {CORE, API, SUMMARY, POD}, 'complete actual document population')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document snapshot digest')
        if path != POD:
            require(saved['text'] == plan['candidate_documents'][path], 'exact qualified canonical source result')
        if current:
            require(live_bytes(path) == saved['text'].encode(), 'current canonical document stale')
    semantic, origins = semantic_view(packet['documents'], plan)
    require(packet['semantic_view'] == {'kind': 'derived_semantic_comparison', 'logical_old_path': CORE,
        'text': semantic, 'sha256': sha(semantic.encode()), 'origins': origins}, 'explicit complete source-origin semantic view')
    originals = original_views(plan)
    require(set(packet['legacy_views']) == set(originals)
            and packet['legacy_modes'] == {name: 'saved-only' for name in originals}, 'complete saved-only oracle roles')
    pod = packet['documents'][POD]
    capture = read(AUDIT / 'model-roots-qualified.json.gz')
    for name, view in packet['legacy_views'].items():
        row = plan['reader_profiles'][name]
        require(stripped(view, row, name) == stripped(originals[name], row, name), 'all non-document fields/owners/delegations conserve')
        scoped = target(view, row)
        require(scoped['documents'] == {CORE: {'text': semantic, 'sha256': sha(semantic.encode())}, POD: pod}
                and scoped['sources'][POD] == pod, 'exact declared semantic/POD comparison slots')
        if name == 'composition':
            for cohort in scoped['cohorts'].values():
                require(cohort['documents'] == scoped['documents'] and cohort['sources'][POD] == pod, 'complete nested comparison slots')
        module = importlib.import_module(Path(row['reader']).stem)
        module.verify(view, capture)  # Deliberately saved mode; currency is proved outside the old oracle.
    before = read(AUDIT / 'normalized-boolean-repair-before.json.gz')
    after = read(AUDIT / 'normalized-boolean-repair-after.json.gz')
    importlib.import_module('verify_normalized_booleans').verify(before, after)
    variants = source_population(plan, originals)
    require(set(packet['runtime_sources']) == set(variants), 'complete current code-source population')
    for path, saved in packet['runtime_sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'current source snapshot digest')
        if path == REPORT:
            require(raw == after['sources'][REPORT]['text'].encode(), 'exact qualified current Boolean repair')
            require(variants[path] <= {sha(code(before['sources'][REPORT]['text'].encode())), sha(code(raw))}, 'no unqualified original report source')
        else:
            require(variants[path] == {sha(code(raw))}, 'unchanged dedicated current code')
        if current:
            require(live_bytes(path) == raw, 'current code-source stale')
    require(packet['runtime_sources'][POD] == pod, 'actual POD/source snapshot identity')
    expected = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in ('apply.py', 'bridge.py')}
    require(set(packet['instruments']) == expected, 'migration instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'migration instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current adapter runtime stale')
    return {'canonical_blocks': len(origins), 'legacy_oracles': sorted(originals),
            'source_files': len(variants), 'limits': packet['limits']}


def controls(packet):
    results = {}
    for label in ('lost_part', 'lost_canonical_block', 'lost_compatibility_route', 'lost_origin',
                  'borrowed_origin', 'lost_oracle', 'wrong_oracle_mode', 'lost_field', 'source_change',
                  'wrong_semantic_role', 'instrument_change'):
        bad = copy.deepcopy(packet)
        if label == 'lost_part': bad['documents'].pop(API)
        elif label in ('lost_canonical_block', 'lost_compatibility_route'):
            path = API if label == 'lost_canonical_block' else CORE
            saved = bad['documents'][path]
            saved['text'] = saved['text'].replace('### Normalized report-envelope families\n', '', 1)
            saved['sha256'] = sha(saved['text'].encode())
        elif label == 'lost_origin': bad['semantic_view']['origins'].pop()
        elif label == 'borrowed_origin': bad['semantic_view']['origins'][0]['actual_source'] = CORE
        elif label == 'lost_oracle': bad['legacy_views'].pop('symbols')
        elif label == 'wrong_oracle_mode': bad['legacy_modes']['envelope'] = 'current'
        elif label == 'lost_field': bad['legacy_views']['envelope']['fields'].pop(next(iter(bad['legacy_views']['envelope']['fields'])))
        elif label == 'source_change':
            saved = bad['runtime_sources'][REPORT]; saved['text'] = '# changed\n' + saved['text']; saved['sha256'] = sha(saved['text'].encode())
        elif label == 'wrong_semantic_role': bad['semantic_view']['kind'] = 'actual_old_book_source'
        else:
            saved = next(iter(bad['instruments'].values())); saved['text'] += '\n# changed\n'; saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad)
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    original = live_bytes
    try:
        globals()['live_bytes'] = lambda path: b'changed current-doc fixture\n' if path == API else original(path)
        verify(packet)
        try:
            verify(packet, current=True)
        except ValueError as error:
            results['saved_current_role'] = str(error)
        else:
            raise ValueError('Accepted stale actual current document')
    finally:
        globals()['live_bytes'] = original
    return results


class Page(HTMLParser):
    def __init__(self, raw):
        super().__init__()
        self.anchors, self.links = [], []
        self.feed(raw.decode())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get('id'): self.anchors.append(attrs['id'])
        if attrs.get('href'): self.links.append(attrs['href'])


def rendered(build_path, packet):
    plan = read(PLAN)
    old_name, api_name = Path(CORE).with_suffix('.html').name, Path(API).with_suffix('.html').name
    old_raw, api_raw = (build_path / old_name).read_bytes(), (build_path / api_name).read_bytes()
    old_page, api_page = Page(old_raw), Page(api_raw)
    for route in plan['routes']:
        require(old_page.anchors.count(route['anchor']) == 1 and api_page.anchors.count(route['anchor']) == 1, 'actual old/new unique native anchors')
        require(api_name + '#' + route['anchor'] in old_page.links, 'actual old-anchor canonical native route')
    for level, title, position in contract_module().outline(plan['inputs'][API]['text']):
        require(contract_module().anchor(title) in api_page.anchors, 'actual complete original API native anchors')
    results = {}
    with tempfile.TemporaryDirectory(prefix='reference-native-proxy-', dir=ROOT / '.artifacts/tmp') as temporary:
        proxy = Path(temporary)
        (proxy / old_name).write_bytes(api_raw)
        pod = proxy / 'perl-api/FSM/Support/CapabilityManifest.html'
        pod.parent.mkdir(parents=True)
        shutil.copyfile(build_path / 'perl-api/FSM/Support/CapabilityManifest.html', pod)
        for name, row in plan['reader_profiles'].items():
            if row['rendered_reader']:
                command = [sys.executable, '-B', str(ROOT / row['rendered_reader']), str(proxy)]
                result = subprocess.run(command, capture_output=True, text=True)
                require(result.returncode == 0, 'frozen native oracle refused: ' + name + '\n' + result.stderr)
                results[name] = json.loads(result.stdout)
            else:
                module = importlib.import_module(Path(row['reader']).stem)
                results[name] = (module.rendered(proxy, packet['legacy_views'][name]) if name == 'composition'
                                 else module.rendered(proxy))
    require(not proxy.exists(), 'owned proxy fixture removed')
    return {'actual_core': {'path': old_name, 'sha256': sha(old_raw)},
        'actual_canonical': {'path': api_name, 'sha256': sha(api_raw)}, 'oracle_results': results,
        'proxy_role': 'Temporary legacy filename contains hash-identical actual canonical HTML; it is not the actual old page or published output.',
        'limits': 'Actual native routes and selected table/content checks only; broader browser/manual QA stays owned.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    if args.write:
        destination = args.packet.resolve()
        require(destination.parent == BASE and not destination.exists(), 'new owned migration packet only')
        destination.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    packet = read(args.packet)
    result = verify(packet, args.current)
    result['rejected_controls'] = controls(packet)
    if args.build:
        result['rendered'] = rendered(args.build, packet)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
