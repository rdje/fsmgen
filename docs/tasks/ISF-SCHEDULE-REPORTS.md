# ISF-SCHEDULE-REPORTS: Schedule Report Storage Classes And Schema Stabilization

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Make the ISF schedule report more useful and stable by improving inferred
storage classifications, adding bounded metadata required by shipped features,
and defining the path from current bounded key families toward any fully frozen
schedule JSON schema.

## Non-Goals

- Do not freeze the whole schedule JSON tree until every advertised field has
  owner, tests, and compatibility rules.
- Do not add report fields that are not backed by scheduler truth or a shipped
  feature.
- Do not replace normalized semantic JSON or the broader embedding contracts.

## Acceptance Criteria

- Current schedule-report keys, bounded public key families, and storage
  classifications are inventoried.
- Richer storage classes are specified and implemented for agreed scheduler
  storage families.
- Feature-driven report additions from other ISF trees have documented owners
  and public-contract treatment.
- A schema-freeze readiness checklist exists, with explicit blockers for any
  not-yet-frozen branches.
- Tests cover in-process and CLI schedule report behavior.
- ISF public interface contract, manifest metadata, ISF spec, mdBook, roadmap,
  and live docs agree.

## Task Tree

- ID: `ISF-SCHEDULE-REPORTS`
  Status: `done`
  Goal: `Improve schedule-report storage classes and define schema stabilization.`
  Children: `ISF-SCHEDULE-REPORTS.1`, `ISF-SCHEDULE-REPORTS.2`,
  `ISF-SCHEDULE-REPORTS.3`, `ISF-SCHEDULE-REPORTS.4`,
  `ISF-SCHEDULE-REPORTS.5`

- ID: `ISF-SCHEDULE-REPORTS.1`
  Status: `done`
  Goal: `Inventory current schedule-report shape and public contract boundaries.`
  Acceptance: `The task file lists current top-level keys, bounded key
  families, storage metadata, feature-owned report fields, and non-frozen
  branches.`
  Verification: `prove -l t/1096-isf-schedule-json-report.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1226-isf-data-width-storage-report.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORTS.1: inventory report contract`

- ID: `ISF-SCHEDULE-REPORTS.2`
  Status: `done`
  Goal: `Specify richer inferred-storage class taxonomy.`
  Acceptance: `The tree records storage classes, required source evidence,
  report keys, compatibility rules, and deferred classes.`
  Verification: `prove -l t/1096-isf-schedule-json-report.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1226-isf-data-width-storage-report.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORTS.2: specify storage roles`

- ID: `ISF-SCHEDULE-REPORTS.3`
  Status: `done`
  Goal: `Implement first richer storage-class report slice.`
  Acceptance: `The selected storage families report the new bounded class
  metadata through in-process and CLI schedule JSON.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -l t/1106-isf-schedule-json-counter-storage.t t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1226-isf-data-width-storage-report.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORTS.3: report storage roles`

- ID: `ISF-SCHEDULE-REPORTS.4`
  Status: `done`
  Goal: `Define schedule JSON schema-freeze readiness plan.`
  Acceptance: `The tree and public contract identify what is frozen, what is
  bounded-but-not-frozen, what remains raw/internal, and what blocks full
  schema freeze.`
  Verification: `prove -l t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORTS.4: define schema freeze plan`

- ID: `ISF-SCHEDULE-REPORTS.5`
  Status: `done`
  Goal: `Add tests and synchronize docs/contracts.`
  Acceptance: `Tests cover report metadata, manifest/public contract claims,
  CLI/in-process parity, and synchronized user-facing docs.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -l t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1141-isf-public-identity-flags-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1227-isf-schedule-report-freeze-boundary.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SCHEDULE-REPORTS.5: close report contract tree`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | `closed` | `done` | All planned schedule-report storage/schema leaves are complete. |

## ISF-SCHEDULE-REPORTS.1 Inventory

Current top-level schedule-report keys are the bounded public family advertised
by `embedding.isf_public_interface`:

```text
source
scheduled_fsm
clock
reset
watchdog
port_count
inputs
outputs
state_count
inferred_storage
transactions
transaction_stages
temporal_contracts
dt_blocks
generated_composition
compatible_fanin_groups
priority_resolutions
resource_arbitration
compile_issues
```

