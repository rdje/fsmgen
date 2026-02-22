# MEMORY
This is the live continuity document for fast session recovery after crashes, restarts, or agent handoffs.
## Purpose
- Preserve the minimum complete context needed to resume work immediately.
- Capture key technical decisions and current implementation status.
- Reference canonical docs for deeper details instead of duplicating everything.
## Non-negotiable workflow (user requirement)
After each completed task, always do this in order:
1. Update `MEMORY.md` with new state and next actionable direction.
2. Update other live docs as needed (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, and any user-facing docs impacted by the change).
3. Run validation for the task scope (syntax checks + regression tests when applicable).
4. Run commit workflow:
   - write `git_message_brief.txt`
   - commit with `git commit -F git_message_brief.txt`
   - include `Co-Authored-By: Warp <agent@warp.dev>`
   - clear `git_message_brief.txt` after commit (`truncate -s 0 git_message_brief.txt`)
## Current technical status (updated 2026-02-22)
- Assignment families are implemented and stabilized: `c`, `r`, `m`, `rm`, `mr`, `pN`.
- `pN` semantics are authoritative and must not regress:
  - `<N` means exact delay to cycle `Q+N` (not duration).
  - one-cycle pulse only.
  - `<N 1`: positive pulse (`0->1->0`), `<N 0`: negative pulse (`1->0->1`).
- Regression baseline is currently green:
  - `prove -I perl t`
  - `Files=5, Tests=117, PASS`.
## EnableGraph extraction status
Behavior-preserving extraction from `FlattenedDT` into `EnableGraph` is active and working.
### Already moved into `perl/FSM/Synthesis/EnableGraph.pm`
- `build_unified_assignment_analysis`
- `group_assignments_by_rhs`
- `generate_complete_enable_structure`
- `build_multiplexer_config`
- `generate_unified_wen_en_signals`
- `generate_dt_enables_from_analysis`
- `generate_lhs_enables_from_analysis`
- `generate_signal_assignments`
- `generate_unified_comb_mux`
- `generate_unified_flop_mux`
- `generate_unified_pulse_delay_logic`
- `get_pulse_delay_cycles_for_lhs`
- `get_pulse_active_level_for_lhs`
- `normalize_rhs_logic_level`
- `clean_signal_name`
- `generate_rhs_based_enable_name`
- `signal_uses_register_assignment`
- `get_signal_assignment_type`
### Still strong candidates for next slices
- remaining phase-3/per-assignment support helpers still owned by `FlattenedDT` (for example reset/default helper seams and related output-decision helpers), extracted incrementally with parity checks.
- broader synthesis-layer boundary tightening once helper ownership is sufficiently centralized in `EnableGraph`.
## Recent milestone commits (most recent first)
- `a82d5cd` Delegate enable naming helper ownership to EnableGraph
- `59a86d3` Delegate pulse helper analysis ownership to EnableGraph
- `d65e86a` Delegate unified pulse-delay emission to EnableGraph
- `a2725c9` Add live MEMORY.md continuity document and update workflow policy
- `0bf08d4` Delegate unified flop mux emission to EnableGraph
- `1f29750` Delegate unified combinational mux emission to EnableGraph
- `d4dc317` Delegate unified phase-3 assignment orchestration to EnableGraph
- `32892d4` Delegate unified phase-2 WEN/EN emission to EnableGraph
- `f62d6fe` Extract unified assignment-analysis orchestration into EnableGraph
- `6bb94d4` Extract multiplexer config assembly into EnableGraph synthesis layer
- `36a574f` Extract RHS grouping orchestration into EnableGraph synthesis layer
- `2a05831` Add assignment edge/snapshot regressions and extract initial EnableGraph layer
- `fe1cc3c` Implement c/r/m/rm/mr/pN assignment semantics and document pN as Q+N delay
## Quick resume checklist
1. Read `MEMORY.md` first.
2. Read latest entries in `CHANGES.md` and `DEVELOPMENT_NOTES.md`.
3. Check repo state: `git --no-pager status --short`.
4. Run baseline regression: `prove -I perl t`.
5. Continue the next extraction slice with behavior-preserving delegation.
6. Before committing, update `MEMORY.md` and related live docs again.
## Live document references
- `CHANGES.md`: persistent technical change history.
- `DEVELOPMENT_NOTES.md`: rationale, architecture, and policy-level technical knowledge.
- `docs/USER_GUIDE.md`: user-facing usage guidance.
- `README.md`: project overview and quickstart.
