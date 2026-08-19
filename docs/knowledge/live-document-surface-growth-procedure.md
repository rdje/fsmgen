---
id: live-document-surface-growth-procedure
title: Live-document growth is a declared measurement; ceiling increases are reviewed
answers:
  - "how do I add a new knowledge fact card?"
  - "adding a fact card fails the live document size check, what do I do?"
  - "how do I grow a live-document surface that is at its declared allowance?"
  - "what does transition max_growth mean and who may change it?"
  - "how is a live-document enforcement ceiling increased?"
  - "what is doctrine/live_document_size/ceiling_increase_authorities.jsonl for?"
  - "surface knowledge_cards transition debt exceeded its owned allowance"
  - "unauthorized enforcement-ceiling increase requires exactly one new authority record"
  - "surface is at 80.0% and must declare warning_debt"
  - "may I delete knowledge cards or prose to fit a live-document budget?"
  - "how do I add a knowledge map card or write a fact card?"
  - "what is the knowledge card ceiling and how do I raise a fact card ceiling?"
  - "what is a ceiling increase authority record and when do I need one?"
  - "what does max_growth mean in doctrine/live_document_size/surfaces.jsonl?"
  - "why must a surface declare warning_debt at 80 percent?"
  - "surface knowledge_cards transition debt exceeded its owned allowance: files"
  - "does adding a fact card need a decision record?"
  - "live document size check failed on a knowledge card edit"
date: 2026-08-19
status: current
tags: [live-document-size, knowledge-map, doctrine, containment, ceilings]
evidence: >-
  docs/decisions/0064-live-document-growth-is-declared-measurement-with-paired-decisions.md;
  LIVE_DOCUMENT_SIZE_CONTAINMENT.md;
  doctrine/live_document_size/surfaces.jsonl;
  doctrine/live_document_size/ceiling_increase_authorities.jsonl;
  scripts/check_live_document_size.sh;
  scripts/check_live_document_ceiling_authority.pl
reverify: >-
  scripts/check_live_document_size.sh 2>&1 | grep 'surface knowledge_cards:'
---

Adding an ordinary fact card is a normal write. Decision `0064` raised the
`knowledge_cards` collection ceilings to the surface's own reviewed health
targets, so a card needs no decision record, authority row, or ceiling change.

Two mechanisms are separate. Raising a surface's `transition.max_growth` to the
new measured actual, inside an unchanged ceiling, is a **declared measurement**
and needs no authority record. Raising an `enforcement_ceilings` value is a
**reviewed increase**: it needs one `ceiling_increase_authority` row whose
`decision` names a `docs/decisions/NNNN-*.md` record added in the same commit,
which `check_live_document_ceiling_authority.pl` enforces via `--diff-filter=A`.

Read current pressure rather than a copied number with
`scripts/check_live_document_size.sh 2>&1 | grep 'surface <ID>:'`.

Never delete or thin a recorded fact to fit a budget; compaction removes only
duplicated or superseded narration. Some surfaces sit just under their 80%
warning milestone, so one added line trips `must declare warning_debt` — rewrite
a line in place or route the content to the surface whose role owns it.

A collection ceiling cannot relieve a per-file bound. When one member is at its
own `lines_each` / `bytes_each` / `line_bytes_each` limit, partition that member
by topic instead of growing anything — see
[[knowledge-card-sizing-and-partition]].

For the enforced rule, read the registries and the two guards;
`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` carries the same rule as rationale plus the
local procedure. Related: [[live-document-size-containment]].