Current bounded nested key families:

| Report branch | Required keys | Optional keys / value families |
| --- | --- | --- |
| `reset` | `name`, `kind`, `polarity` | `kind` values: `async`, `sync`; `polarity` values: `active_high`, `active_low`; omitted reset reports as JSON null. |
| `inferred_storage[]` | `name`, `kind` | Optional `role`, `width`; `kind` values: `counter`, `register`; `role` values are the bounded storage purpose family; `width` is a positive integer when present. |
| `transactions[]` | `name`, `states`, `count` | `states` keeps emitted scheduled-state order per transaction; `count` equals the states length. |
| `transaction_stages[]` | `transaction`, `name`, `kind`, `state`, `ready`, `valid` | Current `kind` value: `ready_valid_barrier`. |
| `temporal_contracts[]` | `transaction`, `name`, `kind`, `trigger`, `signal`, `within_cycles`, `pending_signal`, `counter_signal`, `fail_signal`, `overlap_policy`, `reset_policy`, `assertion_projection` | Current `kind` value: `bounded_eventually`; `overlap_policy` value: `fail`; `assertion_projection` value: `none`; `reset_policy` uses the bounded reset shape or null. |
| `dt_blocks[]` | `name`, `kind`, `assignments` | Current `kind` values: `drive`, `latency_counter`, `rule`, `rule_trigger_fanin`, `temporal_contract_monitor`; `assignments` is a count, not a payload list. |
| `compile_issues[]` | `code`, `severity`, `target`, `domain`, `proof_status`, `reason`, `sources` | Successful no-issue reports keep this as an empty array; current nonfatal proof status includes `not_doable`. |
| `compile_issues[].sources[]` | `owner`, `owner_kind`, `source_kind`, `target`, `operator`, `rhs`, `domain` | Capped bounded source summaries only; raw assignment provenance remains private. |
| `compatible_fanin_groups[]` | `kind`, `domain`, `sources` | Optional `target`, `target_transaction`, `fanin_target`, `operator`, `rhs`. |
| `priority_resolutions[]` | `target`, `winner`, `winner_kind`, `loser`, `loser_kind` | Static priority-lowering summaries, not runtime traces. |
| `resource_arbitration[]` | `resource`, `kind`, `arbiter`, `user`, `user_kind`, `suppressed_by` | Static resource grant-shaping summaries, not runtime grant traces. |
| `generated_composition` | `kind`, `top_module`, `top_fsm`, `parent`, `children`, `instances` | Null when no generated composition top exists; nested generated-composition key families are separately advertised. |

Current scalar and ordering policies:

- `source` and `scheduled_fsm` are actor-derived `.isf` and `.fsm` basenames
  for the current parent report scope.
- `clock` is the actor clock signal name. `watchdog` is a scalar parser-carried
  limit when configured and JSON null when omitted.
- `inputs`, `outputs`, `port_count`, and `state_count` are non-negative
  integer counts. `port_count` equals `inputs + outputs`.
- `dt_blocks` follow the advertised deterministic order: transaction/rule
  created DTs in construction order, generated rule-trigger fan-in DTs by
  transaction name, then hash-backed drive DTs lexically by drive name.
- For multi-file lowerings, parent schedule-report scope remains current
  public behavior. Child scheduled `.fsm` text stays available through
  `lower(...)` result files, while `generated_composition` summarizes the
  generated top, child files, spawned instances, handoffs, and bindings.

Current storage metadata baseline:

- `inferred_storage[]` reports storage names seen in scheduled state
  assignments plus generated scheduler counters that are not already seen.
- Generated `*_wd`, `*_cc`, and `*_cnt` scheduler families report
  `kind = counter` with inferred positive integer `width` and evidence-backed
  roles when generated by the lowerer.
- Generated drive request/payload handoff names from the counter table also
  report positive integer widths and `drive_request`/`drive_payload` roles.
- Register storage with known ISF width evidence reports `kind = register` and
  positive integer `width`; sampled aliases, extracted fields, ordinary data
  registers, and completion pulses report roles when assignment source-kind
  evidence is available.
- Register storage without stable width evidence may omit `width`; the key is
  optional by contract.
