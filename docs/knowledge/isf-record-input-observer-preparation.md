---
id: isf-record-input-observer-preparation
title: Fixed record-input observer preparation preserves diagnostics and caller kinds
answers:
  - "why did the initial fixed record-input observer remain unqualified?"
  - "how does fixed record-input admission preserve caller JSON primitive kinds?"
  - "where is fresh record-input observer qualification owned?"
date: 2026-10-01
status: current
tags: [isf, record-ports, verification, runtime, admission]
evidence: docs/audits/record-input-observer-20261001/manifest.json; docs/audits/record-input-observer-corrected-20261001/preparation.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove docs/audits/record-input-observer-corrected-20261001/preparation.t
---

SEM .60.4.3.2.5.2.1 preserves the initial sealed finite native control evidence
but does not qualify that integration. Its independent saved verifier rejects
outer stderr because the new admission module's `return sort (...)` emits a
Perl warning. Removing only that exact warning from detached saved rows lets
all original native/result/gap/cleanup and hostile checks pass, without a
native fixture rerun. Initial source/manifest/receipts remain byte-exact.

The corrected sibling uses an explicit path array and `sort @paths`; its finite
qualifier also checks exact outer stderr. Pure fresh JSON/string-count controls
prove that aliased numeric inspection changes caller scalar flags and JSON
kinds. Detached closed root/count/digest values repair this private validator
without changing accepted values, target membership or stage limits. The CLI
explicitly owns numeric serialization of its newly constructed count packet.
The preserved actual before module still falsifies caller-kind preservation
under an isolated package name; complete caller JSON is checked after both
acceptance and refusal. The initial Storable-clone draft is excluded.

Final pure preparation and clean syntax establish preparation only. Fresh
exclusive native control qualification remains .5.2.2 and HIAL .11.5.1;
genuine direct HDL execution remains .5.3. No public wire/supervisor defect,
feature runtime signoff or historical EPERM repair follows. Actual saved
receipts and caller serialization re-derive these facts; warning-only removal,
hostile saved controls and the actual-before implementation falsify weaker
claims. Tracked sources, RED/final receipts, tests, task and Git provide durability.
