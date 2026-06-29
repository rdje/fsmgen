# Generated-IAL1 Output Default/Reset Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.714`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.714` implements the generated-IAL1
actor interface output metadata selected in `.713`:

```text
(output NAME [(width WIDTH)] [(domain DOMAIN)]
             [(reset VALUE)] [(default VALUE)])
```

The first shipped slice accepts only non-negative integer literal `VALUE`
tokens on actor-level outputs whose width resolves to a positive integer at
parse time. Inputs cannot carry this output metadata. Outputs that use
`(type TYPE)` or unresolved symbolic widths remain deferred for a later
type-aware owner.

This is a generated-IAL1 substrate feature. It does not add AHB subordinate
`.ppif` parser/generator/source/sample/support-accounting behavior, AHB
profile-alias widening, direct backend behavior, verification-output
generation, backend-language variants, AXI, APB, AHB protocol behavior, or
VHDL behavior.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.715`, public IAL2
AHB subordinate implementation over the now-shipped output default/reset
substrate.

## Parser Contract

Accepted output metadata is stored on the parser-returned actor shell output
entry:

```text
reset_value   => VALUE
default_value => VALUE
```

The parser rejects:

- `(reset ...)` or `(default ...)` on inputs;
- malformed arity such as `(reset)` or `(default 0 1)`;
- negative values;
- non-integer values;
- duplicate `reset` or `default` options;
- values that do not fit the resolved output width; and
- type-referenced or unresolved-width outputs carrying reset/default metadata.

The implementation keeps the accepted literal text until fit checking, so
large literals are checked with `Math::BigInt` rather than through host integer
coercion.

## Generated `.fsm` Contract

`(reset VALUE)` lowers to generated IAL0 `.fsm` `+size` reset metadata:

```text
(+size
  (ready 1 (reset 1))
  (error 1 (reset 0))
  (data 8 (reset 0)))
```

`(default VALUE)` lowers to a reviewable idle/quiescent output assignment in
each generated transaction entry state. The shipped assignment family is the
flopped output operator `<-`, matching generated named-drive output
assignments:

```text
(main_idle_0
  (<- (data> 0))
  (<- (error> 0))
  (<- (ready> 1))
  ...)
```

The lowerer skips a default assignment for an output that is already assigned
in that entry state, so explicit state-local drives are not overwritten. Named
drive behavior in scheduled transaction states remains explicit and unchanged.

## SystemVerilog Contract

The generated SystemVerilog path sees the reset metadata through the existing
`.fsm` reset-value carrier and emits output reset assignments for the selected
registered outputs.

Because generated idle defaults and generated named drives both use the same
flopped output assignment family, the direct backend keeps a single registered
assignment family per output. This avoids mixed combinational/sequential
assignment classification while still making reset and idle behavior
reviewable in the generated `.fsm`.

## Validation Evidence

Focused validation:

```bash
prove -v t/1476-isf-output-default-reset.t
```

The test covers:

- parser-returned `reset_value` and `default_value` metadata;
- generated `.fsm` `+size` reset metadata;
- generated idle-state `<-` default assignments;
- preservation of explicit named drives;
- strict SystemVerilog generation with reset/default output assignments; and
- fail-closed diagnostics for input metadata, malformed values, negative
  values, too-wide values, and unresolved-width outputs.

Closeout also reruns the public ISF contract metadata tests, Knowledge Map,
mdBook, memory, diff-hygiene, and doctrine gates.

## Residue

Future exact owners must still handle:

- public IAL2 AHB subordinate `.ppif` parser/generator/source/sample/support
  behavior;
- type-aware output reset/default values;
- symbolic reset/default values;
- signed/aggregate output default/reset metadata;
- AHB subordinate `.ahb` profile-alias widening;
- AHB interconnect/decode, scoreboards, and full-manager behavior;
- direct backend behavior beyond the generated `.fsm` path used here;
- verification-output generation;
- backend-language variants; and
- VHDL behavior.
