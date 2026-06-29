# Generated-IAL1 Output Default/Reset Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.713`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.713` selects the generated-IAL1 output
default/reset contract needed before public AHB subordinate implementation.
It does not implement parser, lowerer, emitter, test, source, or runtime
behavior.

The selected IAL1 source surface is an additive interface-output option pair:

```text
(interface
  (output NAME [(width WIDTH)] [(type TYPE)] [(domain DOMAIN)]
               [(reset VALUE)] [(default VALUE)]))
```

The first implementation owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.714`.
`.714` may add parser/lowerer/generated-IAL0/SystemVerilog/test/docs behavior
only for the selected output default/reset substrate. It must not implement
AHB subordinate `.ppif` parser/generator/source behavior.

No parser behavior, generator behavior, public source sample,
support-accounting catalog behavior, capability-manifest behavior, test
behavior, schedule/check/semantic JSON behavior, generated tracked artifact,
HDL/runtime behavior, seed behavior, direct backend behavior,
verification-output generation, backend-language variant, AXI, APB, AHB, or
VHDL behavior changed in this selector.

## Source Surface

The selected options are valid only on actor-level interface outputs:

```text
(output HREADYOUT (reset 1) (default 1))
(output HRESP (reset 0) (default 0))
(output HRDATA (width 32) (reset 0) (default 0))
```

The first slice supports non-negative integer literal values only. Values must
fit the resolved output width. If an output uses a type reference or a width
that is not resolved to a positive integer at parse/lowering time, output
default/reset values for that port remain deferred until a later exact owner
selects type-aware value checking.

`(reset VALUE)` and `(default VALUE)` are independent:

- `(reset VALUE)` selects the hardware reset value for the output port in the
  generated `.fsm` review artifact.
- `(default VALUE)` selects the generated idle/quiescent output drive for the
  output port.
- A port may specify either option or both.
- AHB subordinate generation must specify both options for `HREADYOUT`,
  `HRESP`, and `HRDATA`.

The selected names are intentionally explicit. `reset` matches the existing
storage reset option vocabulary. `default` describes generated idle/default
drive behavior without introducing protocol-specific wording such as `idle`.

## Generated `.fsm` Contract

For each selected output `(reset VALUE)`, generated IAL0 `.fsm` must carry the
same reset metadata in `+size`:

```text
(+size
  (HREADYOUT 1 (reset 1))
  (HRESP 1 (reset 0))
  (HRDATA 32 (reset 0)))
```

For each selected output `(default VALUE)`, generated IAL0 `.fsm` must include
a reviewable idle/quiescent assignment for every generated transaction idle
state that can wait for a new activation:

```text
(ahb_lite_access_idle_0
  (= (HREADYOUT> 1))
  (= (HRESP> 0))
  (= (HRDATA> 0))
  ...)
```

The default assignment must not override explicit named-drive behavior in
scheduled transaction states. It is the value presented while the generated
transaction is idle or quiescent, not a replacement for transaction-specific
`(drive ...)` clauses.

For the AHB subordinate follow-on, the generated `.fsm` must prove reset/idle
behavior equivalent to the direct seed boundary selected in `.708` and shipped
in `.709`: `HREADYOUT=1`, `HRESP=0`, and `HRDATA=0` before and between
accepted AHB transfers.

## SystemVerilog Contract

The generated SystemVerilog from a `.fsm` carrying output reset/default
metadata must be reviewable at two levels:

- reset logic initializes the output registers to the selected reset values;
- idle/quiescent state logic drives the selected default values without
  suppressing explicit transaction drives.

For the first focused substrate test, the implementation owner should generate
SystemVerilog for a small `.isf` fixture and inspect for reset assignments and
idle-state output assignments rather than relying on parser acceptance alone.

## Diagnostics

The implementation owner must fail closed for:

- `(reset ...)` or `(default ...)` on interface inputs;
- malformed arity such as `(reset)` or `(default 0 1)`;
- negative values;
- non-integer values in the first slice;
- duplicate `reset` or `default` options;
- values that do not fit a resolved positive integer width; and
- output default/reset values on type-referenced or unresolved-width outputs
  until a later exact owner selects type-aware checking.

The diagnostic wording should name the port, the option, and the reason. It
should also make clear that this is generated-IAL1 interface-output metadata,
not storage metadata.

## Selected `.714` Scope

`.714` should implement only the selected generated-IAL1 output default/reset
substrate.

Acceptance for `.714` should include:

- parse `(reset VALUE)` and `(default VALUE)` on actor interface outputs only;
- preserve existing `(width ...)`, `(type ...)`, and `(domain ...)` behavior;
- carry selected output reset values into the generated `.fsm` `+size`
  metadata;
- carry selected output defaults into generated transaction idle/quiescent
  state assignments;
- add focused parser/lowerer/generated-`.fsm`/SystemVerilog coverage, likely
  in `t/1476-isf-output-default-reset.t`;
- update ISF public docs, downstream integration docs, mdBook, README,
  ROADMAP_V2, Memory, Knowledge Map, and task tree;
- select the next AHB subordinate owner after the substrate is proven; and
- avoid AHB subordinate `.ppif` parser/generator/source/sample/support
  behavior in `.714`.

## Validation

Closeout for this selector is documentation-only plus direct seed
reverification:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
rg -n 'output default/reset|\\(output HREADYOUT \\(reset 1\\) \\(default 1\\)\\)|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.714' \
  docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_CONTRACT_SELECTION.md \
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md \
  docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md MEMORY.md
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback removes this selector, its Knowledge Map fact, task-tree
advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update, and
regenerated Knowledge Map entries. No runtime behavior is affected.
