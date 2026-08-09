# OSVVM 2026.05 advanced-services emission gallery

This checked gallery is the deterministic, provider-dependent companion to
the provider-free portable VHDL gallery. Regenerate it from the repository
root with:

```text
perl scripts/refresh_vial_vhdl_osvvm_gallery.pl
```

Verify the checked bytes without rewriting them with:

```text
perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check
```

The profile consumes the exact recursive OSVVM 2026.05 materialization under
`.artifacts/cache/providers/osvvm/2026.05/source`. Provider bytes are ignored
cache data; `evidence/provider-materialization.json` freezes all 14 repository
tree/commit identities, 13 gitlinks, and 14 tracked licence-file identities.
No notice file exists in the release, and the exact pinned `Documentation`
repository contains no tracked licence or notice file; the evidence infers no
licence coverage for that repository.

Seven exact adapter mappings cover isolated native randomization,
supplementary coverage, scoreboarding and reporting, component coordination,
provider memory, and an OSVVM Common address-bus transaction type. The six
portable VHDL sources remain byte-identical. OSVVM cannot rerandomize portable
decisions, move phase barriers, redefine comparison or coverage meaning,
change the closed trace, or replace the normalized result.

The checked `.15.7` qualification now proves the exact combined OSVVM 2026.05
plus GHDL 6.0.0 LLVM-JIT profile for this bounded fixture. It compiles the 44
OSVVM core and 17 Common sources in their exact selected VHDL-2008 order,
analyzes this adapter and generated fixture, elaborates and executes the
fixture plus a provider probe twice, preserves the closed 42-record trace and
normalized result across 19 applicable portable parity paths, and validates
four byte-identical supplementary OSVVM reports. Rerun it under the repository
RAM guard with:

```text
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
```

The bounded qualification is not general provider breadth. The Common
address-bus type is analysis-qualified but no OSVVM verification-component
transaction executes. UVVM, PSL, complete VHDL-2008, another simulator,
mixed-language execution, legacy-package analysis, general parity, and scale
remain explicit non-claims.
