# AXI IAL2 Manager Dynamic Same-ID Policy Metadata Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.435`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.435` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.436`, direct metadata-first parser/report
support for the selected `(dynamic-id-reuse reject)` policy.

The first implementation should accept and report the selected public policy
without generating new same-ID queue, scoreboard, response-demux, read-data,
HDL, or runtime behavior. Dynamic response-demux sources that also select
same-ID policy should remain fail-closed until a later owner maps the policy
to generated no-active-same-ID assertion enforcement.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, HDL, or
runtime behavior changes in this audit.

## Inputs Read

The audit read:

- `.434` dynamic same-ID policy contract selection;
- `.433` dynamic same-ID policy readiness audit;
- `.219` dynamic transaction-ID metadata behavior;
- generated dynamic and mixed dynamic/static response-demux/read-data/
  raw-`ARLEN`/runtime-validation/multi-beat/recapture records, including
  multiple-dynamic read response-demux and two-dynamic-plus-one-static mixed
  read burst-last recapture;
- concrete same-ID `reject` and `issue-order-queue` parser/report metadata
  records, support-accounted samples, selected-not-generated diagnostics, and
  generated concrete queue-head behavior records;
- current PPIF `same-id-ordering` parser, which accepts only
  `concrete-id-reuse`;
- current `AxiManagerCapacityStatus` normalizer/report paths, which require
  `same_id_ordering_policy.<family>.concrete_id_reuse` and report
  `concrete_id_reuse_policy`;
- current dynamic interaction guard, which rejects dynamic transactions
  combined with any same-family `same_id_ordering_policy`;
- current dynamic response-demux builders, which reject dynamic response
  matching combined with same-family same-ID policy;
- focused `t/1436`, `t/1437`, and `t/1438` expectation surfaces;
- support-accounting catalog entries for dynamic transaction metadata and
  concrete same-ID policy samples;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Readiness Finding

The first parser/report implementation can be direct. It does not need a
separate lowerer, HDL, support-accounting infrastructure, Knowledge Map, or
mdBook prerequisite.

The required code changes are localized:

- extend PPIF same-ID family parsing to accept `dynamic-id-reuse reject`
  alongside existing `concrete-id-reuse` clauses;
- allow each family arm to contain either concrete policy, dynamic policy, or
  both, while rejecting an empty family arm;
- normalize dynamic policy into an additive
  `same_id_ordering.dynamic_id_reuse_policy.<family>` report branch;
- require at least one dynamic transaction in the selected family;
- preserve the existing dynamic ID-family validation for positive-width
  request/response ID signals through transaction normalization;
- keep `dynamic-id-reuse issue-order-queue`, `dynamic-id-reuse scoreboard`,
  duplicate dynamic clauses, malformed values, and concrete-only policy for
  dynamic transactions fail-closed;
- add a public metadata-only PPIF sample and support-accounting entry;
- add focused generator/parser diagnostics and report tests.

The implementation must not claim generated dynamic same-ID enforcement yet.
For the first sample, `implementation_status` and `enforcement` stay:

```text
selected_not_generated
not_generated
```

and:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

## Behavior Boundary

Dynamic response-demux shapes already generate no-active-same-ID request
checks and active dynamic-ID uniqueness assertions for selected bounded
multiple-dynamic and mixed dynamic/static families. `.436` should not report
those assertions as the selected dynamic same-ID policy enforcement yet.

That mapping is intentionally deferred because it requires precise report
movement for each covered response-demux family and careful preservation of
current fail-closed diagnostics around same-ID policy plus dynamic response
matching. The first implementation should keep sources that combine
`response-demux.<family>` with `dynamic-id-reuse reject` fail-closed with a
specific diagnostic, unless `.436` finds a smaller, behavior-free report
mapping that is clearly safe and records it before editing code.

Dynamic same-ID `issue-order-queue` and `scoreboard` remain future exact
owners. They accept same-ID concurrency, unlike `reject`, and would require
request arbitration, per-ID queue or scoreboard state, overflow and ambiguity
assertions, response-order semantics, report/residue movement, and broader
validation.

## Selected `.436` Boundary

`.436` should implement metadata-first support for `(dynamic-id-reuse reject)`
only. Its acceptance should include:

- PPIF parser support for `(same-id-ordering (<family>
  (dynamic-id-reuse reject)))`;
- preservation of existing `(concrete-id-reuse reject)` and
  `(concrete-id-reuse issue-order-queue)` behavior;
- coexistence of concrete and dynamic policy clauses in one family arm;
- targeted diagnostics for duplicate `dynamic-id-reuse`, empty family arms,
  unsupported values, missing transactions, and selected dynamic policy with
  no dynamic transaction in that family;
- normalized report fields under
  `same_id_ordering.dynamic_id_reuse_policy.<family>`;
- `mode: dynamic_id_reuse_policy` for dynamic-only policy reports and
  `mode: id_reuse_policy` when concrete and dynamic policies coexist without
  auto-ID same-ID avoidance;
- `generated_behavior: false` for metadata-only dynamic policy;
- honest `same_id_ordering` and `dynamic_transaction_id_behavior` residue;
- one public sample, likely
  `ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif`;
- one support-accounting entry, likely
  `intent.ppif_axi_manager_capacity_status_dynamic_same_id_reject_policy`;
- parser/adapter, generator, support-accounting, check JSON, semantic JSON,
  docs, mdBook, Memory, task-tree, and Knowledge Map updates.

`.436` should not add generated dynamic same-ID enforcement, queues,
scoreboards, response-demux mapping, HDL behavior, or VHDL behavior.

## Validation For `.436`

Focused implementation gates should include:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_axi_dynamic_same_id_reject_policy.sv ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif
```

Focused Perl test runs should cover the new parser/report and
support-accounting expectations. Broad `prove`, supported-corpus, and HDL
verification commands remain RAM-guarded.

Selector closeout for `.435` only requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

## Preservation Matrix

`.436` must preserve:

- transaction-local `(id dynamic)` metadata and existing dynamic ID
  diagnostics;
- generated dynamic and mixed dynamic/static response-demux/read-data/
  raw-`ARLEN`/runtime-validation/multi-beat/recapture behavior;
- concrete `concrete-id-reuse reject` and `concrete-id-reuse
  issue-order-queue` parser/report metadata and generated concrete queue-head
  behavior;
- auto-ID same-ID avoidance behavior and reports;
- existing public sample identities and support-accounting entries;
- generated artifacts, schedule/check/semantic JSON, HDL behavior, direct
  backend deferral, verification-output deferral, VHDL deferral, and
  backend-language neutrality except for the one new metadata-only public
  sample.

## Rollback

Rollback for `.435` is limited to this audit record, fact card, task-tree
frontier movement, README, roadmap, mdBook, Memory, and Knowledge Map
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, HDL, or runtime behavior is part of
this audit slice.
