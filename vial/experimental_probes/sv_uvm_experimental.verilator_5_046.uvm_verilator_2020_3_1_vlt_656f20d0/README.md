# Native UVM experimental probe

This directory holds non-product feasibility evidence for the exact profile
`sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0`.
It does not advertise a supported native-UVM backend.

The selected source is the CHIPS Alliance `uvm-verilator` branch
`uvm-2020-3.1-vlt` at commit
`656f20d087370a7c742e00188d20bbf30fa95339`. Materialize that immutable
checkout at the repository-relative cache path printed in
`probe-report.json`; the probe never fetches network content. Then regenerate
or verify the evidence from the repository root:

```console
mkdir -p .artifacts/cache/uvm-verilator/656f20d087370a7c742e00188d20bbf30fa95339
git clone --no-checkout https://github.com/chipsalliance/uvm-verilator.git .artifacts/cache/uvm-verilator/656f20d087370a7c742e00188d20bbf30fa95339/source
git -C .artifacts/cache/uvm-verilator/656f20d087370a7c742e00188d20bbf30fa95339/source checkout --detach 656f20d087370a7c742e00188d20bbf30fa95339
git -C .artifacts/cache/uvm-verilator/656f20d087370a7c742e00188d20bbf30fa95339/source rev-parse HEAD HEAD^{tree}
```

The final command must print the selected commit and tree recorded in the
report. Network materialization is an explicit operator step; ordinary native
UVM emission and the probe itself remain offline.

Run or byte-check the experiment:

```console
perl scripts/run_vial_native_uvm_experimental_probe.pl
perl scripts/run_vial_native_uvm_experimental_probe.pl --check
```

Every stage has its own argv, status, diagnostic owner, normalized transcript
digest, and bounded timeout/output policy. `UVM_NO_DPI` applies throughout.
`--bbox-unsup` applies only to the deliberately separate fixture
compile/elaboration attempt. Neither deviation can qualify runtime semantics.

The checked report is an observation of the exact profile, not a promise that
another tool, source revision, host, VIAL fixture, or complete UVM feature set
will behave the same way.
