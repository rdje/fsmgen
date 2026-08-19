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
  - "have all the live-document target pairs been checked, or only the ones that failed?"
  - "why did root_documents allow 12000 lines per root markdown file?"
  - "how is a multi-class collection's bytes_each derived?"
date: 2026-08-19
status: current
tags: [live-document-size, containment, doctrine, memory-architecture, decisions, toolbox]
evidence: docs/decisions/0069-live-document-target-pairs-are-swept-not-fixed-under-pressure.md; docs/decisions/0065-live-document-line-and-byte-targets-are-derived-as-a-pair.md; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/ceiling_increase_authorities.jsonl; LIVE_DOCUMENT_SIZE_CONTAINMENT.md; scripts/check_memory_architecture.sh; docs/tasks/LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.md
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

`LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.1` and decision `0069` swept every
declared pair rather than waiting for the next milestone to fire, because
which surface fires first is decided by which round number happened to be
tightest. All nineteen surfaces that declare health targets were measured; nine
pairs were re-derived and the rest were already one derivation or a recorded
divergence.

| Surface | Reviewed dimension | Change |
| --- | --- | --- |
| `enforced_rules` | bytes (32 KiB mandatory read) | `lines_each` 300 -> 576 |
| `high_level_direction` | lines | `bytes_each` 65536 -> 32768 |
| `active_index` | lines | `bytes_each` 196608 -> 81920 |
| `fact_index` | lines | `bytes_each` 131072 -> 45056 |
| `engineering_rationale` | lines (ledger window) | `bytes_each` 262144 -> 131072 |
| `shipped_behavior` | lines (per part) | `bytes_each` 524288 -> 409600 |
| `isf_reference` | lines (per part) | `bytes_each` 524288 -> 425984 |
| `root_documents` | lines | `lines_each` 12000 -> 1200, `bytes_each` -> 81920 |
| `rationale` | lines (aggregate) | `bytes_total` 2097152 -> 655360 |

Only `enforced_rules` rose, so only it needed authority; the other eight are
lowerings that remove headroom the content could never reach. Two further
rules come out of that sweep:

- **A multi-class collection derives its byte dimension from the densest member
  that can actually reach the line bound, not from the collection mean.**
  `shipped_behavior` and `isf_reference` are derived from a 70.5 and a 73.6
  bytes-per-line chapter, because the ~52 and ~60 means would let a dense
  chapter fire on bytes before the reviewed line bound.
- **A re-derivation that creates a new warning is not a calibration.** Check
  each proposed value against current usage before writing it.
