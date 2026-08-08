# 0053 — A portable containment-adoption guide expands the governance interface

- Date: 2026-08-08
- Type: architecture/convention
- Status: accepted
- Refines: [0041](0041-live-documents-use-bounded-views-over-durable-stores.md), [0044](0044-external-live-document-review-corrections-precede-wider-reuse.md)
- Evidence owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.27`
- Ceiling authority: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.27-FOCUSED-DOCUMENT`
- Surface: `focused_documents`
- Dimension: `files`
- Change: `1006 -> 1007`

## Context

The project-neutral live-document doctrine is reusable, but a project that has
already adopted durable memory can still lack a concise bridge from a repeatedly
full resume pointer to the wider lifecycle adoption. The doctrine defines the
target architecture; it intentionally does not diagnose one adopter's current
memory coupling or tell a director which donor metadata must not be copied.

The director requested one tracked document that can be forwarded to any such
project. Adding that durable governance interface creates one new member of the
complete `docs/*.md` focused-document collection. Its inclusive file-count
ceiling is already exact at 1,006, so the addition cannot land honestly without
a separately reviewed one-file expansion authority.

## Decision

1. Add `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md` as a
   project-neutral, non-normative bridge. The receiving project's owned copy of
   `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` remains the authority.
2. The guide covers bounded-pointer stabilization, utility-first inventory,
   lifecycle selection, local measurement, transition debt, atomic migration,
   enforcement, stop conditions, and a ready-to-forward director instruction.
3. Classify the guide as project governance in the generated complete focused
   document index and expose it from FSMGen's fenced local adoption note and
   mdBook reference map.
4. Authorize exactly one focused-document file-count ceiling increase, from
   1,006 to 1,007. No line, byte, line-width, per-part, aggregate, or other
   surface ceiling increases. The immutable adoption baseline does not change;
   finite transition growth is updated only to the resulting measured guide
   addition.
5. Do not activate or pre-decide the separately deferred legacy-continuity
   inventory. The guide supplies a reusable method, not project-specific
   lifecycle outcomes.

## Consequences

- A director can forward one concise adoption bridge together with the neutral
  doctrine instead of reconstructing the relationship conversationally.
- Receiving projects are explicitly warned not to unbound `MEMORY.md` or copy
  FSMGen thresholds, paths, registries, debt, migrations, or retention claims.
- FSMGen's focused collection grows by one reviewed governance member under an
  exact authority; every other enforcement ceiling remains unchanged.
- The guide remains discoverable without contaminating the neutral doctrine
  body with FSMGen-local navigation.
