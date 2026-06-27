# IAL2 APB Multi-Register Decode Readiness Audit

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.579`

Date: 2026-06-27

## Summary

`.579` audits APB multi-register decode readiness after APB requester
status-field behavior and selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.580`,
public APB multi-register completer decode contract selection. This audit
changes no behavior.

## Current Boundary

The shipped APB completer and fixed-composition surfaces model one register:

- `ppif/apb_completer.ppif` and `ppif/apb_completer.apb` contain one
  `(register reg0 ...)` clause.
- `ppif/apb_composition_status.ppif` and its `.apb` alias embed the same
  one-register completer under the fixed requester/completer composition.
- `fsm/apb_completer.fsm` is also a one-register address-0 fixture.
- APB completer and status-capable APB composition schedule reports still
  carry `apb_multi_register_decode_deferred`.

The live probes for `.579` confirmed that the current reports still expose
this boundary and that a synthetic second register is rejected with the current
selected diagnostic:

```text
supports exactly one (register ...) clause in this slice
```

## Readiness Evidence

The PPIF parser already has useful syntax vocabulary for multi-register work:
it scans `(storage ...)` for repeated `(register ...)` clauses and parses each
register name, `(address VALUE width WIDTH)`, and `(data NAME width WIDTH reset
RESET)` shape. It then deliberately rejects anything except exactly one
register.

The rest of the public and generated path is still singular:

- `ApbCompleter` normalizes `storage.register` as one hash, not an ordered
  register list.
- Static validation requires the single register address to be value 0, width
  32, data width 32, and reset 0.
- Duplicate-signal checking only accounts for one storage data signal.
- Generated ISF declares one storage variable and emits four fixed
  read/write-hit/error branches around one address comparison.
- The report schema exposes `bindings.storage.register` and
  `transfer.register`, both singular.
- `ApbComposition` embeds the completer report and forwards the same
  `apb_multi_register_decode_deferred` residue.
- Focused APB tests assert the singular storage variable, report shape,
  generated IAL0 fragments, and outdir artifact behavior.

That means direct implementation is not the next safe owner. The project needs
a contract decision before changing accepted syntax or generated behavior.

## Selection

`.580` shall select the public APB multi-register completer decode contract.
It must decide at least:

- whether the source syntax is repeated `(register ...)` clauses under the
  existing `(storage ...)` block or a new explicit register-map wrapper;
- whether register order is source order, address-sorted order, or another
  deterministic ordering;
- address uniqueness, address width, alignment, and duplicate-address
  diagnostics;
- whether the first multi-register slice keeps 32-bit data and reset 0 for all
  registers;
- read/write priority and generated error behavior for unmapped addresses;
- generated storage naming, duplicate-name checking, and top/composition
  report shape;
- whether public reports evolve from `storage.register` to a register list and
  how backward compatibility for existing one-register samples is preserved;
- which new `.ppif` and `.apb` samples, support-accounting identities, tests,
  and mdBook examples are in scope; and
- which work remains deferred to side effects, byte lanes, sidebands/strobes,
  alternate widths, multi-peripheral topology, and back-to-back policy.

## Non-Goals

`.579` changes no source syntax, parser acceptance, diagnostics, generator
logic, samples, support-accounting, validation behavior, generated artifacts,
schedule/check/semantic JSON, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.

`.580` is also selected as a contract slice. It must not ship generated
multi-register behavior unless a later owned implementation leaf selects that
behavior.

## Deferred Work

Multi-peripheral APB interconnect/topology, sidebands/strobes, byte lanes,
register side effects, alternate APB widths, back-to-back transfer policy,
status-only/status-enum/status-sticky requester work, direct backend lowering,
verification-output generation, backend-language variants, AXI follow-on
behavior, and VHDL remain deferred outside `.579`.

## Validation Plan

The closeout validation for `.579` is documentation, probe, and doctrine
focused:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
perl -Iperl -MFSM::Adapter::IAL2::PPIF -0777 -ne 's/\(register reg0\n        \(address 0 width 32\)\n        \(data reg_data_q width 32 reset 0\)\)/$&\n      (register reg1\n        (address 4 width 32)\n        (data reg1_data_q width 32 reset 0))/ or die "substitution failed\n"; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($_, "multi-register-probe.ppif"); 1 }; die "unexpected success\n" if $ok; die $@ unless $@ =~ /supports exactly one \(register/; print "multi-register probe rejected with selected diagnostic\n";' ppif/apb_completer.ppif
prove -Iperl t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this audit, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.577` APB status behavior and `.578` selector remain unchanged.
