"""Qualify the tooling reader against the admitted public observer publication."""
import argparse
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-tooling-current-reader-20261006')
CHECKS = Path('docs/audits/tooling-current-reader-checks-20261006')
PUBLIC = Path('docs/audits/record-value-public-boundary-publication-20261006')
PUBLIC_CHECKS = Path('docs/audits/public-boundary-publication-checks-20261006')
REVISION = 'e94e43234e4456d55fd55c99f2e3e37a529a4cbf'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.5.4.2.3'
CORE = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
OBSERVER = 'docs/knowledge/record-value-original-observer-helper-paths.md'
TOOLING = 'docs/knowledge/mdbook-build-destination-locality.md'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'
TOOLING_CHAPTER = 'docs/book/src/90-reference-map.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
PATHS = (CORE, OBSERVER, TOOLING)
IDS = {Path(p).stem for p in PATHS}
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B ' + str(BASE / 'verify.py') + ' --current'
SUCCESS = 'PASS authenticated tooling-route source and saved snapshot; current currency requires --current.\n'
CURRENT_SUCCESS = 'PASS current complete core/observer/tooling facts, questions and source routes under unchanged collection authority.\n'
FRAME = '''The following observer publication guide records its 2026-10-06 checkpoint.
Its scoped observer command remains valid. The companion repair and complete
current core/observer/tooling route are qualified immediately after that guide.

'''
GUIDE = '''The tooling companion now uses the qualified current reader below. The
earlier pending-repair statements describe the observer publication checkpoint;
this companion repair completes that dependency. The core and observer cards
remain exact, and every tooling fact and ordered question remains unchanged.
Only the tooling date and current reverify route change. No physical card or
question is added, and the collection authority is unchanged.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-tooling-current-reader-20261006/verify.py --current
```

This current role checks complete core/observer/tooling meanings and actual
direct/cache question ownership, the scoped guides, source selection, relative
endpoints, current bytes, ignore policy, indexed members and exact budgets.
Unrelated book progress is permitted. Default replay authenticates the source
and saved publication snapshot; it cannot establish current currency.
`--current --build repository-relative-output` additionally checks current native
source copies and rendered guidance. The original destination-locality replay
remains part of the tooling reverify command. Historical source-plane replay
uses its snapshot adapter; older current readers retain their exact epochs.
No old programme or seal changes. Visual QA and original/private/formatter,
class/frame/coordinate/address, host-native and broader CI/push gaps remain
separately owned.

'''


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def module(path):
    ns = {'__name__': 'tooling_prerequisite', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def load(path):
    return json.loads(path.read_bytes())


def git(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + str(path)])


def committed(root):
    raw = subprocess.check_output(['git', 'archive', REVISION, str(root)])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        return {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}


def whole(root):
    paths = list(root.iterdir())
    require(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in paths),
            'complete regular same-volume reader members')
    return {str(p): p.read_bytes() for p in paths}


def pins(blobs):
    return {p: identity(raw) for p, raw in sorted(blobs.items())}


