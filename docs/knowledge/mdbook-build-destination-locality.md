---
id: mdbook-build-destination-locality
title: mdBook custom destinations resolve from the invocation working directory
answers:
  - "where does mdbook build resolve a relative dest-dir?"
  - "how do book verification scripts keep output inside the repository?"
  - "what caused the reset-slice book output locality recovery?"
  - "do canonical source symlinks outside the book refresh under native serve?"
  - "why do native book source-view addresses encode terminal markdown extensions?"
  - "why must historical source-plane replay use the helper snapshot role?"
date: 2026-10-05
status: current
tags: [mdbook, documentation, artifacts, locality, verification]
evidence: docs/audits/specforge-rule-admission-20260924/book-output-recovery.json; docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/audits/record-value-own-boundary-publication-20261005/scope.txt
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/specforge-rule-admission-20260924/verify-book-output-locality.py && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-own-boundary-publication-20261005/verify.py --current
---

`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` against the
invocation working directory, not `docs/book`. Therefore `../../.artifacts/`
from the repository root escapes the repository. The reset-slice publisher
exposed that mistaken assumption when it could not find fresh local HTML.

Custom-output automation must derive an absolute destination from the current
repository root at runtime, check it remains inside the root and on its volume,
and start with a fresh destination. Persist its repository-relative identity;
never change the actual tool argument merely to avoid recording an absolute
path. Build success alone does not identify the output consumed by validation.

The owning reset slice copied and hash-verified both exact misplaced books,
consumed their recovered HTML, deleted only those old roots, and recorded the
residue census. The first carrier build had been valid and local; the later
relative-destination check reused that earlier render. Its historical receipt
now explicitly records the correction. No compiler or HDL test result changes.
The tracked probe builds a miniature book from another source directory,
checks relative and absolute destinations against the invocation directory,
requires fresh marker-bearing HTML and same-volume local paths, then removes
its owned temporary workspace. The manifest retains the actual recovery.


## Native canonical source views

The selected source-view plane uses relative filesystem links to canonical
repository files and native-safe `.source.txt` addresses. A terminal `.md` in
the address is encoded as `.markdown`: the initial `.md.source.txt` recipe
served a directly requested asset but native rendered clicks were rewritten
to `.html`. Actual href checks qualify the encoded recipe. Views preserve
complete UTF8 source text; Markdown links inside them remain literal text.

The admitted mdBook0.5.4 prototype serves every selected source and refreshes
a controlled visible source outside the book directory under default native
serve. Ignored scratch and deliberately parent-ignored visible inputs remain
stale, including with extra-watch enabled. Source presence and successful
build do not prove watcher admission. The executed factory checks complete
selection, current source endpoints/bytes and ignore policy; native output
verification additionally checks every copied source. Published views reflect
their latest book build, without a universal refresh-time or platform promise.

`python3 -B scripts/book_source_references.py --write` regenerates the finite
manifest and relative endpoints. `--check` qualifies current sources;
`--verify-build .artifacts/BOOK_OUTPUT` also checks copied native bytes. The
original destination-locality replay remains required, alongside the recorded
source-plane qualifier. Source and asset paths must remain on the repository
volume and within this repository. No extra chapter or copied prose is added.

## Historical and current reader roles

An actual source-qualified helper-card extension obstructed the original
source-plane default replay because it invoked the old whole-current helper
reader. The qualified historical adapter changes only that call to the helper
reader's existing snapshot mode, conserving every other original predicate,
programme and product. Its command is:

`python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot`

Historical success does not establish current card, query, reader or source
currency. The current publication reader checks complete core/helper/tooling
meanings and question ownership, unique book guidance, canonical source-view
selection/endpoints/bytes/ignore policy, exact current budget and indexed members.
The original destination-locality replay remains required. Native copied bytes
still need the factory's explicit output check; visual QA remains pending.
