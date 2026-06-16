# ISF-VERIFICATION-OBSERVATION-METADATA: IAL1 Passive Observation Metadata

## Metadata

- Tree ID: `ISF-VERIFICATION-OBSERVATION-METADATA`
- Status: `active`
- Roadmap lane: `Verification code generation / IAL1 source feature`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Ship the first IAL1 verification-specific source feature: actor-level passive
observation metadata that records which public interface signals a future
generated verification component should observe.

## Non-Goals

- Do not generate SV/UVM, VHDL, PSL, testbench, scoreboard, coverage, or VIP
  artifacts in this tree.
- Do not change scheduled `.fsm`, generated RTL/HDL, inline assertion
  lowering, or existing support-accounted behavior except for the additive
  report/manifest surfaces selected here.
- Do not accept transaction objects, observed events, expected/actual pairing,
  aggregate paths, child endpoints, clock-domain overrides, or direct IAL2
  annotations in the first slice.
- Do not treat the observation metadata as a complete verification-output
  contract; it is the first source prerequisite only.

## Acceptance Criteria

- The actor-body source form
  `(observe NAME (role passive_monitor) (signals SIG...))` is accepted and
  validated exactly as selected by
  `docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md`.
- Successful schedule JSON additively exposes `verification_observations[]`
  with stable public contract metadata for entry keys, signal-entry keys, and
  role values.
- Accepted observation declarations are report-only: no scheduled states, no
  generated `.fsm` carrier, no HDL, and no verification-output artifact is
  emitted.
- Malformed observation declarations fail closed with targeted diagnostics.
- Support accounting, focused tests, CLI/in-process report parity, mdBook,
  README/roadmap/task index, Memory, and Knowledge Map are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-VERIFICATION-OBSERVATION-METADATA`
  Status: `active`
  Goal: `Ship bounded actor-level passive observation metadata for future verification-code generation.`
  Children: `ISF-VERIFICATION-OBSERVATION-METADATA.1`

- ID: `ISF-VERIFICATION-OBSERVATION-METADATA.1`
  Status: `pending`
  Goal: `Implement actor-level passive observation metadata and schedule-report projection.`
  Acceptance: `Parser accepts the exact actor-body observe form, rejects malformed/unsupported variants, records source-ordered interface signal observations, report JSON exposes verification_observations[] through advertised public contract keys, support accounting and a supported-smoke fixture cover the feature, mdBook documents a runnable example, and generated .fsm/HDL behavior remains unchanged.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `pending` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` selected this exact source prerequisite before any SV/UVM, VHDL-oriented, direct IAL2, or public verification-output behavior. |

## Decisions

- `2026-06-16`: Select actor-level passive observation metadata as the first
  IAL1 verification-specific source feature. It follows existing report-only
  actor metadata precedent, but uses a dedicated `verification_observations[]`
  schedule-report family so generated verification tooling does not bind to
  generic phase/stage metadata.

## Open Questions

- What transaction/event object model should follow once passive signal
  observations ship?
- Which SV/UVM output family should consume this source contract first?
- Whether IAL2 protocol facts should later annotate IAL1 observations remains
  owned by `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`.

## Blockers

- None for `.1`.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `pending` | `pending` |

## Changelog

- `2026-06-16`: Created active implementation owner tree from
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`.

