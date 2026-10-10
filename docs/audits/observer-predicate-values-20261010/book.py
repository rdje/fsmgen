"""Publish and replay the exact predicate source-value guide without widening capacity."""
import argparse
import hashlib
import json
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/observer-predicate-values-20261010')
REVISION = '6715ce66cf7b8a63c3a7f3125d722b578b29ad87'
CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.5.2.2.2.1'
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
ADDITION = 'The failed-predicate source values now have a separate complete qualification.\nOwn helpers that explicitly select `? 1 : 0` supply numeric zero on failure.\nComparison and negation failures supply a defined empty string with numeric\nzero behavior. A failed `&&` or `||` preserves the operand selected by its\nshort circuit; the whole guard and qualified input determine that operand.\nThese language rules use the [public Perl operator contract](https://perldoc.perl.org/5.34.0/perlop).\n\n| Source constructor | Qualified false value | Current selected display |\n| --- | --- | --- |\n| Literal zero or helper normalization | String `0`, numeric zero | `0` |\n| Failed comparison or negation | Empty string, numeric zero | `""` |\n| Short circuit | Selected operand\'s complete value | Selected operand\'s token |\n\nThe source reader covers every failed-predicate location and both operand\nschemas, retaining whole inputs, aliases, guards and branch facts. Independent\nreconstruction rejects wrong values, branches, membership, source inputs,\nencoding and promotion of original native flags. Source-neutral public\nfixtures select their expressions and display hypotheses before capture;\nthe complete current headers agree under their explicit public profile.\nA real normalization intervention separates the empty-string and zero forms.\nThe original capture\'s flags, runtime and display settings remain unmeasured.\n\nFirst parser, precedence and fixture-boundary failures retain their complete\nprograms and results. Replay the complete source and public qualification:\n\n```sh\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-predicate-values-20261010/verify.py\n```\n\nRemaining scalar and regex constructors, full original source headers,\nthe original-body join and parent publication retain their unchanged\nacceptance. Native/private meanings and visual review remain separately open.\n\n'


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
        line = re.sub(r'\[([^\]]+)\]\([^)]+\)',r'\1',line)
        line = re.sub(r"(?<=[A-Za-z])'(?=[A-Za-z])",'\u2019',line)
        lines.append(line.replace('`', ''))
    wanted = ' '.join(' '.join(lines).split())
    need(' '.join(''.join(parser.parts).split()).count(wanted) == 1, 'complete unique native predicate source-value guide with table and inline code')


def source():
    names = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    before = {name: git('show', REVISION + ':' + name) for name in names}
    old = before[str(CHAPTER)].decode()
    need(old.count(ANCHOR) == 1 and ADDITION not in old, 'unique original predicate source-value source seam')
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
        need(not destination.exists(), 'one fresh predicate source-value publication epoch')
        current = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
        need(current == after, 'whole sole predicate source-value book addition and unchanged membership')
        records = [json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        for row in records:
            if row.get('surface_id') == 'shipped_behavior':
                old, new = aggregate(before.values()), aggregate(after.values())
                row['reference_contract']['aggregate_change'] = {
                    'authority_id': 'OBSERVER-PREDICATE-VALUES-20261010', 'baseline': old,
                    'delta': {key: new[key] - old[key] for key in old}, 'owner': OWNER,
                    'rationale': 'Document the complete independently qualified failed-predicate values and unchanged remaining value/header obligations while preserving original observer/settings/native scopes and every capacity ceiling.'}
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
        guide.update(surface_id='observer_predicate_values_guide', targets=[str(BASE / 'GUIDE.md')], owner=OWNER)
        limits = dict(bytes_each=6144, bytes_total=6144, files=1, line_bytes_each=512, lines_each=96, lines_total=96)
        guide.update(enforcement_ceilings=limits, health_targets=limits)
        guide['classification'] = dict(audience='Observer source-header implementers and reviewers', role='current_qualification_procedure', rationale='One exact dated source and current public constructor procedure and successor obligations. The reviewed 96-line envelope and 64-byte density derive the 6144-byte cap; 512 bytes bounds each line. No prior surface or Knowledge Map ceiling changes.')
        records.append(guide)
        (BASE / 'before-surfaces.jsonl.txt').write_bytes(git('show', REVISION + ':' + str(REGISTRY)))
        REGISTRY.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in records))
        value = {'revision': REVISION, 'owner': OWNER, 'source': str(CHAPTER), 'addition': ADDITION,
                 'before': {p: pin(raw) for p, raw in before.items()},
                 'after': {p: pin(raw) for p, raw in after.items()}, 'task_metrics': metrics,
                 'registry_after': records}
        destination.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
        print('PASS whole sole observer predicate source-value book addition and measured task pressure; every capacity ceiling unchanged.')
    elif args.native:
        output = BASE / 'native-final.html.txt'
        proof = BASE / 'native-final-proof.json'
        need(not output.exists() and not proof.exists(), 'one fresh complete native predicate source-value capture')
        raw = Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
        native_text(raw)
        output.write_bytes(raw)
        proof.write_text(json.dumps({'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
                                    'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'}, sort_keys=True, indent=2) + '\n')
        print('PASS whole native chapter and unique complete predicate source-value guide retained; visual QA remains open.')
    else:
        saved = json.loads(destination.read_bytes())
        need(saved['revision'] == REVISION and saved['owner'] == OWNER and saved['source'] == str(CHAPTER)
             and saved['addition'] == ADDITION and saved['before'] == {p: pin(raw) for p, raw in before.items()}
             and saved['after'] == {p: pin(raw) for p, raw in after.items()}, 'complete dated predicate source-value book source reconstruction')
        raw = (BASE / 'native-final.html.txt').read_bytes()
        need(json.loads((BASE / 'native-final-proof.json').read_bytes()) == {
            'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
            'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'},
            'complete dated native source and scope')
        native_text(raw)
        print('PASS whole dated predicate source-value source and native guide reconstruct independently of later live progress.')


if __name__ == '__main__':
    main()
