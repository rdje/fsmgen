# IAL2 Post Exact-Four Paired Composition Next-Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.824`

Date: 2026-07-30

## Outcome

Select one byte-identical `.ahb` profile alias as the next exact owner:

```text
ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb
```

Completed `IAL2-FEATURE-COMPLETENESS-FRONTIER.825`, activated only after clean
selector commit `5b601fffc`, ships the selected alias. It
mirror the shipped generic source byte-for-byte, reuse the existing AHB suffix
and lowering machinery, add exact support accounting and one focused parity
test, and reuse t1537 as the sole assertion-enabled runtime proof.

This selector changes no parser, generator, public source, support entry,
test, checked-in artifact, report, semantic/MCP API, HDL/runtime, simulator
integration, backend, protocol behavior, HIAL/VIAL, VHDL, verification
generation, scale implementation, or decision-0020 behavior.

## Why This Owner Is Next

The matching alias is the smallest adjacent roadmap slice after generic
one-window exact-four pairing ships at 329/370/53 split 27 `.ppif` / 26
`.ahb`:

- its future bytes are identical to the shipped generic source;
- current `.ahb` suffix handling already accepts the aggregate and removes
  only profile-alias exposure residue;
- requester, subordinate, interconnect, reports, artifacts, semantic export,
  MCP, HDL, and assertion runtime already exist;
- exact-one/two/three paired generic/profile families establish the same
  generic-first cadence; and
- one focused parity test can prove the public surface without compiling a
  second simulation.

The two-subordinate exact-four topology is larger: it needs a new four-child
generic source and independent two-command assertion runtime before any alias.
Counts above four and broader policy/status/burst/signal behavior add new
public semantics. Generic priority, HIAL/VIAL, verification generation,
portability, and large-design scale are broader architecture owners. Those
remain important and proposed, but they do not outrank this proven data-only
sibling closure.

## Disposable Same-Volume Proof

A repository-local candidate copied the exact 4,978 source bytes to:

```text
.artifacts/tmp/ial2-feature-selector-824/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb
```

The candidate proved:

```text
strict/check:        success, zero diagnostics, intentionally unmatched support
module/root:         ahb_tb / top
children/signals:    3 / 28
IAL1 artifacts:      3
IAL0 artifacts:      4
requester:           before_beat=2, beats=4, width-three counter
subordinate policy:  parks_on=[busy]
fabric ownership:    one_hot_accepted_subordinate
semantic schema:     normalized v1
MCP provenance:      read_only=true, shell_access=false
public verifier:     pass
```

The generic source retains alias-deferred residue; the `.ahb` interpretation
removes aggregate/requester/subordinate alias residue and alias-exposure text
through existing suffix handling. Substantive exact-four, topology, burst,
signal, direct-backend, and verification-output residue remains unchanged.

The real repo-relative `fsmgen_semantic_introspect` call returns the same
`ahb_tb`/`top`/3-child facts with unmatched disposable support. Public
`--verify-hdl` succeeds. The exact one-file workspace was removed and a residue
census leaves only the pre-existing 491-byte project-local `xcrun_db` cache.

## Selected Public And Support Contract

`.825` must add exactly:

```text
alias path:
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb

support id:
  intent.ahb_profile_alias_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park

coverage:
  ial2_ahb_profile_alias_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind / class / strict:
  ial2_profile_alias / supported_smoke / true

HDL module / semantic root / child count:
  ahb_tb / top / 3
```

One additive support-accounted alias now establishes 330 protocol fixtures,
371 supported-smoke and strict-supported fixtures, and 54 AHB paths split evenly
between 27 `.ppif` sources and 27 `.ahb` aliases.

## Selected Test Contract

Select:

```text
t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t
```

t1538 proves:

- tracked alias existence and byte identity with the generic source;
- parse/report equality except exact alias-residue cleanup;
- exact 3 IAL1/4 IAL0 artifact and width-three requester equality;
- strict check and exact support identity/coverage/source kind;
- schedule JSON and normalized semantic JSON parity;
- a real repo-relative read-only shell-disabled MCP call;
- repository-derived same-volume review output and public `--verify-hdl`;
- targeted wrong-profile/wrong-object `.ahb` diagnostics; and
- preservation of generic exact-four, exact-three paired alias, standalone
  exact-four requester alias, and adjacent aggregate identities.

t1538 compiles no second simulation or testbench. Assertion-enabled t1537
remains authoritative for five presentations, four data beats, one BUSY
episode, four qualified BUSY events, internal `4 -> 3 -> 2 -> 1 -> 0`, one
resumed `SEQ`, and storage `32'h44332211`.

## Simulator And Architecture Boundary

Verilator remains the event-capable compiled portable-fast supported-subset
profile. It is not promoted to a full-SystemVerilog-LRM/UVM authority. The
proposed HIAL/VIAL architecture retains a separate qualified full-language
SystemVerilog/UVM profile plus independent VHDL and mixed-language profiles.

## Explicit Deferrals And Rollback

The two-subordinate exact-four topology, counts above four, multiple insertion
points, runtime/policy/random BUSY insertion, distinct local bus-BUSY status,
broader bursts/signals/managers/fabrics, generic priority, other protocols and
backends, HIAL/VIAL activation, verification generation, VHDL, scale
implementation, and decision 0020 remain separate task-tree-owned work.

Rollback of `.825` removes the alias/support/t1538 and returns current
accounting to 329/370/53 split 27/26; the generic source and shared t1537
runtime remain shipped. The selector evidence itself remains historical.
