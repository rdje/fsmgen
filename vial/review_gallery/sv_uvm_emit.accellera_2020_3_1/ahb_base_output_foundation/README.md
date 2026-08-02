# Native UVM AHB base-output review gallery

This accumulating `sv_uvm_emit.accellera_2020_3_1` gallery contains byte-exact emitter snapshots for:

- `vial/ahb_subordinate_base_output_arbitration.vial`
- `ppif/ahb_lite_subordinate.ppif`
- plan `plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574`

Seven UVM-facing sources cover context/components, timing, notifications,
active stimulus/scenarios, TLM, scoped factory/configuration, private RAL and
native-constraint previews, lifecycle/results, and the top. The twelve-artifact
graph also contains the HIAL DUT, manifests, profiles, and static report. VIAL
owns transactions, scenarios, and decision replay; generated scenarios never
call the native solver.

These files prove deterministic emission and structural review only. They have not been preprocessed, parsed, compiled, elaborated, or run, and produce no result or parity claim. Record review findings in the owning task-tree rather than patching only this snapshot.
