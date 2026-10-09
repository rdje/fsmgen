"""Reviewed non-growing tooling fact for finite caller expression attribution."""

REVISION = '6b3783bb03f5f0d65619dddbba31ea4fda3d0890'
QUESTION = 'why can Perl caller lines follow pattern or predicate expressions?'
READER = 'docs/audits/coordinate-expression-alternative-checks-20261009/verify_alternatives.py'
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B ' + READER
BODY = 'Public caller/compiler fixtures: helper pattern starts; live guard predicate endings; constant-only guard statement labels. Conditional source alternatives; original/private/toolchain coordinates unmeasured. [Probe](../audits/coordinate-expression-alternative-checks-20261009/verify_alternatives.py).'

# Ordered, reviewed proposition correspondence; exact original remains archived.
EDITS = (
    ('`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` from invocation cwd,\nnot `docs/book`. From repository root, `../../.artifacts/` escapes. The reset publisher\nexposed this assumption when fresh local HTML was absent.',
     '`mdbook build docs/book --dest-dir DEST`: relative `DEST` uses cwd, not `docs/book`; root `../../.artifacts/` escapes. Reset publisher found fresh local HTML absent.'),
    ('Custom builds derive fresh absolute destinations from the current root at runtime;\ncheck containment/same-volume locality. Persist repo-relative identity; retain the actual\nargument even if absolute. Build success alone cannot identify validated output.',
     'Custom builds: fresh runtime-root absolute destinations; containment/same-volume checks; persist repo-relative identity and actual arguments (even absolute). Build success cannot identify validated output.'),
    ('Reset recovery copied/hash-verified both exact misplaced books, consumed recovered\nHTML, deleted only old roots and censused residue. First carrier build was valid/local;\nthe later relative-destination check reused its render (historical receipt correction).\nCompiler/HDL results stay unchanged. Tracked miniature-book probe: another source\ndirectory; relative/absolute destinations from invocation cwd; fresh marker HTML;\nlocal same-volume paths; workspace removal. Manifest retains recovery.',
     'Reset copied/hash-verified both misplaced books, consumed recovered HTML, deleted only old roots, censused residue. First carrier valid/local; later relative-destination check reused its render (receipt correction). Compiler/HDL unchanged. Tracked miniature-book probe: other source directory, relative/absolute destinations from cwd, fresh marker HTML, same-volume local paths, workspace removal. Manifest retains recovery.'),
    ('## Native canonical source views',
     '## Native source views'),
    ('Canonical files use relative filesystem links to native-safe `.source.txt` views.\nNative clicks rewrote `.md.source.txt` to `.html` despite valid direct requests.\nEncode terminal `.md` as `.markdown`; href checks qualify encoding.\nViews retain complete UTF8 source/literal Markdown links.',
     'Relative links expose full canonical UTF8/literal Markdown as `.source.txt`. Native clicks rewrote `.md.source.txt` to `.html` despite valid direct requests. Href-checked encoding: terminal `.md` to `.markdown`.'),
    ('Admitted mdBook0.5.4 serves all selected sources; default native serve refreshes a\ncontrolled visible source outside the book directory. Even extra-watch leaves\nignored scratch/parent-ignored visible sources stale. Presence/build success proves\nno watcher admission. Factory checks complete current selection/endpoints/bytes/\nignore policy; native checks every copied source. Views reflect their latest build,\nwithout universal refresh-time/platform promises.',
     'mdBook0.5.4 serves all selected sources. Default serve refreshes controlled visible sources outside book; ignored scratch/parent-ignored sources stay stale even with extra-watch. Presence/build success proves no watcher admission. Factory checks all selection/endpoints/current bytes/ignore policy; native checks every copied source. Views reflect latest build; no universal refresh-time/platform promise.'),
    ('`python3 -B scripts/book_source_references.py`: `--write` regenerates finite manifest/relative endpoints;\n`--check` verifies current sources; `--verify-build .artifacts/BOOK_OUTPUT` checks copied native bytes.\nOriginal destination-locality replay/source-plane qualification stay required.\nSource/assets stay in this repository on its volume; views add no chapter/copied prose.',
     '`python3 -B scripts/book_source_references.py`: `--write`: finite manifest/relative endpoints; `--check`: current sources; `--verify-build .artifacts/BOOK_OUTPUT`: native copied bytes. Original destination-locality replay/source-plane qualification required. Source/assets stay in this repository/on its volume; no extra chapter/copied prose.'),
    ('## Historical and current reader roles',
     '## Historical/current reader roles'),
    ('Source-qualified helper-card extension blocked original source-plane default’s\nwhole-current helper call. Historical adapter switches only that call to existing\nhelper snapshot mode; all other original predicates/programmes/products conserve:',
     'Source helper-card extension blocked original source-plane default’s whole-current helper call. Historical adapter changes only that call to existing helper snapshot mode; other original predicates/programmes/products conserve:'),
    ('`python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot`',
     '`python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot`'),
    ('Historical pass proves no current card/query/reader/source currency. Current checks\ncomplete core/helper/tooling meanings/questions, unique book guide, canonical selection/\nendpoints/bytes/ignore policy, exact budgets/indexed members. Original destination-locality\nreplay/factory native copied-byte checks stay required; visual QA stays pending.',
     'Historical pass proves no current card/query/reader/source currency. Current checks all core/helper/tooling\nmeanings/questions, unique book guide, canonical selection/endpoints/bytes/ignore policy, exact\nbudgets/indexed members. Original destination-locality replay/factory native copied-byte checks required;\nvisual QA pending.'),
    ('The old class/frame current check froze unrelated card bytes/queries. This route\nderives complete global source allocation.',
     'Old class/frame current checking froze unrelated card bytes/queries; this route derives complete global source\nallocation.'),
    ('Replay the historical result qualifier unchanged in a same-volume committed-epoch\nfixture.',
     'Replay historical result qualifier unchanged in a same-volume committed-epoch fixture.'),
    ('[Reader](../audits/record-value-coordinate-public-reference-20261008/verify.py): dated public fixtures; original coordinates/identities unmeasured.',
     '[Reader](../audits/record-value-coordinate-public-reference-20261008/verify.py): dated public fixtures; original coordinates/identities unmeasured.'),
)

def extend(text):
    front, body = text.rsplit('---\n', 1)
    parts = body.strip().split('\n\n')
    if parts != [old for old, new in EDITS]:
        raise ValueError('complete original tooling proposition domain')
    date = 'date: 2026-10-08\n'
    if front.count(date) != 1 or QUESTION in front:
        raise ValueError('unique expression fact question and epoch')
    front = front.replace(date, '  - "' + QUESTION + '"\ndate: 2026-10-09\n', 1)
    result = front + '---\n\n' + '\n\n'.join([new for old,new in EDITS] + [BODY]) + '\n'
    if len(result.encode()) > len(text.encode()) or result.count('\n') > text.count('\n'):
        raise ValueError('non-growing expression fact bytes and lines')
    return result