- The APB fixture currently reports width-bearing storage such as
  `apb_transfer_cc: counter width 5`, `apb_transfer_wd: counter width 17`,
  sampled aliases `addr: register width 32`, `wdata: register width 32`,
  `rdata: register width 32`, one-bit aliases `is_write` and `slverr`, and
  completion/status registers `done` and `last_error` as one-bit registers.

Feature-owned report branches:

| Branch | Current owner / originating tree |
| --- | --- |
| Base top-level report shell, transaction summaries, DT summaries, reset and scalar count shapes | ISF scheduler/public interface contract. |
| `inferred_storage.width` for known data registers | `ISF-DATA-WIDTHS`. |
| `transaction_stages[]` | `ISF-STAGES-CONTRACTS`. |
| `temporal_contracts[]` | `ISF-STAGES-CONTRACTS`. |
| `generated_composition` | `ISF-COMPOSITION`. |
| `compatible_fanin_groups[]` and `compile_issues[]` conflict projections | `ISF-CONFLICTS`, with rule-action integration from `ISF-RULE-ACTIONS`. |
| `priority_resolutions[]` and `resource_arbitration[]` | `ISF-RESOURCE-PRIORITY`. |

Non-frozen branches and boundaries:

- `schedule_report_full_schema_stable` is false. Downstream consumers should
  use the advertised bounded key families rather than assuming the whole JSON
  tree is frozen.
- Raw `LoweringIR` hashes, raw assignment provenance, activation proof context,
  assignment indexes, priority/resource suppression bookkeeping, and raw
  monitor equations are private.
- Generated state names are visible review artifacts, but only the advertised
  ordering/count/key-family policies are public contract.
- `generated_composition` nested summaries are bounded by their advertised key
  families, but the full composition plan and raw lower-result hash are not
  public schema.
- Remaining storage roles beyond the shipped first family are not public yet.
  They need source evidence, compatibility rules, contract keys, and tests
  before they can extend current storage metadata.

## ISF-SCHEDULE-REPORTS.2 Storage Role Taxonomy

Public shape decision:

- Keep `inferred_storage[].kind` as the coarse hardware/storage category. The
  current public values remain `counter` and `register`.
- Add an optional `inferred_storage[].role` key for richer scheduler purpose.
  The first role family is now shipped; `role` remains additive and may be
  omitted when the lowerer lacks stable evidence.
- Do not encode role into `kind`; that would force downstream consumers to
  relearn the physical storage category when they only need to distinguish
  register-like from counter-like storage.

Compatibility rules:

- Existing consumers that read only `name`, `kind`, and optional `width` must
  continue to work when `role` is added.
- `role` values are a bounded public value family. Adding a role requires a
  contract update, report-key audit, focused tests, and docs.
- A storage entry may omit `role` when evidence is ambiguous. Guessing from a
  name alone is not allowed unless that name family is generated by the
  scheduler and already part of a stable generated-name contract.
- If two evidence sources disagree for the same storage name, lowering should
  fail closed before emitting a successful report rather than choosing one
  role silently.

Shipped `role` values for the first implementation slice:

| Role | Coarse `kind` | Required evidence |
| --- | --- | --- |
| `watchdog_counter` | `counter` | Generated watchdog counter name `*_wd` registered in the counter-width table. |
| `latency_counter` | `counter` | Generated latency counter name `*_cc` registered in the counter-width table, or latency-counter source kind on the state/DT assignment. |
| `repeat_counter` | `counter` | Generated repeat counter name `*_cnt` registered in the counter-width table. |
| `drive_request` | `counter` | Generated named-drive request storage ending in `_start` and registered through drive-call or spawn-drive handoff metadata. |
| `drive_payload` | `counter` | Generated named-drive payload storage registered through drive parameter width metadata. |
| `sample_alias` | `register` | State assignment with `source_kind = sample_capture`. |
| `extract_field` | `register` | State assignment with `source_kind = extract_capture`. |
| `data_register` | `register` | State assignment with source kind from ordinary data operations: `update`, `shift`, or `assemble`. |
| `completion_pulse` | `register` | State assignment with `source_kind = complete_pulse` or `timeout_pulse`. |

Deferred `role` values:

