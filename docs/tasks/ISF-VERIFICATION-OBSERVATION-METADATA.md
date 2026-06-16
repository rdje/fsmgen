# ISF-VERIFICATION-OBSERVATION-METADATA: IAL1 Passive Observation Metadata

## Metadata

- Tree ID: `ISF-VERIFICATION-OBSERVATION-METADATA`
- Status: `done`
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
  Status: `done`
  Goal: `Ship bounded actor-level passive observation metadata for future verification-code generation.`
  Children: `ISF-VERIFICATION-OBSERVATION-METADATA.1`

- ID: `ISF-VERIFICATION-OBSERVATION-METADATA.1`
  Status: `done`
  Goal: `Implement actor-level passive observation metadata and schedule-report projection.`
  Acceptance: `Parser accepts the exact actor-body observe form, rejects malformed/unsupported variants, records source-ordered interface signal observations, report JSON exposes verification_observations[] through advertised public contract keys, support accounting and a supported-smoke fixture cover the feature, mdBook documents a runnable example, and generated .fsm/HDL behavior remains unchanged.`
  Verification: `passed`
  Commit: `ISF-VERIFICATION-OBSERVATION-METADATA.1: ship observation metadata`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `done` | Shipped the selected report-only observation metadata prerequisite; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` can now select the first SV/UVM output contract. |

## Decisions

- `2026-06-16`: Select actor-level passive observation metadata as the first
  IAL1 verification-specific source feature. It follows existing report-only
  actor metadata precedent, but uses a dedicated `verification_observations[]`
  schedule-report family so generated verification tooling does not bind to
  generic phase/stage metadata.
- `2026-06-16`: Ship `.1`: the parser accepts exact actor-level
  `(observe NAME (role passive_monitor) (signals SIG...))` declarations,
  resolves public interface signals for schedule JSON, advertises the new
  public contract key/value families, and keeps generated `.fsm`, HDL, UVM,
  VHDL, scoreboard, coverage, and VIP behavior unchanged.

## Open Questions

- What transaction/event object model should follow once passive signal
  observations ship?
- Which SV/UVM output family should consume this source contract first?
- Whether IAL2 protocol facts should later annotate IAL1 observations remains
  owned by `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1260-isf-verification-observation-metadata.t t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `perl -Iperl t/296-regression-corpus-supported-behavior.t`; `perl -Iperl t/301-check-json-supported-corpus.t`; `./bin/fsmgen --emit-semantic-json isf/verification_observation_metadata.isf`; `./bin/fsmgen --strict --emit-semantic-json isf/verification_observation_metadata.isf`; `mdbook build docs/book`; `prove -Iperl t/297-capability-manifest.t t/1305-isf-book-feature-matrix-audit.t t/1376-isf-book-example-lowering-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; Knowledge Map regeneration/check; memory architecture check; diff hygiene | `passed`; observation metadata is parser/report/public-contract covered, support-accounted, book-documented, and remains report-only with unchanged generated `.fsm`/HDL behavior |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `ISF-VERIFICATION-OBSERVATION-METADATA.1: ship observation metadata` | Shipped actor-level passive observation metadata and additive `verification_observations[]` schedule-report/public-contract projection. |

## Changelog

- `2026-06-16`: Created active implementation owner tree from
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`.
- `2026-06-16`: Implemented the report-only observation metadata source
  contract and unblocked `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`.