def members():
    return {Path(p).name: identity(raw) for p, raw in whole(BASE).items() if Path(p).name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole saved reader product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed reader cannot add products')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def transform_card(before):
    old = 'docs/audits/record-value-own-boundary-publication-20261005/verify.py --current'
    new = str(BASE / 'verify.py') + ' --current'
    require(before.count(old) == 1 and before.count('date: 2026-10-05\n') == 1, 'unique tooling source date/route')
    return before.replace(old, new, 1).replace('date: 2026-10-05\n', 'date: 2026-10-06\n', 1)


def transform_chapter(before):
    guide = module(PUBLIC / 'verify.py')['GUIDE']
    require(before.count(guide) == 1 and FRAME not in before and GUIDE not in before, 'unique original observer guide')
    return before.replace(guide, FRAME + guide + GUIDE, 1)


def metadata():
    return module(Path('docs/audits/knowledge-card-rollover-20261005/verify.py'))


def expected_cards():
    return {p: transform_card(git(p).decode()) if p == TOOLING else git(p).decode() for p in PATHS}


def target_rows(text):
    rows = []
    wanted = {q for p, text in expected_cards().items() for q in metadata()['metadata'](text.encode())[1]}
    for row in text.splitlines():
        fields = row.split('\t')
        require(len(fields) == 3, 'complete actual query row grammar')
        if fields[0] in wanted or IDS.intersection(fields[1].split(',')):
            rows.append(row)
    return sorted(rows)


def current_input():
    public = module(PUBLIC / 'verify.py')
    return dict(cards={p: Path(p).read_text() for p in PATHS}, chapter=Path(CHAPTER).read_text(),
        tooling_chapter=Path(TOOLING_CHAPTER).read_text(), queries=public['queries'](),
        census=public['metrics'](public['cards']()), surface=public['authority'](Path(REGISTRY).read_bytes()),
        source_budget=next(json.loads(s) for s in Path(REGISTRY).read_text().splitlines()
                           if json.loads(s).get('surface_id') == 'book_source_manifest'))


def check_current(record):
    expected = expected_cards()
    require(record['cards'] == expected, 'complete current core observer tooling facts questions identity and routes')
    require(record['chapter'].count(FRAME) == 1 and record['chapter'].count(GUIDE) == 1
            and record['chapter'].count(COMMAND) == 1, 'unique scoped current and checkpoint reader guidance')
    public = module(PUBLIC / 'verify.py')
    public['check_current'](dict(card=record['cards'][OBSERVER], chapter=record['chapter'], queries=record['queries'],
        census=record['census'], surface=record['surface']))
    allocation = metadata()['allocation']({p: text.encode() for p, text in expected.items()})['rows'].splitlines()
    for role, result in record['queries'].items():
        require(target_rows(result['stdout']) == sorted(allocation), 'complete current core observer tooling question ownership')
    budget = next(json.loads(s) for s in git(REGISTRY).decode().splitlines()
                  if json.loads(s).get('surface_id') == 'book_source_manifest')
    require(same(record['source_budget'], budget), 'whole unchanged canonical source budget')
    plane = module(Path('scripts/book_source_references.py'))
    original = load(Path('docs/audits/book-source-plane-20261005/book-authority.json'))['block'].split('\nThe asset plane is available;', 1)[0]
    require(record['tooling_chapter'].count(original) == 1, 'unique complete raw-source and native build roles')
    for row in plane['expected_rows']():
        chapter = record['chapter'] if row['chapter'] == '13k-isf-feature-support-matrix' else record['tooling_chapter']
        require(chapter.count('](' + row['asset'] + ')') == 1, 'unique complete canonical source destination')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact reader source epoch and owner')
    require(set(binding['archives']) == {str(PUBLIC), str(PUBLIC_CHECKS)}, 'complete publication prerequisite domain')
    for root, expected in binding['archives'].items():
        actual = whole(Path(root))
        require(actual == committed(root) and same(pins(actual), expected), 'whole committed publication and actual-result members')
    for path, pin in binding['programmes'].items():
        raw = Path(path).read_bytes()
        require(raw == git(path) and same(identity(raw), pin), 'whole committed current query/source programme')
    public = module(PUBLIC / 'verify.py')
    public['authenticate'](replay=False)
    require(same(public['source_proof'](), load(PUBLIC / 'source-proof.json')), 'complete regenerated publication source proof')
    require(same(public['controls'](load(PUBLIC / 'publication.json')['snapshot']), load(PUBLIC / 'controls.json')),
            'complete regenerated publication controls')
    prior = load(CHECKS / 'prior-replay.json')
    require(type(prior['status']) is int and prior['status'] == 0 and prior['command'] ==
        ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(PUBLIC_CHECKS / 'verify_seal.py')]
        and prior['stdout'] == load(PUBLIC_CHECKS / 'independent-result.json')['stdout']
        and re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', prior['stderr']) is not None,
        'actual fresh prerequisite replay command status and default guard')
    require(set(prior['instruments']) == {str(CHECKS / 'run.py'), 'scripts/run_with_ram_guard.sh', str(PUBLIC_CHECKS / 'verify_seal.py')}
        and all(same(pin, identity(Path(p).read_bytes())) for p, pin in prior['instruments'].items()),
        'whole invocation-time prerequisite replay instruments')
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable reader seal')


