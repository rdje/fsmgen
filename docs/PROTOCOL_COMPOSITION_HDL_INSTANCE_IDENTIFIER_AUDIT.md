# Protocol-Composition HDL Instance-Identifier Audit

## Scope

`PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1` inventories every
current child-instance-name producer that reaches a composition top, checks
the shipped SystemVerilog and VHDL emission boundaries, and selects one shared
contract. This audit changes no parser, generator, report, or generated HDL.

The concern is specifically a child *instance label*. Module names, top names,
ports, nets, parameters, and other identifier families remain outside this
slice even where they use the same syntax-only predicates.

## Root Cause

FSMGen has several copies of an "HDL identifier" predicate, but every relevant
copy checks spelling only: `[A-Za-z_][A-Za-z0-9_]*`. None checks target-language
reserved words. The typed C4 path then carries the chosen label unchanged into
`StructuralRTLIR`, and both structural emitters insert that value directly:

- SystemVerilog: `module_name instance_name (`;
- VHDL: `instance_name : entity work.module_name`.

The local AHB and APB uniqueness helpers add collision suffixes only when a
top port or earlier sibling already uses the desired name. AHB's earlier
`interconnect` failure was repaired locally by changing its seed to `fabric`.
APB retained the same reserved seed, exposing that the missing boundary is
shared rather than protocol-specific.

## Producer Inventory

| Producer | Ownership | Current label policy | Risk on current HEAD |
| --- | --- | --- | --- |
| Direct C4 `?fsmc:name`, `?dtc:name`, `?rtl:name` | authored | syntax-only parse; duplicate realized children fail | a reserved word reaches both emitters unchanged |
| APB one-requester/one-completer | authored | endpoint `instance_name` is emitted unchanged | same as direct C4 |
| APB multi-peripheral requester/peripherals | generated alias derived from authored name | local top-port/sibling collision helper; authored and generated labels are both reported | reserved words are not reserved by the allocator |
| APB multi-peripheral interconnect | generated | fixed desired seed `interconnect` plus local collision helper | reproducible SystemVerilog syntax failure |
| AHB requester/subordinates | generated alias derived from authored name | local top-port/sibling collision helper; authored and generated labels are both reported | latent for authored reserved words |
| AHB interconnect | generated | fixed desired seed `fabric` plus local collision helper | current public composition is legal |
| AXI read/write compositions | generated | fixed labels: `ar_driver`, `r_acceptor`, `aw_driver`, `w_driver`, `b_acceptor`, `coordinator`, `request_coordinator`, and `transaction_coordinator` | audited labels are legal, but there is no shared guard |
| ISF `spawn ... as NAME` | authored | scalar shape and duplicate-instance checks | reserved words reach generated C4 unchanged |
| ISF generated `do`/repeat/conditional/rule-trigger activations | generated | deterministic owner/child/ordinal suffixes | current suffix-bearing shapes are legal; no shared guard |
| Reusable library `use ... as NAME` | authored | scalar shape and per-actor duplicate check; specialized module name is generated separately | the public instance label reaches generated C4 unchanged |
| ATL static actor instance | authored | scalar shape and network duplicate check | selected generated tops preserve the label unchanged |
| ISF parent/domain/CDC helpers | mixed | actor/domain/child-derived labels and deterministic suffixes | most suffix-bearing labels are legal; parent actor labels remain syntax-only |

Collision checks are therefore present but incomplete. They prevent duplicate
sibling labels and selected top-port collisions; they do not reserve language
keywords or provide one cross-producer allocation rule.

## Focused Evidence

All temporary inputs and outputs lived under
`.artifacts/tmp/protocol-identifier-audit/` and were removed after inspection.
No off-volume scratch or cache was used.

### SystemVerilog

Strict `--verify-hdl` probes produced these exact results:

| Route | Emitted construct | Result |
| --- | --- | --- |
| direct C4 authored alias | `child_module interconnect (` at line 78 | Verilator: `unexpected interconnect` |
| public APB multi-peripheral | `apb_interconnect interconnect (` at line 3134 | Verilator: `unexpected interconnect` |
| reusable `use ... as interconnect` | generated library module followed by `) interconnect (` at line 924 | Verilator: `unexpected interconnect` |
| `spawn ... as interconnect` | `child_worker interconnect (` at line 598 | Verilator: `unexpected interconnect` |
| public AHB interconnect | generated `fabric` label | Verilator and Yosys pass |
| public AXI read composition | fixed `ar_driver`, `r_acceptor`, `transaction_coordinator` labels | Verilator and Yosys pass |

The direct, library, and spawn probes also prove that author-owned labels pass
their source parsers before the target parser rejects generated HDL.

### VHDL

No VHDL parser is installed in the current tool profile (`ghdl` and `nvc` are
absent), and the full APB/library/spawn VHDL shapes currently stop at their
separately documented bounded composition-target gates. Direct invocation of
the shipped structural VHDL emitter nevertheless proves the identifier gap:
its syntax-only `_identifier` helper accepts `process` and emits:

```vhdl
process : entity work.child_module
```

`process` is a VHDL reserved word, so the source is not a legal basic label.
This is a latent backend defect even though current full-shape target support
can fail earlier. Escaping is not a portable remedy: Verilog-family escaped
identifiers and VHDL extended identifiers use different syntax and would make
reports and wiring target-dependent.

## Selected Contract

Decision `0027` selects one portable, origin-aware contract:

1. A shared support module owns the simple spelling rule and the union of
   unescaped reserved words for every shipped HDL target. Each set follows its
   language's case rules: VHDL comparisons are case-insensitive, while
   Verilog-family keyword matches remain case-sensitive.
2. Author-owned child instance labels fail closed at the nearest source
   boundary. Diagnostics name the label, origin, conflicting target keyword
   family, and rename guidance. FSMGen never silently changes a public identity.
3. Generator-owned labels use one deterministic allocator. A reserved desired
   name first becomes `<desired>_instance`; an ordinary collision keeps the
   existing `<desired>_<role>` style; remaining collisions receive stable
   `_2`, `_3`, ... suffixes.
4. The allocator reserves the portable keyword union, declared top ports, and
   already allocated siblings. Legal non-colliding labels remain byte-stable.
5. Reports retain authored identity separately wherever it exists and expose
   the actual generated label used by wiring/HDL. APB's generated interconnect
   label is expected to change from `interconnect` to
   `interconnect_instance`; that public report delta must be tested and
   documented in the implementation slice.
6. C4/source validation is the primary boundary. Both structural emitters add
   defense-in-depth validation so direct `StructuralRTLIR` construction cannot
   bypass the contract.

The portable union is intentionally stricter than selecting names separately
per backend. It preserves one composition identity and one report across
SystemVerilog, Verilog, and VHDL, matching the backend-neutral IAL contract in
decision `0018`.

## Implementation Outcome

Leaf `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2` implements the
selected contract in `perl/FSM/Support/HDLInstanceIdentifierPolicy.pm`.
SystemVerilog keywords retain case-sensitive matching; VHDL-2008 keywords and
portable name collisions use case-insensitive matching. Authored direct C4,
spawn, reusable-library, ATL, APB, and AHB labels fail at their bounded source
boundary, and both structural emitters enforce the same rule for direct IR
callers.

APB/AHB now share the allocator. Public APB multi-peripheral tops use
`interconnect_instance` consistently across child declaration, wiring,
derived HDL carriers, and report fields. AHB `fabric` and the fixed AXI
`aw_driver`, `w_driver`, and `coordinator` labels remain byte-stable. Focused
public APB generation passes Verilator parse/lint with its separately owned
warnings non-fatal and passes Yosys synthesis. The VHDL emitter rejects
case-folded `PROCESS` before rendering an invalid entity label.

The implementation intentionally leaves module/top/port/net/parameter
identifier families outside this child-instance-label contract.