| Deferred role family | Reason |
| --- | --- |
| Temporal contract monitor storage roles such as pending, age, and fail | The temporal contract report already exposes generated storage names; richer storage roles should be added with contract-report compatibility checks. |
| Child `do` / `spawn` start and done handoff roles | Handoff storage crosses parent/child composition reporting and should be handled with the composition report owner. |
| Rule trigger source roles | Rule-trigger fan-in already has provenance in scheduled `.fsm` and compatible-fan-in reports; storage roles should not duplicate it until the desired downstream use is clear. |
| Resource grant/debug roles | Runtime grant traces are explicitly not part of the current schedule report. |

## ISF-SCHEDULE-REPORTS.4 Schema-Freeze Readiness Plan

The current schedule report is a bounded public report, not a fully frozen
JSON schema. Downstream consumers should discover the current supported surface
from `embedding.isf_public_interface` and should treat
`schedule_report_full_schema_stable = false` as normative.

Contractual now:

- `FSM::Scheduler::ISF->report($actor)` and
  `./bin/fsmgen --emit-schedule-json path.isf` return the same successful
  schedule-report shape for accepted sources.
- The advertised top-level key family is exact for the current public report:
  `source`, `scheduled_fsm`, `clock`, `reset`, `watchdog`, `port_count`,
  `inputs`, `outputs`, `state_count`, `inferred_storage`, `transactions`,
  `transaction_stages`, `temporal_contracts`, `dt_blocks`,
  `generated_composition`, `compatible_fanin_groups`,
  `priority_resolutions`, `resource_arbitration`, and `compile_issues`.
- The public contract owns bounded nested key/value families for reset,
  inferred storage, transactions, transaction stages, temporal contracts, DT
  blocks, compile issues, compatible fan-in groups, priority resolutions,
  resource arbitration, and generated-composition summaries.
- Existing advertised scalar policies are contractual: port and state counts
  are non-negative integers, `port_count = inputs + outputs`, `watchdog` is a
  scalar limit or null, and `reset` is a bounded reset object or null.
- Advertised ordering policies are contractual for transactions and DT blocks.
  Generated `.fsm` text remains a review artifact; consumers should rely on
  the advertised order/count summaries rather than private IR layout.

Bounded but not fully frozen:

- New optional keys or new bounded value-family members may be added only with
  public-contract metadata, focused tests, and docs in the same slice.
- `inferred_storage[].role` is additive. Consumers that only need
  `name`/`kind`/`width` must keep working.
- `compile_issues[]`, `compatible_fanin_groups[]`,
  `priority_resolutions[]`, `resource_arbitration[]`,
  `transaction_stages[]`, `temporal_contracts[]`, and
  `generated_composition` are bounded summaries owned by their feature trees;
  they are not promises that raw feature IRs or backend equations are public.
- Child scheduled `.fsm` text is available through `lower(...)` result files,
  while the schedule report currently describes the parent report scope plus a
  bounded generated-composition summary.

Raw/internal and non-public:

- Raw parser actor hashes beyond the actor-shell contract.
- `FSM::Scheduler::ISF::LoweringIR` objects and child implementation hashes.
- Raw assignment provenance, activation proof context, assignment indexes,
  state-link bookkeeping, priority/resource suppression internals, monitor
  equations, and backend assertion text.
- Raw generated-composition plans and any unadvertised lower-result or
  schedule-report keys.

Full-freeze readiness status:

- The report now has explicit top-level `schema_version: 1`.
- The storage-role family has been synchronized for current emitted roles;
  resource-grant/debug storage remains explicitly deferred until future
  lowering materializes such storage.
- Generated-name stability, assignment-provenance privacy, multi-file
  child-summary scope, and additive/breaking evolution policy are documented.
- `t/1255-isf-schedule-report-golden-matrix.t` now maintains the executable
  golden matrix for every advertised `schedule_report_*` branch through both
  in-process and CLI report paths.
- `schedule_report_full_schema_stable` remains false until a later dedicated
  freeze slice intentionally flips the public flag.

Readiness checklist for freezing any branch:

1. The branch has a named owner and originating feature tree.
2. Required keys, optional keys, scalar shapes, ordering, nullability, and
   value families are documented in the public contract.
3. In-process and CLI tests cover successful reports and fail-closed behavior
   where applicable.
4. The mdBook and live spec explain the runtime meaning and downstream
   compatibility policy.
