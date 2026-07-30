# 0025 — Interim lifecycle split for project documents

- Date: 2026-07-30
- Type: convention
- Status: accepted (executed in `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2`)

## Context

Decision `0007` correctly stopped automatic growth across four large prose
files, but its blanket freeze treated different document roles as if they had
one lifecycle. The director clarified that FSMGen still needs a curated
technical changelog for every completed slice, while development rationale is
useful only when a slice produces a durable engineering insight. The usefulness
of the two status narratives remains an open question already owned by
`PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`.

## Decision

Until the scheduled lifecycle review selects longer-term outcomes:

1. `CHANGES.md` is live. Every completed task, slice, lane, or task-scoped
   activity adds one concise entry in the same commit. The entry names the
   work-unit id, summarizes the technical result, and records decisive
   verification. It does not duplicate the owning task-tree's full evidence
   log or replace git as the exact diff/history.
2. `DEVELOPMENT_NOTES.md` is conditional. Update it only when a slice produces
   engineering rationale, a design constraint, or a working decision that
   will help future implementation and is not better owned by a decision
   record, fact card, task-tree entry, user-facing mdBook change, or git.
   Slices that do not meet that bar add no placeholder.
3. `ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md` remain frozen and must
   not be edited before `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` reviews
   their distinct audiences and long-term usefulness.
4. Decision `0007` continues to govern bounded `MEMORY.md` and canonical
   routing through task trees, decisions, facts, the mdBook, and git. This
   decision supersedes only its blanket-freeze rule for prospective
   `CHANGES.md` and `DEVELOPMENT_NOTES.md` updates.

## Consequences

- Every future completed slice has a short human-readable change entry plus
  exact task-tree and git evidence.
- Engineering rationale is preserved when useful without recreating an
  automatic per-slice narrative blob.
- Neither status file is changed by this interim policy; their scheduled
  evidence-based review remains open and unprejudiced.
- Historical content is not rewritten retroactively.
