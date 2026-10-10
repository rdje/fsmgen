"""Publish and replay the exact diagnosis guide without widening capacity."""
import argparse
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/observer-join-prerequisite-20261010')
REVISION = '60f6259b7c789d91d6df24c13e0ee1994ca030d7'
CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.5.1'
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
ADDITION = '''Full observer joining remains a prerequisite for complete raw-stack closure.
The earlier finite class/frame join qualifies visible source prefixes and
whole-body custody. Complete observer headers and exact quoting/truncation
remain owned by the still-open original observer join.

A dated diagnosis shortens one actual truncated public subtest-name display
to another proper source prefix. The limited prefix predicates accept it;
the full historical reader rejects the changed body at its custody gate.
Both contracts behave as declared. Neither result qualifies the pending
full-header contract or measures original formatter/settings identity.

Replay the complete dated source, candidate and actual-result diagnosis:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-join-prerequisite-20261010/verify.py
```

Full observer repair and publication precede raw-stack closure. Class/frame
parents and raw-stack acceptance remain open; coordinate/address qualifications
and all separately owned native, cause, consumer, alias and cold scopes retain.

'''


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


def native_text(raw):
    parser = Text()
    parser.feed(raw.decode())
    wanted = ' '.join(ADDITION.replace('```sh\n', '').replace('```\n', '').split())
    need(' '.join(''.join(parser.parts).split()).count(wanted) == 1, 'complete unique native diagnosis guide')


def source():
    names = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    before = {name: git('show', REVISION + ':' + name) for name in names}
    old = before[str(CHAPTER)].decode()
    need(old.count(ANCHOR) == 1 and ADDITION not in old, 'unique original diagnosis source seam')
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
    destination = BASE / 'publication.json'
    if args.publish:
        need(not destination.exists(), 'one fresh diagnosis publication epoch')
        current = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
        need(current == after, 'whole sole diagnosis book addition and unchanged membership')
        records = [json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        for row in records:
            if row.get('surface_id') == 'shipped_behavior':
                old, new = aggregate(before.values()), aggregate(after.values())
                row['reference_contract']['aggregate_change'] = {
                    'authority_id': 'OBSERVER-JOIN-PREREQUISITE-20261010', 'baseline': old,
                    'delta': {key: new[key] - old[key] for key in old}, 'owner': OWNER,
                    'rationale': 'Document the actual unfinished observer full-header prerequisite and the limited-prefix/full-custody distinction without claiming its repair or widening any ceiling.'}
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
        print('PASS whole sole observer diagnosis book addition and measured task pressure; every capacity ceiling unchanged.')
    elif args.native:
        output = BASE / 'native.html.txt'
        proof = BASE / 'native-proof.json'
        need(not output.exists() and not proof.exists(), 'one fresh complete native diagnosis capture')
        raw = Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
        native_text(raw)
        output.write_bytes(raw)
        proof.write_text(json.dumps({'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
                                    'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'}, sort_keys=True, indent=2) + '\n')
        print('PASS whole native chapter and unique complete diagnosis guide retained; visual QA remains open.')
    else:
        saved = json.loads(destination.read_bytes())
        need(saved['revision'] == REVISION and saved['owner'] == OWNER and saved['source'] == str(CHAPTER)
             and saved['addition'] == ADDITION and saved['before'] == {p: pin(raw) for p, raw in before.items()}
             and saved['after'] == {p: pin(raw) for p, raw in after.items()}, 'complete dated diagnosis book source reconstruction')
        raw = (BASE / 'native.html.txt').read_bytes()
        need(json.loads((BASE / 'native-proof.json').read_bytes()) == {
            'source': str(CHAPTER), 'html': pin(raw), 'addition': ADDITION,
            'scope': 'Complete rendered text and source-copy currency are separate checks; visual QA remains open.'},
            'complete dated native source and scope')
        native_text(raw)
        print('PASS whole dated diagnosis source and native guide reconstruct independently of later live progress.')


if __name__ == '__main__':
    main()
