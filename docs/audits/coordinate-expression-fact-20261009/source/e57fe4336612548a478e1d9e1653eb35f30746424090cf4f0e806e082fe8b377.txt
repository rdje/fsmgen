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
  - "where are public coordinate recipes verified?"
date: 2026-10-08
status: current
tags: [mdbook, documentation, artifacts, locality, verification]
evidence: docs/audits/specforge-rule-admission-20260924/book-output-recovery.json; docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/audits/record-value-own-boundary-publication-20261005/scope.txt
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/specforge-rule-admission-20260924/verify-book-output-locality.py && scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py
---

`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` from invocation cwd,
not `docs/book`. From repository root, `../../.artifacts/` escapes. The reset publisher
exposed this assumption when fresh local HTML was absent.

Custom builds derive fresh absolute destinations from the current root at runtime;
check containment/same-volume locality. Persist repo-relative identity; retain the actual
argument even if absolute. Build success alone cannot identify validated output.

Reset recovery copied/hash-verified both exact misplaced books, consumed recovered
HTML, deleted only old roots and censused residue. First carrier build was valid/local;
the later relative-destination check reused its render (historical receipt correction).
Compiler/HDL results stay unchanged. Tracked miniature-book probe: another source
directory; relative/absolute destinations from invocation cwd; fresh marker HTML;
local same-volume paths; workspace removal. Manifest retains recovery.

## Native canonical source views

Canonical files use relative filesystem links to native-safe `.source.txt` views.
Native clicks rewrote `.md.source.txt` to `.html` despite valid direct requests.
Encode terminal `.md` as `.markdown`; href checks qualify encoding.
Views retain complete UTF8 source/literal Markdown links.

Admitted mdBook0.5.4 serves all selected sources; default native serve refreshes a
controlled visible source outside the book directory. Even extra-watch leaves
ignored scratch/parent-ignored visible sources stale. Presence/build success proves
no watcher admission. Factory checks complete current selection/endpoints/bytes/
ignore policy; native checks every copied source. Views reflect their latest build,
without universal refresh-time/platform promises.

`python3 -B scripts/book_source_references.py`: `--write` regenerates finite manifest/relative endpoints;
`--check` verifies current sources; `--verify-build .artifacts/BOOK_OUTPUT` checks copied native bytes.
Original destination-locality replay/source-plane qualification stay required.
Source/assets stay in this repository on its volume; views add no chapter/copied prose.

## Historical and current reader roles

Source-qualified helper-card extension blocked original source-plane default’s
whole-current helper call. Historical adapter switches only that call to existing
helper snapshot mode; all other original predicates/programmes/products conserve:

`python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot`

Historical pass proves no current card/query/reader/source currency. Current checks
complete core/helper/tooling meanings/questions, unique book guide, canonical selection/
endpoints/bytes/ignore policy, exact budgets/indexed members. Original destination-locality
replay/factory native copied-byte checks stay required; visual QA stays pending.

The old class/frame current check froze unrelated card bytes/queries. This route
derives complete global source allocation.

Replay the historical result qualifier unchanged in a same-volume committed-epoch
fixture.

[Reader](../audits/record-value-coordinate-public-reference-20261008/verify.py): dated public fixtures; original coordinates/identities unmeasured.
