"""Publish and replay the exact source-role census guide without widening capacity."""
import argparse
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/observer-header-source-census-20261010')
REVISION = '60791d20a69e2d93572c74aac9c6c64982077cd0'
CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.5.2.2.1'
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
ADDITION = 'The complete source-header prerequisite census now retains every qualified\nobserver case, throw phase, ordered group, frame, operand and load role. Its\nrecursive producer and independent explicit group reconstruction agree on the\nwhole source model; original trace display supplies no new semantic oracle.\n\nThe census exposes source-value obligations before exact header generation.\nA failed predicate gives logical false without selecting zero, an empty string\nor undef as its displayed token. Context operands explicitly leave scalar\nencoding unmeasured. Regex source patterns retain their complete bodies while\nconstructor flags and encoding require separate qualification. Entire inherited\nserialized inner operands remain dated evidence, with their prior scope.\n\nOriginal display settings, native reference identity, public receiver tokens\nand private framework intervals retain their unmeasured boundaries. Source\n`do` loading and the diagnostic `require` marker remain distinct roles.\nWhole-product omission, borrowing, reordering, role, schema, scope and premature\nheader-closure controls reject. Replay the complete source-only census:\n\n```sh\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-header-source-census-20261010/verify.py\n```\n\nSource-value qualification precedes full source-generated headers, the\noriginal-body join and observer publication. Their unchanged parent acceptance\nremains open, together with the separately owned native and visual scopes.\n\n'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args):
    r = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(r.returncode == 0 and not r.stderr, 'complete fixed book source input')
    return r.stdout


def aggregate(rows):
    return {'files': len(rows), 'lines_total': sum(raw.count(b'\n') for raw in rows), 'bytes_total': sum(map(len, rows))}


class Text(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)

    def handle_endtag(self, tag):
        if tag in ('p', 'th', 'td', 'tr', 'pre'):
            self.parts.append(' ')


def native_text(raw):
    parser = Text()
    parser.feed(raw.decode())
    lines = []
    for line in ADDITION.splitlines():
        if line.startswith('```'):
            continue
        if line.startswith('|'):
            cells = [cell.strip() for cell in line.split('|')[1:-1]]
            if all(cell and set(cell) <= {'-', ':'} for cell in cells):
                continue
            line = ' '.join(cells)
        lines.append(line.replace('`', ''))
    wanted = ' '.join(' '.join(lines).split())
    need(' '.join(''.join(parser.parts).split()).count(wanted) == 1, 'complete unique native source-role census guide with table and inline code')


def source():
    names = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    before = {name: git('show', REVISION + ':' + name) for name in names}
    old = before[str(CHAPTER)].decode()
    need(old.count(ANCHOR) == 1 and ADDITION not in old, 'unique original source-role census source seam')
    after = dict(before)
    after[str(CHAPTER)] = old.replace(ANCHOR, ADDITION + ANCHOR, 1).encode()
    return before, after


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--publish', action='store_true')
    group.add_argument('--native', action='store_true')
    group.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    before, after = source()
    destination = BASE / 'publication-final.json'
    if args.publish:
        need(not destination.exists(), 'one fresh source-role census publication epoch')
        current = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
        need(current == after, 'whole sole source-role census book addition and unchanged membership')
        records = [json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        for row in records:
            if row.get('surface_id') == 'shipped_behavior':
                old, new = aggregate(before.values()), aggregate(after.values())
                row['reference_contract']['aggregate_change'] = {
                    'authority_id': 'OBSERVER-HEADER-SOURCE-CENSUS-20261010', 'baseline': old,
                    'delta': {key: new[key] - old[key] for key in old}, 'owner': OWNER,
                    'rationale': 'Document the complete independently qualified source census and exact-header successor obligations while preserving original observer/settings/native scopes and every capacity ceiling.'}
            if row.get('surface_id') == 'task_evidence':
                paths = sorted({p for pattern in row['targets'] for p in Path('.').glob(pattern)})
                raw = [p.read_bytes() for p in paths]
                metrics = {**aggregate(raw), 'lines_each': max(x.count(b'\n') for x in raw),
                           'bytes_each': max(map(len, raw)),
                           'line_bytes_each': max(len(line.rstrip(b'\r')) for x in raw for line in x.split(b'\n'))}
                for key, actual in metrics.items():
                    if actual > row['baseline'][key] + row['transition']['max_growth'][key]:
                        row['transition']['max_growth'][key] = min(actual + row['transition']['ratchet_step'][key],
                            row['enforcement_ceilings'][key]) - row['baseline'][key]
        original_registry = [json.loads(line) for line in git('show', REVISION + ':' + str(REGISTRY)).splitlines()]
        need([r.get('enforcement_ceilings') for r in records] == [r.get('enforcement_ceilings') for r in original_registry],
             'all original capacity ceilings unchanged')
        guide = next(r for r in records if r.get('surface_id') == 'observer_display_guide').copy()
        guide.update(surface_id='observer_header_source_census_guide', targets=[str(BASE / 'GUIDE.md')], owner=OWNER)
        limits = dict(bytes_each=6144, bytes_total=6144, files=1, line_bytes_each=512, lines_each=96, lines_total=96)
        guide.update(enforcement_ceilings=limits, health_targets=limits)
        guide['classification'] = dict(audience='Observer source-header implementers and reviewers', role='current_qualification_procedure', rationale='One exact dated source-only census procedure and successor obligations. The reviewed 96-line envelope and 64-byte density derive the 6144-byte cap; 512 bytes bounds each line. No prior surface or Knowledge Map ceiling changes.')
        records.append(guide)
        (BASE / 'before-surfaces.jsonl.txt').write_bytes(git('show', REVISION + ':' + str(REGISTRY)))
        REGISTRY.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in records))
        value = {'revision': REVISION, 'owner': OWNER, 'source': str(CHAPTER), 'addition': ADDITION,
                 'before': {p: pin(raw) for p, raw in before.items()},
                 'after': {p: pin(raw) for p, raw in after.items()}, 'task_metrics': metrics,
                 'registry_after': records}
        destination.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
        print('PASS whole sole observer source-role census book addition and measured task pressure; every capacity ceiling unchanged.')
    elif args.native:
        output = BASE / 'native-final.html.txt'
        proof = BASE / 'native-final-proof.json'
        need(not output.exists() and not proof.exists(), 'one fresh complete native source-role census capture')
        raw = Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
        native_text(raw)
        output.write_bytes(raw)
        proof.write_text(json.dumps({'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
                                    'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'}, sort_keys=True, indent=2) + '\n')
        print('PASS whole native chapter and unique complete source-role census guide retained; visual QA remains open.')
    else:
        saved = json.loads(destination.read_bytes())
        need(saved['revision'] == REVISION and saved['owner'] == OWNER and saved['source'] == str(CHAPTER)
             and saved['addition'] == ADDITION and saved['before'] == {p: pin(raw) for p, raw in before.items()}
             and saved['after'] == {p: pin(raw) for p, raw in after.items()}, 'complete dated source-role census book source reconstruction')
        raw = (BASE / 'native-final.html.txt').read_bytes()
        need(json.loads((BASE / 'native-final-proof.json').read_bytes()) == {
            'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
            'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'},
            'complete dated native source and scope')
        native_text(raw)
        print('PASS whole dated source-role census source and native guide reconstruct independently of later live progress.')


if __name__ == '__main__':
    main()
