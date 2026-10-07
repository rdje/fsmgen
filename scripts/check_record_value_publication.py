#!/usr/bin/env python3
"""Check current class/frame publication without freezing unrelated fact epochs."""

import argparse
import hashlib
import json
import os
import subprocess
from pathlib import Path

import book_source_references as plane
from decision_store_git import MAX_TRACKED_PATHS

ROOT = plane.ROOT
HISTORICAL = Path('docs/audits/record-value-class-frame-publication-20261006')
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py'
BUILD = COMMAND + ' --build .artifacts/class-frame-current-book'
SUCCESS = 'PASS current class/frame facts, complete current source/query allocation and unchanged capacity/source contracts.\n'
QUESTION = 'why did the class/frame current reader reject unrelated Knowledge Map updates?'
OLD_SCOPE = '''Historical success does not establish current card/query/reader/source currency. Current
publication checks complete core/helper/tooling meanings/question ownership, unique book
guidance, canonical selection/endpoints/bytes/ignore policy, exact current budget and
indexed members. Original destination-locality replay remains required. Explicit factory
output checks remain required for native copied bytes; visual QA stays pending.
'''
NEW_SCOPE = '''Historical success proves no current card/query/reader/source currency. Current checks
complete core/helper/tooling meanings/questions, unique book guidance, canonical
selection/endpoints/bytes/ignore policy, exact budgets and indexed members. Original
destination-locality replay and factory native copied-byte checks remain required;
visual QA stays pending.

The old class/frame current check froze unrelated card bytes/queries. This route
derives complete global source allocation.
'''


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def historical():
    """Keep the complete sealed programme and its snapshot predicate unchanged."""
    namespace = {'__name__': 'retained_publication', '__file__': str(HISTORICAL / 'verify.py')}
    exec(compile((HISTORICAL / 'verify.py').read_bytes(), str(HISTORICAL / 'verify.py'), 'exec'), namespace)
    require(same(namespace['load'](HISTORICAL / 'manifest.json'), namespace['members']()),
            'complete immutable historical publication seal')
    return namespace


def expected_cards(prior):
    result = {}
    for path, text in prior['model']['cards']().items():
        old = prior['model']['COMMAND']
        require(text.count(old) == 1 and text.count('date: 2026-10-06\n') == 1,
                'unique original current card route and date')
        result[path] = text.replace(old, COMMAND, 1).replace('date: 2026-10-06\n', 'date: 2026-10-07\n', 1)
        if path == prior['TOOLING']:
            require(result[path].count(OLD_SCOPE) == 1, 'complete original tooling current-scope paragraph')
            result[path] = result[path].replace('date: 2026-10-07\n',
                '  - "' + QUESTION + '"\ndate: 2026-10-07\n', 1).replace(OLD_SCOPE, NEW_SCOPE, 1)
    return result


def guide(prior):
    book = prior['book']
    result = book['GUIDE'].replace(book['BUILD'], BUILD).replace(book['COMMAND'], COMMAND)
    return result.replace('Unrelated book\nprogress is permitted by the current reader.',
        'Unrelated book and non-target Knowledge Map progress is permitted. The current\n'
        'reader derives the complete global question allocation and physical census from\n'
        'current canonical sources; the saved historical snapshot keeps its exact epoch.')


def sources():
    """Enumerate both canonical scan roots; reject foreign or nonregular inputs.

    The existing finite Git population and canonical-source byte bounds apply
    before reads. No submodule, symlink directory or nested repository is entered.
    """
    result = {}
    for root in ('docs/knowledge', 'docs/decisions'):
        plane.local_parents(ROOT / root / 'endpoint')
        for directory, children, files in os.walk(ROOT / root, followlinks=False):
            base = Path(directory)
            for child in children:
                plane.local_parents(base / child / 'endpoint')
            for name in sorted(files):
                if not name.endswith('.md'):
                    continue
                path = base / name
                require(len(result) < MAX_TRACKED_PATHS, 'bounded canonical source population')
                relative = str(path.relative_to(ROOT))
                raw = plane.local_read(path, plane.SOURCE_BYTES)
                raw.decode('utf-8', errors='strict')
                result[relative] = raw
    return dict(sorted(result.items()))


def authority(prior):
    return prior['source_model']()


def current_input(prior, canonical):
    public = prior['public']
    physical = {p: raw for p, raw in canonical.items() if Path(p).parent == Path('docs/knowledge')}
    registry = plane.local_read(ROOT / prior['REGISTRY'], plane.SOURCE_BYTES)
    book_budget = next(json.loads(s)['enforcement_ceilings']['bytes_each']
                       for s in registry.decode().splitlines() if json.loads(s).get('surface_id') == 'shipped_behavior')
    return dict(cards={p: canonical[p].decode() for p in prior['PATHS']},
        chapter=plane.local_read(ROOT / prior['CHAPTER'], book_budget).decode(),
        tooling_chapter=plane.local_read(ROOT / prior['TOOLING_CHAPTER'], book_budget).decode(),
        queries=public['queries'](), census=public['metrics'](physical),
        surface=public['authority'](registry), source_members={p: identity(raw) for p, raw in canonical.items()},
        source_budget=next(json.loads(s) for s in registry.decode().splitlines()
                           if json.loads(s).get('surface_id') == 'book_source_manifest'))


