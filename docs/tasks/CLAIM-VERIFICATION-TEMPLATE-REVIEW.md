# CLAIM-VERIFICATION-TEMPLATE-REVIEW: Review the selected template revision

## Metadata

- Tree ID: `CLAIM-VERIFICATION-TEMPLATE-REVIEW`
- Status: `proposed`
- Roadmap lane: `evidence architecture`
- Created: `2026-09-06`
- Last updated: `2026-09-06`
- Owner: repo-local workflow

## Goal

Review the director-selected claim-verification template changes against the
locally authoritative policy before deliberately selecting any adoption.

## Non-Goals

No automatic upstream synchronization, imported deployment claims, changed
quantitative gates, or interruption of the owned CI startup repairs.

## Acceptance Criteria

Classify every template delta; accept, adapt, or reject each with local
rationale; own any policy/checker/book implementation before changing it.

## Task Tree

- ID: `CLAIM-VERIFICATION-TEMPLATE-REVIEW`
  Status: `proposed`
  Goal: `Review the changed template without silently replacing local authority.`
  Children: `CLAIM-VERIFICATION-TEMPLATE-REVIEW.1`

- ID: `CLAIM-VERIFICATION-TEMPLATE-REVIEW.1`
  Status: `proposed`
  Goal: `Select the locally useful template revisions and their enforcement limits.`
  Acceptance: `Disposition the domain-free rule, evidence granularity, reversible attribution, bidirectional set census, history oracle, challenged-claim grading, and revised examples; separate exact contracts from judgment and never require unsupported certainty.`
  Verification: `The 2026-09-06 read-only comparison requested by the director found the local neutral-body SHA-256 8f194574ec718749e90a402cf6e4dc6650e44f6185dd194853a54482eef68643 still equals its adoption identity, while the selected sibling-project template now hashes to 9f99df25209c43afb74d77e348dd2d0cdb68ce96cf17a4f272ede8328f6046bd. A full unified body diff independently identifies the listed additions. The external source was caller-authorized, read-only, and on the repository volume; it is a template, not an upstream. Decision 0074 remains authoritative. This record preserves the discovery; adoption is not selected.`
  Commit: `pending selection`

## Decisions

- Preserve decision `0047` and conditional rationale updates, as reconfirmed by
  the director during startup. Do not restore the retired changelog.
- The selected input is the sibling PGEN `docs/CLAIM_VERIFICATION.md`; derive
  its physical root from the current checkout's sibling directory at review.
  No machine-specific absolute path is persisted.

## Open Questions

- Which revisions warrant a local policy change, and which can be enforced
  honestly rather than implying that a structural checker proves judgment?

## Blockers

- Proposed behind the active CI startup-repair frontier; no implementation
  authorization is inferred merely from a changed external template.
