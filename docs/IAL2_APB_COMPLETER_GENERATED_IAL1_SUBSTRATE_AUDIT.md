# IAL2 APB Completer Generated-IAL1 Substrate Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.560`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.560` finds the selected APB `.ppif`
completer contract blocked on a smaller IAL1 prerequisite before direct
implementation.

The generated-IAL1 path can represent several required APB completer
ingredients: a target endpoint without a public done port, actor-owned storage
with reset, runtime wait counts, address-dependent read/write state updates,
and reportable generated `.fsm` artifacts. However, the setup-detect guard
required by the selected APB contract is `PSEL && !PENABLE`. A transaction
entry written as `(when (& PSEL (! PENABLE)) (sample ...))` currently lowers
to an invalid generated `.fsm` guard suffix containing `ARRAY(...)` text
instead of a serialized expression. That is not a signoff-level review
artifact and must be repaired before APB completer behavior ships.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.561`, an IAL1
expression entry-activation guard rendering prerequisite. `.561` should repair
transaction entry `(when EXPR (sample ...))` lowering so generated `.fsm`
guards and sample enables carry valid expression syntax, add focused coverage,
and preserve scalar entry guard behavior. `.561` must not implement APB
completer `.ppif` behavior.

No parser behavior, generator behavior, samples, support-accounting catalog,
validation behavior, generated tracked artifacts, tests, schedule/check/
semantic JSON behavior, HDL/runtime behavior, suffix acceptance, direct
backend lowering, verification-output generation, backend-language variants,
AXI behavior, APB behavior, or VHDL behavior changed.

## Evidence Read

The audit read the `.559` APB completer/interconnect contract, the `.558`
readiness audit, the shipped `.554` APB `.apb` requester-transfer behavior,
the `.550` APB `.ppif` requester-transfer behavior, the `.549` APB source
contract, the `.548` APB source-shape readiness audit, `fsm/apb_completer.fsm`,
`fsm/apb_tb.fsm`, ISF transaction/runtime-wait/control-flow/storage docs and
fixtures, PPIF parser/generator/report boundaries, support-accounting entries,
README, ROADMAP_V2, mdBook, task tree, Memory, and the Knowledge Map.

The selected APB completer contract from `.559` still stands:

```text
ppif/apb_completer.ppif
(apb-completer apb_completer ...)
apb_completer.isf
apb_completer.fsm
fsmgen.ial2.protocol_intent.apb_completer.v1
intent.ppif_apb_completer
```

## Positive Substrate Findings

The in-memory ISF probes found these pieces ready enough for a future APB
completer generator after the guard prerequisite is fixed:

- a transaction without a public `(complete ...)` output lowers to a generated
  `.fsm`, so the APB completer does not need to invent a public `done` port
  merely to return to idle;
- actor-owned scalar storage with `(reset 0)` lowers into the generated
  `.fsm` size/reset metadata, matching the selected `reg_data_q` storage
  requirement;
- `(wait wait_n)` after sampling `wait_cycles` emits a `transaction_waits[]`
  runtime-scalar entry with a 4-bit generated counter;
- address-dependent `(when ...)` bodies and `(set ...)` updates can express
  read data, write capture, and unmapped-address `PSLVERR`; and
- the PPIF requester-transfer implementation already proves the IAL2 report
  pattern for generated `.isf` before generated `.fsm`, report schema,
  generated artifacts, support accounting, and direct IAL2-to-IAL0 rejection.

The runtime-wait probe reported:

```json
[{"count_kind":"runtime_scalar","count_source":"wait_n","counter_signal":"apb_complete_wait_4_cnt","counter_width":4,"cycles":null,"entry_state":"apb_complete_wait_4","exit_state":"apb_complete_when_5","transaction":"apb_complete"}]
```

## Blocking Finding

The selected APB setup detector requires expression entry activation:

```text
(when (& PSEL (! PENABLE))
  (sample PADDR as addr)
  (sample PWRITE as write_q)
  (sample PWDATA as wdata_q)
  (sample wait_cycles as wait_n))
```

Scalar entry guards lower correctly today. A scalar entry probe emits valid
guards such as:

```text
(<= (hold din) <start)
(<start
  (-> main_set_1))
```

The equivalent expression entry probe lowers incorrectly today:

```text
(<= (hold din) <ARRAY(...))
(-> main_set_1 <ARRAY(...))
```

The APB-shaped probe showed the same issue on the selected setup-detect path:

```text
(<= (addr PADDR) <ARRAY(...))
(<= (write_q PWRITE) <ARRAY(...))
(<= (wdata_q PWDATA) <ARRAY(...))
(<= (wait_n wait_cycles) <ARRAY(...))
(-> apb_complete_set_1 <ARRAY(...))
```

That generated `.fsm` is not a valid review artifact. It also means a direct
APB `.ppif` completer implementation would either ship invalid generated IAL0
or be tempted to bypass the mandatory generated `.isf` boundary. Both outcomes
violate the selected APB contract and repository doctrine.

## Implementation Boundary After `.561`

After `.561` repairs expression entry guard rendering, a later APB completer
implementation owner may use this audit as readiness evidence but still needs
its own behavior task-tree leaf. That future behavior owner must add, in one
owned slice or a further split if needed:

- PPIF parser support for exactly one `(apb-completer ...)` object under
  explicit `(profile apb)`;
- a new APB completer protocol-intent generator that emits reviewable
  `apb_completer.isf` before `apb_completer.fsm`;
- report schema `fsmgen.ial2.protocol_intent.apb_completer.v1`;
- support-accounting entry `intent.ppif_apb_completer` with coverage
  `ial2_ppif_apb_completer_pipeline_cli`;
- diagnostics that keep `.apb` completer exposure, interconnect/composition,
  sidebands, alternate widths, multi-peripheral decode, back-to-back policy,
  direct backend lowering, backend-language variants, verification-output
  generation, and VHDL deferred; and
- focused schedule/check/semantic/outdir/doc/mdBook/Knowledge Map/doctrine
  validation.

The implementation owner must also make the APB completer idle/default output
contract explicit. The authored lower-layer fixture drives `PREADY` high in
idle through `.fsm` state assignments; generated IAL1 transaction assignments
are scheduled states. That timing/default distinction should be reviewed in
the generated artifact tests rather than assumed away.

## Selected `.561` Scope

`.561` should repair IAL1 expression entry-activation guard rendering before
APB completer implementation.

Acceptance for `.561` should include:

- read this audit, the transaction/control-flow docs, `FSM::Adapter::ISF`,
  `FSM::Scheduler::ISF::LoweringIR`, generated `.fsm` emitter paths, existing
  when/on/sample tests, APB fixture evidence, README, ROADMAP_V2, mdBook, task
  tree, Memory, and Knowledge Map;
- add focused tests proving scalar entry guards remain unchanged;
- add focused tests proving `(when (& a (! b)) (sample ...))` entry guards
  lower to valid generated `.fsm` guard expressions and never to `ARRAY(...)`;
- include an APB-shaped `PSEL && !PENABLE` sample-enable/transition guard
  probe;
- run focused ISF tests and doctrine gates; and
- do not add PPIF APB completer parser/generator/sample/support-accounting
  behavior.

## Validation

Closeout for this no-behavior audit is documentation-only:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update,
and regenerated Knowledge Map entries. No runtime behavior is affected.
