# DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT: Reconcile public source-path provenance

## Metadata

- Tree ID: `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT`
- Status: `proposed`
- Roadmap lane: `downstream integration / public provenance locality`
- Created: `2026-08-11`
- Last updated: `2026-08-11`
- Owner: repo-local workflow

## Origin

The pre-push downstream-contract audit proved that check and normalized-semantic
JSON deliberately expose an absolute `source.resolved_path`. Code, public docs,
backend-parity guidance, and extensive tests agree, so the field cannot change
silently. The director authorized the repaired CI push while separating this
pre-existing compatibility/policy question into its own task tree.

## Goal

Reconcile public source-path provenance with repository-relative locality
without surprising SPECFORGE or any other downstream consumer.

## Non-Goals

- Do not retroactively classify the unchanged field as part of the hosted-CI
  failure or repair.
- Do not break the existing JSON schema or consumer workflows through an
  unversioned semantic change.
- Do not block exact hosted qualification of the already repaired pushed CI
  revision.

## Acceptance Criteria

- Select either a backward-compatible repository-relative migration or a
  narrow, explicit provenance exemption using code, schema, history, consumer,
  and locality evidence.
- Synchronize implementation, diagnostics, capability/support accounting,
  downstream handoff/contract documents, SPECFORGE guidance, mdBook, and tests
  for the selected contract.
- Preserve a documented compatibility route for current consumers.
- Pass focused public JSON/consumer tests, mdBook validation, task integrity,
  project-data locality, and the full doctrine gate.
- Commit each activated implementation slice through `COMMIT.md`.

## Task Tree

- ID: `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT`
  Status: `proposed`
  Goal: `Reconcile public source.resolved_path semantics with repository-relative locality through an explicit consumer-compatible contract.`
  Children: `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT.1, DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT.2`

- ID: `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT.1`
  Status: `pending`
  Goal: `Select the public compatibility and locality contract.`
  Acceptance: `On clean activation, inventory every producer, schema promise, consumer instruction, backend normalization, and test of source.resolved_path; compare a versioned or additive repository-relative representation with a narrow provenance exemption; record the selected contract and exact compatibility boundary in a decision record before implementation.`
  Verification: `Pending. Discovery evidence is preserved in GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.1.1 and the downstream-consumer-contract-lockstep Knowledge card.`
  Commit: `pending activation`

- ID: `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT.2`
  Status: `pending`
  Goal: `Implement and qualify the selected downstream provenance contract in lockstep.`
  Acceptance: `After .1 selects the contract, implement the smallest compatible code/schema change or explicit exemption; update all downstream contracts, SPECFORGE guidance, mdBook, capability/support surfaces, and tests; prove consumer compatibility, repository locality, and all gates.`
  Verification: `Pending .1.`
  Commit: `pending activation`

## Decisions

- `2026-08-11`: Keep this pre-existing public-contract question independent
  from the repaired CI push; exact hosted requalification may proceed first.

## Open Questions

- `.1` owns the migration-versus-exemption choice and compatibility design.

## Blockers

- Clean explicit activation after the current hosted push qualification closes.
