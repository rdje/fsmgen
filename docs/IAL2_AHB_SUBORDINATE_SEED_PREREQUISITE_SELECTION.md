# IAL2 AHB Subordinate Seed Prerequisite Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.703`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.703` does not select the lower-layer AHB
subordinate seed contract yet. The current repository evidence is not
source-backed enough to specify a signoff-level subordinate seed contract.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.704`, an AHB
subordinate source-reference and seed-evidence audit. `.704` must establish
the source-backed subordinate signal/timing evidence needed for a direct
`.fsm` seed contract, or select the smallest prerequisite if that evidence is
still missing.

No parser behavior, generator behavior, source sample, support accounting,
capability manifest, test behavior, schedule/check/semantic JSON, generated
artifact, HDL/runtime behavior, suffix behavior, direct backend behavior,
verification-output generation, backend-language variant, AXI, APB, or VHDL
behavior changed in this selector.

## Evidence Read

The selector read:

- `.702`, the AHB completer/subordinate readiness audit;
- `.701`, the post-AHB profile-alias selector;
- `.700`, bounded AHB `.ahb` profile-alias behavior;
- `.697`, bounded AHB requester `.ppif` behavior;
- current AHB mdBook boundary coverage;
- direct requester seed `fsm/amba_requester.fsm`;
- APB lower-layer completer and composition precedent;
- current `docs/vendor/` inventory;
- README, ROADMAP_V2, task tree, Memory, and Knowledge Map.

The local vendor inventory currently contains AXI, PSS, UVM, and SystemRDL
references, but no AHB/AHB-Lite source reference:

```text
docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf
docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf
docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf
docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf
docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf
```

The existing AHB seed and IAL2 sources are requester-only:

```text
fsm/amba_requester.fsm
ppif/ahb_requester.ppif
ppif/ahb_requester.ahb
```

Later status: `.706` imported the local AHB source reference, `.707`
extracted source-backed subordinate facts, `.708` selected the lower-layer
seed contract, and `.709` shipped `fsm/ahb_lite_subordinate.fsm` with
support-accounting identity `protocol.ahb_lite_subordinate`. This `.703`
selector remains the historical reason source-backed evidence was required
before the direct subordinate seed contract.

## Finding

`.702` established that a lower-layer AHB subordinate seed must precede IAL2
AHB completer/subordinate public contract selection. `.703` now finds that the
seed contract itself needs source-backed subordinate evidence first.

Selecting exact subordinate seed semantics from requester-only code would
force the project to infer subordinate-side transfer qualification,
ready/response timing, read/write storage behavior, reset/default outputs, and
unsupported-transfer policy. That is not signoff-level enough for a new
protocol endpoint.

## Selected `.704` Scope

`.704` should audit and route the source-backed evidence required for the
lower-layer AHB subordinate seed contract.

The audit should determine:

- whether an acceptable local AHB/AHB-Lite source reference already exists or
  must be added through a separately owned artifact/reference step;
- which source-backed signal names and roles are admissible for the first
  subordinate seed;
- whether the first seed should model AHB-Lite subordinate behavior, a
  full-AHB subordinate boundary, or a narrower named subset;
- the minimum source-backed transfer, ready/response, read/write, reset, and
  error-policy facts needed before selecting a direct `.fsm` seed contract;
- whether the first seed can target requester compatibility without
  over-claiming interconnect/decode behavior;
- the exact next owner: lower-layer seed contract selection, reference
  ingestion, or another prerequisite; and
- validation and rollback.

`.704` must not add a source reference, seed, parser/generator behavior,
support-accounting entry, manifest entry, test behavior, generated artifact, or
HDL/runtime behavior unless a later exact owner selects that work.

## Rejected Alternatives

Selecting a direct AHB subordinate seed contract in `.703` is rejected because
the repo lacks a local source-backed subordinate reference.

Adding the seed immediately is rejected because neither the source-backed
contract nor support-accounting identity is selected.

Selecting IAL2 AHB completer/subordinate public contract is rejected because it
depends on a lower-layer seed, and the seed contract is still unselected.

AHB interconnect/decode remains later because it needs at least one selected
subordinate endpoint first.

APB evidence is useful for workflow shape, but it cannot define AHB
subordinate protocol behavior.

## Validation

The selector validation is documentation-only:

```bash
rg --files docs/vendor
perl -we 'for my $f (qx(rg --files docs/vendor)) { die $f if $f =~ /(?:ahb|ahb-lite|ihi00(?:11|33))/i } print "no local AHB vendor reference\n";'
./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm
perl -we 'for my $f (qx(rg --files fsm ppif perl/FSM/IAL2/ProtocolIntent t)) { die $f if $f =~ /ahb.*(?:completer|subordinate|slave)|(?:completer|subordinate|slave).*ahb/ } print "no AHB completer/subordinate fixture\n";'
rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.703|IAL2-FEATURE-COMPLETENESS-FRONTIER\.704|source-reference|lower-layer AHB subordinate seed' \
  docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md \
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md \
  README.md ROADMAP_V2.md MEMORY.md
```

Closeout reruns Knowledge Map, mdBook, memory, docs path, diff, and doctrine
gates.

## Rollback

Rollback of `.703` removes this selector, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/Memory updates. No runtime behavior, source
sample, parser rule, generator, support-accounting entry, test, generated
artifact, public suffix behavior, direct backend behavior, or backend-language
behavior is changed by this selector.
