# Decision Trees and FSMs

FSMGen has two main direct authored roots:

- `?fsm:name`
- `?dt:name`

They are related, but not interchangeable.

## Direct Root Boundary

The active direct source roots are:

- `(?fsm:module_name ...)` for encoded FSMs
- `(?dt:module_name ...)` for standalone decision-tree modules
- `(?mod:module_name ...)` and `(?module:module_name ...)` as currently
  accepted direct single-module roots on the shared implementation path

Root names must be HDL-identifier-compatible. Names such as `?fsm:bad-name`,
`?dt:0bad`, or `?top:bad-name` are rejected as source-shape errors rather than
silently truncated to a valid prefix.

Default mode also accepts the legacy `+fsm` root family:

```lisp
(+fsm my_module)
(+system (clock clk) (sreset reset))
(idle ...)
```

and the nested legacy form:

```lisp
(+fsm my_module
  (+system (clock clk) (sreset reset))
  (idle ...))
```

Those legacy forms are compatibility residue. Strict mode rejects legacy
`+fsm` roots and requires `?fsm:module_name`. Strict mode also rejects the long
direct-root alias `?module:` and requires canonical `?mod:` for the current
module/entity-architecture root family.

Files that start directly with FSM content such as `(+system ...)` or
`(idle ...)` must be wrapped in a supported root. Unsupported tagged wrappers,
including old template-like roots, do not become valid just because they contain
a supported root inside them.

## `?fsm:name`

Use `?fsm:name` when you are modeling an actual finite-state machine with:

- named states,
- transitions,
- sequential state-holding behavior,
- and optional non-state DT blocks alongside those states.

Typical ingredients:

- `+system`
- `+size`
- `+constants`, `+enums`, `+types`
- `:=` init/reset directives
- state blocks such as `idle`, `run`, `done`

## `?dt:name`

Use `?dt:name` for a standalone decision tree, especially when the logic is:

- decision-oriented,
- naturally described as decision-tree routing,
- or intended to be reused as a direct child in composition.

The current `?dt:name` contract is intentionally narrower than `?fsm:name`.

Accepted top-level content for `?dt:name` currently includes conventional
`+system`, `+size`, `+constants`, `+enums`, `+define`, `+params`, bounded
`+types`, bounded `+import`, canonical `(:= (signal value))` directives, and
general non-state DT blocks such as `(-route ...)`. Regular FSM-state blocks
such as `(idle ...)` and dedicated reset-state blocks are rejected inside
standalone-DT roots.

Without explicit `+system`, a purely combinational standalone `?dt` exposes no
implicit system ports. If any sequential assignment appears and no `+system`
is authored, the current generator exposes implicit `clk` and asynchronous
active-low `rst_n`.

## What a Decision Tree Is

A decision tree (DT) is the combinational glue that computes mux-selection
enables. It is not storage, and it is not a procedural block. A DT may read any
number of input signals or expressions of any width, including top-level inputs
and flop Q outputs. From those inputs it computes a set of one-bit predicates
that say which value should be selected for each target.

Every DT has a conceptual one-bit decision-tree enable, called `DTE`. For a DT
`i`, target/LHS `j`, and candidate value `k`, FSMGen's flattened model has an
ungated one-bit selection predicate:

```text
DT_i_LHS_j_VAL_k
```

That predicate is then gated before it reaches the target mux:

```text
DT_i_LHS_j_VAL_k_EN  = DTE_i && DT_i_LHS_j_VAL_k
DT_i_LHS_j_VAL_k_WEN = DTE_i && DT_i_LHS_j_VAL_k
```

All of these signals are one bit. When `DTE_i` is `0`, every
`DT_i_*_EN`/`DT_i_*_WEN` is `0` in the same cycle; the DT is off, disabled, or
inactive. When `DTE_i` is `1`, the gated enables are allowed to follow the
predicates computed by the DT logic; the DT is on, enabled, or active.

For state DTs, `DTE_i` is the decode of that FSM state. For non-state DTs,
`DTE_i` defaults to `1`, or to the optional guard authored immediately after
the non-state DT name.