def check(record, canonical, prior, declared):
    require(type(record) is dict and set(record) == {
        'cards', 'chapter', 'tooling_chapter', 'queries', 'census', 'surface', 'source_members', 'source_budget'},
        'closed complete current publication input')
    expected = expected_cards(prior)
    require(record['cards'] == expected and all(canonical.get(p) == text.encode() for p, text in expected.items()),
            'complete current target meanings questions metadata and replay routes')
    require(record['chapter'].count(guide(prior)) == 1 and record['chapter'].count(prior['book']['EPOCH']) == 1,
            'unique complete current and retained publication guidance')
    pins = record['source_members']
    require(type(pins) is dict and all(type(pin) is dict and set(pin) == {'bytes', 'sha256'}
        and type(pin['bytes']) is int and pin['bytes'] >= 0 and type(pin['sha256']) is str
        for pin in pins.values()), 'current source member identity kinds')
    require(same(pins, {p: identity(raw) for p, raw in canonical.items()}),
            'complete independently enumerated current source members')
    physical = {p: raw for p, raw in canonical.items() if Path(p).parent == Path('docs/knowledge')}
    prior['public']['within'](record['census'], record['surface'])
    require(same(record['census'], prior['public']['metrics'](physical)), 'complete current physical census')
    require(same(record['surface'], declared['surface']), 'unchanged current collection authority')
    require(type(record['queries']) is dict and set(record['queries']) == {'direct', 'cached'},
            'complete actual current query roles')
    allocation = prior['metadata']['allocation'](canonical)
    target = sorted(prior['metadata']['allocation']({p: t.encode() for p, t in expected.items()})['rows'].splitlines())
    for role, actual in record['queries'].items():
        require(type(actual) is dict and set(actual) == {'command', 'status', 'stdout', 'stderr'},
                'closed actual current query result')
        require(type(actual['status']) is int and actual['status'] == 0, 'actual current query integer success')
        command = ['knowledge-map/scripts/query_knowledge_map.sh', '--all'] + (['--no-cache'] if role == 'direct' else [])
        require(actual['command'] == command and actual['stderr'] == '' and type(actual['stdout']) is str,
                'distinct actual current query command and streams')
        require(prior['target_rows'](actual['stdout']) == target, 'complete current target question ownership')
        require(actual['stdout'] == allocation['rows'], 'complete source-derived current global query allocation')
    require(same(record['source_budget'], declared['source_budget']), 'unchanged current canonical source budget')
    original = prior['load'](Path('docs/audits/book-source-plane-20261005/book-authority.json'))['block'].split('\nThe asset plane is available;', 1)[0]
    require(record['tooling_chapter'].count(original) == 1, 'complete canonical source and native build roles')
    for row in plane.expected_rows():
        chapter = record['chapter'] if row['chapter'] == prior['CHAPTER'].stem else record['tooling_chapter']
        require(chapter.count('](' + row['asset'] + ')') == 1, 'unique complete canonical source destination')


def check_native(html, prior):
    parsed = prior['book']['Visible']()
    parsed.feed(html)
    require(all(parsed.codes.count(command) == 1 for command in (COMMAND, BUILD, prior['book']['DEFAULT'])),
            'native distinct current build and historical commands')
    visible = ' '.join(' '.join(parsed.parts).split())
    for block in (guide(prior), prior['book']['EPOCH']):
        text = block.replace('```bash\n', '').replace('```\n', '').replace('`', '')
        require(' '.join(text.split()) in visible, 'native complete current retained scope and gaps')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', help='repository-relative current native book output')
    args = parser.parse_args()
    require(Path.cwd().resolve() == ROOT, 'invoke current publication from repository root')
    prior = historical()
    command = ['python3', '-B', str(HISTORICAL / 'verify.py')]
    result = subprocess.run(command, capture_output=True, text=True)
    require(type(result.returncode) is int and result.returncode == 0
        and result.stdout == prior['SUCCESS'] and result.stderr == '', 'complete actual historical snapshot replay')
    canonical = sources()
    check(current_input(prior, canonical), canonical, prior, authority(prior))
    rows = plane.expected_rows()
    plane.check(rows, args.build)
    plane.check_index(rows)
    if args.build:
        output = ROOT / plane.relative(args.build)
        html = plane.local_read(output / (prior['CHAPTER'].stem + '.html'), plane.SOURCE_BYTES * 4).decode()
        check_native(html, prior)
    require(canonical == sources(), 'whole current canonical source epoch conserved during verification')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
