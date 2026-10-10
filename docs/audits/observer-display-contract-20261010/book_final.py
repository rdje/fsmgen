"""Publish and replay the exact public display guide without widening capacity."""
import argparse
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')
REVISION = '4b170801ddceb148da52df769f7a53b4dda93d05'
CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.5.2.1'
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
ADDITION = 'The public display prerequisite now qualifies a complete dated source-neutral\nfixture corpus. Source hypotheses precede its fresh native capture; a separate\noracle reconstructs every whole token, source lifetime and raw body. Original\nobserver headers and original formatter/settings identity remain open.\n\nThese examples describe the selected current public fixtures only:\n\n| Source argument and profile | Qualified display |\n| --- | --- |\n| Scalar `V$W`, default profile | `"V\\$W"` |\n| Scalar `V@W`, default profile | `"V\\@W"` |\n| Scalar `V`, newline, `W` | `"V\\x{a}W"` |\n| Selected nonnumeric 65-character argument, length limit 64 | Quoted first 61 characters followed by `...` |\n| Numeric-looking string of 65 digits, length limit 64 | All 65 digits, bare |\n| Wide regex longer than the length limit | `qr(prefix)...u` |\n| No arguments, count limit -1 | `...` |\n\nThe selected limits below 3 leave strings unshortened. Truncation uses source\ncharacters before escaping. Regex display retains its selected constructor\nflags and bypasses the general reference formatter in these fixtures; the own\n`CARP_TRACE` hook takes priority for its selected object. Plain reference\naddresses join only simultaneous held source values, with explicit aliases.\nNo cross-call or original-capture address identity follows.\n\nThe first full corpus rejected incomplete escape, numeric-order and regex\nhypotheses. Every failed source/native/result epoch is retained. An earlier\ninvestigation miscounted a saved 65-digit display as 61 digits; whole-source\nand display remeasurement withdrew that assertion. Loss metadata records\nactual shortening, and hostile controls reject both false loss and promotion\nof a genuinely truncated value to a complete source value.\n\nReplay the whole finite qualification, independent controls and source custody:\n\n```sh\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-display-contract-20261010/verify.py\n```\n\nThis completes the public prerequisite only. Complete source-generated\noriginal headers, their original-body join and observer publication still\nprecede full raw-stack closure. All native/provider/private limits retain.\n\n'


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
    need(' '.join(''.join(parser.parts).split()).count(wanted) == 1, 'complete unique native public display guide with table and inline code')


def source():
    names = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    before = {name: git('show', REVISION + ':' + name) for name in names}
    old = before[str(CHAPTER)].decode()
    need(old.count(ANCHOR) == 1 and ADDITION not in old, 'unique original public display source seam')
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
        need(not destination.exists(), 'one fresh public display publication epoch')
        current = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
        need(current == after, 'whole sole public display book addition and unchanged membership')
        records = [json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        for row in records:
            if row.get('surface_id') == 'shipped_behavior':
                old, new = aggregate(before.values()), aggregate(after.values())
                row['reference_contract']['aggregate_change'] = {
                    'authority_id': 'OBSERVER-DISPLAY-CONTRACT-20261010', 'baseline': old,
                    'delta': {key: new[key] - old[key] for key in old}, 'owner': OWNER,
                    'rationale': 'Document the independently qualified finite public display prerequisite and its retained failures/correction, preserving original observer/settings/native scopes and every capacity ceiling.'}
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
        REGISTRY.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in records))
        value = {'revision': REVISION, 'owner': OWNER, 'source': str(CHAPTER), 'addition': ADDITION,
                 'before': {p: pin(raw) for p, raw in before.items()},
                 'after': {p: pin(raw) for p, raw in after.items()}, 'task_metrics': metrics,
                 'registry_after': records}
        destination.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
        print('PASS whole sole observer public display book addition and measured task pressure; every capacity ceiling unchanged.')
    elif args.native:
        output = BASE / 'native-final.html.txt'
        proof = BASE / 'native-final-proof.json'
        need(not output.exists() and not proof.exists(), 'one fresh complete native public display capture')
        raw = Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
        native_text(raw)
        output.write_bytes(raw)
        proof.write_text(json.dumps({'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
                                    'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'}, sort_keys=True, indent=2) + '\n')
        print('PASS whole native chapter and unique complete public display guide retained; visual QA remains open.')
    else:
        saved = json.loads(destination.read_bytes())
        need(saved['revision'] == REVISION and saved['owner'] == OWNER and saved['source'] == str(CHAPTER)
             and saved['addition'] == ADDITION and saved['before'] == {p: pin(raw) for p, raw in before.items()}
             and saved['after'] == {p: pin(raw) for p, raw in after.items()}, 'complete dated public display book source reconstruction')
        raw = (BASE / 'native-final.html.txt').read_bytes()
        need(json.loads((BASE / 'native-final-proof.json').read_bytes()) == {
            'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
            'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'},
            'complete dated native source and scope')
        native_text(raw)
        print('PASS whole dated public display source and native guide reconstruct independently of later live progress.')


if __name__ == '__main__':
    main()
