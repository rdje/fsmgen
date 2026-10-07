"""Reviewed non-growing tooling fact extension for historical result epochs."""

QUESTION = 'why does historical class/frame actual-result verification reject live progress?'
BODY = """Replay the historical result qualifier unchanged in a same-volume committed-epoch
fixture.
"""
EDITS = (
    ("""Custom builds derive a fresh absolute destination from the current root at runtime and
check containment/same-volume locality. Persist repository-relative identity; never change
the actual argument to avoid recording an absolute path. Build success alone does not
identify the validated output.
""", """Custom builds derive fresh absolute destinations from the current root at runtime;
check containment/same-volume locality. Persist repo-relative identity; retain the actual
argument even if absolute. Build success alone cannot identify validated output.
"""),
    ("""The reset slice copied and hash-verified both exact misplaced books, consumed recovered
HTML, deleted only those old roots and recorded a residue census. The first carrier build
was valid/local; the later relative-destination check reused its render. Its historical
receipt explicitly records this correction. No compiler or HDL test result changes. The
tracked miniature-book probe uses another source directory, checks relative/absolute
destinations against the invocation directory, requires fresh marker-bearing HTML and
same-volume local paths, then removes its owned workspace. The manifest retains the actual
recovery.
""", """Reset recovery copied/hash-verified both exact misplaced books, consumed
recovered HTML, deleted only those old roots and censused residue. Its first
carrier build was valid/local; the later relative-destination check reused that
render, as the historical receipt corrects. Compiler/HDL test results stay unchanged.
A tracked miniature-book probe uses another source directory to test relative/
absolute destinations from invocation cwd, requires fresh marker-bearing HTML
and local same-volume paths, then removes its workspace. Manifest retains recovery.
"""),
    ("""Relative filesystem links connect canonical repository files to native-safe `.source.txt`
views. Native clicks rewrote `.md.source.txt` to `.html` despite valid direct requests;
encode terminal `.md` as `.markdown`. Actual href checks qualify encoding. Views preserve
complete UTF8 source with literal Markdown links.
""", """Relative filesystem links connect canonical files to native-safe `.source.txt` views.
Native clicks rewrote `.md.source.txt` to `.html`; direct requests were valid.
Encode terminal `.md` as `.markdown`. Href checks qualify encoding; views preserve
complete UTF8 source/literal Markdown links.
"""),
    ("""Admitted mdBook0.5.4 serves every selected source; default native serve refreshes a
controlled visible source outside the book directory. Ignored scratch/parent-ignored
visible inputs stay stale, even with extra-watch enabled. Presence/build success do not
prove watcher admission. Executed factory checks complete selection, current
endpoints/bytes/ignore policy; native verification checks every copied source. Views
reflect their latest book build; no universal refresh-time/platform promise applies.
""", """Admitted mdBook0.5.4 serves all selected sources; default native serve refreshes a
controlled visible source outside the book directory. Even extra-watch leaves
ignored scratch/parent-ignored visible sources stale. Presence/build success proves
no watcher admission. Factory checks complete current selection/endpoints/bytes/
ignore policy; native checks every copied source. Views reflect their latest build,
without universal refresh-time/platform promises.
"""),
)


def extend(text):
    for before, after in EDITS:
        if text.count(before) != 1:
            raise ValueError('unique reviewed tooling proposition source')
        text = text.replace(before, after, 1)
    date = 'date: 2026-10-07\n'
    if text.count(date) != 1 or QUESTION in text or BODY in text:
        raise ValueError('unique tooling epoch question and source date')
    return text.replace(date, '  - "' + QUESTION + '"\n' + date, 1) + '\n' + BODY
