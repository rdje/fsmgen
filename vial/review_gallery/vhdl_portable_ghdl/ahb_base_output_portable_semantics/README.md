# Portable VHDL semantics review gallery

This gallery is the byte-locked output of the private
`vhdl_portable_ghdl` emitter for
`vial/ahb_subordinate_base_output_arbitration.vial` bound to
`ppif/ahb_lite_subordinate.ppif`. Its immutable execution identity is
`plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574`.

The six sources show the generated HIAL VHDL DUT, provider-free typed value
and logical-time packages, exact operation/scenario/fiber/model metadata, a
direct entity/port-bound testbench, and the declared probe adapter. The
testbench emits strong four-state drivers, samplers that preserve the original
`std_logic` symbol, one inactive-edge scheduler, bounded scenario/fiber state,
and deterministic event-counter models.

The generated scheduler alone owns VIAL sample, react, check, and next-drive
ordering. The clock process supplies time but has no semantic authority;
delta-cycle and process wake-up order are deliberately excluded from the
contract. The probe adapter is the only generated source allowed to use a
VHDL-2008 external name, and it names the bridge-declared DUT target directly.

Scoreboard comparison, coverage, fault application, procedural checks,
diagnostics, trace closure, and normalized results belong to the next slice.
The current check phase is therefore an explicit placeholder rather than an
implemented or qualified checking path.

The JSON files preserve the closed backend manifest, complete
portable-semantics source map, ordered source list, exact
selected-but-unexecuted GHDL 6.0.0 command shapes, and thirteen-check static
validation report. GHDL and OSVVM bytes were neither required nor fetched
during emission.

These artifacts have not been analyzed, elaborated, or run. They provide no
runtime, result, parity, PSL, full VHDL-2008, OSVVM, mixed-language, or product
support claim. The older `vhdl-observation-package` command remains a separate
unchanged inert compatibility surface and is not consumed by this graph.

Regenerate the deterministic snapshots from the repository root:

```text
perl scripts/refresh_vial_vhdl_portable_gallery.pl
```

Check them without writing:

```text
perl scripts/refresh_vial_vhdl_portable_gallery.pl --check
```