def source_proof():
    public = module(PUBLIC / 'verify.py')
    before = {p: raw for p, raw in committed('docs/knowledge').items() if Path(p).parent == Path('docs/knowledge') and p.endswith('.md')}
    after = {**before, TOOLING: transform_card(before[TOOLING].decode()).encode()}
    publication = load(BASE / 'publication.json')
    require(same(publication['before_members'], pins(before)) and same(publication['after_members'], pins(after)),
            'whole source physical member conservation')
    old, new = before[TOOLING], after[TOOLING]
    require(old.split(b'\n---\n', 1)[1] == new.split(b'\n---\n', 1)[1]
        and metadata()['metadata'](old) == metadata()['metadata'](new), 'whole unchanged tooling body identity and ordered questions')
    require(len(new) <= len(old) and new.count(b'\n') == old.count(b'\n'), 'non-growing tooling card bytes and exact LF')
    require(publication['chapter_before'].encode() == git(CHAPTER) and publication['chapter_after'] == transform_chapter(publication['chapter_before']),
            'whole independently transformed checkpoint and current guide')
    logical = {**committed('docs/knowledge'), **committed('docs/decisions')}
    old_rows = metadata()['allocation']({p: raw for p, raw in logical.items() if p.endswith('.md')})['rows']
    logical[TOOLING] = new
    new_rows = metadata()['allocation']({p: raw for p, raw in logical.items() if p.endswith('.md')})['rows']
    require(old_rows == new_rows, 'whole unchanged global source-derived question population')
    for role, receipt in publication['snapshot']['queries'].items():
        require(receipt['stdout'] == new_rows, 'whole actual initial global query conservation: ' + role)
    check_current(publication['snapshot'])
    require(same(publication['snapshot']['census'], public['metrics'](after)), 'complete initial source physical census')
    book = {p: raw for p, raw in committed('docs/book/src').items() if Path(p).parent == Path('docs/book/src') and p.endswith('.md')}
    keys = ('files', 'lines_total', 'bytes_total')
    baseline = {k: public['metrics'](book)[k] for k in keys}
    book[CHAPTER] = publication['chapter_after'].encode()
    delta = {k: public['metrics'](book)[k] - baseline[k] for k in keys}
    require(same(publication['baseline'], baseline) and same(publication['delta'], delta), 'whole independently measured book aggregate')
    original_authority = next(json.loads(s) for s in git(REGISTRY).decode().splitlines()
                              if json.loads(s).get('surface_id') == 'shipped_behavior')
    current_authority = copy.deepcopy(original_authority)
    current_authority['reference_contract']['aggregate_change'] = dict(
        authority_id='TOOLING-CURRENT-READER-20261006-SHIPPED-BEHAVIOR', owner=OWNER,
        baseline=baseline, delta=delta,
        rationale='Repair the current tooling route and distinguish the retained observer checkpoint from the complete current reader.')
    require(same(publication['authority_before'], original_authority)
            and same(publication['authority_after'], current_authority), 'whole exact measured book authority')
    return dict(revision=REVISION, before=public['metrics'](before), after=public['metrics'](after),
        byte_delta=len(new)-len(old), LF_delta=new.count(b'\n')-old.count(b'\n'),
        original_tooling=old.decode(), current_tooling=new.decode(), global_query_identity=identity(new_rows.encode()),
        book_baseline=baseline, book_delta=delta,
        legs=dict(rederive='fixed-Git whole source members and independent complete metadata allocation',
                  falsify='genuine facts questions routes kinds capacity source-budget and borrowed-role interventions',
                  durability='whole saved source/current/native products plus invocation-bound actual result and manifest'),
        prerequisite_role='Fresh actual full prior-result replay is retained; original transitive native executions remain qualified saved checkpoints, not recaptures.')


