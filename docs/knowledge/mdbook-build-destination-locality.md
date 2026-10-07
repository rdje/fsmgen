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
date: 2026-10-06
status: current
tags: [mdbook, documentation, artifacts, locality, verification]
evidence: docs/audits/specforge-rule-admission-20260924/book-output-recovery.json; docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/audits/record-value-own-boundary-publication-20261005/scope.txt
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/specforge-rule-admission-20260924/verify-book-output-locality.py && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-20261006/verify.py --current
---

`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` from the invocation
working directory, not `docs/book`. `../../.artifacts/` from the repository root therefore
escapes it. The reset publisher exposed this mistaken assumption by failing to find fresh
local HTML.

Custom builds derive a fresh absolute destination from the current root at runtime and
check containment/same-volume locality. Persist repository-relative identity; never change
the actual argument to avoid recording an absolute path. Build success alone does not
identify the validated output.

The reset slice copied and hash-verified both exact misplaced books, consumed recovered
HTML, deleted only those old roots and recorded a residue census. The first carrier build
was valid/local; the later relative-destination check reused its render. Its historical
receipt explicitly records this correction. No compiler or HDL test result changes. The
tracked miniature-book probe uses another source directory, checks relative/absolute
destinations against the invocation directory, requires fresh marker-bearing HTML and
same-volume local paths, then removes its owned workspace. The manifest retains the actual
recovery.

## Native canonical source views

Relative filesystem links connect canonical repository files to native-safe `.source.txt`
views. Native clicks rewrote `.md.source.txt` to `.html` despite valid direct requests;
encode terminal `.md` as `.markdown`. Actual href checks qualify encoding. Views preserve
complete UTF8 source with literal Markdown links.

Admitted mdBook0.5.4 serves every selected source; default native serve refreshes a
controlled visible source outside the book directory. Ignored scratch/parent-ignored
visible inputs stay stale, even with extra-watch enabled. Presence/build success do not
prove watcher admission. Executed factory checks complete selection, current
endpoints/bytes/ignore policy; native verification checks every copied source. Views
reflect their latest book build; no universal refresh-time/platform promise applies.

`python3 -B scripts/book_source_references.py --write` regenerates finite manifest/relative endpoints. `--check` qualifies current sources; `--verify-build .artifacts/BOOK_OUTPUT` also checks copied native bytes. Original destination-locality replay and recorded source-plane qualification remain required. Source/asset paths must stay inside this repository on its volume. No extra chapter/copied prose is added.

## Historical and current reader roles

A source-qualified helper-card extension obstructed original source-plane default’s old
whole-current helper call. The qualified historical adapter changes only that call to
existing helper snapshot mode; every other original predicate/programme/product conserves.
Its command is:

`python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot`

Historical success does not establish current card/query/reader/source currency. Current
publication checks complete core/helper/tooling meanings/question ownership, unique book
guidance, canonical selection/endpoints/bytes/ignore policy, exact current budget and
indexed members. Original destination-locality replay remains required. Explicit factory
output checks remain required for native copied bytes; visual QA stays pending.
