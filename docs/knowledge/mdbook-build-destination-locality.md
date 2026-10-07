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
  - "why did the class/frame current reader reject unrelated Knowledge Map updates?"
  - "why does historical class/frame actual-result verification reject live progress?"
date: 2026-10-07
status: current
tags: [mdbook, documentation, artifacts, locality, verification]
evidence: docs/audits/specforge-rule-admission-20260924/book-output-recovery.json; docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/audits/record-value-own-boundary-publication-20261005/scope.txt
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/specforge-rule-admission-20260924/verify-book-output-locality.py && scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py
---

`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` from the invocation
working directory, not `docs/book`. `../../.artifacts/` from the repository root therefore
escapes it. The reset publisher exposed this mistaken assumption by failing to find fresh
local HTML.

Custom builds derive fresh absolute destinations from the current root at runtime;
check containment/same-volume locality. Persist repo-relative identity; retain the actual
argument even if absolute. Build success alone cannot identify validated output.

Reset recovery copied/hash-verified both exact misplaced books, consumed
recovered HTML, deleted only those old roots and censused residue. Its first
carrier build was valid/local; the later relative-destination check reused that
render, as the historical receipt corrects. Compiler/HDL test results stay unchanged.
A tracked miniature-book probe uses another source directory to test relative/
absolute destinations from invocation cwd, requires fresh marker-bearing HTML
and local same-volume paths, then removes its workspace. Manifest retains recovery.

## Native canonical source views

Relative filesystem links connect canonical files to native-safe `.source.txt` views.
Native clicks rewrote `.md.source.txt` to `.html`; direct requests were valid.
Encode terminal `.md` as `.markdown`. Href checks qualify encoding; views preserve
complete UTF8 source/literal Markdown links.

Admitted mdBook0.5.4 serves all selected sources; default native serve refreshes a
controlled visible source outside the book directory. Even extra-watch leaves
ignored scratch/parent-ignored visible sources stale. Presence/build success proves
no watcher admission. Factory checks complete current selection/endpoints/bytes/
ignore policy; native checks every copied source. Views reflect their latest build,
without universal refresh-time/platform promises.

`python3 -B scripts/book_source_references.py --write` regenerates finite manifest/relative endpoints. `--check` qualifies current sources; `--verify-build .artifacts/BOOK_OUTPUT` also checks copied native bytes. Original destination-locality replay and recorded source-plane qualification remain required. Source/asset paths must stay inside this repository on its volume. No extra chapter/copied prose is added.

## Historical and current reader roles

A source-qualified helper-card extension obstructed original source-plane default’s old
whole-current helper call. The qualified historical adapter changes only that call to
existing helper snapshot mode; every other original predicate/programme/product conserves.
Its command is:

`python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot`

Historical success proves no current card/query/reader/source currency. Current checks
complete core/helper/tooling meanings/questions, unique book guidance, canonical
selection/endpoints/bytes/ignore policy, exact budgets and indexed members. Original
destination-locality replay and factory native copied-byte checks remain required;
visual QA stays pending.

The old class/frame current check froze unrelated card bytes/queries. This route
derives complete global source allocation.

Replay the historical result qualifier unchanged in a same-volume committed-epoch
fixture.
