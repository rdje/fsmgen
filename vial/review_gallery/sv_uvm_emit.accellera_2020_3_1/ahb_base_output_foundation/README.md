# Native UVM AHB base-output review gallery

This `sv_uvm_emit.accellera_2020_3_1` gallery contains exact snapshots for:

- `vial/ahb_subordinate_base_output_arbitration.vial`
- `ppif/ahb_lite_subordinate.ppif`
- plan `plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574`

Nine UVM-facing sources cover context, timing, notifications, stimulus, TLM,
scoped configuration/factory, private RAL/constraint previews, coverage, bound
SVA, models, scoreboard, fault, diagnostic/result collection, lifecycle, and
top. The sixteen-artifact graph also has the HIAL DUT, source map, methodology
profile, structural report, selected mapping matrix, review workflow, and
backend manifest. Public VIAL owns selected meaning and replay; native solving
is never called.

Regenerate the exact snapshots from the repository root:

```console
perl scripts/refresh_vial_native_uvm_gallery.pl
```

Check them without writing files:

```console
perl scripts/refresh_vial_native_uvm_gallery.pl --check
```

`selected-mapping-matrix.json` accounts once for each of the 25 emitted
foundations. `review-workflow.json` distinguishes regeneration, byte checking,
structural validation, pending visual review, future experimental compilation,
and future qualified runtime.

These files prove deterministic emission and structural review only. They have
not been preprocessed, parsed, compiled, elaborated, or run. The collector is
generated code, not a result manifest or parity claim. Record review findings
in the owning task-tree, not only this snapshot.
