---
id: live-document-target-pair-calibration
title: A live-document surface's lines_each and bytes_each must imply the bytes per line it actually writes
answers:
  - "why does a live-document surface hit its line warning while byte pressure is tiny?"
  - "surface is at 81.7% and must declare warning_debt"
  - "how do I fix a lines_each target that blocks an ordinary edit?"
  - "should I raise lines_each or lower bytes_each on a live-document surface?"
  - "how were the diagnostics, active_resume, and rationale targets derived?"
  - "how big is MEMORY.md allowed to be?"
  - "what caps MEMORY.md now that active_resume allows 150 lines?"
  - "why is MEMORY.md capped at 32768 bytes?"
  - "why is docs/decisions/INDEX.md the largest member of the rationale surface?"
date: 2026-08-19
status: current
tags: [live-document-size, containment, doctrine, memory-architecture, decisions, toolbox]
evidence: docs/decisions/0065-live-document-line-and-byte-targets-are-derived-as-a-pair.md; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/ceiling_increase_authorities.jsonl; LIVE_DOCUMENT_SIZE_CONTAINMENT.md; scripts/check_memory_architecture.sh; docs/tasks/LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.md
reverify: scripts/check_live_document_size.sh 2>&1 | grep -E 'surface (diagnostics|active_resume|rationale):'
---

A surface's `lines_each` and `bytes_each` are one derivation, not two
independently chosen round numbers. Divide `bytes_each` by `lines_each`; if the
implied bytes-per-line is far from what the surface actually writes, the
milestone fires on a dimension the content cannot exhaust and an ordinary edit
is rejected at trivial pressure on the other dimension.

Decision `0065` fixes such a pair by choosing the dimension that expresses the
surface's information role and deriving the other from the measured bytes per
line; the derived limit must never reach its milestone before the reviewed one.
Applied at `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2`:

| Surface | Reviewed dimension | Change |
| --- | --- | --- |
| `diagnostics` | bytes (32 KiB reading cost) | `lines_each` 400 -> 768 |
| `active_resume` | two separate criteria | see below (revised by `0066`) |
| `rationale` | lines (prose records) | `lines_each` 512 -> 640, `bytes_each` 262144 -> 65536 |

Two exceptions are part of the rule:

- **A dimension another doctrine owns.** Decision `0066` revised this surface:
  `MEMORY.md`'s two dimensions answer different questions, so neither is derived
  from the other. **Lines** answer "is this still a pointer?" — the cap is
  `MEMORY_POINTER_LINE_CAP` = **120** in `scripts/check_memory_architecture.sh`,
  and it is the layer-routing control; the containment target of 150 puts the
  80% warning exactly on it. **Bytes** answer "can a resuming agent read it in
  one call?" — the maximum is **32,768**, an outer safety bound that does not
  bind, since 120 lines of this file is about 9,000 bytes. Never derive the line
  cap from the byte maximum: at ~75 bytes/line that yields ~440 lines, which is
  the blob `MEMORY_ARCHITECTURE.md` §1 exists to prevent.
- **A collection with more than one member class.** `rationale` holds prose
  records at ~51 bytes/line and `docs/decisions/INDEX.md`, a dense table at
  ~285 bytes/line that is the surface's largest member by bytes and grows about
  490 bytes per added record. Records bind on lines; the index binds on bytes.

Lowering a target or ceiling is free. Raising an enforcement ceiling still
needs a newly added decision record plus a matching appended
`ceiling_increase_authority` row — see [[live-document-surface-growth-procedure]],
[[live-document-size-containment]], and [[knowledge-card-sizing-and-partition]].
