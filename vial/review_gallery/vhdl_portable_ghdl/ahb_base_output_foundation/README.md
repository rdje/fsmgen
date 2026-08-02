# Portable VHDL foundation review gallery

This gallery is the byte-locked output of the private
`vhdl_portable_ghdl` foundation emitter for
`vial/ahb_subordinate_base_output_arbitration.vial` bound to
`ppif/ahb_lite_subordinate.ppif`. Its immutable execution identity is
`plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574`.

The five sources show the generated HIAL VHDL DUT, provider-free typed value
and logical-time packages, fixture metadata, and the direct entity/port-bound
testbench foundation. Driver, sampler, inactive-edge scheduler, scenario,
model, probe-adapter, checking, trace, and result behavior belongs to later
slices and is deliberately absent here.

The JSON files preserve the closed backend manifest, complete
foundation-scope source map, ordered source list, exact selected-but-unexecuted
GHDL 6.0.0 command shapes, and structural-only validation report. GHDL and
OSVVM bytes were neither required nor fetched during emission.

These artifacts have not been analyzed, elaborated, or run. They provide no
runtime, result, parity, PSL, full VHDL-2008, OSVVM, mixed-language, or product
support claim. The older `vhdl-observation-package` command remains a separate
unchanged inert compatibility surface and is not consumed by this graph.

Regenerate the deterministic snapshots from the repository root:

```text
perl scripts/refresh_vial_vhdl_foundation_gallery.pl
```

Check them without writing:

```text
perl scripts/refresh_vial_vhdl_foundation_gallery.pl --check
```
