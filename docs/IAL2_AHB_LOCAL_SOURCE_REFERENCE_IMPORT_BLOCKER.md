# IAL2 AHB Local Source Reference Import Blocker

Date: 2026-06-29

Owning task-tree leaf: `IAL2-FEATURE-COMPLETENESS-FRONTIER.705`

Status: historical blocker, resolved by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.706`.

Resolution record:
[docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md](IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md).

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.705` did not import an AHB/AHB-Lite source
reference artifact. The repo-local approved/provided inputs do not contain an
acceptable AHB/AHB-Lite reference artifact under tracked `docs/vendor/` or the
local `.cache/local-references/` mirror.

The AHB subordinate source-fact extraction and lower-layer direct `.fsm`
subordinate seed contract were blocked at the end of `.705`. `.706` later
imported the user-approved official AHB/AHB-Lite source artifact under
`docs/vendor/arm/amba/ahb/`, recorded its SHA-256 and git-ignore status, and
selected `.707` as the next source-fact extraction owner.

## Evidence Read

This blocker records the executable result of the import prerequisite selected
by `IAL2-FEATURE-COMPLETENESS-FRONTIER.704`.

The slice read:

- `docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md`;
- `docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md`;
- `docs/tasks/AXI-SPEC-LOCAL-REFERENCE-IMPORT.md`;
- `docs/tasks/ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.md`;
- `docs/vendor/`;
- `.cache/local-references/`;
- `README.md`;
- `ROADMAP_V2.md`;
- `docs/book/src/16c-ial2-ahb.md`;
- `docs/book/src/14-feature-backlog.md`;
- `docs/TASK_TREE.md`;
- `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`;
- `MEMORY.md`;
- `KNOWLEDGE_MAP.md`.

## Local Artifact Search

The tracked vendor inventory contains AXI, PSS, UVM, and SystemRDL references:

```bash
rg --files docs/vendor
```

Result:

```text
docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf
docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf
docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf
docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf
docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf
```

The focused repo-local vendor/cache scan found no AHB/AHB-Lite reference
artifact:

```bash
perl -we 'for my $f (qx(rg --files -uu docs/vendor .cache/local-references 2>/dev/null)) { die $f if $f =~ /(?:ahb|ahb-lite|ihi00(?:11|33))/i } print "no local AHB/AHB-Lite reference artifact in repo-local vendor/cache inputs\n";'
```

Result:

```text
no local AHB/AHB-Lite reference artifact in repo-local vendor/cache inputs
```

The existing source/fixture scan still finds no AHB completer, subordinate, or
slave fixture/generator:

```bash
perl -we 'for my $f (qx(rg --files fsm ppif perl/FSM/IAL2/ProtocolIntent t)) { die $f if $f =~ /ahb.*(?:completer|subordinate|slave)|(?:completer|subordinate|slave).*ahb/ } print "no AHB completer/subordinate fixture\n";'
```

Result:

```text
no AHB completer/subordinate fixture
```

## Required Unblock Action

Resolved by `.706`: the user approved an official AHB/AHB-Lite source artifact
and it was imported under `docs/vendor/arm/amba/ahb/`.

After that artifact exists locally, `.707` must:

- extract only source-backed AHB subordinate facts;
- select the lower-layer direct `.fsm` subordinate seed contract before any
  IAL2 AHB completer/subordinate parser, generator, source,
  support-accounting, manifest, test, schedule/check/semantic JSON, generated
  artifact, HDL/runtime, direct-backend, verification-output,
  backend-language variant, AXI, APB, or VHDL behavior changes.

## Non-Changes

This slice does not import a source reference, extract source facts, select or
add an AHB subordinate seed, add parser/generator/source/support-accounting
behavior, add tests, change generated artifacts, change HDL/runtime behavior,
change direct backend behavior, change verification-output generation, or
change backend-language variant, AXI, APB, or VHDL behavior.