The SystemVerilog emitter keeps this as a boundary-gating rule. A state DT's
internal selector predicates may be factored into helper wires, but the state
decode itself stays outside those internal helpers. The emitted DT output
enable is formed as the final gate before the enable leaves the state DT:

```text
state_DT_output_EN = state_DTE && state_DT_selector_predicate
```

That shape is intentional. Inside one state DT, all route predicates that
select the same `LHS`/`VAL` pair are ORed into the DT-local selector predicate.
That ORed selector is then ANDed with the state `DTE` just before it leaves the
state DT. At the FSM level, the already-gated state-DT enables are ORed again
per `LHS`/`VAL` pair to form the FSM-level enable for that mux input. That
final per-value enable is the selector used by the target LHS mux. The path
from the state decode `DTE` to any emitted state-DT output enable is therefore
only the final boundary gate, while the rest of the selector logic can be
optimized independently.

Each ungated `DT_i_LHS_j_VAL_k` predicate is the logical OR of every DT path
that selects `VAL_k` for `LHS_j`. Each path term is the logical AND of the
guards, tests, and branch predicates seen from the root of the tree down to the
assignment on that path. In other words, the DT syntax is a compact way to
author the selector equations.

FSMGen's target mux model is a P-to-1 mux with no hidden decode logic inside
the mux. It has P data inputs, each B bits wide, and P one-bit selection
signals:

```text
MUXOUT = (MUXIN0 && SEL0) || (MUXIN1 && SEL1) || ... || (MUXINP && SELP)
```

Each `SELp` is the logical OR of the gated DT enables that select `MUXINp`.
For a combinational assignment such as `(= (MUXOUT MUXIN0))`, the mux output is
the authored LHS. For a flopped assignment such as
`(<- (MUXOUT_Q MUXIN0))`, the mux output is the D input of the flop whose
Q/output is named `MUXOUT_Q`. For a D-input-named assignment such as
`(<= (MUXOUT_D MUXIN0))`, the authored LHS names the D/next-value side. In all
cases, the target mux, flop, and LHS live outside the DT selector logic even
though the source syntax places the assignment inside the tree.

The textual tree is an upside-down authoring notation: root at the top,
branches underneath. It intentionally resembles control-flow notation, but it
must not be read as procedural execution. If assignment A appears before
assignment B while walking a branch, A does not execute before B. All
assignments on the same root-to-leaf path are enabled in the same cycle.

Well-structured DTs often make sibling paths mutually exclusive, but the DT
model itself does not enforce that. If two different paths have overlapping
conditions, both can be active in the same cycle. The apparent hierarchy is
therefore only a review aid; after flattening, the logic is a set of AND/OR
equations for one-bit mux-selection signals.

The assignment family still matters, but it describes the target being selected
and its timing. It does not make the DT itself combinational, sequential, or
mixed; the DT logic is always combinational.

## State DTs and Non-State DTs

Inside an FSM root, a state DT is written as a normal state block such as
`(idle ...)` or `(run ...)`. A non-state DT is written with a leading dash such
as `(-route ...)`, `(-scl ...)`, or `(-counter_inc ...)`.

The block spelling decides the activation context. A state DT is enabled by
the FSM state decode. A non-state DT behaves as an always-enabled combinational
selector region by default, or as a guarded region when its header binds a
non-state `DTE` guard:

```lisp
(-route <req
  (= (OUT_A 1)))

(-holdoff <!hold
  (= (OUT_B 1)))

(-mode_hit <mode=3
  (= (OUT_C 1)))

(-both_ready <(& req ready)
  (= (OUT_D 1)))
```

Those guards use the same guard grammar described in the language basics
chapter. The guard belongs to the DT header: it computes the DT enable, gates
all output `EN`/`WEN` terms that leave that non-state DT, and is not repeated
on each action. If the header guard is omitted, the non-state DT enable is
`1'b1`.

The assignment operators inside either state or non-state block decide what
kind of target mux or storage is selected:

- `(= (lhs rhs))` is combinational.
- `(<- (lhs rhs))` is sequential/flopped with a Q/output-named LHS.
- `(<= (lhs rhs))` is sequential/flopped with a D-input/next-value-named LHS.

