# Fixed unary reduction observer

Owner: `ISF-REDUCTION-DELIVERY.1.3.2`, coordinated with HIAL `.11.7.1`.

This integration selects the committed `t/2090-isf-unary-reduction-runtime.t`
witness. Its fixed feature coverage is SystemVerilog and compatibility-Verilog
positive compile/runtime pairs, followed by the actual wrong-source
SystemVerilog pair. Qualification uses the immutable native-group witness,
failure-only wrapper, stage observer and finite control fixture. It does not
execute feature HDL, a compiler or a version probe.

`producer-paths.json` fixes the complete tracked `bin/` and `perl/` input
membership at the witness revision. Admissions bind every named producer,
source, bench, vector table, test and integration input. The saved verifier
independently derives producer membership from that Git revision. Original
compile/runtime arguments, results, bounds and errno remain unchanged.

From the repository root, before sealing qualification, use a fresh prefix:

```sh
scripts/run_with_ram_guard.sh -- bash -c 'set -o noclobber; prove -v docs/audits/unary-observer-20261022/qualify.t :: oct22unary > .artifacts/logs/unary-observer-qualification-20261022.log 2>&1'
python3 -B docs/audits/unary-observer-20261022/seal.py oct22unary .artifacts/logs/unary-observer-qualification-20261022.log
python3 -B docs/audits/unary-observer-20261022/verify.py
```

The qualifier rejects other targets, coverage, missing or extra identities,
changed inputs and reused capture directories. An unsealed feature admission
must fail before creating any observation or HDL stage. Exclusive paths retain
every first outcome; a second qualification needs a separately owned reason
and a fresh prefix. The sealer consumes completed results and independently
checks that controlled PIDs and groups are absent. The verifier is read-only
and rejects corrupt saved evidence without replaying process fixtures.

Only after this integration is qualified and committed may ISF `.1.4` create
its own fresh feature admission:

```sh
perl docs/audits/unary-observer-20261022/prepare.pl unary_oct22 unary none 3 3
scripts/run_with_ram_guard.sh -- env FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 perl docs/audits/unary-observer-20261022/observe.t unary_oct22
```

Run these launch commands under the repository RAM guard, retain full original
results, and consume them before further execution. A process exit zero never
establishes semantic acceptance: positive designs require the complete public
pin PASS/hold/reset markers; the deliberately wrong source requires its exact
row-one mismatch and no PASS. Historical native EPERM causality stays open.