5. Additive evolution rules are clear, and private implementation fields are
   explicitly excluded.
6. `schedule_report_full_schema_stable` is flipped only after every top-level
   branch satisfies the same checklist.

## Decisions

- `2026-05-14`: Schedule-report stabilization remains feature-driven. Whole
  schema freeze is tracked, but not assumed, by this tree.
- `2026-05-14`: The current report contract is bounded by advertised key
  families. The full schedule JSON tree remains non-frozen until each branch
  has an owner, compatibility policy, and regression coverage.
- `2026-05-14`: Richer storage classification should use an optional `role`
  key while preserving `kind = counter|register` as the coarse storage
  category. The first role slice should be additive and evidence-driven.
- `2026-05-14`: The first `inferred_storage[].role` slice is shipped for
  watchdog, latency, repeat, named-drive request/payload, sample-alias,
  extract-field, data-register, and completion-pulse storage. Additional role
  families remain backlog until they have direct lowerer evidence and their
  own contract tests.
- `2026-05-14`: Full schedule JSON schema freeze remained blocked by explicit
  schema/version policy, remaining role families, generated-name policy,
  assignment-provenance policy, multi-file report scope, compatibility rules,
  and a golden fixture matrix. Later slices closed those blockers; the report
  remains bounded public metadata until a dedicated freeze slice flips
  `schedule_report_full_schema_stable`.
- `2026-05-14`: The schedule-report tree is closed after adding an explicit
  freeze-boundary regression. Future schedule-report feature additions should
  reopen this tree or create a feature-owned tree before changing report shape.

## Open Questions

- Should feature-owned report additions be centralized here or completed inside
  each feature tree with this tree acting as the schema index?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-SCHEDULE-REPORTS` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-SCHEDULE-REPORTS.1` | `prove -l t/1096-isf-schedule-json-report.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1226-isf-data-width-storage-report.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-SCHEDULE-REPORTS.2` | `prove -l t/1096-isf-schedule-json-report.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1226-isf-data-width-storage-report.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-SCHEDULE-REPORTS.3` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -l t/1106-isf-schedule-json-counter-storage.t t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1226-isf-data-width-storage-report.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-SCHEDULE-REPORTS.4` | `prove -l t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-SCHEDULE-REPORTS.5` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -l t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1141-isf-public-identity-flags-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1227-isf-schedule-report-freeze-boundary.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORTS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-SCHEDULE-REPORTS.1` | `ISF-SCHEDULE-REPORTS.1: inventory report contract` | Current schedule-report shape, owners, and non-frozen branches inventoried. |
| `ISF-SCHEDULE-REPORTS.2` | `ISF-SCHEDULE-REPORTS.2: specify storage roles` | Additive `inferred_storage[].role` taxonomy specified. |
| `ISF-SCHEDULE-REPORTS.3` | `ISF-SCHEDULE-REPORTS.3: report storage roles` | First bounded storage role family implemented in schedule reports and public contract metadata. |
| `ISF-SCHEDULE-REPORTS.4` | `ISF-SCHEDULE-REPORTS.4: define schema freeze plan` | Full schedule JSON freeze boundary, blockers, and readiness checklist documented. |
| `ISF-SCHEDULE-REPORTS.5` | `ISF-SCHEDULE-REPORTS.5: close report contract tree` | Freeze-boundary regression added and schedule-report tree closed. |

## Changelog

- `2026-05-14`: Created the active ISF schedule-report task tree.
- `2026-05-14`: Completed the current schedule-report shape and public
  contract-boundary inventory; advanced the frontier to
  `ISF-SCHEDULE-REPORTS.2`.
- `2026-05-14`: Specified the richer storage role taxonomy and advanced the
  frontier to `ISF-SCHEDULE-REPORTS.3`.
- `2026-05-14`: Implemented the first bounded `inferred_storage[].role`
  report slice and advanced the frontier to `ISF-SCHEDULE-REPORTS.4`.
- `2026-05-14`: Defined the full schedule JSON schema-freeze readiness plan
  and advanced the frontier to `ISF-SCHEDULE-REPORTS.5`.
- `2026-05-14`: Added the freeze-boundary regression, synchronized the public
  contract provenance, and closed the schedule-report tree.
