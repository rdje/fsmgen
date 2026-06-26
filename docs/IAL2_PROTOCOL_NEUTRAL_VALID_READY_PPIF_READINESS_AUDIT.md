# IAL2 Protocol-Neutral Valid-Ready PPIF Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.529`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.529` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.530`, public contract selection for a
protocol-neutral/non-AXI Valid-Ready `.ppif` profile and source-vocabulary
boundary.

The audit found that a protocol-neutral/non-AXI Valid-Ready example should not
be added directly on the current behavior. `.ppif` is already the generic
Protocol/Platform Intent Format IAL2 container, and AXI is only the first
shipped profile/example. However, the current shipped Valid-Ready generator
path is still AXI-profile-local: it accepts only AXI protocol names and AXI
channel families. The next owner must therefore select the public vocabulary
contract before any sample, parser, generator, support-accounting, or report
behavior changes.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias syntax, or VHDL behavior.

## Evidence

The public guardrail from `.527` is the controlling rule:

- `.ppif` is the generic Protocol/Platform Intent Format IAL2 container;
- AXI is the first shipped IAL2 profile/example, not the definition of IAL2;
- future protocol-specific suffixes are profile aliases over IAL2; and
- common IAL2 constructs stay small until compatible reuse is proven across
  multiple profiles.

The current source parser still requires a profile clause for every `.ppif`
input. `FSM::Adapter::IAL2::PPIF` fails closed when `(profile ...)` is missing,
and focused parser coverage keeps that diagnostic stable in
`t/1436-ial2-ppif-parser-cli.t`.

The current Valid-Ready generator is explicitly AXI bounded.
`FSM::IAL2::ProtocolIntent::ValidReadyChannel` normalizes the `.ppif` profile
as a generator protocol and accepts only `axi`, `axi3`, `axi4`, or `axi5`. It
also accepts only AXI channel families `AW`, `W`, `B`, `AR`, and `R`. Its
diagnostics and required-field messages are phrased as "AXI Valid-Ready IAL2
contract" errors.

The support-accounted Valid-Ready samples are AXI-shaped:

- `intent.ppif_axi_aw_valid_ready` uses
  `ppif/axi_aw_valid_ready.ppif`, `(profile axi4)`, channel `AW`, and AXI
  signal/payload naming.
- `intent.ppif_axi_aw_w_valid_ready_bundle` uses
  `ppif/axi_aw_w_valid_ready_bundle.ppif`, `(profile axi4)`, channels `AW` and
  `W`, and the aggregate bundle wrapper/top contract.

The bundle decision remains useful but does not solve protocol neutrality by
itself. Decision `0017` and the shipped bundle docs select aggregate
multi-channel Valid-Ready artifacts over per-channel generated `.isf` and
`.fsm` files. That bundle still passes the top-level profile into every
channel contract, so it inherits the same AXI protocol and channel-family
limits.

## Readiness Finding

The next safe owner is not a new non-AXI sample. Adding such a sample today
would either fail under the current generator boundary or require making a
profile/channel vocabulary decision inside an implementation slice.

The next safe owner is a public contract-selection leaf that decides the
protocol-neutral Valid-Ready vocabulary before behavior changes. That owner
should choose, at minimum:

- whether the protocol-neutral path keeps a required `(profile ...)` clause
  with a new profile name, admits a no-profile form, or uses another explicit
  selector;
- which channel token vocabulary is allowed outside AXI, including whether
  channel names are profile-local symbols, generic role names, or authored
  identifiers;
- whether the existing `manager-to-subordinate` and `subordinate-to-manager`
  roles are common IAL2 vocabulary or profile-local aliases;
- source-anchor expectations for a protocol-neutral educational/sample
  boundary, including what counts as source evidence when no external protocol
  specification is being cited;
- whether the existing `valid_ready_channel.v1` and `valid_ready_bundle.v1`
  report schemas can remain compatible or require an additive profile-neutral
  field/schema owner;
- sample names and support-accounting IDs that do not imply AXI ownership;
- mdBook wording that demonstrates IAL2 generality without claiming broader
  non-AXI protocol behavior; and
- preservation tests for the existing AXI one-channel and bundle paths.

The contract-selection owner should not introduce `.axi`, `.chi`, `.ace`,
`.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`, or any other profile-alias suffix.
Alias dispatch remains a separate profile-extension owner.

## Preservation Matrix

| Surface | Preservation rule |
| --- | --- |
| `.ppif` container | Remains generic IAL2; no direct `.ppif -> .fsm` path. |
| AXI Valid-Ready | Existing one-channel and AW/W bundle behavior remains unchanged. |
| AXI manager capacity/status | Remains profile-local shipped coverage under `.ppif`; no behavior changes here. |
| Profile aliases | Remain future exact-owner work; no suffix alias syntax is introduced. |
| Common IAL2 constructs | No construct is promoted merely because AXI uses it. |
| Support accounting | Existing AXI sample IDs remain unchanged; no new sample is added by this audit. |
| Reports and JSON | Existing schedule/check/semantic JSON schemas and fields remain unchanged. |
| HDL/backends | No HDL/runtime/backend/VHDL behavior changes. |

## Selected `.530` Scope

`.530` should select the public protocol-neutral Valid-Ready `.ppif` contract
before implementation. It should read this audit, decisions `0014`, `0015`,
`0016`, and `0017`, the public guardrail sync, current Valid-Ready parser and
generator surfaces, the support-accounted AXI samples, support accounting,
public contracts, capability manifest boundary, README, ROADMAP_V2, mdBook,
task tree, Memory, and Knowledge Map.

`.530` should produce a contract that an implementation owner can later ship
without guessing syntax or semantics. It must keep AXI as the first shipped
profile/example, not the IAL2 definition.

## Deferred Alternatives

The following remain future exact-owner work:

- direct parser/generator implementation of a protocol-neutral Valid-Ready
  sample;
- support-accounting entries for a new non-AXI or protocol-neutral sample;
- report schema migration beyond an explicitly selected additive contract;
- profile-specific suffix aliases such as `.axi`, `.chi`, `.ace`, `.ahb`,
  `.apb`, `.atb`, `.smbus`, or `.i2s`;
- full non-AXI protocol behavior;
- promotion of AXI queue/order/read-data concepts into common IAL2;
- additional AXI manager behavior;
- direct backend behavior;
- verification-output generation for IAL2 profiles;
- backend-language variants; and
- VHDL.

## Validation

`.529` is documentation-only and closes with:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, generator, sample, support-accounting, runtime, generated HDL, or
backend artifact rollback is required.
