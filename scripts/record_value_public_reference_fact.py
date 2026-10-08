"""Reviewed non-growing tooling route for dated public coordinate fixtures."""

QUESTION = 'where are public coordinate recipes verified?'
READER = 'docs/audits/record-value-coordinate-public-reference-20261008/verify.py'
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B ' + READER
SUCCESS = 'PASS complete finite public recipe reference and genuine controls; no original-coordinate intake or capture execution.\n'
BODY = '\n[Reader](../audits/record-value-coordinate-public-reference-20261008/verify.py): dated public fixtures; original coordinates/identities unmeasured.\n'

# Each replacement conserves the named reviewed proposition set. The exact
# predecessor remains versioned; no source, receipt, original question or
# independently qualified behaviour is removed.
EDITS = (
    ('invocation-and-reset-diagnosis',
     '''`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` from the invocation
working directory, not `docs/book`. `../../.artifacts/` from the repository root therefore
escapes it. The reset publisher exposed this mistaken assumption by failing to find fresh
local HTML.
''',
     '''`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` from invocation cwd,
not `docs/book`. From repository root, `../../.artifacts/` escapes. The reset publisher
exposed this assumption when fresh local HTML was absent.
'''),
    ('reset-recovery-and-independent-probe',
     '''Reset recovery copied/hash-verified both exact misplaced books, consumed
recovered HTML, deleted only those old roots and censused residue. Its first
carrier build was valid/local; the later relative-destination check reused that
render, as the historical receipt corrects. Compiler/HDL test results stay unchanged.
A tracked miniature-book probe uses another source directory to test relative/
absolute destinations from invocation cwd, requires fresh marker-bearing HTML
and local same-volume paths, then removes its workspace. Manifest retains recovery.
''',
     '''Reset recovery copied/hash-verified both exact misplaced books, consumed recovered
HTML, deleted only old roots and censused residue. First carrier build was valid/local;
the later relative-destination check reused its render (historical receipt correction).
Compiler/HDL results stay unchanged. Tracked miniature-book probe: another source
directory; relative/absolute destinations from invocation cwd; fresh marker HTML;
local same-volume paths; workspace removal. Manifest retains recovery.
'''),
    ('factory-modes-locality-and-retained-replays',
     '''`python3 -B scripts/book_source_references.py --write` regenerates finite manifest/relative endpoints. `--check` qualifies current sources; `--verify-build .artifacts/BOOK_OUTPUT` also checks copied native bytes. Original destination-locality replay and recorded source-plane qualification remain required. Source/asset paths must stay inside this repository on its volume. No extra chapter/copied prose is added.
''',
     '''`python3 -B scripts/book_source_references.py`: `--write` regenerates finite manifest/relative endpoints;
`--check` verifies current sources; `--verify-build .artifacts/BOOK_OUTPUT` checks copied native bytes.
Original destination-locality replay/source-plane qualification stay required.
Source/assets stay in this repository on its volume; views add no chapter/copied prose.
'''),
    ('helper-intervention-and-snapshot-conservation',
     '''A source-qualified helper-card extension obstructed original source-plane default’s old
whole-current helper call. The qualified historical adapter changes only that call to
existing helper snapshot mode; every other original predicate/programme/product conserves.
Its command is:
''',
     '''Source-qualified helper-card extension blocked original source-plane default’s
whole-current helper call. Historical adapter switches only that call to existing
helper snapshot mode; all other original predicates/programmes/products conserve:
'''),
    ('current-roles-and-native-obligations',
     '''Historical success proves no current card/query/reader/source currency. Current checks
complete core/helper/tooling meanings/questions, unique book guidance, canonical
selection/endpoints/bytes/ignore policy, exact budgets and indexed members. Original
destination-locality replay and factory native copied-byte checks remain required;
visual QA stays pending.
''',
     '''Historical pass proves no current card/query/reader/source currency. Current checks
complete core/helper/tooling meanings/questions, unique book guide, canonical selection/
endpoints/bytes/ignore policy, exact budgets/indexed members. Original destination-locality
replay/factory native copied-byte checks stay required; visual QA stays pending.
'''),
    ('native-source-links-and-encoding',
     '''Relative filesystem links connect canonical files to native-safe `.source.txt` views.
Native clicks rewrote `.md.source.txt` to `.html`; direct requests were valid.
Encode terminal `.md` as `.markdown`. Href checks qualify encoding; views preserve
complete UTF8 source/literal Markdown links.
''',
     '''Canonical files use relative filesystem links to native-safe `.source.txt` views.
Native clicks rewrote `.md.source.txt` to `.html` despite valid direct requests.
Encode terminal `.md` as `.markdown`; href checks qualify encoding.
Views retain complete UTF8 source/literal Markdown links.
'''),
)


def extend(text):
    original_bytes = len(text.encode('utf-8'))
    for name, before, after in EDITS:
        if text.count(before) != 1:
            raise ValueError('unique reviewed public-reference tooling proposition: ' + name)
        text = text.replace(before, after, 1)
    date = 'date: 2026-10-07\n'
    if text.count(date) != 1 or QUESTION in text or BODY in text:
        raise ValueError('unique public-reference tooling question and source epoch')
    result = text.replace(date, '  - "' + QUESTION + '"\ndate: 2026-10-08\n', 1) + BODY
    if len(result.encode('utf-8')) > original_bytes:
        raise ValueError('public-reference tooling extension must not grow physical card bytes')
    return result
