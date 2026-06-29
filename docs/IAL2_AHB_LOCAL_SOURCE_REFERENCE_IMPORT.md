# IAL2 AHB Local Source Reference Import

Date: 2026-06-29

Owning task-tree leaf: `IAL2-FEATURE-COMPLETENESS-FRONTIER.706`

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.706` imported the user-approved official
Arm AMBA AHB Protocol Specification PDF into the tracked repo-local vendor
tree:

```text
docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf
```

The provided source was identified by the chipdoc-relative fragment:

```text
arm/amba/core/ahb/current/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf
```

The machine-local absolute source path is intentionally not recorded in this
tracked document because repository documentation uses repo-relative paths.

## Artifact Metadata

`pdfinfo` reports:

```text
Title:          AMBA AHB  Protocol Specification
Subject:        ARM AMBA 5 AHB Protocol Specification AHB5, AHB-Lite Advanced High-performance Bus (AHB) Interconnect for Cortex-M Processors and Peripherals via Advanced Peripheral Bus (APB) Bridge Interface
Keywords:       AMBA,Interconnect,AHB Interconnect,AHB Peripherals,Cortex-M
Author:         Arm Limited
Creator:        FrameMaker 2019
Producer:       Acrobat Distiller 21.0 (Windows)
CreationDate:   Thu Sep  9 15:10:18 2021
ModDate:        Thu Sep  9 15:10:51 2021
Pages:          104
Encrypted:      no
File size:      957201 bytes
PDF version:    1.7
```

The copied artifact SHA-256 is:

```text
2ba2920e050e1d9f6a1b728dfef85e66eb400a3c29d774b086b7de71c768f724
```

`git check-ignore -v` produced no match for the imported path, so the PDF is
git-trackable.

## Follow-On Owners

The source-reference artifact blocker recorded by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.705` is resolved for the purpose of local
source availability. `IAL2-FEATURE-COMPLETENESS-FRONTIER.707` completed the
first source-backed AHB/AHB-Lite subordinate fact extraction pass in
[docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md](IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md).
`IAL2-FEATURE-COMPLETENESS-FRONTIER.708` now owns lower-layer direct `.fsm`
subordinate seed contract selection.

That seed-contract follow-on must select the exact first direct `.fsm`
subordinate seed boundary before any seed file or IAL2 AHB
completer/subordinate behavior is added.

## Non-Changes

This slice does not extract source facts, select or add an AHB subordinate
seed, add parser/generator/source/support-accounting behavior, add tests,
change generated artifacts, change HDL/runtime behavior, change direct backend
behavior, change verification-output generation, or change backend-language
variant, AXI, APB, or VHDL behavior.
