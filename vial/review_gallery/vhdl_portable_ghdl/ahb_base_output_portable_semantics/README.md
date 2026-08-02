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
deterministic event-counter models, one capacity-four scoreboard, two portable
coverage counters, a one-cycle substitution-fault seam, procedural checks,
bounded diagnostic records, closed trace framing, and a normalized-result
projection.

The generated scheduler alone owns VIAL sample, react, check, and next-drive
ordering. The clock process supplies time but has no semantic authority;
delta-cycle and process wake-up order are deliberately excluded from the
contract. The probe adapter is the only generated source allowed to use a
VHDL-2008 external name, and it names the bridge-declared DUT target directly.

The scoreboard rejects overflow and compares only against queued expected
items. Coverage preserves the authored `not_stalled` and `stalled` bins. The
unsupported-size scenario applies its authored substitute without mutating
the source transaction value. Procedural checks retain timeout, success/error,
declared-probe, and unknown-value evidence; PSL and native-provider requests
remain rejected. Trace header/footer closure and result consistency are
explicit generated invariants. The result projection includes every normalized
top-level family, per-scenario status/time, aggregate checking metrics, and the
stored diagnostic code/outcome/logical time. Its JSON uses VHDL quote doubling;
C-style escape sequences fail static validation.

The JSON files preserve the closed backend manifest, complete
portable-checking source map, ordered source list, exact
selected-but-unexecuted GHDL 6.0.0 command shapes, and twenty-check static
validation report. GHDL and OSVVM bytes were neither required nor fetched
during emission.

These artifacts have not been analyzed, elaborated, or run. They provide no
runtime, produced-result, parity, PSL, full VHDL-2008, OSVVM, mixed-language,
or product support claim. The older `vhdl-observation-package` command remains a separate
unchanged inert compatibility surface and is not consumed by this graph.

Regenerate the deterministic snapshots from the repository root:

```text
perl scripts/refresh_vial_vhdl_portable_gallery.pl
```

Check them without writing:

```text
perl scripts/refresh_vial_vhdl_portable_gallery.pl --check
```
