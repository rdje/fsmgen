---
id: ial2-ahb-current-boundary-mdbook-coverage
title: AHB mdBook coverage documents only the current direct FSM boundary
answers:
  - "where is the AHB current-boundary mdBook chapter?"
  - "is AHB IAL2 shipped?"
  - "is .ahb accepted by fsmgen?"
  - "what AHB support exists today?"
  - "what must happen before AHB guided more-control or raw full-control IAL2 modes ship?"
date: 2026-06-29
status: current
tags: [ial2, ahb, amba, mdbook, protocol-intent, profile-alias, documentation]
evidence: docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; fsm/amba_requester.fsm; perl/FSM/Support/RegressionCorpus.pm; bin/fsmgen; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'AHB Current Boundary|fsm/amba_requester\.fsm|protocol\.amba_requester|source_kind: fsm|source suffix.*\.ahb.*known IAL2 alias candidate|unsupported_ial2_alias_suffix|Future IAL2 Task-Tree Prerequisites|16c-ial2-ahb' docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/SUMMARY.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/Support/RegressionCorpus.pm bin/fsmgen
---

`docs/book/src/16c-ial2-ahb.md` is the user-facing AHB current-boundary
chapter under the IAL2 protocol/platform intent mdBook section.

The chapter documents only current direct `.fsm` AHB coverage:
`fsm/amba_requester.fsm`, support-accounted as `protocol.amba_requester` with
`source_kind` `fsm` and coverage `direct_root_pipeline_cli`.

AHB IAL2 is not shipped. There are no checked-in `ppif/*ahb*` examples, `.ahb`
remains a known unsupported IAL2 alias candidate, no generated AHB `.isf` or
generated AHB `.fsm` review-artifact chain is selected, and no
`FSM::IAL2::ProtocolIntent::Ahb*` implementation module exists.

Future AHB guided, more-control, and raw/full-control IAL2 modes need
task-tree-owned readiness, contract, implementation, examples, reports,
support accounting, diagnostics, mdBook, Knowledge Map, and validation gates
before they can become user-facing behavior.
