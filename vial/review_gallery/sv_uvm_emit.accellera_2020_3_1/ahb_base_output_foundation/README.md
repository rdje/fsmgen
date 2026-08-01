# Native UVM AHB base-output foundation gallery

This directory is the first checked review gallery for
`sv_uvm_emit.accellera_2020_3_1`. The files are byte-for-byte snapshots of the
native VIAL UVM emitter output for:

- `vial/ahb_subordinate_base_output_arbitration.vial`
- `ppif/ahb_lite_subordinate.ppif`
- plan `plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574`

The gallery intentionally contains the generated UVM-facing sources rather
than another copy of the generated DUT. The canonical emitted artifact graph
also includes that deterministic HIAL DUT, the backend/source-map manifests,
the exact methodology profile, and the static-validation report.

These files establish deterministic emission and structural-review evidence
only. They have not been preprocessed, parsed, compiled, elaborated, or run
against UVM library bytes, and they produce no verification result or parity
claim. Review findings should be recorded in the owning task-tree rather than
silently patched only in this snapshot.
