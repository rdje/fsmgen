# Decision 0096: Regression promotion uses a current eleven-profile corpus

- **Status:** Accepted
- **Date:** 2026-09-02
- **Owners:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.1`
- **Refines:** [0056](../../0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0095](../../0095-calibration-closure-versions-atomically-after-current-validator-drift.md)

## Context

`.17.5` must promote representative non-flaky architecture-scale gates, not
repeat calibration for its own sake. Decision 0056 permits promotion only from
complete current evidence for the exact promoted profiles. Decision 0095 makes
the v1 closure authentic historical evidence and forbids its candidate budgets
from satisfying any current-performance field.

The authenticated v1 report contains 216 profiles, 92 candidate profiles, and
356 raw records. Summing its retained raw `wall_time_ns` values yields
6,806,844,563,000 ns, with maximum recorded tree RSS 2,764,865,536 bytes. A
complete current recapture would preserve broad research coverage, but `.17.4`
already owns exact boundary, adjacent-excess, diagnostic, atomicity, no-tool,
cleanup, and accepted-identity proof across all resource axes. Regression
promotion therefore needs representative stage/tool paths, not duplicate cap
qualification for every axis and noncandidate level.

The current host profile still matches the historical Apple M4 Pro/Darwin
25.5.0/APFS/12-core/25,769,803,776-byte tuple, and Verilator still reports the
qualified 5.046 identity. GHDL is deliberately not assumed to be shell-global:
plain `ghdl` is absent from `PATH`, while the exact repository-local GHDL 6.0.0
LLVM-JIT provider and OSVVM 2026.05 commit
`2f7c391051dfb11890fa4bdbda9918d1db492250` are present. Provider-resolved
availability must therefore be an admission result; absence can never pass.

## Decision

1. `.17.5` selects an independently versioned current promotion corpus, not a
   complete current closure recapture. Complete recapture remains available as
   separately owned research/qualification work and is not represented as
   done.
2. The corpus contains exactly eleven `gate_candidate_v1` profiles:
   semantic `actions`; bridge `backend_bindings`; execution `bindings`;
   checking `random_occurrences`; all three structural emission routes
   (`sv_portable_verilator`, `vhdl_portable_ghdl`,
   `vhdl_osvvm_qualified`); all three qualified runtime routes; and the sole
   balanced-portable structural route.
3. Selection uses stable authority/family/level/axis/backend coordinates.
   Historical profile IDs are audit references only. Current capture must
   reconstruct each coordinate through its canonical producer and bind the
   resulting current identities.
4. Each profile requires one fresh validation plus three fresh raw
   measurements: eleven validation records, 33 raw records, and 44 total
   common measurement-controller invocations. Capture groups those four
   controller records inside one guard-visible profile-worker lifecycle, so
   the publication topology is eleven workers rather than 44 workers. Zero
   exclusions are allowed for promotion.
5. The current corpus publishes atomically under
   `.artifacts/qualification/vial-scale/v2/regression-promotion-corpus-v1/`
   with schema
   `fsmgen.vial_architecture_scale_regression_promotion_corpus.v1`. No v1 byte,
   measurement identity, or candidate budget may satisfy a current field.
6. Historical comparison for the selected coordinates is 33 raw records,
   2,135,252,066,000 ns summed raw wall time, and 1,925,595,136 bytes maximum
   tree RSS. The exact difference from the complete v1 raw corpus is 323 records
   and 4,671,592,497,000 ns. These are scope/cost comparators, never budgets.
7. `.17.5.3` derives budgets only from the new current corpus with the exact
   decision-0056 formulas. Capture revision is immutable provenance, not an
   applicability field. Enforcement requires exact workload/correctness and
   host/tool/guard/provider identity. Other environments still run correctness;
   timing is informational.
8. An unavailable exact provider is `unavailable`, never `pass`. Hosted CI may
   verify the contract, publication, and available correctness paths while
   keeping performance informational. The guarded current corpus and promoted
   gate run at the full pre-push/selected-important-step cadence, not on every
   ordinary slice commit.
9. `FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy` is the caller-sealed
   executable authority. Historical comparison independently recomputes
   complete and selected metrics, requires every coordinate exactly once,
   rejects caller evidence and drift, emits the capture/enforcement contract,
   and returns defensive content-addressed data. Public derivation loads the
   tracked seal from decision 0103 and does not require the ignored closure
   publication.

## Verification legs

- **Re-derive:** run
  `prove -Iperl t/1765-vial-architecture-scale-regression-promotion-policy.t`.
  Public derivation loads the tracked seal from decision 0103. When the local
  historical closure is present, the comparison subtests independently
  recompute the 216/92/356 complete census, eleven-profile/33-record selection,
  raw-wall sums, maximum RSS values, reductions, and 44-invocation current
  contract.
- **Falsify:** the focused watcher changes a raw timing, pre-promotes a
  historical candidate budget, duplicates one selected coordinate, and removes
  another. Each competing hypothesis fails closed; caller evidence, a borrowed
  invocant, and an unguarded exact derivation reject too.
- **Durability:** this decision, the `.17.5.1` task node, the policy module,
  t1765, the mdBook, the canonical Knowledge Map card, and the work-unit commit
  retain the selection, quantitative comparison, provider rule, and nonclaims.

## Consequences

- Current evidence scope is substantially smaller without pretending the
  historical closure is current or weakening cap coverage.
- The expensive runtime and balanced routes remain represented; selection does
  not optimize them away merely because they dominate elapsed cost.
- Repository-local provider discovery is normative for the qualified GHDL
  routes. Shell `PATH` is neither a capability oracle nor a failure by itself.
- Whole-product big/really-big, general capacity, full-language, arbitrary-tool,
  synthesis, mixed-language, native-UVM-runtime, and cross-backend-parity claims
  remain outside this work.

## Rollback

Rollback removes the policy, watcher, and synchronized decision/task/book/card
references, returns `.17.5.1` to active, and leaves `.17.5.2` proposed. It does
not mutate the v1 evidence store or authorize full recapture, budget promotion,
or any support/capacity claim.
