# ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC: Sync Downstream/Contract Docs With Recent Diagnostics

## Metadata

- Tree ID: `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

The recent diagnostic-precision and book-coverage slices updated
`docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` (the downstream integration
spec) but did not propagate to:

1. **`docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`** — the contract doc.
   References `t/1366`/`t/1369`/`t/1370`/`t/1371` for the
   activation-override gate family but does not yet mention `t/1372`
   (cross-domain repeat-body do), `t/1373` (timing-param sub-axes),
   `t/1374` (loop-contained), `t/1375` (deeper-nested), or `t/1376`
   (book-example lowering). The contract's wording for the override
   gate still describes a single static-timing diagnostic rather than
   the four sub-axis-specific ones now emitted.
2. **`docs/SPECFORGE_FEEDBACK_RESPONSE.md`** — has zero matches for
   any of the new diagnostics or tests; the diagnostic-precision
   posture is not reflected.

The user explicitly flagged this as a gap. The slice propagates the
relevant wording and test references to both docs.

## Non-Goals

- Do not restructure either document; only add/update relevant
  paragraphs.
- Do not change validator behavior or tests.
- Do not rewrite the SPECFORGE response history; only append a new
  status section that reflects the current diagnostic surface.

## Acceptance Criteria

- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`:
    * activation-override test list expanded to include `t/1372`,
      `t/1373`, `t/1374`, `t/1375`,
    * sub-axis diagnostic wording added alongside the existing
      "static-timing" description,
    * loop-contained and deeper-nested diagnostic wording added
      alongside the existing "branch nesting and loop-contained
      repeats remain" sentence,
    * `t/1376` (book-example lowering build gate) referenced as
      a doc-correctness regression.
- `docs/SPECFORGE_FEEDBACK_RESPONSE.md`:
    * a new dated section summarizing the diagnostic-precision
      slices shipped this cycle (cross-domain repeat-body do,
      timing-param sub-axes, loop-contained, deeper-nested) and
      the book-example lowering build gate.
- mdBook builds clean (the contract doc is included via `13i`);
  `git diff --check` clean. Audits `t/1305`, `t/1307`, `t/1332`,
  `t/1376` continue to pass.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC`
  Status: `pending`
  Goal: `Sync downstream/contract handoff docs with the recent diagnostic surface.`
  Children:
    `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.1`,
    `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.2`

- ID: `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.1`
  Status: `pending`
  Goal: `Select the slice.`
  Acceptance: `Task tree exists.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.2`
  Status: `pending`
  Goal: `Ship the contract and SPECFORGE doc updates plus live-doc syncs.`
  Acceptance: `Both docs mention t/1372-t/1376 and the new diagnostic wording; audits still pass.`
  Verification: `prove -Iperl t/1305 t/1307 t/1332 t/1376; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` updated both docs and reverified audits. |

## Decisions

- `2026-05-29`: Keep the SPECFORGE_FEEDBACK_RESPONSE update as a
  single dated addendum rather than rewriting the entire document.
  The original responses are historical record.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-29` | `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.2` | `prove -Iperl t/1305 t/1307 t/1332 t/1376` (Files=4, Tests=711); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.1` | `a2d12eb0 ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.1: select downstream/contract handoff sync` | Selection commit. |
| `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.2` | `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.2: ship downstream/contract handoff sync` | `pending` |

## Changelog

- `2026-05-29`: Created per user question whether handoff
  documents for downstream consumers and public API contract
  stabilization were updated.
- `2026-05-29`: Shipped `.2`.
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` activation-override
  section now references `t/1372` (cross-domain), `t/1373`
  (sub-axes), `t/1374` (loop-contained), `t/1375` (deeper-nested),
  and `t/1376` (book-example lowering) plus the matching
  diagnostic wording. `docs/SPECFORGE_FEEDBACK_RESPONSE.md` gained
  a dated "Diagnostic-Precision And Book-Coverage Status" addendum
  summarizing the targeted rejection diagnostics, the
  `lisp` vs `text` block convention, the book example lowering
  build gate, the cookbook ISF recipes, and the current audit set.
