# ISF rule admission and generated-artifact evidence

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.1`; the independent generated
interconnect layering defect is owned by `.32.4` in the same task tree.

`evidence.json` retains exact caller-source hashes, normalized baseline native
reports, the inferred `VALID` input/port inventory and focused regression
receipts. Baseline reports come from the recorded revision before repair.
The tracked regression is `t/1888-isf-rule-operand-admission.t`; it checks
source refusal and a declared-input control through CLI, API and newline MCP.

Reverify ordinary supported-source admission from the repository root:

```sh
mkdir -p .artifacts/rule-admission-reverify
scripts/run_with_ram_guard.sh -- perl \
  docs/audits/specforge-rule-admission-20260924/verify-admission.pl \
  .artifacts/rule-admission-reverify/new-report.json
```

The output must not exist beforehand. The driver derives the repository root,
uses public ISF/protocol adapters and records every selected source and emitted
ISF artifact digest. It stops on failure unless `--collect-failures` is supplied;
that diagnostic mode still exits unsuccessfully if any source fails. This checks ordinary actor admission,
not full HDL generation or independent replay of every generated ISF artifact.
`FSMGEN_ADMISSION_SOURCES` may supply a JSON array of known source identities
for focused diagnosis; a focused receipt must never be reported as the full set.

`ahb-interconnect-generated.isf` is the exact public PPIF artifact from
`ppif/ahb_interconnect.ppif`. Passing its text to the public ISF parser fails at
`address-map`, before rule-read validation. The generator separately builds its
FSM. Historical "review artifact" wording does not prove an executable
`IAL2 -> IAL1 -> IAL0` path. `.32.4` owns the complete affected-artifact census,
protocol-specific lowering repair and independent behavior verification.

The initial broad strict-generation scan was deliberately stopped when its
work exceeded the changed parser boundary. Completed results are additional
evidence only; interrupted children and unvisited sources are not passes.
The first replay probe failed at the retained interconnect artifact. Neither
attempt is reported as complete compatibility qualification.

The compatibility census additionally exposed shared-state reads in AXI
AW/AR/W/burst-W/B/R generators and their compositions. Their intended shared
signals now have actor-storage declarations. Baseline generated FSMs were
captured using the committed parser in an isolated module overlay; repaired
FSMs differ only by the explicit size entries. `verify-axi-behavior.py` runs
the existing independent SV oracles from T1499/T1500/T1501/T1504/T1505 and
`t/data/axi_w_burst4_driver_tb.svt` against those FSMs in fresh Verilator
workspaces. Run it under the RAM guard with a repository-local capture directory
as its argument. It preserves command results and does not reuse spent native
compiler workspaces. The full SV outputs match except for their single date
header, and both versions pass the same behavioral oracles.

The composition coordinators also declare shared flags and expected response
IDs. `verify-axi-behavior.py <capture-directory> --compositions` selects their
existing T1502/T1503/T1506/T1507/T1509 behavior oracles. These deliberately
drive illegal addresses or mismatched response IDs, so they use the published
`--no-assert` profile to check admission and captured error status. Endpoint
oracles use `--assert`; this distinction is retained in command receipts.

Capture current public artifacts and rerun the oracles from the repository root
(use fresh directory names for every capture):

```sh
scripts/run_with_ram_guard.sh -- perl -Iperl -It/lib \
  docs/audits/specforge-rule-admission-20260924/capture-axi.pl \
  .artifacts/axi-endpoint-reverify
scripts/run_with_ram_guard.sh -- python3 -B \
  docs/audits/specforge-rule-admission-20260924/verify-axi-behavior.py \
  .artifacts/axi-endpoint-reverify
scripts/run_with_ram_guard.sh -- perl -Iperl -It/lib \
  docs/audits/specforge-rule-admission-20260924/capture-axi.pl \
  .artifacts/axi-composition-reverify --compositions
scripts/run_with_ram_guard.sh -- python3 -B \
  docs/audits/specforge-rule-admission-20260924/verify-axi-behavior.py \
  .artifacts/axi-composition-reverify --compositions
```

The baseline used `45c0e579c` versions of the ISF parser and modified AXI
generators, loaded from a repository-local module overlay ahead of `perl`.
Other compiler components and tracked protocol sources were unchanged. This
is an isolated changed-component control, not a claim to have rebuilt a
different complete repository revision. The caller's incomplete old-revision
export must still be rebuilt from its own complete revision before comparison.

An initial Icarus attempt was unusable: the installed tool rejects a simple
continuous assignment to a wire declared later, independently reproduced with
a minimal module. It is not counted as HDL qualification. Verilator handles
the actual SystemVerilog unchanged, with assertions enabled.

`width-diagnostics.json` is owned by `.32.1.2`. It preserves the independently declared width-error control,
before/after native reports, exact producer hashes and focused test receipts. Reverify with RAM-guarded `prove -Iperl
-It/lib t/1889-authored-source-operand-diagnostics.t`. The test compares full API/newline MCP reports, retained/direct
source identity, external children and domain failures. After the canonical wiring repair, T1889 uses strict mode with
explicitly supported reset forms. The original width-diagnostic receipt preserves the earlier compatibility-mode
boundary.

`multiclock-strict-wiring.json` belongs to `.32.1.3.1`: original strict failures, post-repair outcomes and date-free
compatibility HDL hashes. T1890 checks canonical event/activation wiring, generated artifacts and full API/MCP parity.
The reset-polarity contradiction, domain `bus` keyword refusal and explicit `ready` route collision are retained with
owners `.32.1.3.2` and `.32.1.3.4`; none is closed by syntax admission.
