# IAL2 APB Interconnect/Composition Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.564`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.564` finds APB
interconnect/composition generation ready for public contract selection, not
ready for direct implementation in this slice.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.565`, APB
interconnect/composition public contract selection. `.565` must decide the
public source vocabulary, generated review-artifact chain, report and
support-accounting identities, diagnostics, validation plan, and rollback
boundary before any parser, generator, sample, support-accounting, or behavior
change.

No parser behavior, generator behavior, samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON
behavior beyond read-only probes, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, AXI behavior, APB behavior, or VHDL behavior changed.

## Evidence Read

The audit read the `.563` selector, the `.562` APB `.ppif` completer behavior,
the `.561` IAL1 expression entry-guard repair, the `.560` APB completer
substrate audit, the `.559` split APB completer/interconnect contract, the
`.558` APB completer/interconnect readiness audit, the `.554` APB `.apb`
requester-transfer behavior, the `.550` APB `.ppif` requester-transfer
behavior, `ppif/apb_completer.ppif`, `ppif/apb_requester_transfer.ppif`,
`ppif/apb_requester_transfer.apb`, `fsm/apb_tb.fsm`,
`fsm/apb_completer.fsm`, `RegressionCorpus`, `LanguageSurfaceSection`,
generated APB reports, README, ROADMAP_V2, mdBook, task tree, Memory, and
Knowledge Map.

## Live Evidence

The audit reverified the current APB endpoint and composition surfaces:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json fsm/apb_completer.fsm
./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm
```

The generated APB `.ppif` endpoint paths now cover:

```text
ppif/apb_requester_transfer.ppif -> apb_requester.isf -> apb_requester.fsm
ppif/apb_completer.ppif -> apb_completer.isf -> apb_completer.fsm
```

The bounded APB `.apb` alias still covers only requester-transfer:

```text
ppif/apb_requester_transfer.apb -> apb_requester.isf -> apb_requester.fsm
```

The lower-layer APB composition target is:

```text
fsm/apb_tb.fsm
```

It declares top ports for requester stimulus, completer wait-state control, and
requester completion observation; instantiates `apb_requester` and
`apb_completer`; and wires `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, `PWDATA`,
`PREADY`, `PRDATA`, and `PSLVERR` between the children.

`RegressionCorpus` support-accounts `fsm/apb_tb.fsm` as
`protocol.apb_tb`, `source_kind => composition`, expected top `apb_tb`, and
expected child modules `apb_requester` and `apb_completer`.

## Readiness Finding

APB interconnect/composition is ready for contract selection because the two
required endpoint roles now have generated public IAL2 source paths and the
repository already has a strict-supported lower-layer composition target that
wires those roles through the APB bus.

A smaller generated aggregate-top prerequisite is not selected first. The
existing composition pipeline already proves the lower-layer top shape,
expected child modules, child wiring, check JSON, semantic JSON, and HDL entry
for `fsm/apb_tb.fsm`. The missing pieces are public IAL2 contract decisions:
source vocabulary, generated artifact names, source identity, report schema,
support-accounting identity, and diagnostics. Those must be selected before a
generated aggregate top can be implemented without guessing.

A report/support-accounting prerequisite is also not selected first. The
support identity for a generated APB composition source depends on whether the
public source is an `(apb-interconnect ...)`, `(apb-composition ...)`, endpoint
bundle, or another shape, and whether the generated top is a `.fsm`
composition root, a generated `.isf` plus generated top `.fsm`, or a wrapper
over generated endpoint artifacts.

Deferral is not selected because the split chosen in `.559` has now completed
its generated completer prerequisite. Keeping interconnect/composition
deferred without contract selection would leave the public APB sequence stalled
despite having both generated endpoint roles and a supported lower-layer
composition target.

## Contract Questions For `.565`

`.565` should select the public APB interconnect/composition contract before
behavior changes.

The contract selector should decide:

- source vocabulary, such as `(apb-interconnect ...)`,
  `(apb-composition ...)`, a requester-plus-completer aggregate, or another
  explicit APB composition object;
- object cardinality and whether the first source embeds endpoint definitions,
  references existing endpoint objects, or binds to generated endpoint
  artifacts;
- whether the first implementation is fixed one-requester/one-completer wiring
  only or includes any decode subset;
- generated review artifacts and names, including whether generated `.isf`
  exists before generated top `.fsm`;
- report schema, source object identity, target protocol object, generated
  artifact summaries, expected child modules, composition wiring summaries, and
  unsupported residue;
- support-accounting entry ID, coverage name, source kind, expected top name,
  expected child modules, and semantic/check JSON source identity;
- diagnostics for mixed unsupported APB objects, missing endpoint roles,
  duplicate roles, invalid bus bindings, decode policy not selected, and
  `.apb` completer/interconnect alias exposure still deferred;
- validation commands for generated endpoint preservation, generated
  composition behavior, lower-layer `fsm/apb_tb.fsm` preservation, mdBook,
  Knowledge Map, and doctrine gates; and
- rollback and deferral boundaries for `.apb` completer aliases, multi-register
  decode, sidebands/strobes, alternate widths, back-to-back policy, direct
  backend lowering, verification-output generation, backend-language variants,
  AXI, and VHDL.

## Rejected Next Owners

Direct APB interconnect/composition implementation is rejected until `.565`
selects the public contract. Implementing first would risk exposing a source
shape, generated top artifact, or support-accounting identity that cannot be
recovered cleanly.

APB completer `.apb` alias exposure remains deferred. The `.apb` surface is a
profile alias for the already shipped requester-transfer object only; widening
it before composition contract selection would add another public endpoint
surface while the aggregate APB boundary is unsettled.

APB multi-register decode, sidebands/strobes, alternate widths, and
back-to-back policy remain deferred. Those are useful APB expansions, but they
either alter endpoint behavior or widen APB protocol breadth. They are not
prerequisites for selecting the first fixed requester-to-completer composition
contract.

AXI return, direct backend lowering, verification-output generation,
backend-language variants, and VHDL remain future candidates outside this APB
composition readiness result.

## Selected `.565` Scope

`.565` should select the APB interconnect/composition public contract before
any behavior change.

Acceptance for `.565` should include reading this audit, `.563`, `.562`,
`.561`, `.560`, `.559`, `.558`, `.554`, `.550`, generated APB endpoint
samples and reports, `fsm/apb_tb.fsm`, `RegressionCorpus`,
`LanguageSurfaceSection`, README, ROADMAP_V2, mdBook, task tree, Memory, and
Knowledge Map. It should record the selected public source shape, generated
artifact chain, report/support-accounting contract, diagnostics, validation,
rollback, and deferrals without changing behavior.

## Validation

Closeout for this no-behavior audit is documentation-only plus exact APB
read-only probes:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json fsm/apb_completer.fsm
./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm
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
