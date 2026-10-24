#!/usr/bin/env python3
"""Independently close byte, semantic-origin, native and knowledge preservation."""
import argparse
from collections import Counter
import copy
import gzip
import hashlib
from html import unescape
from html.parser import HTMLParser
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PREFIX = BASE.relative_to(ROOT).as_posix() + '/'
CORE = 'docs/book/src/11-extensions-and-embedding.md'
API = 'docs/book/src/11a-perl-api-reference.md'
SUMMARY = 'docs/book/src/SUMMARY.md'
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.10.3'
TITLES = (
    'Normalized report-envelope families', 'Normalized payload and IR baseline families',
    'Normalized symbol family subjects', 'Normalized composition envelope and shallow children',
    'Normalized composition parameter-override aliases', 'Normalized composition standalone-DT children',
    'Normalized composition grouped lookups', 'Normalized shared-datapath candidate and contributor subjects',
    'Normalized shared-datapath binding and drive-intent subjects')


def require(condition, reason):
    if not condition:
        raise ValueError(reason)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def read(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def git_bytes(head, path):
    return subprocess.check_output(['git', 'show', head + ':' + path], cwd=ROOT)


def live_bytes(path):
    return (ROOT / path).read_bytes()


def bridge():
    spec = importlib.util.spec_from_file_location('frozen_migration_bridge', BASE / 'bridge.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def slug(title):
    return re.sub('[^a-z0-9 _-]', '', title.lower()).replace(' ', '-')


def block(raw, title):
    marker = ('### ' + title + '\n').encode()
    require(raw.count(marker) == 1, 'independent unique section: ' + title)
    start = raw.index(marker)
    following = re.search(rb'^#{1,3} ', raw[start + len(marker):], re.M)
    require(following is not None, 'independent complete section end')
    end = start + len(marker) + following.start()
    return raw[start:end], start, end


def plain(cell):
    require(not re.search(r'\\\||\]\(', cell), 'selected table has no unhandled pipe/link markup')
    return ' '.join(unescape(cell.replace('`', '').replace('**', '')).split())


def components(raw):
    text = raw.decode()
    tables, table = [], []
    for line in text.splitlines():
        if line.startswith('|'):
            cells = [cell.strip() for cell in line.strip('|').split('|')]
            if not all(re.fullmatch(r':?-+:?', cell.replace(' ', '')) for cell in cells):
                table.append([plain(cell) for cell in cells])
        elif table:
            tables.append(table)
            table = []
    if table:
        tables.append(table)
    examples = [{'language': match[1], 'text': match[2]}
                for match in re.finditer(r'^```([^\n]*)\n(.*?)^```\s*$', text, re.M | re.S)]
    links = re.findall(r'\]\(([^)\n]+)\)', text)
    return {'tables': tables, 'examples': examples, 'links': links}


def without_document_slots(value):
    """Only declared view slots may differ; preserve every other JSON leaf."""
    result = copy.deepcopy(value)
    scoped = result['baseline'] if 'baseline' in result else result
    groups = [scoped] + list(scoped.get('cohorts', {}).values())
    for group in groups:
        group.pop('documents')
        group['sources'].pop('perl/FSM/Support/CapabilityManifest.pm')
    return result


def preservation(migration, plan):
    original = {path: git_bytes(plan['baseline_head'], path) for path in (CORE, API, SUMMARY)}
    actual = {path: migration['documents'][path]['text'].encode() for path in original}
    for path in original:
        require(original[path] == plan['inputs'][path]['text'].encode(), 'independent original Git bytes')
    restored = actual[CORE]
    rows = []
    for title in TITLES:
        before, old_start, old_end = block(original[CORE], title)
        after, new_start, new_end = block(actual[API], title)
        stub, _, _ = block(actual[CORE], title)
        expected_stub = ('### ' + title + '\n\nSee the [canonical field reference]('
                         + Path(API).name + '#' + slug(title) + ').\n\n').encode()
        require(stub == expected_stub, 'independent complete compatibility route')
        require(before == after and actual[API].count(before) == 1
                and before not in actual[CORE], 'independent canonical block preservation')
        restored = restored.replace(stub, after, 1)
        rows.append({'title': title, 'anchor': slug(title), 'sha256': sha(before),
                     'old_source_span': [old_start, old_end],
                     'canonical_source_span': [new_start, new_end], **components(before)})
    require(restored == original[CORE], 'independent every unmoved core byte')
    expected_origins = [{'title': row['title'], 'anchor': row['anchor'], 'actual_source': API,
                         'sha256': row['sha256'], 'start_byte': row['canonical_source_span'][0],
                         'end_byte': row['canonical_source_span'][1]} for row in rows]
    require(migration['semantic_view']['origins'] == expected_origins, 'independent complete source-origin join')
    require(migration['semantic_view']['kind'] == 'derived_semantic_comparison'
            and migration['semantic_view']['text'].encode() == restored, 'independent derived-view role')
    # The old API part survives through precisely the declared title, intro and
    # navigation rewrite. These boundaries are checked separately from the
    # original bridge's substitution algorithm.
    old_api = original[API].decode()
    new_api = actual[API].decode()
    old_front, old_build = old_api.split('## Build and preview\n', 1)
    new_front, new_build = new_api.split('## Build and preview\n', 1)
    require(old_build == new_build, 'independent original API build guidance')
    begin = new_front.index('## Normalized Semantic Metadata Reference\n')
    new_front = new_front[:begin]
    new_front = new_front.replace('# API and Model Reference\n\n## Perl API Reference\n', '# Perl API Reference\n', 1)
    rewrite = plan['navigation_rewrite']
    require(new_front.replace(rewrite['after'], rewrite['before'], 1) == old_front,
            'independent original API introduction and entry links')
    links = lambda raw: re.findall(rb'\]\(([^)]+)\)', raw)
    require(links(original[SUMMARY]) == links(actual[SUMMARY]), 'independent direct index membership/order')
    require(actual[SUMMARY] == original[SUMMARY].replace(b'[Perl API Reference]', b'[API and Model Reference]'),
            'independent only sidebar label change')
    fields = {}
    require(set(migration['legacy_views']) == set(plan['reader_profiles']), 'independent all legacy cohorts')
    for name, profile in plan['reader_profiles'].items():
        old = read(ROOT / profile['packet'])
        new = migration['legacy_views'][name]
        require(without_document_slots(old) == without_document_slots(new),
                'independent all field/deeper-owner leaves: ' + name)
        require(migration['legacy_modes'][name] == 'saved-only', 'independent saved-only legacy role')
        scope = new['baseline'] if name == 'baseline' else new
        fields[name] = {key: len(scope[key]) for key in
                       ('fields', 'remaining_fields', 'remaining_shared', 'remaining_composition') if key in scope}
    return {'blocks': rows, 'cohort_populations': fields,
            'limits': 'All semantic source bytes and JSON leaves conserve through declared document slots; deeper model meaning remains separately owned.'}


class NativeSections(HTMLParser):
    def __init__(self, raw):
        super().__init__()
        self.sections, self.active = {}, None
        self.cell, self.row, self.example = None, None, None
        self.anchors, self.links = [], []
        self.feed(raw.decode())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get('id'):
            self.anchors.append(attrs['id'])
        if attrs.get('href'):
            self.links.append(attrs['href'])
        if re.fullmatch('h[1-3]', tag):
            name = attrs.get('id')
            self.active = {'tables': [], 'examples': [], 'links': []} if name in {slug(t) for t in TITLES} else None
            if self.active is not None:
                require(name not in self.sections, 'independent unique native section')
                self.sections[name] = self.active
        if self.active is None:
            return
        if attrs.get('href'):
            self.active['links'].append(attrs['href'])
        if tag == 'table': self.active['tables'].append([])
        if tag == 'tr': self.row = []
        if tag in ('td', 'th'): self.cell = []
        if tag == 'pre': self.example = []

    def handle_data(self, value):
        if self.cell is not None: self.cell.append(value)
        if self.example is not None: self.example.append(value)

    def handle_endtag(self, tag):
        if self.active is None:
            return
        if tag in ('td', 'th'):
            # mdBook smart punctuation renders prose apostrophes as U+2019.
            # Exact source bytes were already compared; fold only this observed
            # typography difference for the source-to-native table comparison.
            self.row.append(' '.join(''.join(self.cell).replace('\u2019', "'").split()))
            self.cell = None
        if tag == 'tr': self.active['tables'][-1].append(self.row)
        if tag == 'pre':
            self.active['examples'].append(''.join(self.example))
            self.example = None


def native(pages, preserved):
    core = NativeSections(pages['11-extensions-and-embedding.html'].encode())
    api = NativeSections(pages['11a-perl-api-reference.html'].encode())
    require(set(api.sections) == {slug(t) for t in TITLES}, 'independent complete native canonical parts')
    for row in preserved['blocks']:
        name = row['anchor']
        require(core.anchors.count(name) == 1 and api.anchors.count(name) == 1, 'independent stable native anchors')
        require('11a-perl-api-reference.html#' + name in core.sections[name]['links'], 'independent real old route')
        require(not core.sections[name]['tables'] and not core.sections[name]['examples'], 'independent no duplicated maintained native content')
        section = api.sections[name]
        require(section['tables'] == row['tables'], 'independent every native table cell: ' + name)
        require(section['examples'] == [item['text'] for item in row['examples']], 'independent every native code example: ' + name)
        expected = Counter(re.sub(r'\.md(?=#|$)', '.html', link) for link in row['links'])
        actual = Counter(link for link in section['links'] if link != '#' + name)
        require(expected == actual, 'independent every native authored link: ' + name)
    return {'blocks': len(preserved['blocks']),
            'tables': sum(len(row['tables']) for row in preserved['blocks']),
            'examples': sum(len(row['examples']) for row in preserved['blocks']),
            'scope': 'Complete moved native tables/examples/authored links and stable routes; no whole-manual visual signoff.'}


def knowledge(head, current):
    raw = subprocess.check_output(['git', 'ls-tree', '-r', '-z', head, '--', 'docs/knowledge'], cwd=ROOT)
    rows = []
    algorithm = subprocess.check_output(['git', 'rev-parse', '--show-object-format'], cwd=ROOT).decode().strip()
    for entry in raw.split(b'\0'):
        if not entry: continue
        header, path = entry.split(b'\t')
        mode, kind, identity = header.decode().split()
        path = path.decode()
        require(mode == '100644' and kind == 'blob', 'owned regular knowledge source')
        if current:
            data = live_bytes(path)
            obj = hashlib.new(algorithm, b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
            require(obj == identity, 'independent current knowledge parity: ' + path)
        rows.append({'path': path, 'git_blob': identity})
    if current:
        actual = {path.relative_to(ROOT).as_posix() for path in (ROOT / 'docs/knowledge').rglob('*') if path.is_file()}
        require(actual == {row['path'] for row in rows}, 'independent complete knowledge population')
    return rows


def build(build_path):
    plan = read(BASE / 'partition-contract-final-qualified.json.gz')
    migration = read(BASE / 'migration-qualified.json.gz')
    pages = {name: (build_path / name).read_text() for name in
             ('11-extensions-and-embedding.html', '11a-perl-api-reference.html')}
    return {'schema': 'fsmgen.normalized_reference_closure.v1', 'owner': OWNER,
            'inputs': {PREFIX + name: sha((BASE / name).read_bytes()) for name in
                       ('partition-contract-final-qualified.json.gz', 'migration-qualified.json.gz', 'bridge.py')},
            'preservation': preservation(migration, plan), 'native_pages': pages,
            'knowledge': knowledge(plan['baseline_head'], True),
            'instrument': {'path': PREFIX + 'closure.py', 'text': Path(__file__).read_text()},
            'limits': 'Reference partition closes only; runtime/model/source/HIAL/publication and broad visual obligations remain open.'}


def verify(packet, current=False, build_path=None):
    require(packet['schema'] == 'fsmgen.normalized_reference_closure.v1' and packet['owner'] == OWNER, 'closure identity')
    expected_inputs = {PREFIX + name: sha((BASE / name).read_bytes()) for name in
                       ('partition-contract-final-qualified.json.gz', 'migration-qualified.json.gz', 'bridge.py')}
    require(packet['inputs'] == expected_inputs, 'closure frozen input population/identity')
    plan = read(BASE / 'partition-contract-final-qualified.json.gz')
    migration = read(BASE / 'migration-qualified.json.gz')
    preserved = preservation(migration, plan)
    require(packet['preservation'] == preserved, 'closure complete independent preservation result')
    require(packet['knowledge'] == knowledge(plan['baseline_head'], current), 'closure original knowledge population/identity')
    require(packet['instrument'] == {'path': PREFIX + 'closure.py', 'text': Path(__file__).read_text()}, 'closure exact instrument identity')
    require(set(packet['native_pages']) == {'11-extensions-and-embedding.html', '11a-perl-api-reference.html'}, 'closure native population')
    result = native(packet['native_pages'], preserved)
    if current:
        for path, saved in {**migration['runtime_sources'], **migration['documents']}.items():
            require(live_bytes(path) == saved['text'].encode(), 'closure current source/doc identity: ' + path)
    if build_path is not None:
        for name, saved in packet['native_pages'].items():
            require((build_path / name).read_bytes() == saved.encode(), 'closure current native identity')
    # Separate frozen six-cohort/current-code proof supplements this independent
    # byte/JSON/native join. It never substitutes for the checks above.
    result['bridge'] = bridge().verify(migration, current=current)
    result['knowledge_files'] = len(packet['knowledge'])
    result['native_sha256'] = {name: sha(text.encode()) for name, text in packet['native_pages'].items()}
    result['limits'] = packet['limits']
    return result


def controls(packet):
    plan = read(BASE / 'partition-contract-final-qualified.json.gz')
    migration = read(BASE / 'migration-qualified.json.gz')
    results = {}
    for label in ('omitted_block', 'duplicate_block', 'misrouted_block', 'borrowed_origin', 'lost_deeper_owner', 'wrong_legacy_mode'):
        bad = copy.deepcopy(migration)
        title = TITLES[0]
        raw, _, _ = block(bad['documents'][API]['text'].encode(), title)
        if label == 'omitted_block': bad['documents'][API]['text'] = bad['documents'][API]['text'].replace(raw.decode(), '', 1)
        elif label == 'duplicate_block': bad['documents'][API]['text'] += raw.decode()
        elif label == 'misrouted_block': bad['documents'][CORE]['text'] = bad['documents'][CORE]['text'].replace('11a-perl-api-reference.md#' + slug(title), '11a-perl-api-reference.md#wrong', 1)
        elif label == 'borrowed_origin': bad['semantic_view']['origins'][0]['actual_source'] = CORE
        elif label == 'lost_deeper_owner': bad['legacy_views']['shared_drive']['remaining_fields'].pop(next(iter(bad['legacy_views']['shared_drive']['remaining_fields'])))
        else: bad['legacy_modes']['shared_drive'] = 'current'
        try:
            preservation(bad, plan)
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Independent preservation accepted ' + label)
    for label in ('lost_native_example', 'changed_native_cell', 'wrong_native_route'):
        pages = copy.deepcopy(packet['native_pages'])
        if label == 'lost_native_example': pages['11a-perl-api-reference.html'] = re.sub(r'<pre>.*?</pre>', '', pages['11a-perl-api-reference.html'], count=1, flags=re.S)
        elif label == 'changed_native_cell': pages['11a-perl-api-reference.html'] = pages['11a-perl-api-reference.html'].replace('<code>public_top_level_presence_keys</code>', '<code>counterfeit</code>', 1)
        else: pages['11-extensions-and-embedding.html'] = pages['11-extensions-and-embedding.html'].replace('11a-perl-api-reference.html#' + slug(TITLES[0]), '11a-perl-api-reference.html#wrong', 1)
        try:
            native(pages, packet['preservation'])
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Independent native reader accepted ' + label)
    original = live_bytes
    try:
        globals()['live_bytes'] = lambda path: b'stale actual API fixture\n' if path == API else original(path)
        verify(packet)
        try:
            verify(packet, current=True)
        except ValueError as error:
            results['stale_live_source'] = str(error)
        else:
            raise ValueError('Current mode accepted stale live source')
    finally:
        globals()['live_bytes'] = original
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    if args.write:
        require(args.build is not None and args.packet.resolve().parent == BASE and not args.packet.exists(), 'new owned closure packet with native input only')
        args.packet.write_bytes(gzip.compress((json.dumps(build(args.build), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    packet = read(args.packet)
    result = verify(packet, current=args.current, build_path=args.build)
    result['rejected_controls'] = controls(packet)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
