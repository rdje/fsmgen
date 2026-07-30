# IAL2 Post Rustdoc-Repair Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.838` selects proposed
`PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1` as the next exact owner.

The selected leaf must inventory generated composition instance-name producers,
reproduce reserved-word handling across the supported target languages, and
select one bounded shared remediation contract without changing behavior. This
selector does not activate or modify the selected child before its own commit
is clean.

## Current-HEAD Evidence

The mismatch is current and target-visible:

- AHB seeds its generated interconnect-role instance as legal `fabric`;
- APB still seeds the same generated role as `interconnect`;
- both local uniqueness helpers deconflict only against top-port and sibling
  names, not target-language reserved words;
- strict HDL verification of public
  `ppif/apb_composition_multi_peripheral.ppif` emits
  `apb_interconnect interconnect (` and Verilator rejects the instance token as
  unexpected at generated line 3134.

The failed probe ran on clean selector-activation commit `070d6ba2d`. Its exact
repository-local SystemVerilog output was inspected and removed; the lowerer's
temporary combined source cleaned itself up.

## Candidate Comparison

| Candidate | Result | Evidence |
| --- | --- | --- |
| Protocol-composition instance-identifier audit `.1` | **selected** | One public APB composition reproduces a target-language parse failure, while AHB carries a local one-off avoidance; the no-behavior audit is the smallest ungated owner that can prevent another protocol fork. |
| Four-document lifecycle review | remains proposed | Director direction schedules the discussion but keeps it inactive; decision `0025` controls the interim split and both legacy status files remain untouched. |
| HIR and host-language builder frontiers | remain proposed | Both are architecture selections broader than one reproduced HDL-validity audit. |
| HIAL/VIAL, scale, and MCP-write horizons | remain proposed | Their portable/native semantics, workload/oracle, or trust-boundary scopes are materially larger. |
| RAM guard, t1436, transaction layering, and AXI book coherence | ineligible | Their task trees retain explicit director gates or no-pivot direction. |

## Selected Contract And Rollback

The child may inventory and probe instance-name producers across AHB, APB, AXI,
reusable-library, actor-network, SystemVerilog, and VHDL paths. It may select a
fail-closed diagnostic or deterministic shared rename/sanitization contract and
must record report/public-name consequences plus focused validation. It must not
change implementation behavior during the audit.

It must keep authored legal names stable, avoid renaming module/object identities
without evidence, preserve the project-document lifecycle boundary, and leave
every director-gated direction inactive. Rollback returns `.838` to active and
leaves the candidate proposed; no source or product behavior changed in this
selector.

## Closeout Evidence

- The APB public probe fails only at Verilator's `unexpected interconnect`
  diagnostic for the generated child instance; its exact output is removed.
- Source inspection proves the current APB `interconnect` versus AHB `fabric`
  seed and the absence of reserved-word checking in both local collision helpers.
- Feature-backlog status, live-book-path, and relative-path audits pass with
  `Files=3, Tests=40`.
- Knowledge Map generation/check passes at 1,071 facts / 5,513 question keys;
  mdBook HTML build and diff hygiene pass.
- `MEMORY.md` remains at its 60-line cap, `README.md` remains 246 lines,
  neither legacy status file changed, and no background job remains.

Clean selector commit `b0bcb12b5` activates only the selected no-behavior
identifier audit through continuity changes. APB/AHB/AXI/library/actor-network
name producers, generated outputs, tests, reports, and target behavior remain
unchanged during activation.