def controls(record):
    cases = [
        ('tooling-body-loss', lambda r: r['cards'].update({TOOLING: r['cards'][TOOLING].replace('The original destination-locality replay remains required.', 'Locality replay is optional.')}), 'complete current core observer tooling facts questions identity and routes'),
        ('core-body-loss', lambda r: r['cards'].update({CORE: r['cards'][CORE].replace('Original classes were unmeasured.', 'Original classes were measured.').replace('original classes were unmeasured.', 'original classes were measured.')}), 'complete current core observer tooling facts questions identity and routes'),
        ('observer-loss', lambda r: r['cards'].update({OBSERVER: r['cards'][OBSERVER].replace('The parser receiver role is declared;', 'The parser role is declared;')}), 'complete current core observer tooling facts questions identity and routes'),
        ('lost-tooling-question', lambda r: r['cards'].update({TOOLING: r['cards'][TOOLING].replace('  - "why must historical source-plane replay use the helper snapshot role?"\n', '')}), 'complete current core observer tooling facts questions identity and routes'),
        ('superseded-tooling-route', lambda r: r['cards'].update({TOOLING: git(TOOLING).decode()}), 'complete current core observer tooling facts questions identity and routes'),
        ('borrowed-tooling-owner', lambda r: r['queries']['direct'].update(stdout=r['queries']['direct']['stdout'].replace('\tmdbook-build-destination-locality\t', '\tborrowed-tooling\t')), 'complete current core observer tooling question ownership'),
        ('snapshot-guide', lambda r: r.update(chapter=r['chapter'].replace(COMMAND, COMMAND.removesuffix(' --current'))), 'unique scoped current and checkpoint reader guidance'),
        ('lost-source-budget', lambda r: r['source_budget']['targets'].clear(), 'whole unchanged canonical source budget'),
        ('lost-native-role', lambda r: r.update(tooling_chapter=r['tooling_chapter'].replace('## Canonical Source Views', '## Removed Source Views', 1)), 'unique complete raw-source and native build roles'),
    ]
    out = []
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(record); mutate(candidate)
        require(not same(candidate, record), 'genuine reader intervention: ' + name)
        try:
            check_current(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended reader refusal: ' + name)
            out.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green reader intervention: ' + name)
    # The existing observer model supplies its exact typed/status/command and
    # six-dimensional capacity controls in addition to these companion seams.
    public = module(PUBLIC / 'verify.py')
    observer = dict(card=record['cards'][OBSERVER], chapter=record['chapter'], queries=record['queries'],
                    census=record['census'], surface=record['surface'])
    return dict(companion=out, observer=public['controls'](observer))


def rendered(html):
    visible = module(PUBLIC / 'verify.py')['Visible'](); visible.feed(html)
    require(visible.codes.count(COMMAND) == 1, 'native exact current companion command')
    text = ' '.join(' '.join(visible.parts).split())
    for block in (FRAME, GUIDE):
        plain = block.replace('```bash\n', '').replace('```\n', '').replace('`', '')
        require(' '.join(plain.split()) in text, 'native complete checkpoint and current companion guide')


def native_proof(html):
    rendered(html); rows = []
    for name, old, new, cause in (
        ('snapshot-command', COMMAND, COMMAND.removesuffix(' --current'), 'native exact current companion command'),
        ('borrowed-currency', 'it cannot establish current currency', 'it establishes current currency', 'native complete checkpoint and current companion guide'),
        ('invented-visual-qualification', 'Visual QA and original/private/formatter', 'Visual QA is complete and original/private/formatter', 'native complete checkpoint and current companion guide'),
    ):
        candidate = html.replace(old, new); require(candidate != html, 'genuine native companion intervention: ' + name)
        try:
            rendered(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended native companion refusal: ' + name)
            rows.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green native companion intervention: ' + name)
    return dict(input_identity=identity(html.encode()), controls=rows, visual_QA='pending; separately owned')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    require(args.current or args.build is None, 'current native build requires explicit current role')
    authenticate(); save('source-proof.json', source_proof())
    snapshot = load(BASE / 'publication.json')['snapshot']
    save('controls.json', controls(snapshot))
    save('native-proof.json', native_proof((BASE / 'native-input.html').read_text()))
    if args.current:
        check_current(current_input())
        plane = module(Path('scripts/book_source_references.py')); rows = plane['expected_rows']()
        plane['check'](rows); plane['check_index'](rows)
        subprocess.run(['python3', '-B', 'scripts/check_book_source_index.py'], check=True, stdout=subprocess.DEVNULL)
        if args.build:
            output = Path(args.build)
            require(not output.is_absolute() and '..' not in output.parts and output.resolve().is_relative_to(Path.cwd())
                    and output.stat().st_dev == Path.cwd().stat().st_dev, 'repository-relative same-volume native output')
            plane['check'](rows, args.build)
            rendered((output / '13k-isf-feature-support-matrix.html').read_text())
    if args.seal:
        save('manifest.json', members())
    print(CURRENT_SUCCESS if args.current else SUCCESS, end='')


if __name__ == '__main__':
    main()
