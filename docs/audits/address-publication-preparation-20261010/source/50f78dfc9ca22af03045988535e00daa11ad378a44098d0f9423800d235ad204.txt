---
id: mdbook-build-destination-locality
title: mdBook custom destinations resolve from invocation cwd
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
  - "why can Perl caller lines follow pattern or predicate expressions?"
date: 2026-10-10
status: current
tags: [mdbook, documentation, artifacts, locality, verification]
evidence: docs/audits/specforge-rule-admission-20260924/book-output-recovery.json; docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/audits/record-value-own-boundary-publication-20261005/scope.txt
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/specforge-rule-admission-20260924/verify-book-output-locality.py && scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py
---

`mdbook build docs/book --dest-dir DEST`: relative `DEST` uses cwd, not `docs/book`; root `../../.artifacts/` escapes.
Reset publisher found fresh local HTML absent.

Custom builds: fresh runtime-root absolute destinations; containment/same-volume checks; persist repo-relative identity
and actual arguments (even absolute). Build success cannot identify validated output.

Reset copied/hash-verified both misplaced books, consumed recovered HTML, deleted only old roots, censused residue.
First carrier valid/local; later relative-destination check reused its render (receipt correction). Compiler/HDL
unchanged. Tracked miniature-book probe: other source directory, relative/absolute destinations from cwd, fresh marker
HTML, same-volume local paths, workspace removal. Manifest retains recovery.

## Native source views

Relative links expose full canonical UTF8/literal Markdown as `.source.txt`. Native clicks rewrote `.md.source.txt` to
`.html` despite valid direct requests. Href-checked encoding: terminal `.md` to `.markdown`.

mdBook0.5.4 serves all selected sources. Default serve refreshes controlled visible sources outside book; ignored
scratch/parent-ignored sources stay stale even with extra-watch. Presence/build success proves no watcher admission.
Factory checks all selection/endpoints/current bytes/ignore policy; native checks every copied source. Views reflect
latest build; no universal refresh-time/platform promise.

`python3 -B scripts/book_source_references.py`: `--write`: finite manifest/relative endpoints; `--check`: current
sources; `--verify-build .artifacts/BOOK_OUTPUT`: native copied bytes. Original destination-locality replay/source-plane
qualification required. Source/assets stay in this repository/on its volume; no extra chapter/copied prose.

## Historical/current reader roles

Source helper-card extension blocked original source-plane default’s whole-current helper call. Historical adapter
changes only that call to existing helper snapshot mode; other original predicates/programmes/products conserve:

`python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot`

Historical pass proves no current card/query/reader/source currency. Current checks all core/helper/tooling
meanings/questions, unique book guide, canonical selection/endpoints/bytes/ignore policy, exact budgets/indexed members.
Original destination-locality replay/factory native copied-byte checks required; visual QA pending.

Old class/frame current checking froze unrelated card bytes/queries; this route derives complete global source
allocation.

Replay historical result qualifier unchanged in a same-volume committed-epoch fixture.

[Public reader](../audits/record-value-coordinate-public-reference-20261008/verify.py) alone leaves original
coordinates/identities unmeasured; separate [original
reader](../audits/coordinate-original-hostile-checks-20261009/verify_hostile.py) qualifies own coordinates.
Private/toolchain/identity/external coordinates remain unmeasured; current checks also govern parser facts.

Public caller/compiler fixtures: helper pattern starts; live guard predicate endings; constant-only guard statement
labels. Conditional source alternatives; original/private/toolchain coordinates unmeasured.
[Probe](../audits/coordinate-expression-alternative-checks-20261009/verify_alternatives.py).