Therefore a state DT or a non-state DT can contain assignment forms that target
combinational destinations, flopped destinations, or both. That does not make
the DT sequential; it means the combinational selector predicates are feeding
different kinds of target muxes. The same assignment-family validation rules
described in the language basics chapter still apply.

Non-state DT names must use exactly one leading dash plus an
HDL-identifier-compatible base name, for example `-route_dt` or `-comb_1`.
Malformed block names such as `(bad-name ...)`, `(-bad-name ...)`, and
`(--bad ...)` are rejected explicitly.

Dedicated reset-state DT blocks are the short and long reset spellings:

- `-syncrst` and `-syncreset`, both normalized to `syncreset`
- `-asyncrst` and `-asyncreset`, both normalized to `asyncreset`

They are reset-state DT blocks, not regular encoded states. They do not
participate in normal state encoding or `current_state` comparisons.

## Reset and Initialization

Current direct-root reset/init comes from two places:

- the conventional `+system` contract
- explicit `:=` directives

Prefer the canonical pair form:

```lisp
(:= (valid 0))
(:= (next_mode mode.IDLE))
(:= (reset_count (+ RESET_BASE EXTRA_RESET)))
```

The right-hand side is a constant-expression slot. It can be a literal, a
named constant, an enum member, a param/generic, an aggregate scalar leaf, or a
nested Lisp-ish arithmetic/bitwise expression. The older compact
`(:= signal=value)` spelling is kept as default-mode compatibility residue;
strict mode rejects it and points to `(:= (signal value))`.

Those reset/init rules are still documented as a live contract rather than as a
fully frozen language forever, so keep an eye on current wording in the
reference docs.

## State Transitions

Transitions target named FSM states in the same root.
Targets must be declared regular FSM-state DT blocks and must be
HDL-identifier-compatible. A transition to `bad-name`, `-comb`, or an unknown
state is rejected before generation.

Transitions can be unconditional or guarded:

Example:

```lisp
(idle
  (<start
    (-> active)
  )
)

(active
  (<done
    (-> idle)
  )
)
```

The suffix form is the single-action equivalent of wrapping the transition in a
guard:

```lisp
(-> active <start)
(-> idle <!busy)
(-> joined <(& w0_done w1_done w2_done))
```

The compound suffix form is useful when a transition depends on several done or
ready signals and the source should show the conjunction at the transition
site.

## Non-State DT Enable Guards

Every DT/state block has a conceptual activity input: its `DTE`. State DTs
derive that enable from the FSM state decode. Non-state DTs now expose a
bounded author-facing DTE binding through an optional leading guard:

```lisp
(-name <guard
  body...)
```

The guard syntax is exactly the normal guard syntax:

- `<signal` means `signal != 0`
- `<!signal` means `signal == 0`
- `<name<op>value` uses the existing compact comparison grammar, such as
  `<mode=3`, `<mode!=0`, `<count<=7`, or `<count>=2`
- `<(& req ready)` uses the normal list-form expression language

The lowered model is:

```text
name_DTE = lowered(guard)
name_LHS_VAL_EN = name_DTE && name_LHS_VAL_selector
```

If no guard is authored, `name_DTE = 1'b1`. This keeps existing non-state DT
sources compatible while giving intent-level producers such as ISF a clean way
to activate an entire non-state DT once. Local guarded blocks, condition
suffixes, and test nodes inside the DT still contribute to the DT-local
selector predicates; the header guard is the boundary enable.

The parser captures the authored DTE guard as CoreAST state metadata, signal
analysis validates referenced operands before HDL generation, and the
SystemVerilog backend emits the top-level `*_en` assignment plus the final
boundary gate on each DT output enable. Expression guards may create internal
intermediate wires; those intermediates are kept live because the DTE
assignment is a final enable expression.

Explicit author control of state-DT DTEs remains outside the current language:
state DTs still derive their DTE from state decode. Broader multi-active-region
semantics need their own validation and diagnostics before becoming a public
state-DT feature.

## Practical Guidance

Prefer:

- `?fsm` when you need persistent state and explicit transitions
- `?dt` when you want a standalone routing/decision surface

If you later want hierarchy, both can participate in composition as generated
children through `?fsmc` and `?dtc`.
