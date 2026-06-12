# 0016 — `.ppif` is the first public IAL2 container

- Date: 2026-06-12
- Type: architecture
- Status: accepted
- Refines: `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md`
- Complements: `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md`

## Context

Decision `0014` intentionally left the generic IAL2 extension open among
`.pif`, `.ppi`, and `.ppif`. Decision `0015` kept protocol-specific extensions
available as future vocabulary/profile aliases, but did not choose a first
generic container.

The first in-process behavior-bearing IAL2 slice now exists:
`FSM::IAL2::ProtocolIntent::ValidReadyChannel`. The next public parser/CLI
step needs a closed generic file-surface decision before any suffix
recognition or file parsing code is written.

## Decision

Use `.ppif` as the first public generic IAL2 file extension.

`.ppif` means Protocol/Platform Intent Format. It is the clearest of the
candidate spellings because it names both protocol intent and platform intent,
while still making clear that this is a file format. `.pif` and `.ppi` remain
historical candidates, not first implementation suffixes.

The first public `.ppif` source shape is Lispish and protocol/platform-generic.
It selects an AXI vocabulary through a profile clause instead of using an
AXI-only file extension:

```text
(protocol-platform-intent axi_aw_valid_ready
  (profile axi4)
  (source
    (object axi-valid-ready-aw)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (valid-ready-channel axi_aw
    (channel AW)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid awvalid)
    (ready awready)
    (payload
      (awaddr width 32)
      (awlen width 8))))
```

The first parser/CLI implementation may support exactly one
`valid-ready-channel` object per `.ppif` file. Later owners may extend the file
to multiple objects, platform placement clauses, or other protocol profiles.

The mandatory lowering chain remains:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Direct `.ppif` to `.fsm` generation is forbidden.

## Consequences

- `.ppif` is the canonical generic IAL2 suffix for the first public file
  implementation.
- `.isf` remains IAL1 and must not accept IAL2 source forms.
- The first `.ppif` parser should map the source shape above to
  `FSM::IAL2::ProtocolIntent::ValidReadyChannel`.
- The parser/CLI implementation must expose generated `.isf` before generated
  `.fsm` and must return or emit the IAL2 source-anchor/residue report.
- `.pif` and `.ppi` are not accepted aliases in the first public implementation
  unless a later exact owner selects them.
- Protocol-profile aliases such as `.axi` remain allowed later by decision
  `0015`, but they are not part of the first public file-surface slice.
- Any parser/CLI implementation still requires a new exact task-tree owner,
  focused tests, mdBook examples, Knowledge Map updates, and commit workflow.
