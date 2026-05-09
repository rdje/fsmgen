# FSMGen User Guide

This guide remains the broad live reference while the progressive mdBook is
being built under `docs/book/`.

Recommended entry points now are:

- `docs/book/src/SUMMARY.md` for the book table of contents
- `docs/book/src/00-introduction.md` for the conceptual starting point
- `docs/book/src/12-cookbook.md` for copyable patterns

This file still carries the full live reference during the migration, so when a
detail has not been split into the book yet, this guide remains authoritative.

## 1) What FSMGen is
FSMGen converts Lisp-like `.fsm` state-machine descriptions into HDL.

Primary output:
- SystemVerilog (`.sv`)

Also supported:
- Verilog (`.v`) via conversion from SystemVerilog

Current limitation:
- VHDL target is recognized by CLI but backend is not yet implemented.
- Composition/top-level generation is implemented in a deliberately narrow active model.
- The currently shipped composition boundary is:
  - one `?top:name`,
  - zero or more bounded `(+constants ...)` / `(+enums ...)` / `(+types ...)` declaration blocks and zero or more bounded `(+import ...)` package-import blocks inside that `?top` root,
  - zero or one `?ports` block,
  - one or more child instances, currently `?fsmc`, `?dtc`, and `?rtl`,
  - generated child sources realized either from the same file or from external searchable `.fsm` child sources,
  - package sources realized either from embedded `?pkg:name` roots in the same file or from external searchable `.fsm` package sources,
  - external RTL children realized through embedded or sidecar `.rtlif` interface metadata,
  - `C1` single-child passthrough via deterministic same-name wiring or exact child-interface inference when `?ports` is omitted or empty,
- `C2` multi-generated-child composition via explicit `?toplink` wiring with `instance.port` child endpoints, source-side top-port bit/slice expressions, source-side child-output bit/slice expressions, bounded source-side concat and repeat expressions including nested brace-group forms, and the first bounded source-actual forms (`=open`, scalar `=0` / `=1`, unsized binary/decimal/signed-decimal/octal/hex direct forms such as `=0b10`, `='b10`, `=0d10`, `='d10`, `=-1`, `=0d-1`, `='sd-1`, `='sb1010`, `='so7`, `='shA`, `=0o7`, `='o7`, `=0xA`, `='hA`, `=170`, or `=A5`, underscore-separated spellings such as `=0b1010_0101`, `='b1010_0101`, `=1_70`, `='d1_70`, `=0o2_45`, `='o2_45`, `='hA_5`, `='so6_45`, `='shA_5`, and `=8'hA_5`, exact-width `=N'b...` / `=N'sb...` / `=N'd...` / `=N'sd...` / `=N'o...` / `=N'so...` / `=N'h...` / `=N'sh...`, and named literal actuals resolved from composition-root `(+constants ...)` / `(+enums ...)` or imported `?pkg:name` packages such as `=RESET_BYTE`, `=mode.BUSY`, `=shared.RESET_BYTE`, or `=shared.mode.BUSY`), with `=open` still targeting realized child inputs only while direct scalar `=0` / `=1` plus unsized binary/decimal/octal/hex direct actuals widen to the realized child-input or declared top-output target width, unsized signed decimal direct actuals and unsized signed binary/octal/hex direct actuals widen when the signed value fits the direct target range, exact-width literal actuals may now also target declared top outputs, and named literal actuals stay bounded to those same direct actual and concat-operand positions on the existing structural literal path, together with bounded omitted/empty-`?ports` inference when explicit top links themselves still make the top boundary unambiguous, bounded undeclared top-interface inference for still-top-facing child inputs and unique top-facing child outputs, bounded plain-explicit-port same-name convention, and bounded same-name internal-carrier inference for unique producer-to-consumer families.
  - `C3` explicit-link composition for any explicit-link top that includes at least one `?rtl` child, with that same bounded source-side top-expression and source-actual slice plus the same bounded undeclared top-interface, plain-explicit-port convention, and internal-carrier inference rules.
  - `C4` declared top-port connect-by-name via `=name` declarations inside `?ports`.
- See [docs/COMPOSITION_SCOPE.md](docs/COMPOSITION_SCOPE.md) for the scoped `R6` plan and [docs/COMPOSITION_LEGACY_MAPPING.md](docs/COMPOSITION_LEGACY_MAPPING.md) for historical context.

## 2) Core concepts
### FSM input file
A `.fsm` file defines states, decision trees, conditions, assignments, and transitions.

### Terms and concepts
- **State**: named execution context in the FSM.
- **Decision tree (DT)**: conditional/action structure evaluated within an FSM state or within a standalone `?dt:name` module root.
- **Conditional branch**: guard plus actions (assignments or transitions).
- **Transition**: state change action written as `->`.
- **Standalone/reset-style DTs**: top-level DT blocks that are not normal runtime states (for reset/clear style control).
- **Intermediate signal**: generated internal wire used to factor repeated expressions.
- **Enable-style control (WEN/EN)**: internal enable signals used by generation stages to drive selected assignments.

### DT/mux enable architecture (reference)
This model is important for understanding generated RTL behavior.

- A DT has an enable condition and emits one or more enable-like controls (WEN/EN) for assignments.
- Conceptually, each DT-local enable is gated by DT activity:
  - `dt_local_en = dt_enable & condition`
- For combinational targets, selected values are merged through enable gating (mux-equivalent behavior).
- For flopped targets, next-value logic typically includes hold/feedback behavior when no write-enable path is active.
- Multiple candidate write paths to a target are reduced through enable composition, then applied according to assignment type (`=`, `<-`, `<=`).
- State decoding/selection controls which DT logic is active at a time for normal FSM progression.

Notes:
- Internal implementation details can evolve, but this execution model is the intended mental model for users.
- Debug traces (`--debug=3`) are the best way to inspect exact enable composition for a specific FSM.
- Current `.fsm` authoring does not yet expose a way to drive the root DT/state `dt_enable`; normal DT/state blocks behave as if that activity input is tied to `1` once their surrounding state/root is active.
- Future advanced DT enable control should make that implicit input visible as a semantic, pre-generation-checked expression with default `1`, for example an input signal or a bounded logical expression. That would let an authored DT/state region be activated by several sources and would support richer patterns such as several independently activatable initial/entry regions without hiding the behavior in backend-only wiring.
- A classic single-initial-state, one-active-state FSM should be understood as the conservative subset of that broader activation-region model. Because externally activated/deactivated regions can create pathological machines, future support must surface drive conflicts, merge/priority policy, assertion hooks, and debug reports rather than silently resolving them in a backend.

### Assignment operators
- `A <- expr` : synchronous/flopped assignment where the authored LHS names the flop output/Q value
- `A <= expr` : synchronous/flopped assignment variant where the authored LHS names the D-input/next-value side
- `A = expr`  : combinational assignment
- `(= (A expr))`, `(<- (A expr))`, `(<= (A expr))` : canonical Lisp-ish pair forms for the same assignment families
- `(<-= (A expr))`, `(<=+ (A expr))`, `(<N (A 1))` : canonical pair forms for dual-output and delayed-pulse families

### Combinational safety rule
For `=` assignments, RHS must not depend on the same LHS through any combinational path.
Examples rejected by parser:
- direct: `A = A`
- indirect: `A = B` and `B = A`

Synchronous Q/output-named loopback remains valid:
- `A <- A`

For D-input-named `<=` and `<=+`, the RHS expression and assignment guard must not read the same LHS name. For example, `A <= (+ A 1)` is rejected because `A` is the D-input carrier in that assignment family and reading it on the RHS creates combinational feedback before HDL generation. Use `A <- (+ A 1)` when the source should read the existing Q/output value, or use `A <=+ expr` and read the generated `A_r` Q mirror when the design intentionally needs both same-cycle D visibility and registered Q visibility.

## 2.1) Currently supported `.fsm` constructs (live reference)
This section is the current live support boundary.

Standard used here:
- "fully supported" means the construct is in the active parser, goes through the active SystemVerilog/Verilog generation path, and is locked by current regressions.
- "implemented but not fully regression-backed" means the parser/runtime has support for it, but the current test depth is not strong enough to present it as equally solid.

### Fully supported single-module constructs
- Root form `(?fsm:module_name ...)` with an HDL-identifier-compatible module name (`[A-Za-z_]\\w*`)
- Root form `(?dt:module_name ...)` with an HDL-identifier-compatible module name (`[A-Za-z_]\\w*`)
  - top-level standalone-DT content is currently limited to the conventional `(+system ...)` form, `(+size ...)`, `(+constants ...)`, `(+enums ...)`, bounded `(+types ...)`, `(+define ...)`, `(+params ...)`, bounded `(+import ...)`, canonical top-level `(:= (signal value))` directives, default-mode compact `(:= signal=value)` compatibility directives, and general DT blocks like `(-foo ...)`
  - explicit `(+system ...)` yields `clk` plus the authored reset signal in standalone-DT roots too
  - without explicit `(+system ...)`, purely combinational `?dt:name` modules expose no implicit system ports
  - without explicit `(+system ...)`, any `?dt:name` module that contains at least one sequential assignment implicitly exposes `clk` / `rst_n`
  - driven non-intermediate targets in `?dt:name` are exposed as module outputs by default
  - `?dt:name` does not synthesize `current_state` / `next_state`
- Additional direct single-module roots currently accepted by the live toolchain:
  - `(?mod:module_name ...)`
  - `(?module:module_name ...)`
  - these roots currently compile through the same direct single-module path as `?dt:name`
  - but that implementation reuse should not be read as semantic identity: `?dt` describes one decision tree, while `?mod` / `?module` are reserved for broader module/entity-architecture semantics
  - default mode still accepts both spellings on that shared path
  - strict mode now narrows that alias family to canonical `?mod:` while the broader module-root contract continues to settle
- Legacy `+fsm` root family:
  - flattened sibling form with a first top-level entry `(+fsm module_name)` and sibling `(+system ...)`, state blocks, and `(+size ...)`
  - nested legacy root form `(+fsm module_name ...)`
  - supported in default mode only; the current first strict-mode slice rejects this legacy family and requires `?fsm:module_name`
- Conventional `(+system ...)` section declaring the shared system pair and reset policy:
  - `(+system (clock clk) (sreset reset))` for synchronous active-high reset
  - `(+system (clock clk) (areset rst_n))` for asynchronous active-low reset
  - default mode still accepts legacy `(asreset rstn)` and misleading `(sreset rstn)` compatibility forms, but strict mode rejects them
- Regular state blocks like `(s0 ...)`, `(idle ...)`
  - regular FSM-state DT names must be HDL-identifier-compatible (`[A-Za-z_]\\w*`)
- Special reset states `(-syncrst ...)`, `(-syncreset ...)`, `(-asyncrst ...)`, and `(-asyncreset ...)`

Reset-state note:
- The short and long spellings normalize to the same internal reset-state identities:
  - `-syncrst` and `-syncreset` => `syncreset`
  - `-asyncrst` and `-asyncreset` => `asyncreset`
- These reset blocks are supported as dedicated reset-state combinational-DT blocks.
- They do not participate in regular state encoding or `current_state` comparisons.
- Combinational DT blocks like `(-alpha_dt ...)`, `(-misc ...)`, or `(-mycombit ...)`
- Symbol-definition sections:
  - `(+constants ...)`
  - `(+enums ...)`
  - `(+types ...)`
  - `(+define ...)`
  - `(+params ...)`
- Bounded package-import sections:
  - `(+import pkg_name ...)`
  - imported namespaced package scalar leaves such as `shared.RESET_BYTE`, `shared.mode.BUSY`, `shared.BYTES[1]`, and `shared.FRAME.flag` currently resolve as literals in direct-root assignment RHS expressions and guard equality conditions
- Canonical top-level init/reset directives like `(:= (tester_reset 1))`

Combinational DT note:
- Both syntaxes are decision trees, but they play different roles.
- A regular named block like `(aState ...)` is an FSM-state DT for state `aState`.
- A hyphen-prefixed top-level block like `(-foobar ...)` is a general/combinational DT block.
- General/combinational DT names must use exactly one leading `-` plus an HDL-identifier-compatible base name, for example `-mycombDT` or `-comb_1`.
- General/combinational DT blocks now carry an explicit internal `standalone_dt` role and use DT-style enables instead of joining the encoded `current_state` set.
- When an FSM contains only combinational DT blocks, the active runtime treats it as DT-only generation and does not synthesize a `current_state` / `next_state` state-register plan.
- FSM-state DTs additionally participate in state encoding and transition planning.
- Malformed state/DT names such as `(bad-name ...)`, `(-bad-name ...)`, or `(--bad ...)` are rejected explicitly.

- `(+size ...)` signal-width declarations
  - including the legacy empty no-op form `(+size)`
- Unconditional state transitions `(-> next_state)`
  - transition targets must name a declared regular FSM-state DT block inside the same FSM source
  - target names must be HDL-identifier-compatible (`[A-Za-z_]\\w*`)
  - malformed or unknown targets such as `(-> bad-name)`, `(-> -comb)`, or `(-> missing_state)` are rejected explicitly
- Test-node branching on a signal or computed selector, for example:
  - `(?SIG (=0 ...) (!=8'0 ...) (>8'3 ...) (<=8'3 ...))`
  - `(?(| A B) (=0 ...) (=1 ...))`
  - plain `?SIG` test nodes require an HDL-identifier-compatible signal name
  - malformed plain test-node signal names such as `?bad-name` or `?0` are rejected explicitly
  - computed selectors `?(expr)` must start with a real selector expression and include at least one branch
- Canonical assignment pair forms such as `(<- (Q D))`, `(<= (D_IN NEXT_VALUE))`, `(= (A B))`, `(<-= (I J))`, `(<=+ (D_IN NEXT_VALUE))`, and `(<N (P 1))`
- Default-mode infix assignment compatibility forms such as `(Q <- D)`, `(D_IN <= NEXT_VALUE)`, `(A = B)`, `(I <-= J)`, `(K <=+ L)`, and `(P <N 1)`
- Explicit output exposure on the LHS, for example `(= (G> H))`, `(<= (output_data> 8'1))`, `(G> = H)`, and `(output_data> <= 8'1)`
  - the `>` marker must stay on the LHS in either spelling; `(<= (output_data> 8'1))` is equivalent to `(output_data> <= 8'1)`, while `(<= (output_data 8'1))` drives an unmarked internal target and does not request public output exposure
- Dual-output register form `(<-= (I J))` or `(I <-= J)` producing `next_I`
- Dual-output D-input form `(<=+ (K L))` or `(K <=+ L)` producing `K_r`
- Delayed pulse form `(<N (P 0))`, `(<N (P 1))`, `(P <N 0)`, and `(P <N 1)`, including `N=0`
  - malformed delayed-pulse RHS values such as `(P <1 B)` or `(P <1 2'0)` are rejected explicitly
  - unsupported assignment operators such as `(A ?= B)` or `(A => B)` are rejected explicitly
- Literal forms `1`, `8'3`, `8'b1010`, `8'hFF`, and `const_8b0`
- Signal-reference forms `SIG`, `SIG[3]`, `SIG[7:0]`, `SIG'8`, `SIG.member`, and `SIG>`
- Static numeric indexed/sliced LHS assignments on the current `?fsm:` / `?dt:` direct path
  - current regression-backed lowering covers `=`, `<-`, `<=`, `<-=`, and `<=+`
  - base-signal width may come from explicit `+size` entries or directly from the static slice/index bounds themselves on the current direct path
  - same-context piecewise writes such as `(OUT[3:2] = HI)`, `(OUT[1] = MID)`, `(OUT[0] = LO)` are assembled into one full-width mux input
  - partial sequential writes such as `(RO[0] <- LO)` and `(RI[0] <= LO)` retain untouched bits through the appropriate feedback path instead of collapsing to raw whole-signal replacement
  - partial dual-output sequential writes such as `(ROD[3:2] <-= HI)` and `(RID[3:2] <=+ HI)` now also keep their auxiliary outputs (`next_ROD`, `RID_r`) at the full base-signal width instead of narrowing them to the written fragment
- Condition forms that are in the active supported path: `<sig`, `<!sig`, `<sig=value`, `<sig==value`, `<sig!=value`, `<sig<value`, `<sig<=value`, `<sig>value`, `<sig>=value`, and test-node selector branches like `=0`, `!=8'0`, `<8'4`, `<=8'3`, `>8'3`, and `>=8'1`
- Nested guarded blocks using standalone `< ...` / `<! ...` action forms
- Condition suffixes attached directly to assignments or transitions, for example `(A <= B <start)` and `(-> busy <!full)`
- Compound-update shorthand forms `(++ sig)`, `(-- sig)`, `(+= sig)`, `(-= sig)`, `(+=N sig)`, `(-=N sig)`, `(+= sig N)`, and `(-= sig N)`
  - malformed update-shorthand targets such as `(++ (counter))` or `(+= (byte_count) 4)` are rejected explicitly
  - malformed extra positional tails such as `(+= counter 4 3)` are rejected explicitly
- Inline compound modifiers on assignments, for example `(A <- B (+=))`, `(A <- B (+= 2))`, `(C = D (-=))`, and `(C = D (-= 1))`
  - malformed inline compound modifiers such as `(A <- B (+= 2 3))` or `(A <- B (+= 2) (-= 1))` are rejected explicitly
- RHS operator expressions for the currently regression-backed active families:
  - unary `!`
  - n-ary comparison `==`, `!=`, `<`, `<=`, `>`, `>=`
  - n-ary `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`
  - word aliases `not`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, `xor`
- Enforced diagnostics for illegal combinational self-dependency with `=`
- Enforced diagnostics for illegal D-input self-dependency with `<=` / `<=+`
- Enforced diagnostics for mixing `=` with sequential operators on the same LHS
- Enforced diagnostics for mixing pulse-delayed and non-pulse sequential operators on the same LHS
- Enforced diagnostics for multiple different `<N` delays on the same LHS
- Enforced diagnostics for `<N` with RHS other than literal `0` or `1`

### Fully supported composition `.fsm` constructs
- Root form `(?top:top_name ...)` with an HDL-identifier-compatible top name (`[A-Za-z_]\\w*`)
- Bounded top-root symbol sections `(+constants ...)` and `(+enums ...)`
  - composition-top `+constants` entries may now be scalar literals, non-empty lists, or nested hash-like aggregates written as `(member value)` pairs
  - composition-top aggregate values may now reuse same-scope local constants and enum members as scalar ingredients regardless of declaration order, as long as the symbol dependency graph stays acyclic
  - composition-top aggregate references may now resolve either to a scalar leaf such as `BYTES[1]`, `FRAME.flag`, or `NEST.header.nibble`, or to one whole aggregate root such as `=HEADER`, `=TAIL`, or `=FRAME` on the bounded `?toplink` actual/concat path
  - whole hash-like aggregate roots now lower by packing authored members left to right in declaration order, recursively, when every leaf still resolves to one scalar literal
- Bounded package roots `(?pkg:package_name ...)` for shared named scalar values, bounded named aggregate values, and enum families
- Bounded top-root package imports `(+import pkg_name ...)` with namespaced package references such as `=pkg_name.RESET_BYTE`, `=pkg_name.mode.BUSY`, `=pkg_name.BYTES[1]`, and `=pkg_name.FRAME.flag`
  - those symbols currently feed only `?toplink` literal-actual positions, and aggregate imports may now resolve either to a scalar leaf or to one whole aggregate root such as `=pkg_name.HEADER` or `=pkg_name.FRAME`
  - imported hash-like aggregate roots follow that same authored-member packing order when lowered whole
- Explicit `(?ports:block ...)` blocks with flat port tokens
- Port tokens like `clk`, `reset`, `rst_n`, `data_in<8`, `txd>`, and `=final_data>8`
- `(?fsmc:instance child_source)` with exactly one child FSM source token
  - or `(?fsmc:instance)` on named children, which defaults the child source to `instance`
  - optionally with one semantic parameter/generic override block such as `(?fsmc:u_child child_src (params (WIDTH 16) (LANES TOP_LANES)))`
  - generated-child overrides must name direct `(+params ...)` declarations in the child source; scalar values stay width-flexible and aggregate values must match the child parameter default's inferred aggregate shape before generation
  - the active child source may be embedded in the same file as `?fsm:name`
  - or resolved from an external `.fsm` file beside the composition source, through repeated `--path DIR` roots, then through `FSMLIB`
  - strict mode narrows this child contract to the canonical `?fsm:name` root family only
- `(?dtc:instance child_source)` with exactly one standalone-DT child source token
  - or `(?dtc:instance)` on named children, which defaults the child source to `instance`
  - optionally with one semantic parameter/generic override block such as `(?dtc:u_filter filter_src (params (WIDTH 16)))`
  - generated-child overrides follow the same direct-child `+params` declaration, symbol-resolution, scalar, and aggregate-shape rules as `?fsmc`
  - the active child source may be embedded in the same file as `?dt:name`
  - the current live path also accepts embedded or external `?mod:name` / `?module:name` child roots there, even though those roots are not semantically identical to `?dt:name`
  - strict mode narrows this child contract to the canonical `?dt:name` root family only
  - or resolved from an external `.fsm` file beside the composition source, through repeated `--path DIR` roots, then through `FSMLIB`
  - combinational `?dtc` children expose only their real user-facing interface ports
  - standalone `?dtc` children with explicit conventional `(+system ...)` expose `clk` plus their authored reset signal
  - standalone `?dtc` children without explicit `(+system ...)` expose implicit `clk` / `rst_n` only when they contain sequential assignments
- `(?rtl:module)` for external RTL children when the instance name matches the module name
- `(?rtl:instance module)` for reusing one external RTL module/interface contract under several instance names
- External RTL interface loading via sidecar `<module>.rtlif`
  - or via an embedded `(?rtlif:module_name ...)` companion root in the same composition source
  - flat `(?rtlif:module_name ...)` roots with explicit port tokens
  - optional `(params (NAME default_value) ...)` declaration blocks for scalar or aggregate external RTL parameters/generics; defaults may be literal values or package-qualified symbols from packages imported by the consuming composition source
  - token forms such as `clk`, `data_in<8`, `txd>`, `core_clk:clock`, and `rst_async_n:reset`
  - explicit type annotations currently limited to `:data`, `:clock`, and `:reset`
  - typed `:clock` / `:reset` metadata lets custom-named RTL system ports auto-wire through mixed composition
- Explicit `(?toplink:name ...)` blocks with flat `/source/target/` tokens
- Source-side top-port bit/slice `?toplink` expressions such as `payload_bus[15:8]` and `status_bus[0]` when the target is a realized child input or declared top output
- Source-side child-output bit/slice `?toplink` expressions such as `producer.payload[7:4]` and `producer.payload[0]` when the target is a realized child input or declared top output
- Source-side bounded concat `?toplink` expressions such as `/header_bus,status_bus[0],=1,payload_bus[3:0]/uart_tx.data_in/`, including nested brace-group forms such as `/header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/uart_tx.data_in/`, when the target is a realized child input or declared top output, now also including intrinsic-width unsized binary/decimal/octal/hex actual operands such as `=0b10`, `='b10`, `=170`, `=0d170`, `='d170`, `=0o7`, `='o7`, `=0xA5`, `='hA5`, or `=A5`, exact-width signed and unsigned based/decimal literal operands such as `=4'sb1010`, `=3'so7`, `=4'shA`, or `=8'sd-1`, named literal actual operands such as `=HEADER_NIBBLE`, `=BYTES[1]`, `=FRAME.flag`, `=mode.BUSY`, `=shared.RESET_BYTE`, or `=shared.mode.BUSY` resolved from top-root `+constants` / `+enums` and imported `?pkg:name` packages, and child-output operands such as `producer.payload`, `producer.payload[7:4]`, or `producer.payload[0]`
- Those same composition actual lanes now also accept FSMGen intent-sized exact-width literals such as `=5'23`, `=8'-10`, `=8'-0xA`, `=8'-0b1010`, or `=20'x1`; they normalize through the same checked literal frontend before structural lowering.
- In those composition actual lanes, obviously bitstring-like bare `0/1` payloads such as `=00001110` or `=10000000` are rejected instead of being guessed. Use `=0b...` for intrinsic-width binary, `=N'b...` for exact-width binary, or `=0d...` if decimal was intended.
- Source-side bounded repeat-group `?toplink` expressions such as `/{3{status_bus[0]}}/uart_tx.data_in/` or `/{2{producer.serial_lo}}/packed_out/`, which lower through the same typed structural path and reuse the same deterministic child-output carrier family when the repeated operand comes from a child output
- Explicit `?toplink` source actuals `=open`, scalar `=0` / `=1`, unsized binary/decimal/signed-decimal/octal/hex direct actuals such as `=0b10100101`, `='b10100101`, `=0d170`, `='d170`, `=-1`, `=0d-1`, `='sd-1`, `='sb1010`, `='so645`, `='shA5`, `=0o245`, `='o245`, `=0xA5`, `='hA5`, `=170`, or `=A5`, underscore-separated spellings such as `=0b1010_0101`, `='b1010_0101`, `=0d1_70`, `='d1_70`, `=0o2_45`, `='o2_45`, `='so6_45`, `=0xA_5`, `='hA_5`, `=1_70`, or `=A_5`, exact-width binary/decimal/signed-decimal/octal/hex literals in unsigned or signed form such as `=8'b10100101`, `=8'sb10100101`, `=8'd165`, `=8'sd-1`, `=8'o245`, `=8'so245`, `=8'hA5`, or `=8'shA5`, whole aggregate roots such as `=HEADER`, `=TAIL`, `=FRAME`, `=shared.HEADER`, or `=shared.FRAME`, and named literal actuals resolved from top-root `+constants` / `+enums` and imported `?pkg:name` packages such as `=RESET_BYTE`, `=BYTES[1]`, `=FRAME.flag`, `=mode.BUSY`, `=shared.RESET_BYTE`, or `=shared.mode.BUSY`, with `=open` still targeting realized child inputs only while direct scalar `=0` / `=1` plus unsized binary/decimal/octal/hex direct actuals widen to the realized child-input or declared top-output target width, unsized signed decimal direct actuals plus unsized signed binary/octal/hex direct actuals widen when the signed value fits the signed range of that direct target width, exact-width literal actuals may now also target declared top outputs, whole aggregate roots staying bounded to aggregates whose leaves all lower to scalar literals, hash-like whole roots packing authored members left to right in declaration order, and named literal actuals staying bounded to the same direct actual and concat-operand positions on the existing structural literal path
  - when one such whole aggregate root binds directly to a declared top output or realized child input that preserved an aggregate declared type alias, the inferred whole-aggregate shape must also match that target aggregate contract instead of passing on packed width alone
  - when one source-side top expression or child expression binds directly to a declared top output or realized child input that preserved an aggregate declared type alias, that expression must now also keep one compatible aggregate contract instead of passing on packed width alone:
    - whole typed signal refs preserve their declared aggregate contract,
    - bit/slice expressions become scalar `bit` / `bits[N]` contracts,
    - bounded concat and repeat expressions become ordered `list<...>` contracts on the typed path,
    - so width-equal but aggregate-shape-incompatible expression-to-target bindings now fail explicitly

Package note:
- `?pkg:name` roots are reusable declaration containers, not HDL-generating roots.
- Local composition-top symbol note:
  - composition-top `(+constants ...)` entries may now also be scalar literals, non-empty lists, or nested hash-like aggregates written as `(member value)` pairs.
  - composition-top aggregate values may now also reuse same-scope local constants and enum members as scalar ingredients regardless of declaration order, with explicit dependency cycles rejected.
  - local composition-top references may now resolve either to a scalar leaf such as `BYTES[1]`, `FRAME.flag`, or `NEST.header.nibble`, or to one whole aggregate root such as `HEADER`, `TAIL`, or `FRAME` on the bounded literal-actual path.
  - whole hash-like aggregate roots now lower by packing authored members left to right in declaration order when every nested leaf still resolves to one scalar literal.
- The active package slice is still intentionally bounded:
  - package `(+constants ...)` entries may now be scalar literals, non-empty lists, or nested hash-like aggregates written as `(member value)` pairs.
  - package aggregate values may now also reuse same-scope package constants and enum members as scalar ingredients regardless of declaration order, with explicit dependency cycles rejected.
  - imported package references may now resolve either to a scalar leaf such as `shared.BYTES[1]`, `shared.FRAME.flag`, or `shared.NEST.header.nibble`, or to one whole aggregate root such as `shared.HEADER`, `shared.TAIL`, or `shared.FRAME`.
  - whole hash-like imported aggregate roots follow that same authored-member packing order when lowered whole.
- Bounded direct `?fsm` / `?dt` roots may now also use `(+import pkg_name ...)`, and namespaced package scalar leaves such as `shared.RESET_BYTE`, `shared.mode.BUSY`, `shared.BYTES[1]`, and `shared.FRAME.flag` plus whole package aggregate roots such as `shared.BYTES`, `shared.TAIL`, or `shared.FRAME` now resolve as literals in assignment RHS expressions and guard equality conditions on that direct-root path.
- Generated child sources that are realized through that same direct-root path may use the same bounded `(+import ...)` contract too.
- Richer typed whole-aggregate package flow/types remain future work.
- The source frontend now preserves brace-grouped slash-token text before composition parsing, so nested concat `?toplink` groups survive from `.fsm` source through raw AST and emitted HDL instead of being flattened away at read time
- One realized child output source fanned out to multiple top outputs through one deterministic shared carrier plus explicit top-output assignments
- One declared top input fanned out directly to one or more top outputs through explicit top-output assignments while sibling child-input consumers reuse that same top input without helper nets
- Dotted child endpoints in links, for example `/producer.output_data/consumer.input_data/`
- `C1` lane: one `?top`, one child (`?fsmc`, `?dtc`, or `?rtl`), explicit `?ports`, deterministic same-name top wiring
- `C2` lane: multiple generated children (`?fsmc` / `?dtc`) plus explicit `?toplink` wiring and deterministic internal nets
- `C3` lane: explicit `?toplink` composition with at least one `?rtl` child and any number of generated children (`?fsmc` or `?dtc`) beside those RTL children, with `.rtlif`-based interface validation
- `C4` lane: declared connect-by-name through `=name` in `?ports` for one or more generated children, one or more `?rtl` children, or any mixture of those generated and external RTL children
  - top outputs still require exactly one matching child output
  - top inputs may fan out to one or more matching child inputs of the same name and width
  - when those ports came from named type aliases, matching now also requires one compatible declared type contract instead of width-only coincidence
- In explicit-link `C2` / `C3`, plain explicit top ports may now also adopt the same-name convention in a narrower way:
  - plain explicit top inputs may fan out to matching child inputs when same-name child-side evidence keeps one direction plus exact width/type agreement and any preserved declared type contract stays compatible,
  - plain explicit top outputs may bind one unique same-name top-facing child output when that child-side evidence is still exact, including any preserved declared type contract,
  - and explicit top-boundary links still override that convention locally.
- `C5` diagnostics: duplicate-driver rejection, explicit-link width mismatch rejection, connect-by-name ambiguity rejection, connect-by-name unknown-endpoint rejection, and width mismatch rejection
- `C6` scoped rejection of legacy out-of-scope composition constructs
- The typed composition result now also carries first-pass provenance metadata for tooling/debugging:
  - top ports expose `origin_kind` so declared versus inferred top-boundary decisions stay visible,
  - links expose `origin_kind` so explicit toplinks, `=name`, same-name convention, internal-carrier, and auto-system links can be distinguished,
  - and `composition_plan->resolved_links` exposes the final planned link set instead of only the originally declared `links`.
- Composition results now also carry a user-facing provenance summary:
  - `generate_hdl_from_file(...)` returns `composition_report` for composition sources,
  - that report summarizes top-port and resolved-link provenance by `origin_kind`,
  - it also reports the first shipped local override cases, including explicit top links overriding same-name convention and explicit top outputs re-exporting inferred internal carriers, and now keeps one concise example subject per override kind,
  - it now also reports the first shipped blocked cases, including explicit child links blocking undeclared top-interface inference and inferred internal carriers staying internal by default, and now keeps one concise example subject per block kind,
  - and the first bounded failure-path wording slice is now shipped too, so plain explicit top-port same-name convention failures now say when the convention is blocked,
  - and that failure-path blocked-wording lane now also covers undeclared top-input/top-output and undeclared internal-carrier inference failures,
  - and it now also covers explicit top-output re-export mismatches when a declared top output does not match the inferred same-name internal-carrier family exactly,
  - and it now also covers explicit-toplink-driven undeclared top-port inference failures when direction, width, or type evidence disagrees,
  - and it now also covers explicit `?toplink` validation failures when endpoint resolution, direction, duplicate-drive, or width evidence blocks the declared link,
  - and it now also covers explicit-link top-wiring and realized-child-wiring failures when declared top ports or realized child ports remain unwired in explicit-link lanes,
  - and it now also covers explicit-link lane-entry and remaining topology failures when explicit-link lanes are entered without `?toplink` or when a still-unsupported explicit-link topology is requested,
  - and it now also covers top-level composition lane/shape gates when no child instances exist, when `?ports` multiplicity is invalid, or when omitted/empty `?ports` appears outside the bounded inference cases,
  - and it now also covers declared `=name` connect-by-name failures when direction, width, ambiguity, or missing-endpoint evidence blocks the declared match,
  - and it now also covers `C1` passthrough exposure failures when explicit top exposure omits a realized child port or disagrees with the realized child interface on name, width, or direction,
  - and it now also covers duplicate top-port and duplicate child-instance declarations when those composition-shape conflicts would otherwise make planning ambiguous,
  - and it now also covers reserved system-port `=name` declarations and unsupported explicit endpoint syntax when those endpoint-shape errors would otherwise leave the binding contract ambiguous,
  - and it now also covers malformed `?ports` and `?toplink` parser items when top-port or top-link token flatness/shape/sizing/declaration-mode would otherwise fail through older raw wording,
  - and it now also covers unsupported composition backend targets when a valid composition source asks for a backend that the current composition lanes do not emit,
  - and it now also covers generated child-source resolution/realization failures when external `?fsmc` / `?dtc` child sources are missing or resolve to the wrong active root kind,
  - and it now also covers blocked `C2` lane selection when an explicit-link generated-child composition still provides only one generated child,
  - and it now also covers blocked external RTL metadata resolution when a `?rtl` child has no reachable `.rtlif` metadata,
  - and it now also covers blocked external RTL metadata structure when a reachable `.rtlif` file does not contain the required `?rtlif:<module>` root,
  - and it now also covers blocked external RTL metadata port typing when a reachable `.rtlif` token resolves to an unsupported explicit type,
  - and it now also covers blocked external RTL metadata system-port direction when a reachable `.rtlif` token declares output-direction `clock` / `reset` metadata,
  - and it now also covers blocked external RTL metadata token shape when a reachable `.rtlif` token is syntactically invalid for the active flat port-token contract,
  - and it now also covers blocked external RTL metadata port sizing when a reachable `.rtlif` token declares a non-positive explicit width,
  - and it now also covers blocked external RTL metadata port declaration uniqueness when a reachable `.rtlif` file repeats the same port name,
  - and it now also covers blocked external RTL metadata port presence when a reachable `.rtlif` file declares no ports under the required root,
  - and it now also covers blocked external RTL metadata flatness when a reachable `.rtlif` file contains nested structure under the required root,
  - and it now also covers blocked embedded RTL metadata root uniqueness when the same composition source contains multiple embedded `?rtlif:<module>` roots for one external RTL child,
  - and it now also covers malformed child-entry structure when empty child entries, non-string child headers, or dotted-pair child payloads would otherwise fail through older raw wording or warnings,
  - and it now also covers unsupported child kinds when a composition child header falls outside the active `?fsmc` / `?dtc` / `?rtl` / `?ports` / `?toplink` family,
  - and it now also covers malformed generated-child source payloads when `?fsmc` / `?dtc` payloads use nested option structures or the wrong number of flat source names,
  - and non-quiet `bin/fsmgen` runs now print the same composition provenance summary directly in the CLI close-out.
- non-quiet failed composition runs now also print a first bounded composition-failure summary when a blocked composition boundary can be extracted from the raised diagnostic, including a `Lane:` line when the blocked diagnostic already names the active `C1` / `C2` / `C3` / `C4` lane, a `Construct:` line when the blocked diagnostic already points clearly at one active syntax construct such as `?ports`, `?toplink`, `?rtl`, `?fsmc`, `?dtc`, or `=port`, a `Child source file:` line when a blocked `?fsmc` / `?dtc` realization failure already names the resolved external `.fsm` file, an `Expected child source file:` line when a blocked `?fsmc` / `?dtc` resolution failure names the missing external source target, an `Expected RTL metadata file:` line when a blocked `?rtl` resolution failure names the missing sidecar target, an `RTL metadata file:` line when a blocked `.rtlif` structure, token, sizing, typing, system-port direction, flatness, or declaration failure already names the resolved metadata file, a `Search roots:` line when blocked lookup diagnostics already expose the active search roots, a concise context line for the offending child/top-port/top-expression/child-expression/explicit-endpoint/actual-source/actual-endpoint/token/repeated-RTL-port/RTL-root when that context can be separated honestly from the longer failure text, plus a concise blocked-reason line.

### Implemented, but not strong enough yet to call fully supported
- No additional construct family is currently parked in this middle bucket.

### Explicitly out of active support
- VHDL generation
- Non-conventional `(+system ...)` forms, including:
  - alternative clock names,
  - malformed reset identifiers,
  - additional system directives,
  - and partial `+system` declarations that do not match the conventional shared pair
- Unsupported top-level directive sections outside the current supported family, for example:
  - `(+clock clk)`
  - `(+areset rst_n)`
  - `(+bogus ...)`
- Unsupported tagged top-level source kinds outside the active source family, for example:
  - `(?define:legacy_template ...)`
  - other legacy wrapper/template source kinds that are neither `?fsm:name`, `?dt:name`, nor `?top:name`
- Unsupported top-level bare forms inside `(?fsm:name ...)`, for example:
  - `(tester_reset := 1)`
  - `(BROKEN 1)`
- Bare condition suffixes without an explicit guard marker, for example:
  - `(A <= B start)`
  - `(-> busy full)`
- Malformed action forms or empty guarded blocks that do not carry a real action body, for example:
  - `(BROKEN)`
  - `(<req)`
- Malformed empty or scalar-only state/DT blocks that do not carry a real decision-tree body, for example:
- Malformed empty state/DT blocks that do not carry a real decision-tree body, for example:
  - `(idle)`
  - `(-misc)`
- Malformed test-node branches that do not carry a real branch body, for example:
  - `(?MODE (=0))`
- Malformed test-node selectors that omit the explicit selector operator, for example:
  - `(?MODE (BUSY ...))`
  - `(?MODE (0 ...))`
- Malformed computed test selectors that omit the selector expression or all branches, for example:
  - `(? (=0 ...))`
  - `(?(| A B))`
- Unsupported or malformed expression forms outside the current active operator family, for example:
  - `(A = (bogus B C))`
  - `(A = (== B))`
  - `(A = <start)`
- Legacy composition forms such as `?&...`, nested `?top`, `?ports` mapping directives, nested `?toplink`, and multi-source `?fsmc`
- Legacy generic/template expansion forms, including:
  - placeholder selectors such as `?[READ]`
  - repeat macros such as `?repeat:[MAX_COUNT]`
  - placeholder tokens such as `[DATAIN]` or `[?size: MAX_COUNT]`

### Draft normative contract for guards, suffixes, updates, and operator expressions
This is the current `R8` draft normative contract for the active language slice that is now regression-backed explicitly.

Guarded blocks:
- `(<cond ...actions...)` executes its actions when `cond` is true in the active condition model.
- `(<!cond ...actions...)` executes its actions when `cond` is false in the active condition model.
- Guarded blocks must contain at least one nested action.
- Nested guarded blocks are allowed, and nested guards compose by logical `AND`.
- Active shorthand semantics:
  - `(<foo ...)` means `foo != 0`
  - `(<!foo ...)` means `foo == 0`
  - `(<foo=value ...)` and `(<foo==value ...)` mean equality
  - `(<foo!=value ...)`, `(<foo<value ...)`, `(<foo<=value ...)`, `(<foo>value ...)`, and `(<foo>=value ...)` mean the corresponding comparison against `foo`
- Current active examples include:
  - `(<req (A <= B))`
  - `(<!full (-> busy))`
  - `(<mode==3 (OUT = IN))`
  - `(<count<=8'3 (FLAG = 1))`
  - `(<(& req start !full) (D = C))`
  - `(<count=8'3 (FLAG = 1))`

Condition suffixes:
- A suffix guard is the single-action form of a guarded block.
- Suffix guards must use the explicit guarded forms `<...` or `<!...`; bare suffixes like `(A <= B start)` are not part of the active contract.
- Examples:
  - `(A <= B <start)` is the single-action guarded form of `(<start (A <= B))`
  - `(-> busy <!full)` is the single-action guarded form of `(<!full (-> busy))`
  - `(OUT = IN <mode==1)` is the single-action guarded form of `(<mode==1 (OUT = IN))`
  - `(-> special <count<=3)` is the single-action guarded form of `(<count<=3 (-> special))`

Update shorthand:
- `(++ counter)` means increment `counter` by `1`
- `(-- retry_count)` means decrement `retry_count` by `1`
- `(+= counter)` means increment `counter` by `1`
- `(-= retry_count)` means decrement `retry_count` by `1`
- `(+=4 byte_count)` means increment `byte_count` by `4`
- `(-=1 remaining)` means decrement `remaining` by `1`
- `(+= byte_count 4)` means increment `byte_count` by `4`
- `(-= remaining 3)` means decrement `remaining` by `3`
- Update shorthand must target a scalar signal name.
- After the optional delta, update shorthand accepts only an explicit guard suffix such as `<start`, `<!full`, or `< (& req ready)`.
- Inline forms keep the surrounding assignment family:
  - `(ACC <- SRC (+=))`
  - `(ACC <- SRC (+= 2))`
  - `(COMB = SRC (-=))`
  - `(COMB = SRC (-= 1))`
  - Bare inline forms `(+=)` and `(-=)` mean delta `1`.

Operator expressions:
- The RHS expression grammar is shared across combinational and sequential assignments.
- The assignment operator decides timing/storage semantics; the RHS decides only the expression tree.
- The active assignment-operator family is:
  - `=`
  - `<-`
  - `<-=`
  - `<=`
  - `<=+`
  - delayed-pulse forms like `<1`, `<2`, and `<N`
- Unsupported assignment operators such as `?=` or `=>` are rejected explicitly instead of falling through to internal parser errors.
- Current regression-backed operator surface:
  - unary: `!`
  - negated n-ary bitwise/logical-style families: `!&`, `!|`, `!^`
  - n-ary comparison: `==`, `!=`, `<`, `<=`, `>`, `>=`
  - n-ary arithmetic/logic: `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`
  - aliases: `not`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`, `sub`, `mul`, `div`, `mod`, `and`, `nand`, `or`, `nor`, `xor`, `xnor`
- Current lowering model:
  - `+`, `*`, `&`, `|`, `^` are treated as n-ary expression families
  - `!&`, `!|`, and `!^` lower as unary `!` over the corresponding factored `&`, `|`, or `^` family
  - `-`, `/`, `%` are treated as left-associative n-ary expression families
  - `==`, `!=`, `<`, `<=`, `>`, `>=` are treated as chained adjacent-pair comparison families
    - `(< a b c)` means `((a < b) && (b < c))`
    - `(eq a b c d)` means `((a == b) && (b == c) && (c == d))`
  - generated HDL preserves nested AST grouping when target-language
    left-associativity would otherwise change meaning; for example
    `(% addr_q (* beats_total_q addr_step_q))` lowers to
    `addr_q % (beats_total_q * addr_step_q)`, not
    `addr_q % beats_total_q * addr_step_q`
- Examples:
  - `(match = cnt[2:1]!=2'2)`
  - `(sum = (+ a b c d))`
  - `(diff = (- a b c d))`
  - `(prod = (* a b c d))`
  - `(quo = (/ a b c d))`
  - `(rem = (% a b c d))`
  - `(between = (< low value high))`
  - `(equal_chain = (eq a b c d))`
  - `(mask = (^ x y z))`
  - `(alias_sum = (add a b c d))`
  - `(alias_xor = (xor x y z))`
  - `(mask_nand = (!& a b !c (| d e)))`
  - `(mask_nor = (nor a b c))`
  - `(mask_xnor = (xnor a b c))`
  - `(packed = (concat header payload))`
  - `(alias_packed = (cat header payload))`
  - `((concat high_half low_half) = packed)`
  - `((cat reg_high reg_low) <- packed_next)`
  - `(inv = (not ready))`

Boundary note:
- The active contract now includes the systematic shorthand guard family for simple truthiness and inline comparisons.
- Exact authored width evidence is used before generation whenever it is safe:
  static references such as `fifout[31:24]` infer the base signal width, explicit
  guard comparisons such as `<txtimer>20'x1` infer the compared signal width,
  and explicit test selectors such as `=2'3` infer the tested signal width.
  This keeps simple `.fsm` files ergonomic without asking users to add `+size`
  entries for widths that the source already proves.
- Intent-level truthiness still means “non-zero” for both one-bit and multibit
  signals. In flattened generated SystemVerilog, multibit truthiness inside a
  one-bit enable expression is emitted as a reduction predicate such as
  `(|COUNT)` for true/non-zero or `(~|bytept)` for false/zero. This avoids
  width-changing bitwise expressions like `en & COUNT` and warning-prone
  logical negations like `!bytept` while preserving the intent-level meaning.
- Direct assignment RHS pack expressions now support `(concat ...)` with the shorter `(cat ...)` alias. Operands are authored left to right and emitted high to low as a SystemVerilog concat such as `{header, payload}`.
- Direct RHS concat operands must have exact widths before generation, currently from declared signal widths, bit/slice or typed aggregate leaf access, or explicitly sized literal constants. Width mismatches against the LHS are rejected by the pre-generation width contract instead of being silently padded or truncated.
- When a direct RHS concat drives a declared aggregate target, FSMGen now infers an ordered source type-shape contract before generation. Typed list targets compare against the concat operand list, nested concat operands keep nested list shape, and typed record targets can map exact top-level concat operands onto record member order, so width-equal but shape/order-incompatible concat assignments are blocked before HDL emission.
- Direct assignment LHS deconstruction now supports a bounded `(concat ...)` or `(cat ...)` target such as `((concat high_half low_half) = packed)` and `((cat reg_high reg_low) <- packed_next)`. Authored operands map left to right onto high-to-low RHS slices, and the frontend lowers the deconstruct into ordinary validated per-target assignments before the backend emits HDL.
- LHS deconstruct operands must be static writable lvalues: whole signals, static bit/slice references, or typed aggregate leaf references. Every operand and the RHS must have an exact positive width before generation, total widths must match exactly, and overlapping or duplicated target ranges are rejected instead of relying on renderer-side concat semantics.
- When a deconstruct RHS is a whole aggregate constant such as `FRAME`, a typed aggregate signal such as `IN_FRAME`, or a typed aggregate sub-root such as `IN_FRAME.payload`, exact nested subaggregate fragments keep their own type-shape contracts. For example, splitting `FRAME` or `IN_FRAME` into `tag` and `payload` fragments checks a typed `payload_t` target against the source `payload` fragment contract rather than against the entire `frame_t` record.
- When a deconstruct RHS is itself a `(concat ...)` / `(cat ...)`, any deconstruct fragment that exactly matches whole RHS concat operand boundaries keeps those operands instead of becoming a part-select of the whole concat expression. Nested RHS concat fragments are handled the same way: aligned nested operands keep ordered list shape, and typed record targets can map exact aligned operands onto record member order before the pre-generation assignment validator runs.
- Canonical assignment pair form:
  - the preferred Lisp-ish spelling is `(assign-op (lhs rhs))`, with an optional assignment-level guard as `(assign-op (lhs rhs) <cond)`,
  - examples include `(= (OUT VALUE))`, `(<- (Q D))`, `(<= (D_IN NEXT_VALUE))`, `(<-= (Q D))`, `(<=+ (D_IN NEXT_VALUE))`, `(<1 (PULSE 1))`, `(= (OUT (+ A B)) <valid)`, and `(<- ((cat REG_HI REG_LO) NEXT_DATA) <load)`,
  - this is active parser syntax and is support-accounted by the maintained regression corpus,
  - existing infix forms such as `(OUT = VALUE)` and `(Q <- D)` remain compatibility spellings and normalize into the same assignment AST/IR,
  - the optional `<cond>` is assignment metadata equivalent to today’s guard suffixes, not part of the RHS expression.
- Broader future language ideas may still refine additional deconstruction/packing helpers later, but the pair form above is now real supported syntax in the active tool.
- Malformed guard shorthand payloads such as `<mode=` or `<==3` are now rejected explicitly instead of falling through to generic expression-token errors.
- Inline scalar comparison tokens such as `cnt[2:1]!=2'2` are part of the active expression surface.
- Malformed inline comparison tokens such as `cnt[2:1]!=` or `=3` are now rejected explicitly instead of falling through to generic expression-token errors.
- Parser-generated intermediate expression signals now keep the source signals from their driving AST live in the generated interface instead of hiding those dependencies behind the intermediate name alone.
- Parser-generated intermediate expression signals referenced only from assignment RHS expressions now stay internal to the generated module instead of being filtered away or leaking into generated-child composition interfaces.
- Unsupported expression operators, malformed operator arity, and guard-only tokens in ordinary RHS expression position are now rejected explicitly instead of drifting through parser fallthrough.

Test nodes:
- `(?SIG (=0 ...actions...) (!=8'0 ...actions...) (>8'3 ...actions...) ...)` is the active multi-way selector form.
- Plain `?SIG` test nodes require `SIG` to be HDL-identifier-compatible.
- `?(expr ...)` is the active computed-selector form when the selector itself is a condition expression, for example:
  - `(?(| A B) (=0 ...actions...) (=1 ...actions...))`
- Computed selectors must start with a real selector expression and include at least one selector branch.
- Malformed plain test-node signal names such as `?bad-name` or `?0` are rejected explicitly.
- Each test branch must include:
  - an explicit operator-prefixed selector token like `=0`, `=1`, `=OTHER`, `!=8'0`, `<8'4`, `<=8'3`, `>8'3`, or `>=8'1`
  - and at least one nested action
- Bare selectors like `BUSY` or `0` are not part of the active contract.
- Malformed empty branches such as `(?MODE (=0))` are rejected explicitly.
- Malformed computed selectors such as `(? (=0 ...))` or `(?(| A B))` are rejected explicitly.
- Selector meaning:
  - `=value` means equality
  - `!=value` means inequality
  - `<value`, `<=value`, `>value`, `>=value` mean the corresponding relational comparison against the test signal
- Selector widths may infer the tested signal when the selector value has an
  exact width, for example `=2'3` or `!=8'0`.
- Computed selectors may synthesize an internal intermediate signal so the expression can be reused by the branch comparisons during HDL generation.

### Draft normative contract for symbol-definition and import sections
This is the current `R8` draft normative contract for the symbol-definition and import families that are now regression-backed explicitly.

`(+size ...)`:
- Declares signal widths through `(signal width_or_type)` entries.
- `width_or_type` may be:
  - a positive integer literal such as `1`, `8`, `0d8`, `0x10`, `0b1000`, `'h8`, or `8'h10`
  - a named scalar or aggregate type such as `bit`, `byte_t`, `frame_t`, or `pkg_name.byte_t`
  - a positive integer constant expression using literals, same-root/imported constants, enum members, params/generics, aggregate scalar leaves, and the bounded Lisp-ish arithmetic/bitwise operators `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^` plus aliases `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, `xor`
- Direct `+size` expression literals and positive scalar width symbols use the same integer-literal interpretation for decimal, `0d`, `0b`, `0o`, `0x`, SystemVerilog-style based spellings, and FSMGen intent-level sized values such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`, or `20'x1`; signed literal terms may participate inside an expression when the final resolved width is still positive, for example `(+ 8'sd9 8'sd-1)`.
- FSMGen intent-level sized literals use `<width>'<integer-value>` in `.fsm`, with the width attached to the value rather than written as a target-HDL token. The backend must normalize them before HDL emission: `5'23` becomes legal SV like `5'd23`, `20'x1` becomes `20'h1`, and negative sized values lower through a two's-complement bit pattern such as `8'-10` -> `8'd246`, `8'-0xA` -> `8'hF6`, and `8'-0b1010` -> `8'b11110110`.
- Value-bearing literal lanes are stricter than positive-width lanes: direct RHS expressions, `+constants`, `+params`, and `.rtlif` parameter/generic scalar defaults reject obviously bitstring-like bare `0/1` tokens such as `00001110` or `10000000` instead of guessing decimal versus binary. Use `0b00001110` for intrinsic-width binary, `8'b00001110` for exact-width binary, or `0d1110` if decimal was intended. Positive-width slots still keep decimal compatibility, so `(+size (DATA 10))` remains decimal ten.
- Width expressions may use aggregate scalar leaves such as `LANES[1]` or `FRAME.meta.mode`, but a whole aggregate root such as `LANES` is not itself a scalar width. Use a scalar leaf or a named aggregate type alias when the intent is typed aggregate storage.
- The legacy empty form `(+size)` remains supported as a no-op in default mode because it still exists in compatibility coverage.
- Strict mode rejects the empty no-op form and requires either explicit width entries or no `+size` section at all.
- Current active use:
  - `(+size (A 8) (B 8))`
  - `(+size (DATA (+ BYTE_W 1)) (MODE mode.WIDTH) (LANE LANES[0]))`
  - `(+size (SIGNED_TERM_W (+ 8'sd9 8'sd-1)) (DEC_TERM_W (+ 0d10 -2)))`
  - `(+size)`
- Malformed payloads like `(+size BROKEN)`, malformed entries like `(+size (A))`, unresolved width symbols, whole aggregate width-expression roots, unsupported width operators like `(pow 2 3)`, malformed operator arity like `(+ 8)`, invalid width arithmetic such as `(/ 8 0)` or `(% 8 0)`, and non-positive widths like `(+size (A 0))` are rejected explicitly.

`(+constants ...)`:
- Defines named literal constants.
- Shape:
  - non-empty list of `(NAME value)` entries
- Current active use:
  - `(+constants (C0 8'3) (RESET_BYTE 0xA5) (LANE_MASK 0b1010) (OCT_W 0o10) (ZERO const_8b0))`
- Scalar constants may use plain decimal, sized SystemVerilog literals, unsized SystemVerilog-style based literals such as `'hA5`, prefixed forms such as `0xA5`, `0b1010`, `0o77`, FSMGen intent-level sized values such as `5'23` or `8'-0xA`, and underscore-separated digits.
- In those value-bearing constant lanes, obviously bitstring-like bare `0/1` tokens such as `00001110` or `10000000` are rejected before generation instead of being guessed. Spell them explicitly as `0b...`, `N'b...`, or `0d...`.
- References to those names resolve as literals in assignment RHS expressions and guard equality conditions.
- Direct-root note:
  - inside `?fsm:name` and `?dt:name`, `(+constants ...)` also has a bounded aggregate extension where values may be non-empty lists or nested hash-like `(member value)` aggregates.
  - direct-root aggregate values may now also reuse same-scope local constants and enum members as scalar ingredients regardless of declaration order, with explicit dependency cycles rejected.
  - the live direct-root path now accepts scalar leaves such as `BYTES[1]`, `FRAME.flag`, or `NEST.header.nibble`, and whole aggregate roots such as `BYTES`, `TAIL`, or `FRAME`.
  - whole hash-like aggregate roots lower by packing authored members left to right in declaration order when every nested leaf still resolves to one scalar literal.
  - when one of those whole aggregate roots is assigned directly into a `+size` target that preserved an aggregate named type alias, the inferred whole-aggregate shape must also match that target aggregate contract instead of relying only on packed width.
- Composition-top note:
  - inside `?top:name`, `(+constants ...)` has that same bounded aggregate extension, and the live composition path now accepts scalar leaves such as `BYTES[1]` or `FRAME.flag` plus whole aggregate roots such as `HEADER`, `TAIL`, or `FRAME` on the bounded literal-actual path.
  - whole hash-like aggregate roots lower there through that same authored-member packing rule.
  - on direct `?toplink` bindings into typed aggregate top outputs or typed aggregate child inputs, width-equal whole aggregate roots must now also match the target aggregate type shape instead of relying only on packed width.
- Malformed shapes like `(+constants)`, `(+constants BROKEN)`, and malformed entries like `(+constants (C0))` are rejected explicitly.

`(+define ...)`:
- Defines one named literal-like value per directive block.
- Shape:
  - exactly one `(NAME scalar_value)` pair
- Current active use:
  - `(+define (D0 8'4))`
- References to that name resolve as literals in assignment RHS expressions and guard equality conditions.
- Malformed shapes like `(+define)`, `(+define BROKEN)`, and malformed entries like `(+define (D0))` are rejected explicitly.

`(+params ...)`:
- Defines named parameter values for direct roots.
- Shape:
  - non-empty list of `(NAME value)` entries
- Current active use:
  - `(+params (P0 8))`
  - `(+params (WIDTH 0x10) (LANES (8'hA5 8'h3C)))`
  - `(+params (RESET_PARAM RESET_BYTE) (MODE_PARAM mode.BUSY) (LANE_PARAM LANES))`
  - `(+params (ALIAS_WIDTH WIDTH) (WIDTH 16) (LANE_ALIAS LANES))`
- Values use the same bounded parameter/generic value normalizer as external RTL metadata:
  - scalar integer literals such as `8`, `8'hA5`, `'hA5`, `0xA5`, `0b1010`, and `0o77`
  - obviously bitstring-like bare `0/1` tokens such as `00001110` or `10000000` are rejected here; use `0b...`, `N'b...`, or `0d...` explicitly instead
  - bounded literal aggregate payloads such as `(8'hA5 8'h3C)` or `((mode 2'b10) (flag 1))`, which lower to one packed literal when used as whole values
  - bounded scalar operator expressions such as `(+ WIDTH 1)`, `(* COUNT 2)`, `(+ BYTES[1] 1)`, `(+ FRAME.meta.mode 1)`, or `(and MASK 8'hF0)` using `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`, or word aliases `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, `xor`
  - bounded aggregate expressions such as `(+ BYTES BYTE_INC)`, `(- BYTES BYTE_DEC)`, `(* BYTES BYTE_SCALE)`, `(/ BYTES BYTE_DIV)`, `(% BYTES BYTE_MOD)`, `(and BYTES BYTE_MASK)`, `(or FRAME FRAME_MASK)`, or `(xor LANE_A LANE_B)`, using leafwise `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^` or aliases `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, `xor` between matching list/record aggregate shapes
- Values may also reuse resolved semantic value symbols:
  - same-root `+constants`, including bounded whole aggregate roots
  - enum members such as `mode.BUSY`
  - same-root direct `+define` values
  - same-root direct `+params`, including forward references and aggregate parameter aliases
- Param-to-param references are resolved as one acyclic dependency graph, so declaration order does not matter when there is one safe answer; dependency cycles such as `(P_A P_B)` plus `(P_B P_A)` are rejected before HDL emission.
- Parameters/generics can be scalar or aggregate semantic values; the current operator-expression support includes scalar expressions plus the first bounded aggregate leafwise operator slice.
- Scalar parameter expressions may use scalar leaves from list/record aggregates, including nested leaves and aggregate parameter defaults such as `P_LIST[0]`.
- Aggregate expressions require all operands to be list/record aggregates with matching inferred shapes, fold leaf-by-leaf into one aggregate value before generation, and reject mixed scalar/aggregate operands or shape mismatches before HDL emission.
- Aggregate arithmetic leaves are unsigned, fixed-width folds: leaf widths must match, divide/modulo by zero is rejected, and overflow or underflow outside the leaf width aborts before HDL generation.
- Richer aggregate operator expressions remain future work when they go beyond the shipped leafwise numeric/bitwise operators: an operator between aggregate values is valid only when that operator is defined for the operand aggregate types/shapes and the result can be validated before HDL generation.
- References to those names remain named parameter references in direct-root expressions instead of being substituted back to their default literals.
- Direct SystemVerilog module generation emits a `#(...)` `parameter NAME = default_value` block for these direct-root params, so a generated module can still expose true HDL configuration knobs.
- Width handling stays conservative: explicitly sized parameter defaults and packed aggregate defaults can contribute exact width where the semantic checker requires it, while unsized scalar defaults such as `(P0 8)` and scalar expression defaults remain width-implicit until their HDL context resolves them.
- Malformed shapes like `(+params)`, `(+params BROKEN)`, malformed entries like `(+params (P0))`, duplicate parameter names, and dependency cycles are rejected explicitly.

`(+enums ...)`:
- Defines named enumerations with member/value pairs.
- Shape:
  - non-empty list of `(enum_name (MEMBER value) ...)` definitions
  - each enum definition must contain at least one member pair
- Current active use:
  - `(+enums (mode (IDLE 0) (BUSY 1)))`
- Enum members are referenced as `enum_name.member_name`, for example `mode.BUSY`.
- Those references resolve as literals in assignment RHS expressions and guard equality conditions.
- Malformed shapes like `(+enums)`, `(+enums BROKEN)`, `(+enums (mode))`, and malformed members like `(+enums (mode BROKEN))` are rejected explicitly.

`(+types ...)`:
- Defines bounded named types.
- Shape:
  - non-empty list of `(type NAME bit)`, `(type NAME (bits N))`, `(type NAME (signed bit))`, `(type NAME (signed (bits N)))`, `(type NAME (two_state ...))`, `(type NAME (four_state ...))`, `(type NAME (list ...))`, `(type NAME (record (field TYPE) ...))`, or `(type NAME other_type)` entries
- Current active use:
  - `(+types (type flag_t (two_state bit)) (type sflag_t (four_state (signed bit))) (type byte_t (bits 8)) (type sbyte_t (four_state (signed (bits 8)))) (type header_t (list byte_t byte_t)) (type frame_t (record (tag flag_t) (payload header_t))) (type byte_alias shared.byte_t))`
- Direct-root note:
  - inside `?fsm:name` and `?dt:name`, `(+size ...)` width entries may now use local or imported type names such as `(OUT byte_t)`, `(FRAME frame_t)`, or `(FLAG shared.flag_t)`.
  - bounded aggregate type aliases now cover packed `(list ...)` and `(record ...)` forms; on the current direct generated-module SystemVerilog backend, those named aggregate types now lower to backend-owned packed typedefs instead of flattening back to raw packed-vector declarations when declared type metadata reaches the boundary/internal declaration plan.
  - direct generated-module aggregate typedefs follow the same Verilog-family convention as composition typedefs: record fields keep authored names, list fields become deterministic `item_0`, `item_1`, ... members, and scalar leaves preserve explicit signedness plus `two_state` / `four_state` intent as `bit` / `logic`.
  - when one of those direct-root `+size` targets preserves an aggregate alias such as `frame_t`, whole aggregate RHS roots such as `FRAME` must now also keep one compatible aggregate shape instead of slipping through on equal packed width alone.
  - direct-root expressions may now also read declared aggregate-typed signals through record members and list/scalar indexes, for example `(OUT_TAG = IN_FRAME.tag)` and `(OUT_PAYLOAD_MID = IN_FRAME.payload[1])`; record member names stay authored, while list indexes lower through the generated SystemVerilog typedef field convention such as `IN_FRAME.payload.item_1`.
  - partial direct-root aggregate LHS writes such as `(OUT_FRAME.tag = IN_FRAME.tag)` and `(OUT_FRAME.payload[1] = IN_NIBBLE)` are mapped through the typed AST to the correct packed base-signal ranges before final mux generation.
  - when one of those width entries resolves to a signed scalar type alias, the generated SystemVerilog boundary/internal declarations now preserve that signedness, for example `input wire signed [7:0] IN` or `reg signed [7:0] OUT`.
  - when one of those width entries resolves to an explicit `(two_state ...)` or `(four_state ...)` scalar type alias, the generated SystemVerilog boundary/internal declarations now also preserve that state-model intent as `bit` or `logic`, for example `input bit [7:0] IN`, `logic signed [7:0] OUT`, or `input logic signed [7:0] IN`.
  - those same direct-root `(+size ...)` width entries may now also use local or imported positive integer scalar symbols such as `(OUT BYTE_W)` or `(FLAG shared.FLAG_W)` when the resolved symbol is one positive integer literal value; those width symbols accept common scalar literal spellings such as `8`, `8'h8`, `'h8`, `0x8`, `0b1000`, and `0o10`.
  - local and imported types resolve through one declarative-scope pass, so normal non-cyclic references do not depend on declaration order.
  - when one of those width entries resolves through a named type alias, the forward `structural_rtl_ir` boundary and mirrored `module_info` now also preserve `declared_type_name` plus the resolved canonical `declared_type_spec` on those module ports, so embedders can still see the authored type contract instead of only the flattened width/signed/state-model result.
- Composition-top note:
  - inside `?top:name`, local `(+types ...)` declarations may now drive local `?ports` width aliases such as `out_data>byte_t`, `out_flag>flag_t`, `out_header>header_t`, or `out_frame>frame_t`.
  - imported package type aliases may now also drive `?ports` widths through package-qualified tokens such as `out_data>shared.byte` or `out_frame>shared.frame_t`.
  - local aliases may now also target imported package types, including aggregate members inside local aggregate aliases, so forms like `(+types (type byte_t shared.byte))` and `(+types (type lane_t (record (head shared.header_t) (tail (list bit bit)))))` may then drive `?ports` widths through `out_data>byte_t` or `out_lane>lane_t`.
  - when those local or imported `?ports` width aliases resolve to signed scalar types, emitted Verilog-family top ports now preserve that signedness, for example `input signed [7:0] in_data` or `output signed [7:0] out_data`.
  - when those local or imported `?ports` width aliases resolve to explicit `(two_state ...)` or `(four_state ...)` scalar types, emitted Verilog-family top ports now also preserve that state-model intent as `bit` or `logic`, for example `input bit [7:0] in_data`, `output bit [7:0] out_data`, or `input logic signed [7:0] in_data`.
  - when those local or imported `?ports` width aliases resolve to aggregate aliases, emitted composition-top SystemVerilog now synthesizes backend-owned local packed typedefs such as `frame_t__fsmgen_t` or `shared__frame_t__fsmgen_t`; record fields keep authored names, list fields become deterministic `item_0`, `item_1`, ... members, and typed top ports plus typed structural nets then reuse those typedefs instead of flattening back to raw packed-vector declarations.
  - composition `?ports` width tokens may now also use local or imported positive integer scalar symbols such as `out_data>BYTE_W` or `out_data>shared.BYTE_W` when the resolved symbol is one positive integer literal value; those width symbols accept common scalar literal spellings such as `8`, `8'h8`, `'h8`, `0x8`, `0b1000`, and `0o10`.
- when a declared `?ports` width token resolves through a named type alias, composition-top `structural_rtl_ir` now preserves `declared_type_name` plus the resolved canonical `declared_type_spec` on those top ports, and realized generated-child interface ports preserve the same metadata when the child source declared those ports through named `+types`.
- when an internal composition carrier net is inferred from one typed child-output family, composition-top `structural_rtl_ir` now preserves that carrier net's `declared_type_name` plus canonical `declared_type_spec` too, instead of flattening the net back to width-only metadata.
- Malformed shapes like `(+types)`, `(+types BROKEN)`, malformed entries like `(+types (type only_name))`, and explicit type dependency cycles are rejected explicitly.

`(+import ...)`:
- Imports one or more shared package namespaces from bounded `?pkg:name` roots.
- Shape:
  - non-empty flat list of package names
- Current active use:
  - `(+import shared other_pkg)`
- Direct-root references stay namespaced, for example `shared.RESET_BYTE`, `shared.mode.BUSY`, `shared.BYTES[1]`, and `shared.FRAME.flag`.
- Those imported names currently resolve as literals in direct-root assignment RHS expressions and guard equality conditions when the reference reaches a scalar leaf.
- Composition-top imports reuse the same package sources, but currently feed only `?toplink` literal-actual positions such as `=shared.RESET_BYTE`, `=shared.mode.BUSY`, `=shared.BYTES[1]`, and `=shared.FRAME.flag`.
- Malformed shapes like `(+import)`, `(+import BROKEN_LIST)`, and invalid package names such as `(+import bad-name)` are rejected explicitly.

Forward IR note:
- direct `?fsm` / `?dt` results now also preserve one bounded `symbol_contract` through `intent_hir` and mirrored `module_info`
- composition `?top` results now preserve that same bounded `symbol_contract` through composition-top `intent_hir` and mirrored `module_info`
- that surface currently carries local constant/enum/type names and counts, canonical constant payloads, canonical scalar type specs, scalar-leaf convenience payloads, aggregate-root path summaries, and imported package names/counts
- the sibling `structural_rtl_ir` surface now also preserves `declared_type_name` plus canonical `declared_type_spec` on direct-root module ports, composition top ports, and realized generated-child interface ports whenever those live boundaries came from named type aliases instead of plain numeric width tokens
- it is meant as a semantic export/inspection surface for embedders and future compiler work, not as evidence that whole-aggregate assignment/type flow is already shipped

Regression-backed examples:
```lisp
(+constants
  (C0 8'3)
  (ZERO const_8b0)
  (FRAME ((mode 3) (flag 1)))
)
(+define (D0 8'4))
(+params
  (P0 8)
)
(+enums
  (mode
    (IDLE 0)
    (BUSY 1)
  )
)

(-dt
  (A = C0)
  (B = D0)
  (C = P0)
  (D = mode.BUSY)
  (FLAG = 1 <SEL=C0)
  (BUSY_SEEN = 1 <SEL=mode.BUSY)
)
```

Boundary note:
- This slice locks direct-root symbol resolution in assignment RHS expressions and guard equality conditions.
- It also locks namespaced package import resolution on that same direct-root path plus bounded composition-top package-import use on `?toplink` literal-actual positions.
- It also locks the malformed section/entry boundary for `+constants`, `+define`, `+params`, `+enums`, `+types`, and `+import`, so these families no longer rely on incidental Perl list-unpacking errors.
- Broader semantics for these families should be documented explicitly if and when the contract is widened beyond that current active use.

### Draft normative contract for top-level source kinds
This is the current `R8` draft normative contract for the active top-level source boundary.

Accepted source roots:
- `(?fsm:name ...)`
- `(?dt:name ...)`
- `(?mod:name ...)`
- `(?module:name ...)`
- flattened legacy `+fsm` roots
- `(?top:name ...)` through the composition pipeline

Current boundary:
- Supported:
  - `?fsm:module_name` as the active FSM source root, with an HDL-identifier-compatible module name
  - `?dt:module_name` as the active standalone-DT source root, with an HDL-identifier-compatible module name
  - `?mod:module_name` and `?module:module_name` as additional currently accepted direct single-module roots on the live shared parser/backend path, without declaring them semantic synonyms of `?dt:module_name`
  - `+fsm` as the legacy FSM root family:
    - either the flattened sibling form with a first top-level `(+fsm module_name)` entry,
    - or the nested legacy root form `(+fsm module_name ...)`
  - `?top:top_name` as the active composition source root, with an HDL-identifier-compatible top name
- Rejected explicitly:
  - unsupported tagged wrapper/template roots such as `(?define:legacy_template ...)`
  - other tagged source kinds that are neither active FSM sources, active standalone-DT sources, nor active composition sources
  - malformed `+fsm` roots that do not provide a scalar module name in one of the two supported legacy layouts
  - malformed tagged source roots such as `?fsm:bad-name`, `?dt:bad-name`, `?mod:bad-name`, `?module:bad-name`, or `?top:bad-name` whose source name is not HDL-identifier-compatible
  - bare top-level FSM content without a wrapping supported source root, such as files that start directly with `(+system ...)` or `(idle ...)`
  - malformed structured `?fsm:name` roots whose body is empty or contains non-list top-level items such as `(?fsm:empty_root)` or `(?fsm:scalar_root BROKEN)`
- Important rule:
  - an unsupported tagged top-level wrapper does not become supported just because it contains a nested supported source root somewhere inside it

Boundary note:
- This slice makes the top-level source-kind boundary explicit instead of letting legacy tagged wrappers drift through the nested-`?fsm` fallback path.
- The active toolchain now treats unsupported tagged roots as out of support at the top-level boundary, not as accidental containers for live FSM parsing.
- Bare top-level FSM content is now also rejected through an explicit source-root boundary instead of the older generic “expected `?fsm:name` or `+fsm`” parser error.
- Top-level pipeline and CLI failures now also keep a `Source file: '...'` line so parse/support-tier failures stay source-local in larger runs.
- CLI entrypoint failures that happen before pipeline generation now also keep explicit artifact context instead of only a raw one-line failure:
  - unresolved source lookup failures now keep `Requested source: '...'`,
  - and output-open failures now keep both `Source file: '...'` and `Output file: '...'`.
- CLI failure output now also suppresses raw Perl `confess` stack traces for ordinary string diagnostics, so those same source-local messages stay readable instead of expanding into call-frame noise.
- Typed extension hook failures now keep matching artifact context too:
  - `Source file: '...'` for the failing source,
  - `Extension module: 'Module::Name'` for the failing extension,
  - and `Extension stage: 'after_parse_source'` or `Extension stage: 'after_generate_result'` before the underlying extension diagnostic.
- Typed extension loading failures now keep matching artifact context too:
  - `Extension config file: '...'` for malformed or unreadable extension config input,
  - `Extension module: 'Module::Name'` for missing or constructor-failing extension modules,
  - and CLI constructor failures now also stay cleaned instead of dumping the raw `bin/fsmgen` script line.
- Generated-child realization failures now keep the same source-local framing too:
  - external child failures keep the child `Source file: '...'` plus a `Parent composition source: '...'` line,
  - embedded child failures keep the containing composition `Source file: '...'`,
  - both now keep a `Generated child source: '?...c' 'name'` line before the underlying child diagnostic,
  - wrong-kind external child failures now keep that same resolved-child and parent-composition framing instead of surfacing only the wrong-kind note,
  - and missing external child failures now keep the containing composition `Source file: '...'`, an `Expected child source file: 'source_name.fsm'` line, explicit `Search roots:` and `Searched locations:` lines, plus the generated-child identity line instead of surfacing only the unresolved-child search text.
- External `?rtl` metadata failures now keep matching source-local framing too:
  - unresolved sidecar `.rtlif` failures keep `Source file: '...'`, `Expected RTL metadata file: 'module.rtlif'`, and `Search roots: '...'`,
  - resolved sidecar `.rtlif` failures keep `RTL metadata file: '...'` plus `Parent composition source: '...'`,
  - embedded `?rtlif` failures keep `Source file: '...'` for the containing composition source,
  - and both now keep `RTL child module: '?rtl' 'module_name'` before the underlying metadata diagnostic.
- The legacy `+fsm` root family is supported as a real source kind, but it must still follow the active scalar-name contract:
  - accepted:
    - `(+fsm my_module)` followed by sibling `(+system ...)`, state/DT blocks, and other supported top-level forms
    - `(+fsm my_module ...)`
  - rejected:
    - `(+fsm)` without a scalar module name
    - malformed `+fsm` roots whose payload does not match either supported legacy layout
- Files that start directly with FSM content like `(+system ...)` or `(idle ...)` must still be wrapped in a supported source root:
  - accepted:
    - `(?fsm:my_module ...)`
    - `(?dt:my_dt_module ...)`
    - `(+fsm my_module)` followed by sibling FSM content
  - rejected:
    - a file whose first top-level form is `(+system ...)`
    - a file whose first top-level form is `(idle ...)`
- Tagged source-root names are now accepted or rejected as a whole:
  - accepted: `?fsm:ctrl_unit`, `?dt:route_block`, `?mod:route_block`, `?module:route_block`, `?top:packet_bridge`
  - rejected: `?fsm:bad-name`, `?dt:bad-name`, `?mod:bad-name`, `?module:bad-name`, `?top:bad-name`
  - malformed tagged names no longer truncate silently to a valid prefix.
- Structured `?fsm:name` roots must also carry a real top-level item list:
  - accepted:
    - `(?fsm:ctrl_unit (+system ...) (idle ...))`
  - rejected:
    - `(?fsm:empty_root)`
    - `(?fsm:scalar_root BROKEN)`
    - any structured `?fsm:name` root whose top-level body items are not list forms
- Structured `?dt:name` roots must also carry a real top-level item list:
  - accepted:
    - `(?dt:route_block (+size ...) (-drive ...))`
  - rejected:
    - `(?dt:empty_dt_root)`
    - `(?dt:scalar_dt_root BROKEN)`
    - any structured `?dt:name` root whose top-level body items are not list forms
- Legacy `+fsm` roots must carry a real body too:
  - accepted:
    - `(+fsm my_module)` followed by sibling FSM content
    - `(+fsm my_module (+system ...) (idle ...))`
  - rejected:
    - `(+fsm my_module)` with no sibling or nested body content at all
    - `(+fsm my_module BROKEN)`
    - any legacy `+fsm` root whose body items are not list forms

### Strict mode (current first slice)
- The CLI now accepts `--strict`, and the public pipeline facade now accepts `strict_mode => 1`.
- The current first strict-mode slice is intentionally narrow:
  - strict mode rejects the legacy `+fsm` root family,
  - strict mode also rejects the legacy `+fsm` root family when it is used specifically as a `?fsmc` child root and requires canonical `?fsm:` there,
  - strict mode also rejects `?mod:` / `?module:` when they are used specifically as `?dtc` child roots and requires canonical `?dt:` there,
  - strict mode also rejects the long direct-root alias `?module:` and requires canonical `?mod:` for module/entity-architecture roots,
  - strict mode also rejects the legacy empty `(+size)` no-op section and requires either explicit width entries or no `+size` section at all,
  - strict mode also rejects legacy or misleading reset spellings such as `(+system (clock clk) (asreset rstn))` and `(+system (clock clk) (sreset rstn))`; use `(+system (clock clk) (sreset reset))` for synchronous active-high reset or `(+system (clock clk) (areset rst_n))` for asynchronous active-low reset,
  - strict mode also rejects the legacy compact top-level `(:= signal=value)` directive on the current `?fsm:` / `?dt:` direct-root path and under generated-child realization; use canonical `(:= (signal value))` instead,
  - strict mode also rejects infix assignment compatibility forms such as `(OUT = IN)` and `(Q <- D)`; use canonical assignment pairs such as `(= (OUT IN))` and `(<- (Q D))` instead,
  - requires the modern explicit `?fsm:module_name` root form for FSM sources,
  - and otherwise leaves the currently accepted `?dt:`, `?mod:`, and `?top:` roots unchanged while their broader contracts continue to settle.
- In practice:
  - default mode still accepts `?fsm:name`, legacy `+fsm`, `?dt:name`, `?mod:name`, and `?module:name`,
  - strict mode currently accepts `?fsm:name`, `?dt:name`, `?mod:name`, and `?top:name`,
  - strict mode currently accepts only canonical `?fsm:name` roots under `?fsmc`,
  - strict mode currently accepts only canonical `?dt:name` roots under `?dtc`,
  - the maintained regression corpus now runs every `supported_smoke` entry through default pipeline/CLI, enforces that each coverage bucket belongs to its intended classification, marks every supported protocol fixture and every supported direct language-feature fixture as `strict_supported`, requires every supported direct language-feature entry to carry explicit HDL-shape pattern metadata, and requires expected-failure entries to carry stable diagnostic codes plus compiled diagnostic metadata, so the APB/AMBA protocol smoke fixtures plus canonical reset, canonical init/default, partial LHS writes, RHS concat/cat packing, LHS concat/cat deconstruction, expression-backed widths, runtime div/mod expressions, and canonical assignment pairs are checked through both `strict_mode => 1` and `bin/fsmgen --strict`; the catalog-level supported-behavior test runs every supported and strict-supported entry regardless of fixture family,
  - and strict mode currently rejects legacy `+fsm` under `?fsmc`, `?mod:` / `?module:` under `?dtc`, direct-root `?module:`, empty `(+size)` no-op sections, legacy/misleading explicit reset spellings such as `(+system ... (asreset rstn))` and `(+system ... (sreset rstn))`, compact top-level `(:= signal=value)` directives on the current `?fsm:` / `?dt:` direct-root path, and infix assignment compatibility forms.
- Strict-mode failures now also keep the same `Source file: '...'` context line as other top-level pipeline failures.
- This is the first support-tier enforcement slice, not the final full strict-mode surface.

### Draft normative contract for current `?dt:name` roots
This is the current live contract for the first shipped reusable standalone-DT slice.

Implementation note:
- The live toolchain also currently accepts `?mod:name` and `?module:name` on the same direct single-module path.
- That shared path is an implementation convenience, not a declaration that `?mod` / `?module` mean the same thing as `?dt`.
- In the intended language model, `?dt` describes one decision tree, while `?mod` / `?module` are broader module/entity-architecture roots and may later grow different structure or instantiation rules.
- Strict mode now narrows that direct module-root alias family to canonical `?mod:name`; `?module:name` remains default-mode compatibility only.

Accepted shape:
```lisp
(?dt:route_block
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
  )
  (-route_data
    (DATA_OUT = DATA_IN)
  )
)
```

Current meaning:
- `?dt:name` is the active standalone-DT root, not an encoded FSM-state-machine root.
- `?dt:name` may contain any number of top-level general DT blocks such as `(-foo ...)`.
- `?dt:name` may mix combinational assignments such as `(P = RHS)` and sequential assignments such as `(Q <- RHS)` in the same module.
- Driven non-intermediate targets are exposed as module outputs by default.
- standalone-DT `?dt:name` roots do not synthesize `current_state` / `next_state`.

Current top-level boundary:
- Supported:
  - conventional `(+system (clock clk) (sreset reset))` for synchronous active-high reset
  - conventional `(+system (clock clk) (areset rst_n))` for asynchronous active-low reset
  - default-mode compatibility also accepts legacy `(asreset rstn)` and misleading `(sreset rstn)` forms, but strict mode rejects them
  - `(+size ...)`
  - `(+constants ...)`
  - `(+enums ...)`
  - `(+define ...)`
  - `(+params ...)`
  - canonical top-level `(:= (signal value))` directives
  - default-mode compact top-level `(:= signal=value)` compatibility directives
  - general DT blocks such as `(-foo ...)`
- Rejected explicitly:
  - regular FSM-state DT blocks such as `(idle ...)`
  - dedicated reset-state blocks such as `(-syncrst ...)`

System-port rule:
- explicit conventional `(+system ...)` inside a standalone-DT root exposes `clk` plus the authored reset signal, for example `reset` for `sreset` or `rst_n` for `areset`
- without explicit `(+system ...)`, purely combinational standalone-DT `?dt:name` roots expose no implicit `clk` / `rst_n`
- without explicit `(+system ...)`, if any sequential assignment appears in that standalone-DT `?dt:name` source, generation implicitly exposes `clk` / `rst_n`

Boundary note:
- The semantic split from `?fsm:name` is the control model, not “combinational-only” versus “sequential-capable”.
- Explicit conventional `(+system ...)` now gives reusable standalone-DT roots and `?dtc` composition children one deliberate way to align with an authored shared clock/reset contract when that interface stability matters.
- The current shipped standalone-DT slice is centered on `?dt:name`.
- The live implementation also currently accepts `?mod:name` and `?module:name` on the same direct-root machinery in default mode, but strict mode now narrows that alias family to canonical `?mod:name` while broader reusable-module interface questions remain future `R11` work.
- Direct standalone-DT generation and realized `?dtc` children now also surface stable block-enable metadata through `module_info`: `standalone_dt_count`, `standalone_dt_names`, `standalone_dt_enable_families`, and one grouped `standalone_dt_module_enable_family` summary.
- That same `module_info` surface now also reports grouped multi-drive target families for standalone-DT roots through `standalone_dt_multi_drive_target_count` and `standalone_dt_multi_drive_targets`.
- Composition tops that realize `?dtc` children now also aggregate those reusable standalone-DT exports through `composition_standalone_dt_child_count`, `composition_standalone_dt_block_count`, `composition_standalone_dt_multi_drive_target_count`, and `composition_standalone_dt_children`.
- That same `composition_standalone_dt_children` export surface now also preserves each realized child's forward `intent_hir` and `lowered_rtl_ir` summaries, so embedders can consume one top-level reusable-child export instead of rewalking the child plan internals for those layers.
- That same reusable standalone-DT child export now also lives inside composition-top `intent_hir`, and the compatible top-level `module_info` surface mirrors it back out from that explicit semantic layer instead of treating it as a separate top-level side channel.
- That same narrower reusable standalone-DT child export path now also derives from the broader semantic `composition_children` layer instead of rebuilding `?dtc` child identity separately from plan instances, with standalone-DT names and enable families coming from child `intent_hir` and grouped multi-drive targets coming from child `lowered_rtl_ir`.
- Composition tops that realize generated children now also surface one broader generated-child export through `composition_generated_child_count`, `composition_generated_fsm_child_count`, `composition_generated_dt_child_count`, and `composition_generated_children`.
- That broader `composition_generated_children` surface covers both realized `?fsmc` and `?dtc` children and preserves each child's forward `intent_hir` and `lowered_rtl_ir` summaries together with stable kind/root/count metadata.
- That same broader generated-child export now also lives inside composition-top `intent_hir`, and the compatible top-level `module_info` surface mirrors it back out from that explicit semantic layer instead of treating it as a separate ad hoc side channel.
- Those compatible `module_info` summary mirrors are separate mutable result containers from the embedded `module_info.intent_hir` payload: they start equivalent for embedding convenience, but annotation of `module_info.signal_analysis`, `module_info.composition_children`, or `module_info.composition_generated_children` must not rewrite the embedded intent-HIR mirrors, and annotation of the embedded mirrors must not rewrite the summaries.
- The compatible lowered summary mirrors follow the same owned-container rule: `module_info.internal_net_names` and `module_info.instance_names` start equivalent to the embedded `module_info.lowered_rtl_ir` lists, but mutation of either side must not rewrite the other.
- That same narrower generated-child export path now also derives from the broader semantic `composition_children` layer instead of rebuilding generated-child identity separately from plan instances.
- Composition tops themselves now also surface top-level forward IR summaries through direct-result `intent_hir` and `lowered_rtl_ir`, and `module_info` mirrors those same serialized layers with bounded top-port, child-count, lane, internal-net, instance, auxiliary-assignment, and shared-datapath-candidate summaries.
- Composition tops now also surface a first bounded `structural_rtl_ir` through direct results and mirrored `module_info`, carrying one AST/netlist-like connectivity view over explicit top ports, internal nets, realized instances, pin bindings, and auxiliary assignments; the active composition-top emitter now walks that structural layer for top-module rendering instead of re-reading the plan directly.
- That same composition-top `lowered_rtl_ir` layer now consumes `structural_rtl_ir` for internal-net names, realized-instance names, and auxiliary-assignment counts, so the bounded lowered summary no longer rebuilds that connectivity slice directly from plan internals.
- Composition-top `module_info` and `statistics` now also consume `structural_rtl_ir` for child, top-port, and internal-net counts, so that bounded top-level accounting no longer rereads those fields directly from plan internals either.
- That same top-level bookkeeping now also consumes the explicit IRs for the remaining mirrored fields: `module_info` now derives internal-net names/counts, instance names/counts, auxiliary-assignment count, and composition lane from `lowered_rtl_ir` / `intent_hir`, and `statistics` now derives composition lane and shared-datapath candidate count from `intent_hir` / `lowered_rtl_ir`.
- Compatible `module_info` lowered-summary mirrors such as `internal_net_names` and `instance_names` are separate mutable result containers from the embedded `module_info.lowered_rtl_ir` payload even though they start equivalent at return time.
- That same composition provenance/report surface now also consumes `structural_rtl_ir` for top-port metadata and resolved-link endpoint lookup, so those bounded boundary/interface details are no longer reread directly from plan internals there either.
- That same composition override/block reporting surface now also consumes `structural_rtl_ir` for top-port and child-interface metadata, so those bounded same-name/interface-family details are no longer reread directly from plan internals there either.
- That same composition-top `intent_hir` layer now also consumes `structural_rtl_ir` for top-port names, counts, and grouped input/output signal-analysis families, and the compatible top-level `module_info` signal metadata now mirrors that same structural top-port boundary instead of rebuilding it separately from plan internals.
- That same composition-top `structural_rtl_ir` layer now also preserves explicit resolved links as first-class connectivity entries beside ports, nets, instances, and pin bindings. The provenance/reporting path now derives resolved-link identity/origin metadata from that structural layer, and compatible top-level resolved-link counts stay aligned with it too.
- Structural composition instance bindings now also preserve typed `connection_expr` nodes, currently bounded to backend-neutral `signal_ref`, source-side top-port bit/slice forms, source-side child-output bit/slice forms, bounded concat and repeat forms over those source-side operands, and the first shipped explicit-toplink actual-source forms through `open` and bit-vector literals, so the active top emitter can walk an explicit actual-connection shape instead of relying only on mirrored binding strings.
- That same structural binding surface now also preserves `connection_type_name` plus canonical `connection_type_spec` whenever one typed source contract is known at planning time: plain typed signal bindings keep their declared alias/type contract, top/child source expressions keep their inferred scalar/list aggregate contract, and whole aggregate actual roots keep their inferred aggregate contract instead of flattening those bindings back to width-only metadata.
- The same composition path now also preserves those typed nodes earlier on realized plan instances, so `structural_rtl_ir` carries them through instead of inventing them only at serialization time.
- That earlier binding normalization now also lives on the runtime `FSM::Composition::RealizedInstance` carrier itself, so `signal_name` / `connection_expr` alignment is now part of the plan-side child-binding contract.
- That same `structural_rtl_ir` layer now also preserves declared explicit-toplink connectivity separately through `declared_links`, so the structural layer now carries both declared and resolved top/child wiring intent instead of only the post-resolution side.
- That same override/block reporting surface now also takes its resolved connectivity from `structural_rtl_ir->{resolved_links}`: explicit-toplink override examples, inferred internal-carrier re-export overrides, and kept-internal carrier family detection no longer reread resolved links directly from plan internals.
- That same block-reporting surface now also takes explicit child-link blocking intent from `structural_rtl_ir->{declared_links}` instead of rereading declared toplinks directly from plan internals.
- That same structural binding path now also carries source-side top-port `name[index]` / `name[msb:lsb]` explicit-toplink sources, source-side child-output `instance.port[index]` / `instance.port[msb:lsb]` sources, bounded repeat groups, and bounded flat concat source forms over top-port, child-output, and shipped literal operands directly into realized child inputs and declared top outputs, and blocked range/operand failures now keep `Top expression '...'` or `Child expression '...'` context in the non-quiet failure summary instead of leaving the expression only in raw exception text.
- The current bounded `signal_ref` / `concat` / `open` / bit-vector-literal construction, binding signal-name recovery, and backend-neutral text rendering for structural actual-connection nodes now also live in dedicated `FSM::IR::StructuralRTLIR::ConnectionExpr` helpers, so that first connection-expression contract is no longer split across pipeline-only helper subs.
- Explicit-toplink actual sources and source-side top expressions now also use that same structural path directly, so `=open`, `=0`, `=1`, exact-width `=N'b...`, `=N'd...`, `=N'o...`, `=N'h...`, bounded repeat groups, and bounded concat child-input or top-output bindings no longer need fake carrier nets or fake undeclared top ports just to reach the emitter.
- Direct generated `?fsm` / `?dt` roots now also surface a bounded `structural_rtl_ir` module-interface slice, and realized generated-child export surfaces preserve that same structural boundary summary beside `intent_hir` and `lowered_rtl_ir`.
- That same composition provenance surface now also preserves per-resolved-link endpoint context plus one example subject per top-port and resolved-link provenance kind; when a provenance example touches a realized generated child endpoint, the example now carries bounded forward child context derived from that child's `intent_hir` and `lowered_rtl_ir`.
- That same composition reporting surface now also preserves structured top-port / child-endpoint context for convention overrides and convention blocks; when those events touch realized generated child endpoints, the carried endpoint context includes bounded forward child summaries from `intent_hir` and `lowered_rtl_ir`, and non-quiet `bin/fsmgen` now prints richer link/endpoint examples instead of plain count-plus-name examples in those sections.
- Composition tops now also preserve one broader `composition_child_count` / `composition_children` semantic export across all realized child kinds (`?fsmc`, `?dtc`, and `?rtl`) inside top-level `intent_hir`, and the compatible top-level `module_info` surface mirrors that same unified child export back out for embedding/reporting use.
- That unified `composition_children` surface preserves each child's stable identity (`kind`, `instance_name`, `module_name`, `source_name`, `source_root_kind`) together with that child's forward `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries when those layers exist.
- That same unified `composition_children` export now derives child identity and order from `structural_rtl_ir->{instances}` instead of rereading realized child identity directly from plan instances, and the sibling generated-child / reusable standalone-DT export builders reuse that same computed child surface in the top-generation path.
- The same composition provenance / override / block endpoint helpers now also consume that unified `composition_children` semantic surface instead of rediscovering realized child identity only from plan instances.
- Non-quiet `bin/fsmgen` composition runs now print one concise reusable standalone-DT child summary section built from that aggregated top-level export metadata.
- Non-quiet `bin/fsmgen` composition runs now also print one concise generated-child summary section built from that broader export surface.
- Those grouped standalone-DT multi-drive target families now also surface onehot0-style assertion metadata over the DT-specific driver-enable signals, and SystemVerilog direct `?dt` roots plus realized `?dtc` children now emit bounded non-synthesis guard assertions from that metadata while Verilog keeps those assertions disabled.
- Composition tops with multiple `?fsmc` children now also surface first shared-datapath candidate metadata through `composition_shared_datapath_candidate_count` and `composition_shared_datapath_candidates`, grouping same-name child output families that agree on width and interface type.
- When those same-name shared-datapath contributors also preserve declared type identity from named aliases, candidate discovery now stays conservative: one family only forms when the typed contributor evidence remains compatible, and width-equal but declared-type-incompatible child output families no longer collapse into one shared-datapath candidate just because the signal names still match.
- Generated roots and realized generated children now also surface `output_drive_family_count` and `output_drive_families` in `module_info`, so embedders can see how each output family is driven without scraping emitted HDL.
- Realized `?fsmc` children now also preserve hidden shared-datapath source-export metadata for per-value enable families used only inside generated composition tops.
- Those shared-datapath candidates now also preserve each contributor's exact selected `output_drive_family` from that child `lowered_rtl_ir`, and the existing bounded per-contributor `drive_intent` summary is now derived from that extracted family instead of being the only contributor-local drive surface. Non-quiet `bin/fsmgen` runs keep printing the same concise per-child drive-intent line under each candidate.
- Those shared-datapath candidate contributors now also preserve each realized child's forward `intent_hir` and `lowered_rtl_ir` summaries together with stable generated-child identity (`kind`, `source_name`), so embedders can consume one self-contained candidate surface without cross-referencing separate child exports.
- That same shared-datapath candidate surface now also preserves declared type identity on uniform typed contributor families plus each typed contributor entry itself, and the private raw contributor nets synthesized during shared-datapath lifting now preserve that contributor-side declared type identity in the structural export instead of flattening those new carriers back to width-only metadata.
- That same shared-datapath candidate-discovery path now also consumes `structural_rtl_ir` for top-output / child-interface connectivity plus the unified `composition_children` semantic export for child identity and lowered contributor context, instead of rereading those bounded families directly from plan instances.
- Non-quiet `bin/fsmgen` runs now also print one concise contributor-context line from that forward child IR surface before the per-child drive-intent details.
- Those shared-datapath candidates now also surface one deterministic whole-target aggregate enable plus per-value aggregate enable families built from the child-local `P_Q_en` families, and non-quiet `bin/fsmgen` runs print those planned aggregate enable names too.
- Generated composition tops now also synthesize the first actual shared-datapath helper HDL from that surface: hidden child source-enable export bindings, per-value aggregate-enable wires, per-value conflict wires, a whole-target aggregate-enable wire, and a whole-target multi-value conflict wire.
- Those shared-datapath candidates now also surface deterministic per-child source-enable aliases plus onehot0-style assertion metadata over those aliases and the aggregate value-enable families, and non-quiet `bin/fsmgen` runs print those planned assertion inputs too.
- SystemVerilog composition tops now also emit bounded non-synthesis shared-datapath guard assertions from that metadata: same-value onehot0 conflicts and whole-target multi-value conflicts become immediate `assert` checks in the generated top, while Verilog targets keep that assertion emission disabled.
- Those shared-datapath candidates now also surface first lifted-ownership planning metadata: storage class, peer-read input endpoints, default lifted visibility, planned top re-exports for internalized registered families, and a bounded loopback-allowed flag.
- Those shared-datapath candidates now also surface explicit peer-read policy metadata for bounded combinational peer-read cases, distinguishing public-preserving top-output-only families from internal-only top-local carrier families, and non-quiet `bin/fsmgen` runs now surface the matching bounded constraint instead of making such families look loopback-eligible.
- That same non-quiet shared-datapath summary now also renders peer-read binding text from the typed structural `bound_connection_expr` surface instead of printing only endpoint names, so lines such as `consumer.status_bus <= left_status` stay aligned with the extracted structural AST.
- That same non-quiet shared-datapath summary now also renders contributor binding text from the typed structural `bound_connection_expr` surface in the main candidate line, so lines such as `left.status_bus <= left_status` stay visible even before the indented detail section.
- Lifted shared-datapath runtime carriers such as `status_bus_shared_q`, `status_bus_shared_next`, and `status_bus_shared_comb` now also exist in the structural net surface instead of only as declarations hidden inside auxiliary HDL text, and uniform typed shared families now carry their declared type contract onto those lifted runtime nets too.
- The bounded combinational peer-read public-preserving case now also has real emitted behavior: generated tops synthesize one shared top-facing combinational carrier from the aggregate value-enable families, preserve the public top outputs from that carrier, rebind peer-read child inputs to it, and move contributor outputs onto private raw nets instead of leaving each public output bound directly to one child.
- The sibling bounded combinational peer-read internal-only case now also has real emitted behavior: generated tops synthesize one shared top-local combinational carrier from the aggregate value-enable families, rebind peer-read child inputs to it, keep contributor outputs on private raw nets, and avoid inventing public top re-export assignments when no such outputs exist.
- Combinational shared-datapath families with multiple preserved public top outputs and no peer-read child inputs now also realize a bounded public-fanout runtime: generated tops synthesize one shared top-facing combinational carrier from the aggregate value-enable families, rebind contributor outputs to private raw nets, and fan that lifted carrier back out to the preserved public top outputs instead of keeping duplicate child-owned public carriers.
- Registered peer-read shared-datapath families with preserved public outputs now also realize the first actual lifted runtime behavior: generated tops synthesize one shared top-level register from the aggregate value-enable families, rebind peer-read child inputs to that lifted register, and re-export the kept public outputs from that shared register instead of driving them directly from one child. That now includes mixed-boundary families where one contributor still preserves a public top output while sibling contributors in the same shared family are only consumed internally.
- The sibling registered peer-read internal-only case now also realizes that lifted runtime behavior: generated tops synthesize the same shared top-level register and rebind peer-read child inputs to it, but keep the lifted carrier internal when no public status outputs are being preserved.
- Registered shared-datapath families with multiple preserved public top outputs and no peer-read child inputs now also realize a bounded public-fanout runtime: generated tops synthesize one shared top-level register from the aggregate value-enable families, rebind contributor outputs to private raw nets, and fan that lifted register back out to the preserved public top outputs instead of keeping duplicate child-owned public carriers.

### Draft normative contract for the conventional `+system` section
This is the current `R8` draft normative contract for the active `+system` boundary.

Accepted form:
```lisp
(+system
  (clock clk)
  (sreset reset)
)
```

Also accepted and canonical for asynchronous active-low reset:
```lisp
(+system
  (clock clk)
  (areset rst_n)
)
```

Current meaning:
- If `+system` is present, the active contract currently treats it as a declarative confirmation of the shared system-input pair:
  - `clk`
  - the authored reset signal
- `(sreset reset)` means synchronous active-high reset; generated SystemVerilog uses `always_ff @(posedge clk)` plus `if (reset)`.
- `(areset rst_n)` means asynchronous active-low reset; generated SystemVerilog uses `always_ff @(posedge clk or negedge rst_n)` plus `if (!rst_n)`.
- If `+system` is absent, the active generator now falls back to one implicit system contract:
  - clock `clk`
  - asynchronous active-low reset `rst_n`
- The parser now validates that exact boundary explicitly instead of silently ignoring richer legacy `+system` content.
- The parser records:
  - default clock domain `clk`,
  - default reset domain using the authored reset name,
  - typed system signals for the authored clock/reset names,
  - reset kind (`sync` or `async`),
  - and reset active level (`1` for `sreset`, `0` for `areset` / legacy `asreset`).
- Strict mode narrows the explicit reset spelling further:
  - default mode still accepts `(asreset rstn)` as legacy async active-low compatibility residue,
  - default mode still accepts misleading `(sreset rstn)` compatibility residue but treats it as synchronous active-high because the keyword says `sreset`,
  - strict mode rejects `(asreset rstn)` and asks for canonical `(areset rst_n)`,
  - and strict mode rejects `(sreset rstn)` because an active-low-looking name is misleading for synchronous active-high reset.

Current boundary:
- Supported:
  - exactly one `(clock clk)`
  - exactly one reset declaration via:
    - `(sreset reset)` or another HDL-identifier-compatible active-high-looking reset name
    - `(areset rst_n)` or another HDL-identifier-compatible active-low-looking reset name
    - `(asreset rstn)` in default mode only as a legacy alias for async active-low reset
- Rejected explicitly:
  - malformed entry structures such as `BROKEN` or `(clock clk extra)` inside `(+system ...)`
  - alternative clock names such as `(clock core_clk)`
  - malformed reset identifiers such as `(sreset reset-name)` or `(areset rst-n)`
  - duplicate clock entries such as two `(clock clk)` declarations
  - duplicate reset declarations, including mixed `(sreset reset)` plus `(areset rst_n)`
  - incomplete `+system` sections

Regression-backed example:
```lisp
(?fsm:system_contract
  (+system
    (clock clk)
    (sreset reset)
  )
  (-dt
    (A = B)
  )
)
```

Boundary note:
- This slice makes the conventional shared-system declaration explicit and regression-backed.
- It now treats reset kind and polarity as semantic metadata instead of deriving behavior from the signal name alone.
- The accepted explicit `(sreset rstn)` spelling is default-mode compatibility residue from the shipped tree, not a polarity-aware naming recommendation.
- Strict mode now treats `(asreset rstn)` and `(sreset rstn)` as compatibility residue and narrows the explicit `+system` reset spelling to `(sreset reset)` for synchronous active-high reset or `(areset rst_n)` for asynchronous active-low reset.
- The forward/default async-reset convention remains `rst_n`, including the implicit no-`+system` path.
- The active generator now also has one explicit implicit-default rule:
  - if no `+system` section is present at all, generation uses `clk` plus asynchronous active-low `rst_n`.

### Draft normative contract for the `:=` init/reset directive
This is the current `R8` draft normative contract for the active top-level init/reset boundary.

Canonical supported form:
```lisp
(:= (tester_reset 1))
(:= (hs_sync_sequence 8'h1d))
(:=
  (tester_reset 1)
  (mode 2'b10)
)
(:= (mode_reset (+ RESET_BASE mode.IDLE)))
(:= (lane_reset (and RESET_MASK DEFAULT_MASK)))
```

Accepted default-mode compatibility form:
```lisp
(:= tester_reset=1)
(:= hs_sync_sequence=8'h1d)
```

Current meaning:
- `:=` is a top-level directive, not a state and not a DT action.
- The canonical supported payload is one or more Lisp-ish pairs `(signal value)`.
- `value` is an expression slot, not only a scalar token: it may be a literal, a named constant/enum/param, an aggregate scalar leaf, or a nested Lisp-ish arithmetic/bitwise expression using the same active expression surface where the referenced symbols resolve before generation.
- The legacy compact single-token form `signal=value` remains accepted in default mode as compatibility residue.
- The directive records explicit reset/default metadata for `signal`.
- The active shipped examples use scalar RHS values such as:
  - `1`
  - `6'0`
  - `8'h1d`
  - `64'x0123456789abcdef`

Current boundary:
- Supported:
  - `(:= (signal literal_or_constant_expr))` at top level inside `(?fsm:name ...)` or `(?dt:name ...)`
  - `(:= (signal literal_or_scalar_expr) (other value))` for multiple canonical entries in one directive
  - `(:= signal=literal_or_scalar_expr)` in default mode only as compatibility residue
- Rejected explicitly:
  - malformed non-scalar payload shapes such as `(:= (tester_reset=1 extra))`
  - malformed payloads such as `(:= BROKEN)`
  - unsupported RHS reset/default values such as `(:= tester_reset=[DATAIN])` or `(:= tester_reset=<start)`
  - unsupported top-level bare alternatives such as `(tester_reset := 1)`
  - malformed DT actions such as `(BROKEN)`
  - empty guarded blocks such as `(<req)`

Boundary note:
- The Lisp-ish pair form `(:= (signal value))` is now the canonical strict-mode surface.
- The legacy compact `:=` form is explicit and regression-backed as default-mode compatibility residue instead of accidental parser behavior.
- Malformed `:=` payload shapes and malformed compact directives are now regression-backed across parser, pipeline, and CLI too.
- Default mode still accepts the compact `:=` form as compatibility residue.
- Strict mode now rejects the compact `:=` form on the current `?fsm:` / `?dt:` direct-root path and points to canonical `(:= (signal value))`.
- Strict mode now also rejects infix assignment compatibility forms such as `(OUT = IN)` and points to canonical assignment pairs such as `(= (OUT IN))`.
- The bare infix alternative `(lhs := value)` remains unsupported.

## 3) Basic usage
From repository root:
```bash
./bin/fsmgen [options] <fsm_file>
```

Examples:
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --language verilog --output /tmp/trial_0.v fsm/trial_0.fsm
./bin/fsmgen --capability-manifest
```

Current narrow composition example:
```lisp
(?top:single_child_top
  (?fsmc:child_ctrl child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
```

This currently works because:
- the child FSM may be embedded in the same file or resolved from a sibling/searchable external `.fsm` source,
- the child exposes `output_data` explicitly as an output,
- and in the bounded `C1` lane the top interface may now be inferred directly from that lone realized child when `?ports` is omitted.

Current narrow standalone-DT child example:
```lisp
(?top:comb_dt_child_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)

(?dt:route_src
  (-route
    (result_data> = data_in)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
)
```

This currently works because:
- the child is a standalone `?dt:name` module source,
- the combinational DT child exposes only its real user-facing ports,
- and the explicit top `?ports` block matches that realized child interface exactly.

Current narrow multi-child example:
```lisp
(?top:two_child_top
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
  )
)
```

This currently works because:
- every generated child resolves to one active `?fsm:name` or `?dt:name` source, either embedded or external,
- `clk` and `rst_n` use the shared system-input contract,
- non-system connections are expressed explicitly through `?toplink`,
- `?ports` may now be omitted or empty in explicit-link `C2` / `C3` when explicit `?toplink` endpoints themselves still imply the missing top ports honestly, including renamed top-boundary names,
- source-side top expressions such as `payload_bus[15:8]` and `status_bus[0]` may now also participate in that omitted/empty-`?ports` inference, including inferable bit/slice operands inside a bounded comma-separated concat source, with the inferred base-port width coming from the highest referenced bit,
- when those bounded concat sources also include child-output operands such as `producer.payload[7:4]`, omitted/empty-`?ports` inference still derives only the real undeclared top operands from that mixed source instead of treating child-output operands as inferred top-boundary evidence,
- undeclared top-facing child inputs may now be inferred when the child-side evidence is unambiguous and those inputs are not already consumed by explicit child-to-child links,
- when those same-name child inputs preserved `declared_type_name` / `declared_type_spec` from named aliases, undeclared top-input inference now also requires one compatible declared type contract and preserves that declared type on the inferred top port,
- undeclared unique top-facing child outputs may now also be inferred when they are not already consumed by explicit child-to-child links,
- plain explicit top inputs may now also reuse that same-name convention when compatible child inputs keep one direction plus exact width/type agreement plus any preserved declared type contract,
- plain explicit top outputs may now also reuse that same-name convention when one unique same-name child output remains top-facing and any preserved declared type contract stays compatible,
- undeclared same-name internal child-to-child carriers may now be inferred when one unique child output and one or more child inputs share the same name and no explicit link already touches that name family,
- those inferred same-name carriers stay internal by default, but an explicit same-name top output may adopt and re-export one of them when width/type metadata and any preserved declared type contract still match,
- explicit-link tops may now also route one declared top input directly to one or more declared top outputs through explicit top-output assignments while sibling child-input consumers reuse that same top input without an invented helper carrier,
- explicit link widths and endpoint roles must match exactly,
- source-side top expressions and child expressions that target typed aggregate ports must now also keep one compatible aggregate contract instead of relying only on equal packed width,
- and plain port-to-port explicit links now also require one compatible declared type contract when both endpoints were declared through named type aliases.

Current narrow plain-explicit-port convention example:
```lisp
(?top:plain_port_convention_top
  (?ports:public_io
    payload_in<8
    result_data>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /producer.mid/consumer.mid/
  )
)
```

This currently works because:
- `payload_in<8` is an ordinary explicit top input, not `=payload_in<8`,
- `result_data>8` is an ordinary explicit top output, not `=result_data>8`,
- explicit-link `C2` / `C3` may now still reuse the same-name convention for those plain explicit ports when the child-side evidence is exact,
- top-input convention still requires compatible child inputs only, with exact width/type agreement,
- top-output convention still requires one unique same-name top-facing child output,
- and any explicit top-boundary `?toplink` touching that port still overrides the convention locally.

Current narrow structural-actual explicit-link example:
```lisp
(?top:uart_defaults_top
  (?ports:public_io
    core_clk
    rst_async_n
    default_data>8
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=8'b10100101/default_data/
    /=8'b10100101/uart_tx.data_in/
    /=open/uart_tx.enable/
    /uart_tx.serial_out/serial_out/
  )
)
```

This currently works because:
- `=8'b10100101`, `=8'sb10100101`, `=8'd165`, `=8'sd-1`, `=8'o245`, `=8'so245`, `=8'hA5`, or `=8'shA5` is a bounded exact-width literal actual source, not a top port,
- underscore-separated digit spellings such as `=8'b1010_0101`, `=8'd1_65`, `=8'o2_45`, `=8'hA_5`, `=1_70`, and `=A_5` are accepted on those same direct actual forms,
- `=open` is a bounded open actual source that leaves the child formal intentionally unconnected,
- scalar `=0` and `=1` direct actuals plus unsized binary/decimal/octal/hex direct actuals such as `=0b10100101`, `='b10100101`, `=0d170`, `='d170`, `=0o245`, `='o245`, `=0xA5`, `='hA5`, `=170`, and `=A5` may now target either a realized child input port or a declared top output by widening to that direct binding target width as numeric values,
- unsized signed decimal direct actuals such as `=-1`, `=0d-1`, and `='sd-1` plus unsized signed binary/octal/hex direct actuals such as `='sb1010`, `='so645`, and `='shA5` may now target those same direct bindings when the signed value fits the signed range of the direct target width,
- fixed-width binary/decimal/signed-decimal/octal/hex literal actuals in unsigned or signed form may now target either a realized child input port or a declared top output,
- `=open` still targets only realized child input ports,
- binary/octal/hex literal actuals, whether unsigned or signed, must still match the target child-input or top-output width exactly, decimal literal actuals must still match the target child-input or top-output width exactly as numeric values, and signed decimal literals must also fit the signed range of their declared width,
- unsized binary/decimal/octal/hex direct actuals fail explicitly if the numeric value does not fit that direct binding target width, and unsized signed decimal direct actuals plus unsized signed binary/octal/hex direct actuals fail explicitly if the signed value does not fit the signed range of that direct binding target width,
- whole aggregate direct actuals such as `=FRAME` still lower through one packed literal, but when the direct target preserved an aggregate type alias such as `frame_t` or `header_t`, that whole-aggregate shape must now also match the target aggregate contract instead of relying only on packed width,
- obviously bitstring-like bare `0/1` actuals such as `=00001110` or `=10000000` are rejected on both direct-actual and concat-operand lanes instead of being guessed,
- and `=0` / `=1` stay one-bit operands inside bounded concat source expressions, intrinsic-width unsized binary/octal/hex operands such as `=0b10`, `='b10`, `=0o7`, `='o7`, `=0xA5`, `='hA5`, or `=A5` keep the width implied by their digits there, unsized decimal forms such as `=170`, `=0d170`, or `='d170` now also keep the minimum width implied by their numeric value there, and negative decimal concat uses currently require an exact-width signed decimal literal such as `=8'sd-1`,
- and those actuals bind directly on the realized child port or the declared top output assignment instead of inventing a top port or synthetic carrier net.

Current narrow intent-sized composition actual example:
```lisp
(?top:composition_intent_integer_literals
  (?ports:public_io
    decimal_out>5
    negative_out>8
    packed_out>33
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=5'23/decimal_out/
    /=8'-0xA/negative_out/
    /=5'23,=8'-10,=20'x1/packed_out/
    /=5'23/uart_tx.decimal_in/
    /=8'-0b1010/uart_tx.negative_in/
    /=5'23,=8'-0xA,=20'x1/uart_tx.packed_in/
  )
)

(?rtlif:uart_tx
  decimal_in<5:data
  negative_in<8:data
  packed_in<33:data
)
```

This currently works because:
- `=5'23` lowers to one exact-width 5-bit literal payload,
- `=8'-0xA`, `=8'-10`, and `=8'-0b1010` lower through the same checked two's-complement path and reach emitted SV as `8'hF6`, `8'd246`, or `8'b11110110`,
- `=20'x1` is accepted as an intent-level radix alias and lowers to one legal exact-width hex payload,
- direct actuals such as `/=5'23/decimal_out/` and `/=8'-0xA/negative_out/` drive the declared top outputs directly instead of inventing helper nets,
- concat actuals such as `/=5'23,=8'-10,=20'x1/packed_out/` preserve each operand's declared width instead of borrowing from the 33-bit target,
- and the same spellings can drive realized child inputs through `/=.../uart_tx.port/` on that same typed structural path.

Maintained regression examples:
- [t/corpus/direct_intent_integer_literals.fsm](t/corpus/direct_intent_integer_literals.fsm)
- [t/corpus/composition_intent_integer_literals.fsm](t/corpus/composition_intent_integer_literals.fsm)

Current narrow typed whole-aggregate actual example:
```lisp
(?top:typed_actual_top
  (+constants
    (FRAME
      (mode 2'b10)
      (flag 1))
  )
  (+types
    (type frame_t (record (mode (bits 2)) (flag bit)))
  )
  (?ports:public_io
    packed_out>frame_t
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=FRAME/packed_out/
    /=0/uart_tx.enable/
  )
)

(?rtlif:uart_tx
  enable:data
)
```

This currently works because:
- `FRAME` is one bounded whole aggregate root whose leaves all lower to scalar literals,
- `frame_t` preserves one aggregate declared type contract on the declared top output,
- the authored aggregate shape matches that same `(record (mode (bits 2)) (flag bit))` contract,
- so direct whole-aggregate actual binding is allowed on that typed direct target,
- but a width-equal target declared as something incompatible like `(list bit (bits 2))` would now fail explicitly instead of slipping through on width alone.

Current narrow top-concat explicit-link example:
```lisp
(?top:uart_concat_top
  (?ports:public_io
    core_clk
    rst_async_n
    header_bus<2
    status_bus
    payload_bus<4
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,status_bus[0],=1,payload_bus[3:0]/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)
```

This currently works because:
- the `/source/target/` token still stays flat, but the source side may now be one bounded comma-separated concat expression,
- concat operands may currently be declared whole top-port refs, top-port bit/slice refs, declared aggregate top-port member/item refs such as `in_frame.tag` or `in_frame.payload[1]`, child-output operands, one-bit scalar actuals `=0` / `=1`, intrinsic-width unsized binary/decimal/octal/hex actuals such as `=0b10`, `='b10`, `=170`, `=0d170`, `='d170`, `=0o7`, `='o7`, `=0xA5`, `='hA5`, or `=A5`, intrinsic-width unsized signed decimal actuals such as `=-1`, `=0d-1`, or `='sd-1`, intrinsic-width unsized signed binary/octal/hex actuals such as `='sb1010`, `='so7`, or `='shA`, exact-width binary/decimal/signed-decimal/octal/hex literal actuals in unsigned or signed form, or bounded repeat groups such as `{3{status_bus[0]}}` or `{2{producer.serial_lo}}`,
- underscore-separated digit spellings are also accepted on those intrinsic-width unsized binary/decimal/octal/hex and exact-width concat literals, for example `=0b1_0`, `=1_70`, `=0d1_70`, `=0xA_5`, `=A_5`, `=2'b1_0`, or `=8'hA_5`,
- but obviously bitstring-like bare `0/1` literals such as `=00001110` or `=10000000` are rejected there as ambiguous; use `=0b...`, `=N'b...`, or `=0d...` explicitly,
- unsized decimal actuals such as `=170` or `=0d170` now also work inside bounded concat by taking the minimum width required by their numeric value instead of borrowing width from the child-input target,
- unsized signed decimal actuals such as `=-1`, `=0d-1`, or `='sd-1` now also work inside bounded concat by taking the minimum signed width required by their numeric value instead of borrowing width from the child-input target,
- repeat groups now lower through typed structural `repeat` expressions instead of raw renderer text, and repeated child-output operands reuse the same deterministic base carrier as their non-repeated siblings,
- that concat still stays source-side only,
- it still targets a realized child input port only,
- and the emitted child binding uses the direct HDL concat instead of inventing a synthetic carrier net.

Current narrow omitted-`?ports` top-expression inference example:
```lisp
(?top:uart_slice_top
  (?rtl:byte_sink)
  (?toplink:wiring
    /payload_bus[15:8]/byte_sink.data_in/
    /status_bus[0]/byte_sink.enable/
  )
)
```

This currently works because:
- omitted `?ports` may now infer `payload_bus` and `status_bus` directly from those explicit links,
- `payload_bus[15:8]` implies a base top-input width of at least 16,
- `status_bus[0]` implies a base top-input width of at least 1,
- the same inference path now also sees `name[index]` / `name[msb:lsb]` operands that appear inside a bounded comma-separated concat source,
- the same inference path now also sizes one undeclared repeated whole-port operand from a bounded repeat group such as `{2{payload_bus}}` when the child-input remainder width divides evenly across the repeat count,
- one remaining undeclared whole-port concat operand may now also pick up an exact width from the remaining child-input target width when the other concat operands are already exact,
- declared aggregate top-port member/item operands such as `in_frame.tag` also count as exact-width operands for that remainder calculation when `in_frame` already has a declared aggregate type, has been inferred as one aggregate contract from another whole-root explicit link in the same `?toplink` block, or can be seeded from an unlinked same-name child input with one uniform record/list declared-type contract,
- but several still-unsized undeclared whole-port concat operands still fail explicitly instead of guessing several widths from one child-input target,
- and uneven repeat-width splits such as `{2{payload_bus}}` into a 5-bit child input now also fail explicitly instead of guessing one per-copy width,
- top expressions still stay source-side only,
- and they may now target realized child input ports or declared top outputs.

Current narrow aggregate-path concat inference example:
```lisp
(?top:frame_sink_top
  (+types
    (type frame_t (record (tag (bits 4)) (flag bit)))
  )
  (?ports:public_io
    in_frame<frame_t
  )
  (?rtl:sink)
  (?toplink:wiring
    /in_frame.tag,payload/sink.data_in/
  )
)
```

Here `in_frame.tag` contributes its four-bit leaf width, so if `sink.data_in`
is eight bits the omitted whole top input `payload` is inferred as four bits.
The aggregate root may be declared explicitly, as shown above, or inferred from
another whole-root explicit link to a typed child input in the same `?toplink`
block. It may also be inferred from an unlinked same-name child input such as
`consumer.in_frame` when that child input already carries one uniform
record/list declared-type contract. If `in_frame` is neither declared nor
inferred as one aggregate contract, FSMGen now fails with an explicit
diagnostic asking for that root contract instead of trying to autovivify an
aggregate shape from `in_frame.tag` alone.

Current narrow declared connect-by-name example:
```lisp
(?top:single_by_name_top
  (?ports:public_io
    clk
    rst_n
    =enable<
    =output_data>8
  )
  (?fsmc:child child_src)
)
```

This currently works because:
- `=enable<` and `=output_data>8` declare that those top ports must be resolved by same-name matching rather than by explicit `?toplink` wiring,
- each declared top output has exactly one compatible child output,
- each declared top input has one or more compatible child inputs,
- compatibility means same name, same direction, same width, and when named type aliases preserved declared type identity, one compatible declared type contract too,
- ambiguous or missing matches fail explicitly.

Realistic `=name` patterns:

1. Expose one child FSM output directly at the top level without a second `?toplink`
```lisp
(?top:packet_formatter_top
  (?ports:public_io
    clk
    rst_n
    =frame_valid>
    =frame_data>32
  )
  (?fsmc:formatter formatter_src)
)
```

This is useful when:
- the child already exposes stable public outputs such as `frame_valid` and `frame_data`,
- and the top is mainly packaging that child rather than renaming or remapping those outputs.

2. Pass a top-level control input through to one child by the same name
```lisp
(?top:stream_gate_top
  (?ports:public_io
    clk
    rst_n
    =enable_stream
    gated_valid>
  )
  (?fsmc:gate gate_src)
  (?toplink:wiring
    /gate.gated_valid/gated_valid/
  )
)
```

This is useful when:
- the composition should expose a user/control input such as `enable_stream`,
- and exactly one child input of the same name should receive it.

3. Expose an external RTL output directly at the top level by the same name
```lisp
(?top:uart_bridge_top
  (?ports:public_io
    clk
    rst_n
    =txd>
  )
  (?rtl:uart_tx)
)
```

With sidecar interface metadata:
```lisp
(?rtlif:uart_tx
  clk
  rst_n
  data_in<8
  txd>
)
```

This is useful when:
- the external RTL module already uses the public top-level signal name you want,
- so the composition can expose `txd` without an extra explicit `/uart_tx.txd/txd/` link.

4. Mix declared top-port `=name` with explicit generated-child to external-RTL wiring
```lisp
(?top:router_uart_top
  (?ports:public_io
    clk
    rst_n
    =payload_in<8
    =txd>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /router.route_data/uart_tx.data_in/
  )
)
```

With sidecar interface metadata:
```lisp
(?rtlif:uart_tx
  clk
  rst_n
  data_in<8
  txd>
)
```

This is useful when:
- one top input should pass through to the generated child by the same name,
- one top output should be exposed directly from the external RTL child by the same name,
- and the child-to-child data path still needs one explicit `?toplink`.

Practical rules for `=name`:
- use it only when the top-level name should intentionally stay the same as the child endpoint name,
- use normal explicit `?toplink` when you need renaming, remapping, or multiple non-system connections,
- do not use `=clk`, `=rstn`, or `=rst_n`; those already use the dedicated shared system-input contract,
- use `reset`-style names for synchronous active-high resets and `rst_n`-style names for asynchronous active-low resets,
- a top-output match is valid only when exactly one child output has the same name and width.
- a top-input match is valid when one or more child inputs have the same name and width.
- if widths do not match, generation fails before emission and the diagnostic names both endpoints and their widths.

Current narrow mixed FSM + external RTL example:
```lisp
(?top:fsm_plus_rtl_top
  (?ports:public_io
    clk
    rst_n
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)
```

With sidecar interface metadata in `uart_tx.rtlif`:
```lisp
(?rtlif:uart_tx
  clk
  rst_n
  data_in<8
  txd>
)
```

This currently works because:
- the generated child is still compiled through the active pipeline whether it comes from `?fsm:name` or `?dt:name`,
- the generated child may be embedded or resolved from a sibling/searchable external `.fsm` source,
- the external RTL child is instantiated but not regenerated,
- composition loads the RTL interface from `uart_tx.rtlif` beside the source file, then through repeated `--path DIR` roots, then through the existing `FSMLIB` search roots,
- non-system mixed-child connections remain explicit through `?toplink`.

Current `.rtlif` token contract:
- metadata uses one `(?rtlif:module_name ...)` root with flat port tokens plus one optional semantic `(params (NAME default_value) ...)` declaration block
- when a composition source contains an embedded `(?rtlif:module_name ...)` companion root, that local declaration takes precedence over any sidecar `<module>.rtlif` file
- `(?rtl:module_name)` is shorthand for one external RTL instance whose instance name and module name are both `module_name`
- `(?rtl:instance_name module_name)` instantiates that external RTL module under a distinct instance name, so several `?rtl` children can reuse one `(?rtlif:module_name ...)` interface contract
- `(?rtl:instance_name (module module_name) (params (NAME value) ...))` is the semantic parameterized instance form; the same shorthand can omit `(module ...)` when the `?rtl` child name is already the module/interface name
- explicit links always refer to the realized instance name, for example `u_uart_a.data_in`, not the shared `?rtlif` root name
- declaration order is preserved
- `port`, `port<8`, and `port>` still work as the compact forms
- `port:data`, `port<8:data`, `core_clk:clock`, and `rst_async_n:reset` are also valid
- only `data`, `clock`, and `reset` are currently accepted as explicit port types
- typed `clock` / `reset` tokens are system-input roles; they let custom-named RTL system ports auto-wire without falling back to `clk` / `rst_n` naming, but output-direction forms such as `core_clk>:clock` or `rst_async_n>:reset` are rejected
- ordinary typed data outputs remain valid, for example `txd>:data`
- `.rtlif` parameter/generic defaults accept scalar integer literals such as `8`, `8'hA5`, `'hA5`, `0xA5`, `0b1010`, and `0o77`, bounded scalar operator expressions such as `(+ param_pkg.DEFAULT_WIDTH 1)` or `(+ param_pkg.DEFAULT_FRAME.flag 1)`, bounded aggregate expressions such as `(+ param_pkg.DEFAULT_LANES param_pkg.DEFAULT_LANE_INC)` or `(and param_pkg.DEFAULT_LANES param_pkg.DEFAULT_LANE_MASK)`, bounded literal list/record payloads such as `(8'hA5 8'h3C)` and `((mode 2'b10) (flag 1))`, and package-qualified symbols from packages imported by the consuming composition source, such as `param_pkg.DEFAULT_WIDTH`, `param_pkg.DEFAULT_LANES`, or `param_pkg.frame_mode.RUN`; unresolved default symbols abort before generation
- per-instance parameter/generic overrides must name parameters/generics declared by the loaded `.rtlif` `(params ...)` block; the shipped override value surface accepts the same scalar integer literals, bounded scalar operator expressions, bounded aggregate expressions, and bounded literal list/record payloads; override values may also reuse resolved composition-top or imported package symbols such as `WIDTH_VALUE`, `mode.BUSY`, `shared.RESET_VALUE`, aggregate roots like `shared.LANES`, or aggregate scalar leaves like `shared.FRAME.flag`; unresolved override symbols abort before generation; aggregate overrides must match the aggregate shape inferred from the `.rtlif` default value; validated overrides are preserved through the composition plan and structural RTL IR and lower to SystemVerilog `#(...)` instance parameters for the Verilog-family backend.
- generated `?fsmc` / `?dtc` child instances use the same semantic override surface with `(?fsmc:u_child child_src (params (NAME value) ...))` or `(?dtc:u_child child_src (params (NAME value) ...))`; named children may still omit the explicit source token and default to the child name; each override name must match a direct `(+params ...)` declaration in the realized child source; scalar overrides, including bounded scalar operator expressions, are width-flexible, aggregate overrides, including bounded aggregate expressions, must match the aggregate shape inferred from the child's parameter default, and valid values are preserved through the composition plan, Intent HIR, structural RTL IR, and current SystemVerilog `#(...)` generated-child instance emission.
- parameter/generic values on these RTL and generated-child surfaces may be scalar or aggregate; richer aggregate-to-aggregate operators beyond the shipped leafwise numeric/bitwise slice remain future typed work that must define which operators are valid for which aggregate types/shapes before HDL lowering.

Example parameterized external RTL instance:
```lisp
(?top:parameterized_rtl_top
  (+constants
    (OVERRIDE_WIDTH 16)
    (LOCAL_LANES (8'hA5 8'h3C))
  )
  (+enums
    (frame_mode
      (RUN 2'b10)
    )
  )
  (+import
    param_pkg
  )
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH OVERRIDE_WIDTH)
      (RESET_VALUE param_pkg.RESET_A5)
      (LANES LOCAL_LANES)
      (FRAME ((mode frame_mode.RUN) (flag param_pkg.FLAG_ON)))
    )
  )
  (?toplink:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH param_pkg.DEFAULT_WIDTH)
    (RESET_VALUE param_pkg.DEFAULT_RESET)
    (LANES param_pkg.DEFAULT_LANES)
    (FRAME param_pkg.DEFAULT_FRAME)
  )
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
  txd>:data
)

(?pkg:param_pkg
  (+constants
    (DEFAULT_WIDTH 8)
    (DEFAULT_RESET 8'h00)
    (DEFAULT_LANES (8'h00 8'h00))
    (DEFAULT_FRAME ((mode 2'b00) (flag 0)))
    (RESET_A5 8'hA5)
    (FLAG_ON 1)
  )
)
```

Example parameterized generated child:
```lisp
(?top:parameterized_generated_child_top
  (+constants
    (OVERRIDE_WIDTH 16)
    (TOP_LANES (8'hA5 8'h3C))
  )
  (?ports:public_io
    clk
    rstn
    payload_in<16
    payload_out>16
  )
  (?fsmc:u_child child_src
    (params
      (WIDTH OVERRIDE_WIDTH)
      (LANES TOP_LANES)
    )
  )
  (?toplink:wiring
    /payload_in/u_child.in_data/
    /u_child.out_data/payload_out/
  )
)

(?fsm:child_src
  (+params
    (WIDTH 8)
    (LANES (8'h00 8'h00))
  )
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (in_data 16)
    (out_data 16)
  )
  (-idle
    (out_data> = LANES <in_data=WIDTH)
  )
)
```

## 4) Useful options
- `-o, --output <file>` : output file path
- `-l, --language <systemverilog|sv|verilog|v|vhdl>` : target language
- `-d, --debug[=N]` : numeric trace compatibility level (`0..4`; bare `--debug` implies `4`)
- `--trace-verbosity <none|low|medium|high|debug>` : named trace verbosity selector
- `--trace-log[=FILE]` : route trace output to FILE (default: `trace.log`)
- `--trace-emojis` / `--notrace-emojis` : enable/disable emoji markers in trace formatting
- `--path <dir>` : add an explicit search root for bare `.fsm` names and related lookup (may be repeated)
- `--extension-module <Module::Name>` : load an explicit typed extension module from `@INC` (may be repeated)
- `--extension-config <file>` : load typed extension modules from an explicit config file (may be repeated)
- `--capability-manifest` : print schema-versioned JSON describing the current support/capability surface and exit without requiring an input `.fsm`
- `--check --json` : run the full pipeline as a check, emit schema-versioned JSON diagnostics, and do not write HDL
- `--emit-semantic-json` : run the full pipeline, emit bounded normalized semantic JSON, and do not write HDL
- `--verify-hdl` : after writing generated SystemVerilog, run Verilator lint and ABC-free Yosys structural synthesis
- `-q, --quiet` : suppress informational messages
- `-h, --help` : full CLI help

The capability manifest is the first machine-readable downstream-tool support
surface. It is generated from
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
and backed by
[perl/FSM/Support/RegressionCorpus.pm](perl/FSM/Support/RegressionCorpus.pm),
and
[perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm),
so support-accounting counts, strict-supported entries, compatibility residue,
expected-failure diagnostic codes, documentation pointers, and intentionally
blocked/not-yet-public surfaces share one source with the regression catalog.
It also advertises which bounded machine-readable surfaces have current
supported-corpus coverage, including check JSON and normalized semantic JSON.
Those two public JSON/report surfaces now also share one bounded nested-object
owner for their `support_accounting` match payloads:
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`producer` object owner for FSMGen identity plus the report builder owner:
[perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`source` object owner for the caller-facing input string and resolved source
path:
[perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`command` object owner for invocation metadata such as `mode`, `json`,
`strict_mode`, and `target_language`:
[perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`generated_output` object owner for whether the report invocation emitted HDL
artifacts:
[perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm).
Successful public check JSON reports now also have one bounded nested `result`
object owner for module identity plus basic summary counts:
[perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm).
Failed public check JSON reports now also have one bounded nested `diagnostic`
object owner for the core stable diagnostic fields, matched-only corpus keys,
optional extracted artifact paths, and nested support-accounting metadata:
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm).
Failed public normalized semantic JSON reports now explicitly reuse that same
bounded nested `diagnostic` owner too.
Successful public normalized semantic JSON reports now also have one bounded
nested `semantic` object owner for module/system metadata, signal analysis,
and the forward-IR projection:
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm).
The nested `semantic.system_contract` summary inside that payload now also has
its own bounded owner for the current clock/reset contract keys:
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](perl/FSM/Support/NormalizedSemanticSystemContract.pm).
The nested `semantic.explicit_system_contract` summary inside that payload now
also has its own bounded owner when the authored explicit contract is
preserved:
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm).
The nested `semantic.signal_analysis` summary inside that payload now also has
its own bounded owner for the current sanitized signal families plus the shared
core signal-entry keys emitted across direct and composition roots:
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm).
The nested `semantic.forward_ir` summary inside that payload now also has its
own bounded owner for the current sanitized forward semantic projections:
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm).
The nested `semantic.forward_ir.lowered_rtl_ir` summary inside that branch now
also has its own bounded owner for the current lowered-RTL shell plus the
current composition-only extension keys:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm).
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded owner for the current structural-RTL shell:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm).
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded owner for the current intent-hir shell plus the
current composition-only extension keys:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm).
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded owner for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm).
The nested `semantic.module` summary inside that payload now also has its own
bounded owner for the core module keys plus the current optional metric-key
family:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm).
The nested `semantic.composition` summary inside that payload now also has its
own bounded owner for composition sources:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The bounded contract for the manifest's `support_accounting` section now has
its own explicit owner in
[perl/FSM/Support/SupportAccountingContract.pm](perl/FSM/Support/SupportAccountingContract.pm).
That contract is also advertised through the manifest itself, so downstream
tools can discover the bounded top-level section keys plus the current
sanitized catalog-entry keys without scraping prose.
The manifest-facing stable diagnostic-code registry now has the same split:
[perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm)
still owns the production `FSMGEN_*` data, while
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm)
owns the bounded public sibling-key and stable-entry-key promise advertised
through `diagnostics.stable_code_registry`.
The manifest shell itself now has its own explicit bounded owner too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
builds the JSON document, while
[perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm)
owns the bounded top-level plus first nested section key lists advertised
through top-level `manifest_contract`.
That shell contract now also explicitly includes the first nested
`support_accounting` key list, so downstream tooling can discover the
corpus-backed section shape without treating it as a hidden special case.
The manifest's `support_accounting` section now also exposes the same bounded
owner through `support_accounting.section_contract`, while deliberately keeping
the existing inline support-accounting contract fields and corpus metadata for
compatibility.
The manifest's `embedding` section now follows the same pattern:
[perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm)
names the published top-level and nested contract-owner map advertised through
`embedding.section_contract`, while the narrower result, composition-report,
serializable plan/report, typed-extension, and debug-runtime details continue
to live behind their own dedicated contracts.
The `embedding.serializable_plan_reports` child is owned by
[perl/FSM/Support/SerializablePlanReportContract.pm](perl/FSM/Support/SerializablePlanReportContract.pm)
and exposes machine-readable identity metadata for schema version, bounded-public
status, owner, and purpose; the capability manifest embeds the same identity
metadata and preserves it across manifest JSON encode/decode. That parent
identity metadata also survives contract JSON round-trip. It advertises the
current JSON-safe report families plus replacement guidance for raw
`HDLGenerator` compatibility shells, and the advertised JSON-safe surface list
survives contract JSON round-trip; the capability manifest preserves the same
surface list across manifest JSON encode/decode. The parent contract's
`public_top_level_presence_keys` list also survives JSON encode/decode and still
matches the decoded contract payload. The parent contract publishes
`raw_shell_replacement_keys` so tools can discover
that compatibility branch family directly. The capability manifest embeds that
same key list with a matching replacement map, rebuilds it cleanly per call, and
preserves it across manifest JSON encode/decode. Its
`surface_registry` maps each surface to its contract owner and portable dotted
primary report paths, with
owners aligned to the nested source map, non-empty unique path lists, and fresh
caller-owned containers that round-trip as JSON data. The parent contract also
preserves the embedded registry across full-contract JSON round-trip and keeps it
aligned with the decoded JSON-safe surface list. The capability manifest
embeds the canonical registry, rebuilds it cleanly, preserves it across manifest
JSON encode/decode, and keeps the decoded registry aligned with the JSON-safe
surface list. Its manifest-embedded
`public_top_level_presence_keys` list also survives JSON encode/decode and still
matches the decoded `serializable_plan_reports` payload. Embedding nested
presence metadata advertises the registry branch.
Manifest-embedded registry owners stay aligned with the manifest-embedded nested
source map, and manifest registry paths remain portable dotted report paths with
the same scalar-owner/non-empty-unique-path invariants as the standalone registry.
The parent contract publishes `surface_registry_entry_keys` for direct discovery
of the per-surface entry shape, preserves that unique list across contract JSON
round-trip, and the capability manifest embeds that same entry-key list alongside
registry entries that match it.
The parent contract returns fresh
nested maps, lists, raw replacement-key lists, and embedded child contracts, and
the capability manifest rebuilds that embedded child and entry-key list cleanly
per call. The contract
also round-trips as JSON with child contracts, exact composition snapshot child
metadata, replacement keys, and replacement guidance intact,
and the full capability manifest preserves that branch, its exact composition
snapshot child metadata, and its entry-key list across JSON encode/decode. Its
advertised public top-level key list is locked to
the keys the parent contract emits, and its nested source map is locked against
the embedded child contracts.
The JSON-safety flags in that parent contract are explicit JSON booleans:
current serializable report surfaces are marked safe, while raw `HDLGenerator`
branches are marked non-safe interchange payloads, and those flags survive
contract JSON round-trip with their boolean shape intact. The capability manifest
embeds those flags with the same boolean shape and values, and preserves them
across manifest JSON encode/decode in the main manifest branch audit.
The parent `guidance` list is also regression-checked as unique scalar guidance
that keeps those embedder rules visible and survives JSON round-trip exactly; the
capability manifest embeds the same structured guidance and preserves it exactly
across manifest JSON encode/decode.
The parent contract also embeds normalized semantic and composition report public
key metadata, plus the composition report JSON fragment path, from their
canonical report contracts and preserves that metadata across JSON round-trip.
The capability manifest carries the same metadata in its serializable
plan/report branch and preserves it across manifest JSON encode/decode.
The full capability manifest preserves that source-owner metadata when embedding
the branch.
Its first dedicated plan API is
[perl/FSM/Support/SerializableCompositionPlanSnapshot.pm](perl/FSM/Support/SerializableCompositionPlanSnapshot.pm),
which builds a JSON-safe `composition_plan_snapshot` with shallow counts and
summaries for ports, links, nets, instances, auxiliary assignments, and
shared-datapath candidates without exporting the raw `FSM::Composition::Plan`
object graph. Successful normalized semantic JSON reports for composition roots
now embed that public snapshot at `semantic.composition.plan_snapshot`. Its
lists and summary maps are caller-owned fresh containers rebuilt for each
semantic report, and the snapshot is JSON round-trip locked for plan summaries
and child collections.
The same manifest child also advertises
[perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm)
as `generation_result_snapshot`, a JSON-safe result summary that records stable
module/source/HDL-size facts plus raw-shell presence metadata without exporting
the raw `HDLGenerator` result hash as a public JSON API. Successful normalized
semantic JSON reports now expose that snapshot as top-level
`generation_result_snapshot`. Generation result snapshot lists and summary maps
are caller-owned fresh containers rebuilt for each semantic report, and the
snapshot is JSON round-trip locked for bounded summaries and raw-shell metadata.
Semantic report top-level key presence is runtime-locked across success and
failure outputs, and actual semantic JSON reports round-trip with embedded
snapshot data intact. Failed
semantic JSON reports omit these success
snapshots, including composition `plan_snapshot`, and continue to expose only
the bounded failure diagnostics/reporting surface. Success and failure semantic
reports are locked to exactly their advertised top-level key sets.
For tooling that only needs diagnostic status, the same manifest child now
advertises [perl/FSM/Support/SerializableDiagnosticSummary.pm](perl/FSM/Support/SerializableDiagnosticSummary.pm)
as `diagnostic_summary`, a JSON-safe count/code/severity summary that avoids
binding to full diagnostic payload shapes. Normalized semantic JSON now embeds
that summary for both success and failure reports, and check JSON now embeds the
same summary for both `--check --json` and `--check-json` outputs. Diagnostic
summary presence is runtime-locked in check JSON success and failure reports,
and actual check JSON reports round-trip with the summary intact. Success and
failure check reports are locked to exactly their advertised top-level key sets.
summary lists and count maps are caller-owned fresh containers rebuilt per
report, and both public JSON report families are checked against the same
standalone summary builder. Diagnostic summaries are JSON round-trip locked for
stable counts, severities, and unique-code lists.
The child serializable report APIs also lock their advertised public top-level
key lists to the keys their builders emit, and each child contract/report points
`contract_source` and `report_source` at its owning support module. Public
semantic/check JSON reports preserve those owners and standalone top-level key
sets on embedded snapshot branches.
The sibling facade and debug-runtime child contracts also have direct
self-description guards:
[t/375-hdl-generator-facade-contract.t](t/375-hdl-generator-facade-contract.t)
and [t/374-debug-runtime-contract.t](t/374-debug-runtime-contract.t)
now require each advertised top-level key list to exactly cover its emitted
contract shell.
The debug-runtime contract test also checks that the advertised debug helper
and control names are real exported `FSM::Debug` functions, and that the named
trace-verbosity values plus numeric range match the live debug runtime mapping.
It now also captures a real trace-bound debug-state snapshot and proves
`snapshot_state_keys` matches the emitted snapshot shape.
That same trace-bound snapshot is checked as not JSON-safe as a whole, matching
the advertised debug-runtime contract.
[t/494-debug-runtime-restore-state-boundary-audit.t](t/494-debug-runtime-restore-state-boundary-audit.t)
also proves `restore_fsm_debug_state(...)` rejects malformed snapshots before
mutating process-global debug state, and that the restore argument shape is
advertised through `embedding.debug_runtime`.
[t/398-debug-runtime-scoped-helper-boundary-audit.t](t/398-debug-runtime-scoped-helper-boundary-audit.t)
also proves `with_fsm_debug_state(...)` restores caller debug state across
scalar, list, void, and error paths, while ordinary debug setters remain
process-global unless callers explicitly scope or restore them.
The manifest's `diagnostics` section now follows the same pattern:
[perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm)
names the published top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract`, while the narrower stable
registry and check-JSON details continue to live behind their own dedicated
contracts.
The manifest's `producer` section now follows the same pattern:
[perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm)
names the published top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`, while the broader producer
story stays deliberately narrow: current tool/build identity, not a fully
stabilized package-release surface.
The manifest's `semantic_exports` section now follows the same pattern:
[perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm)
names the published top-level and nested contract-owner map advertised through
`semantic_exports.section_contract`, while the broader semantic export story
stays deliberately narrow: current bounded interchange surfaces, not every
future semantic report format FSMGen may publish later.
The manifest's `backend_validation` section now follows the same pattern:
[perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm)
names the published top-level and nested contract-owner map advertised through
`backend_validation.section_contract`, while the broader backend validation
story stays deliberately narrow: current bounded validation lanes, not every
future backend/toolchain validation report FSMGen may publish later.
The manifest's `language_surface` section now also has its own bounded owner:
[perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm)
names the published top-level and first nested section-key lists advertised
through `language_surface.surface_contract`, while deeper authored-language
meaning stays with narrower contracts or future deliberate widening.
The manifest's `documentation` section now follows the same pattern:
[perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm)
names the published top-level and path-list keys advertised through
`documentation.section_contract`, while the exact set of doc paths remains
widenable as long as the manifest keeps pointing at repo-relative Markdown
files.
Public `tested_by` provenance is also audited:
[t/381-contract-tested-by-provenance-audit.t](t/381-contract-tested-by-provenance-audit.t)
walks the direct support contracts plus the in-process and CLI manifest
surfaces, finds every `tested_by` list, and requires each published entry to
stay a relative existing `t/*.t` file.
Public module provenance is audited the same way:
[t/382-contract-module-provenance-audit.t](t/382-contract-module-provenance-audit.t)
walks direct contracts plus manifest outputs, finds fields such as
`contract_source`, `*_contract_source_map`, `implementation_owners`,
`report_sources`, `report_builder`, and `registry_source`, and requires each
value to be a loadable `FSM::...` module under `perl/`.
Grouped discovery maps are audited too:
[t/383-contract-family-map-integrity-audit.t](t/383-contract-family-map-integrity-audit.t)
requires public maps such as `presence_key_family_map`,
`nested_presence_key_map`, `constructor_option_family_map`, `name_family_map`,
and `family_map` to remain hashes of non-empty unique scalar lists and to match
same-named sibling lists when present.
The public machine-JSON stdout boundary is audited too:
[t/384-public-json-trace-stdout-boundary-audit.t](t/384-public-json-trace-stdout-boundary-audit.t)
runs the capability manifest, check JSON, and normalized semantic JSON CLI
paths with debug/trace options enabled, proving stdout remains JSON-only,
stderr stays clean, trace output is routed to the requested trace file for
report modes, and check/semantic JSON still do not write HDL artifacts.
It also advertises the optional external SystemVerilog validation lane:
`--verify-hdl` / `--validate-hdl` writes the generated `.sv`, then runs
Verilator in lint-only SystemVerilog mode and Yosys with
`read_verilog -sv -noautowire`, `synth -noabc -top`, and `stat`. Verilator is
the “is this valid lint-clean SystemVerilog?” gate; Yosys is the “can this be
turned into structural logic?” gate. The Yosys ABC algorithm is deliberately
disabled until a later dedicated lane handles ABC-specific timeout and mapping
edge cases. This is a backend validation gate, not a replacement for FSMGen's
own semantic and pre-generation checks. The lane is SystemVerilog-only for now;
VHDL/GHDL validation intentionally waits until FSMGen has an active VHDL
backend. The current regression coverage is a focused generated-SystemVerilog
smoke, not yet a claim that every historical sample under `fsm/` is externally
warning-clean. That focused smoke currently includes `fsm/lte_dif_pmaster.fsm`,
the MIPI byte-serial, packet-FIFO, tester-control, and timer examples, the
cleaned historical direct sample `fsm/trial_1.fsm`, plus the supported APB
requester/completer and AMBA requester protocol fixtures.
The bounded contract for this lane now has its own explicit owner in
[perl/FSM/Support/HDLExternalValidationContract.pm](perl/FSM/Support/HDLExternalValidationContract.pm).
The capability manifest advertises that contract so downstream tools can
discover the command shape, tool identities, stage names, and bounded success
result/step keys without scraping prose.
For in-process embedders, it also exposes the bounded
`HDLGenerator->generate_hdl_from_file(...)` result contract. That contract
stabilizes top-level key presence for fields such as `hdl_code`, `module_info`,
`intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir`, `source_info`, and
`resolved_package_imports`, plus the small nested identity slices
`source_info.header`, `source_info.kind`, `module_info.module_name`, and
`module_info.source_root_kind`, plus the bounded summary keys inside
`source_info`, `module_info`, and `statistics`. That includes source-level
facts such as `package_import_count` and `package_import_names`, reusable
module/stats counts such as `signal_count`, `state_count`,
`parameter_count`, `output_drive_family_count`, `intermediate_signals`,
`global_expressions`, `factoring_enabled`, and the composition-only
count/lane fields when the input root is a composition. It also advertises
that those top-level `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir`
hashes reuse the same bounded shell owners published for normalized semantic
JSON, but it deliberately does not claim the whole raw result hash is
JSON-safe. Nested compatibility fields may still contain live CoreAST/AST
objects; use `--emit-semantic-json` when the integration needs a sanitized
machine interchange document.
That boundary is runtime-audited by
[t/378-hdl-generator-result-json-boundary-audit.t](t/378-hdl-generator-result-json-boundary-audit.t),
which checks real direct and composition raw results against strict JSON
encoding and verifies the normalized semantic JSON path as the JSON-safe
interchange surface.
That same caution now explicitly includes `resolved_package_imports`: the
top-level branch remains a raw hash of `FSM::Package::Spec` objects, so the
stable package-import surface is `source_info.package_import_count` plus
`source_info.package_import_names`, not the typed package-spec payloads. The
`package_import_names` list is a fresh caller-owned array on each returned
`source_info` object, so local caller mutation of one returned summary does not
affect a later result.
That shell-only branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm](perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm),
so embedders have one dedicated contract to follow for that raw package-spec
map rule plus the bounded package-import summary surface.
The public `support_accounting` match objects emitted by both `--check --json`
and `--emit-semantic-json` now share one bounded nested-object contract too:
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm)
owns the common `matched` key plus the success-side and failure-side matched
identity keys advertised through those two report contracts.
The same manifest also advertises the bounded typed-extension/context contract:
explicit object/module/config loading, the current hook names
`after_parse_source` and `after_generate_result`, the stable context accessor
names, and the deliberate absence of legacy `.plg` discovery or `AUTOLOAD`
hook dispatch.
For composition embedders, the manifest also advertises the bounded
composition-report split: raw `composition_report` is an in-process
compatibility report and is not promised JSON-safe, while the sanitized
`semantic.composition.provenance_report` fragment in normalized semantic JSON
is the serializable downstream surface.
The raw result also mirrors that provenance into
`module_info.composition_provenance` and `statistics.composition_provenance`.
Those mirrors start equivalent to `composition_report`, but they are separate
mutable result containers; annotation of one branch must not mutate the others.
The same `HDLGenerator` result contract now also calls out `composition_spec`
and `composition_plan` as shell-only raw `FSM::Composition::Spec` and
`FSM::Composition::Plan` compatibility objects, so composition callers can keep
using those live Perl objects intentionally while JSON-minded tools stay on the
sanitized semantic-report path. The `composition_spec` branch now also has its
own explicit owner through
[perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm](perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm),
so embedders have one dedicated contract to follow for that raw
composition-spec rule plus the sanitized composition-summary fallback
surfaces. The `composition_plan` branch now also has its own explicit owner
through
[perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm](perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm),
so embedders have one dedicated contract to follow for that raw
composition-plan rule plus the same sanitized composition-summary fallback
surfaces.
The same contract now also names `fsm_module` as a shell-only raw
`FSM::CoreAST::FSMModule` object when it is present, and `raw_ast` as a
shell-only frontend/debug artifact. In both cases, downstream structured
consumers should prefer `intent_hir`, the other semantic layers, or normalized
semantic JSON instead of binding themselves to live CoreAST or parser-array
payloads. The `fsm_module` branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorFSMModuleContract.pm](perl/FSM/Support/HDLGeneratorFSMModuleContract.pm),
so embedders have one dedicated contract to follow for that raw CoreAST-object
rule plus the bounded semantic-summary fallback surfaces. The `raw_ast` branch
now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorRawASTContract.pm](perl/FSM/Support/HDLGeneratorRawASTContract.pm),
so embedders have one dedicated contract to follow for that parser/debug-array
rule plus the bounded `intent_hir` fallback surface.
It now also machine-advertises that the whole `source_info`, `module_info`, and
`statistics` hashes are not the stable API either: the bounded public contract
is the advertised identity/summary subsurfaces inside those hashes, not a
promise that every nested compatibility-heavy field in the wider hash is frozen.
The nested `source_info` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorSourceInfoContract.pm](perl/FSM/Support/HDLGeneratorSourceInfoContract.pm),
so embedders have one dedicated contract to follow for the current source
identity and package-import summary fields.
The nested `module_info` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorModuleInfoContract.pm](perl/FSM/Support/HDLGeneratorModuleInfoContract.pm),
so embedders have one dedicated contract to follow for the current module
identity fields plus the direct-root and composition-only scalar summary
families.
The nested `statistics` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorStatisticsContract.pm](perl/FSM/Support/HDLGeneratorStatisticsContract.pm),
so embedders have one dedicated contract to follow for the current direct-root
and composition-only scalar summary families there too.
The same goes for top-level `intent_hir`, `lowered_rtl_ir`, and
`structural_rtl_ir`: those hashes reuse their dedicated normalized-semantic
shell contracts, but the `HDLGenerator` result contract does not pretend they
are separately stabilized full trees beyond the advertised shell keys.

The first bounded check-only JSON surface is:

```bash
./bin/fsmgen --strict --check --json path/to/file.fsm
```

`--check-json` is an alias for the same mode. The command runs the full
pipeline, emits JSON to stdout, exits non-zero when the check fails, and never
writes an HDL file even if `-o` is present. Successful checks report
`success: true`, an empty `diagnostics` array, the resolved source path, and a
small checked-result summary. They also include a report-level
`support_accounting` object: corpus-backed successful sources report the matched
entry id, corpus family, coverage bucket, classification, source kind, and
`strict_supported` marker, while ad-hoc successful sources report
`matched: false`. The support-accounting corpus now verifies that every current
`supported_smoke` entry succeeds through `--check-json`, and every current
`strict_supported` entry succeeds through `--strict --check-json`.
Failed checks report `success: false` and a
diagnostic object. When the failure matches a support-accounting
`expected_failure` entry, that diagnostic includes the stable `FSMGEN_*` code,
severity, stability, family, source file, matched corpus entry, and
migration-hint availability. It also includes a nested `support_accounting`
object that records the matched corpus entry id, corpus family, coverage bucket,
classification, diagnostic code, and migration-hint availability in one
machine-friendly place. FSMGen chooses the most specific matching
support-accounting pattern when more than one expected-failure pattern matches.
Failures outside the current classifier still return JSON with a `null` code
rather than pretending a stable diagnostic identity exists.
The bounded key-presence contract for this surface now has its own explicit
owner in
[perl/FSM/Support/CheckDiagnosticsContract.pm](perl/FSM/Support/CheckDiagnosticsContract.pm).
That contract is also advertised through `--capability-manifest`, so
downstream tools can discover the common top-level keys plus the current
bounded success-result and failure-diagnostic keys without scraping prose or
guessing from sample payloads.

The first bounded normalized semantic JSON surface is:

```bash
./bin/fsmgen --strict --emit-semantic-json path/to/file.fsm
```

`--semantic-json` is an alias for the same mode. Compatibility aliases
`--emit-normalized-json` and `--normalized-json` are accepted too while the
public wording settles. The command runs the same full pipeline as generation,
emits JSON to stdout, exits non-zero when the source is rejected, and never
writes an HDL file even if `-o` is present. Successful reports use
`normalized_semantic_schema_version: 1`, `command.mode: semantic_export`, a
report-level `support_accounting` object, and a `semantic` payload containing
bounded public projections of:

- the module/root summary,
- system/reset contract metadata,
- signal analysis with private live Perl objects removed,
- `intent_hir`,
- `lowered_rtl_ir`,
- `structural_rtl_ir`,
- and, for composition sources, a sanitized
  `semantic.composition.provenance_report` fragment.

This is intentionally not a promise that every private pipeline object is now
public API. It is the first sanitized downstream-tool projection over the
forward semantic layers that already exist. Failed semantic exports reuse the
same stable diagnostic-code classifier as `--check-json` and do not expose
partial semantics. The support-accounting corpus now verifies that every
current `supported_smoke` entry succeeds through `--emit-semantic-json`, and
every current `strict_supported` entry succeeds through
`--strict --emit-semantic-json`, with matched support-accounting identity,
expected module/top identity, sanitized forward-IR projections, and no HDL
emission. Every current `expected_failure` entry is covered as well: it must
reject through `--emit-semantic-json`, emit a stable diagnostic/support-accounting
failure report, write no HDL, and expose no partial semantic payload.
The bounded key-presence contract for this surface now has its own explicit
owner in
[perl/FSM/Support/NormalizedSemanticReportContract.pm](perl/FSM/Support/NormalizedSemanticReportContract.pm).
That contract is also advertised through `--capability-manifest`, so downstream
tools can discover the current top-level and bounded nested success/composition
keys without scraping prose or inferring them from ad hoc samples.
For composition sources, the provenance report fragment is sanitized from the
same raw composition report that in-process callers see, but private Perl
objects and undeclared report branches are removed before JSON emission. This
keeps the report useful for downstream tools without exposing the live
`composition_plan`, `composition_spec`, `fsm_module`, or `raw_ast` payloads as
public API.

## 5) Input resolution and FSMLIB
`fsmgen` resolves `<fsm_file>` as:
1. bare name (`foo`) or `foo.fsm`: searched in repeated `--path DIR` roots, then `FSMLIB` paths, then current directory
2. relative path (`../fsm/foo.fsm`): used directly
3. absolute path: used directly

Example:
```bash
export FSMLIB="/project/fsm:/shared/fsm"
./bin/fsmgen --path ./fsm --path ../shared_fsm lte_dif_pmaster
```

## 6) Debug workflow
Recommended debug run:
```bash
./bin/fsmgen --trace-verbosity=debug --trace-log=trace.log --output /tmp/example.sv fsm/lte_dif_pmaster.fsm
```

Tracing behavior:
- Verbosity levels: `none`, `low`, `medium`, `high`, `debug`
- Every trace line includes origin metadata (file, function, line number)
- Trace output uses indentation-aware formatting and topic separation
- When trace logging is enabled, trace lines are written to `trace.log` (or chosen file) instead of stdout

## 7) Typed extensions (current `R7` boundary)
This is the current replacement direction for legacy `.plg` / `PPlugin` behavior.

What "typed extension" means here:
- an extension is a normal blessed Perl object, not a string hook name,
- the hook entrypoint is an explicit Perl method such as `after_generate_result(...)`,
- the hook receives a typed context object with named accessors such as `source_info`, `target_language`, and `result`,
- the active pipeline validates that extension entries are blessed objects with
  at least one real supported hook method before using them.

What it is not:
- not `.plg` file scanning,
- not `AUTOLOAD` lookup,
- not implicit hook discovery by string name,
- not implicit CLI plugin discovery in the current shipped slice.

The current boundary is explicit.
You can use it either:
- programmatically when embedding [perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm) from Perl,
- or from the CLI with repeated `--extension-module Module::Name` flags.

For CLI loading, the module must already be available in Perl's `@INC`, for
example through `PERL5LIB`, and it must provide a real `new()` method.
Config-file loading is also explicit: the config file lists module names, and
those modules must also already be available in `@INC` with real `new()`
methods.

Current shipped hook:
- `after_parse_source($context)`
- `after_generate_result($context)`

This hook/context boundary is also advertised in the capability manifest under
`embedding.typed_extensions`, backed by
[perl/FSM/Support/ExtensionContract.pm](perl/FSM/Support/ExtensionContract.pm).
That manifest entry is the machine-readable contract for embedders that need to
discover the current hook names, context accessor names, loading entrypoints,
registry extension-list copy policy, and deliberate non-goals.
It also advertises the grouped `name_family_map` key as part of that bounded
top-level contract shell, and
[t/306-extension-contract.t](t/306-extension-contract.t)
now checks that the contract's advertised top-level key list exactly covers the
keys emitted by the typed-extension contract builder.

What they do:
- `after_parse_source($context)` runs after parsing/classification and lets an extension inspect the source frontier before semantic lowering.
- `after_generate_result($context)` runs after generation has produced the normal result hash and before that result is returned to the caller.

Result augmentation is an in-process extension behavior, not an automatic
normalized-semantic JSON schema extension.
[t/379-extension-result-json-boundary-audit.t](t/379-extension-result-json-boundary-audit.t)
locks that boundary by proving extension-added raw result fields and HDL text
stay available on the raw result while `--emit-semantic-json` keeps them out of
the sanitized public JSON payload.

Current context accessors are:
- `stage`: the active hook name.
- `pipeline`: the current `FSM::Pipeline::HDLGenerator` instance.
- `source_path`: the source file path used for this generation call.
- `target_language`: the current HDL target.
- `source_info`: the classified source metadata, such as `fsm`, `dt`, or
  `composition` in `source_info->{kind}`. Each accessor call returns a fresh
  snapshot.
- `raw_ast`: available on `after_parse_source`. Each accessor call returns a
  fresh snapshot.
- `result`: available on `after_generate_result`. This is the live result hash,
  so result-hook augmentation mutates the object returned to the in-process
  caller by design.

Minimal example: add metadata to the returned result
```perl
use FSM::Pipeline::HDLGenerator;

{
    package My::ResultMarker;

    sub new { bless {}, shift }

    sub after_generate_result {
        my ($self, $context) = @_;
        $context->result->{extension_marker} = {
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
        };
    }
}

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    target_language => 'systemverilog',
    extensions => [ My::ResultMarker->new ],
);

my $result = $pipeline->generate_hdl_from_file('fsm/trial_0.fsm');
```

That public constructor-plus-generate seam is now machine-advertised too under
`embedding.hdl_generator_facade`, backed by
[perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm).
The current bounded facade contract covers `new(...)`,
`generate_hdl_from_file(...)`, the core runtime constructor options
`debug_level`, `target_language`, `strict_mode`, and `source_search_paths`, the
accepted compatibility/presentation constructor option `quiet`, plus direct
blessed-object extension injection through `extensions`.
It intentionally does not freeze the lower-level owner-injection constructor
arguments, and it leaves module/config-file extension loading behind
`embedding.typed_extensions` so the narrower in-process seam stays honest.
That boundary is regression-audited by
[t/377-hdl-generator-constructor-boundary-audit.t](t/377-hdl-generator-constructor-boundary-audit.t):
every current constructor `%args` key must be classified, and owner-injection
arguments must stay out of the facade contract and live manifest public
constructor-option lists.
[t/385-hdl-generator-facade-strict-mode-boundary-audit.t](t/385-hdl-generator-facade-strict-mode-boundary-audit.t)
also proves the advertised `strict_mode` constructor option is runtime-backed:
the default facade compiles the legacy infix-assignment compatibility fixture,
the strict facade rejects that same source with the canonical pair-form hint,
and the same strict facade object still accepts the canonical pair-form fixture.
[t/386-hdl-generator-facade-target-language-boundary-audit.t](t/386-hdl-generator-facade-target-language-boundary-audit.t)
also proves the advertised `target_language` constructor option routes real
direct backend behavior: the default path emits SystemVerilog forms, explicit
`verilog` emits Verilog forms, and explicit `vhdl` remains a source-contextual
not-implemented boundary rather than a completed backend promise.
[t/387-hdl-generator-facade-debug-level-boundary-audit.t](t/387-hdl-generator-facade-debug-level-boundary-audit.t)
also proves the advertised `debug_level` constructor option is runtime-backed
and scoped: level `0` stays silent, level `2` emits low/medium trace without
high-detail raw-AST dumps, level `4` emits that high-detail path, and the
caller debug state is restored afterward.
[t/388-hdl-generator-facade-source-search-paths-boundary-audit.t](t/388-hdl-generator-facade-source-search-paths-boundary-audit.t)
also proves the advertised `source_search_paths` constructor option is
runtime-backed and facade-local: missing roots fail at external package
resolution, supplied roots generate HDL with the imported package literal, and
separate facade objects with different roots do not leak resolution state.
[t/389-hdl-generator-facade-extensions-boundary-audit.t](t/389-hdl-generator-facade-extensions-boundary-audit.t)
also proves the advertised `extensions` constructor option is runtime-backed as
direct blessed-object injection: non-blessed values are rejected, hook-capable
injected objects dispatch in order, result-hook mutation reaches the returned
raw result, and separate facade objects do not share injected extension state.
[t/390-hdl-generator-facade-quiet-boundary-audit.t](t/390-hdl-generator-facade-quiet-boundary-audit.t)
also proves the advertised `quiet` constructor option is accepted compatibility
state rather than core runtime behavior: it is grouped under
`compatibility_constructor_option_names`, stays out of the core runtime family,
and in-process generation captures no stdout/stderr for either quiet value.
[t/419-hdl-generator-facade-legacy-debug-boundary-audit.t](t/419-hdl-generator-facade-legacy-debug-boundary-audit.t)
also proves the older `debug` constructor compatibility key stays non-public:
it is absent from the facade contract and manifest public constructor surfaces,
maps boolean values to `debug_level` `0` / `1` only when public `debug_level`
is omitted, yields to public `debug_level` when both are supplied, and rejects
malformed defined values before debug-runtime setup. New embedder-facing code
should use `debug_level`, not legacy `debug`.
[t/420-hdl-generator-facade-constructor-duplicate-option-boundary-audit.t](t/420-hdl-generator-facade-constructor-duplicate-option-boundary-audit.t)
also proves duplicate raw `new(...)` constructor option names fail at the
facade seam before Perl hash assignment can silently keep only the last value:
the duplicate-option policy is manifest-backed, public and non-public repeated
names receive sorted targeted diagnostics, later value-shape or unsupported
name validation does not run first, and caller debug state is preserved.
[t/421-hdl-generator-facade-extension-hook-method-boundary-audit.t](t/421-hdl-generator-facade-extension-hook-method-boundary-audit.t)
also proves direct extension objects must expose at least one real supported
typed-extension hook method: hookless, unsupported-hook-only, and
`AUTOLOAD`/fake-`can` objects fail at the facade before registry or raw method
fallout can leak, while parse-only and result-only real hook objects remain
accepted.
[t/426-typed-extension-registry-constructor-argument-boundary-audit.t](t/426-typed-extension-registry-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Registry->new(...)` construction accepts
only the exact class receiver and an even-length list of unique supported
scalar option names, so malformed registry constructor calls fail before raw
hash-coercion or `bless` fallout can leak.
[t/429-typed-extension-registry-method-receiver-boundary-audit.t](t/429-typed-extension-registry-method-receiver-boundary-audit.t)
also proves direct registry methods require an exact hash-backed
`FSM::Extension::Registry` object constructed by `new(...)`, so class
receivers, subclass stand-ins, and fake exact-class objects fail before hook or
context diagnostics can leak.
[t/432-typed-extension-registry-method-argument-list-boundary-audit.t](t/432-typed-extension-registry-method-argument-list-boundary-audit.t)
also proves direct registry methods own their payload argument counts:
`extensions(...)` takes no payload arguments, `dispatch_hook(...)` takes a
hook name and context, and hook wrapper methods take one context argument after
the registry invocant.
[t/493-typed-extension-registry-extension-list-defensive-copy-boundary-audit.t](t/493-typed-extension-registry-extension-list-defensive-copy-boundary-audit.t)
also proves direct registry construction and `extensions()` accessor calls copy
the extension array, so caller-side list mutation cannot alter the registry's
configured dispatch list while the extension objects remain the live hook
objects that dispatch invokes.
[t/399-hdl-generator-facade-stateful-reuse-boundary-audit.t](t/399-hdl-generator-facade-stateful-reuse-boundary-audit.t)
also proves the advertised `stateful_reuse_supported` promise is
runtime-backed: one facade object preserves `strict_mode`, `target_language`,
and `source_search_paths` across success, strict-mode failure, and later
success, while restoring caller debug state after each path and still keeping
lower-level owner-injection constructor args outside the public facade surface.
[t/380-extension-loading-command-boundary-audit.t](t/380-extension-loading-command-boundary-audit.t)
also locks the module/config loading-owner split: those loading entrypoints are
advertised by `embedding.typed_extensions`, not by
`embedding.hdl_generator_facade`, and semantic JSON `command` objects remain
limited to report-mode metadata even when extension loading is active.
[t/391-typed-extension-programmatic-loading-boundary-audit.t](t/391-typed-extension-programmatic-loading-boundary-audit.t)
also proves that same typed-extension-owned programmatic loading seam is
runtime-backed in-process: `extension_modules` and `extension_config_files`
both load a real module from `@INC`, dispatch `after_parse_source` before
`after_generate_result`, and mutate only the returned raw result for the
pipeline that requested loading.
[t/400-typed-extension-config-line-shape-boundary-audit.t](t/400-typed-extension-config-line-shape-boundary-audit.t)
also proves the advertised config-file line shape is runtime-backed:
config files accept only `module Module::Name` lines plus inert blank,
comment, and inline-comment text; malformed lines report extension config
file and line-number context; and repeated config files preserve parsed module
order during in-process hook dispatch.
[t/401-typed-extension-module-name-shape-boundary-audit.t](t/401-typed-extension-module-name-shape-boundary-audit.t)
also proves module-name validation fails closed before loading: every
`::`-separated segment must use the `Module::Name` identifier shape, so names
such as `FSM::BoundaryAudit::9Bad` are rejected at loader, config parser,
pipeline, and CLI boundaries before `require` runs or emits missing-module
fallout.
[t/402-typed-extension-constructor-list-shape-boundary-audit.t](t/402-typed-extension-constructor-list-shape-boundary-audit.t)
also proves the constructor list shape for programmatic extension loading
fails at the facade seam: scalar/hash values for `extension_modules`,
`extension_config_files`, and direct `extensions` are rejected with targeted
array-reference diagnostics before raw Perl dereference or lower-level loader
fallout can leak.
[t/392-typed-extension-autoload-boundary-audit.t](t/392-typed-extension-autoload-boundary-audit.t)
also proves `AUTOLOAD` remains outside the typed-extension hook boundary:
AUTOLOAD-only extensions, including objects that override `can(...)`, fail
closed as hookless direct extension objects, while explicit and inherited real
hook methods still run normally.
[t/393-typed-extension-hook-set-closed-boundary-audit.t](t/393-typed-extension-hook-set-closed-boundary-audit.t)
also proves the hook set is closed for the current schema version: extra
hook-shaped methods such as `before_parse_source` or `after_emit_hdl` remain
inert during direct and composition generation until the contract deliberately
adds a new hook family.
[t/394-typed-extension-context-accessor-boundary-audit.t](t/394-typed-extension-context-accessor-boundary-audit.t)
also proves the context accessor names are stable for the current schema
version by checking manifest discovery, the implemented
`FSM::Extension::Context` methods, and real direct plus composition hook
contexts through every advertised accessor.
[t/395-typed-extension-explicit-discovery-boundary-audit.t](t/395-typed-extension-explicit-discovery-boundary-audit.t)
also proves extension discovery remains explicit: nearby `extensions.fsmext`,
`fsmgen.fsmext`, and legacy `.plg`-shaped files stay inert for in-process and
CLI generation unless the caller supplies explicit module or config loading
entrypoints.
[t/396-typed-extension-constructor-boundary-audit.t](t/396-typed-extension-constructor-boundary-audit.t)
also proves module-name loading requires a real `new()` method: explicit and
inherited constructors still work, while extension-provided `can(...)` methods
and `AUTOLOAD`-only constructor discovery stay outside the typed loading
boundary.
[t/427-typed-extension-loader-constructor-argument-boundary-audit.t](t/427-typed-extension-loader-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Loader->new(...)` construction accepts
only the exact class receiver and no option/value arguments, so malformed
loader constructor calls fail before raw hash-coercion or `bless` fallout can
leak.
[t/428-typed-extension-loader-method-receiver-boundary-audit.t](t/428-typed-extension-loader-method-receiver-boundary-audit.t)
also proves direct loader methods require an exact hash-backed
`FSM::Extension::Loader` object constructed by `new(...)`, so class receivers,
subclass stand-ins, and fake exact-class objects fail before loading payload
diagnostics can leak.
[t/431-typed-extension-loader-method-argument-list-boundary-audit.t](t/431-typed-extension-loader-method-argument-list-boundary-audit.t)
also proves direct loader methods accept exactly one payload argument after the
loader invocant, so missing or extra payload arguments fail before raw Perl
signature fallout or payload value diagnostics can leak.
[t/397-typed-extension-registry-dispatch-boundary-audit.t](t/397-typed-extension-registry-dispatch-boundary-audit.t)
also proves the registry's direct `dispatch_hook(...)` entrypoint enforces the
same closed hook set: `after_parse_source` and `after_generate_result` still
dispatch, while unsupported hook names are rejected before extension methods
can run.
[t/422-typed-extension-registry-dispatch-context-boundary-audit.t](t/422-typed-extension-registry-dispatch-context-boundary-audit.t)
also proves direct registry dispatch requires a real
`FSM::Extension::Context` object whose `stage` matches the dispatched hook
name, so malformed direct contexts fail before extension code can reinterpret
them.
[t/434-typed-extension-registry-dispatch-constructed-context-boundary-audit.t](t/434-typed-extension-registry-dispatch-constructed-context-boundary-audit.t)
also proves direct registry dispatch requires an exact hash-backed context
object constructed by `FSM::Extension::Context->new(...)`, so fake exact-class
context objects fail at the registry boundary before context accessor fallout
can leak.
[t/423-typed-extension-context-constructor-argument-boundary-audit.t](t/423-typed-extension-context-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Context->new(...)` construction accepts
only the exact class receiver and an even-length list of unique supported
scalar option names, so malformed constructor calls fail before raw Perl
argument or `bless` fallout can leak.
[t/430-typed-extension-context-accessor-receiver-boundary-audit.t](t/430-typed-extension-context-accessor-receiver-boundary-audit.t)
also proves direct context accessors require an exact hash-backed
`FSM::Extension::Context` object constructed by `new(...)`, so class receivers,
subclass stand-ins, and fake exact-class objects fail before raw accessor
fallout can leak.
[t/433-typed-extension-context-accessor-argument-list-boundary-audit.t](t/433-typed-extension-context-accessor-argument-list-boundary-audit.t)
also proves direct context accessors take no payload arguments after the
context invocant, so extra accessor arguments fail before raw Perl signature
fallout can leak.
[t/424-typed-extension-context-constructor-payload-boundary-audit.t](t/424-typed-extension-context-constructor-payload-boundary-audit.t)
also proves direct context construction validates the payload values that hooks
rely on: supported hook stages, a blessed pipeline, scalar source path and
target language, scalar `source_info->{kind}`, parse contexts with
`raw_ast` and no `result`, and result contexts with `result` and no `raw_ast`.
[t/425-typed-extension-dt-source-kind-contract-audit.t](t/425-typed-extension-dt-source-kind-contract-audit.t)
also proves standalone `?dt:` roots are part of the bounded typed-extension
source-kind family: manifests advertise `dt`, and live `dt` generation
dispatches parse/result contexts whose `source_info->{kind}` is `dt`.

For in-process embedders, `FSM::Pipeline::HDLGenerator` no longer leaves its
requested `debug_level` behind as process-global state after construction or
generation. The pipeline now scopes that debug setting to the constructor or
generation call and restores the caller's prior `FSM::Debug` state afterward.

If you need to rebind tracing manually around embedded work, the current
save/restore seam is:

```perl
use FSM::Debug qw(
    capture_fsm_debug_state
    restore_fsm_debug_state
    set_fsm_trace_output_file
    set_fsm_trace_verbosity
);

my $saved = capture_fsm_debug_state();
set_fsm_trace_output_file('embedded-trace.log');
set_fsm_trace_verbosity('debug');

# ... temporary embedded tracing work ...

restore_fsm_debug_state($saved);
```

That restore path preserves the caller-facing trace/debug configuration,
including the original trace sink, instead of forcing embedders to rebuild the
global debug settings by hand after a temporary trace-file switch. Restores now
accept exact schema-version-1 snapshots from `capture_fsm_debug_state(...)` and
reject malformed partial snapshots before mutating process-global debug state.
[t/494-debug-runtime-restore-state-boundary-audit.t](t/494-debug-runtime-restore-state-boundary-audit.t)
proves that restore argument shape through the direct contract, in-process
manifest, both CLI manifest spellings, valid captured restores, targeted
malformed-snapshot diagnostics, and caller-state preservation on rejection.
[t/398-debug-runtime-scoped-helper-boundary-audit.t](t/398-debug-runtime-scoped-helper-boundary-audit.t)
also proves `with_fsm_debug_state(...)` restores caller debug state across
scalar, list, void, and error paths, while ordinary debug setters remain
process-global unless callers explicitly scope or restore them.
That current in-process seam is now also advertised through
`embedding.debug_runtime`, owned by
[perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm).
That bounded contract publishes the shipped helper families, the bounded
snapshot-state keys, the restore snapshot argument shape, the supported named
trace-verbosity values, and the current limit that `FSM::Debug` is still one
process-global singleton rather
than a thread-local debug context.

This is useful when:
- you want to attach extra metadata for downstream tooling,
- but you do not want to change the core generator contract yet.

Early-source example:
```perl
{
    package My::SourceInspector;

    sub new { bless { seen => [] }, shift }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{seen}}, {
            source_kind => $context->source_info->{kind},
            stage => $context->stage,
        };
    }
}
```

This is useful when:
- you want early validation or telemetry at the parsed-source boundary,
- without adding broad mid-pipeline hooks.

CLI version of the same idea:
```bash
PERL5LIB=./my_extensions ./bin/fsmgen \
  --extension-module My::ResultMarker \
  --output /tmp/trial_0.sv \
  fsm/trial_0.fsm
```

Config-file version:
```text
# extensions.fsmext
module My::ResultMarker
```

```bash
PERL5LIB=./my_extensions ./bin/fsmgen \
  --extension-config extensions.fsmext \
  --output /tmp/trial_0.sv \
  fsm/trial_0.fsm
```

Second realistic example: collect generation telemetry across multiple runs
```perl
use FSM::Pipeline::HDLGenerator;

{
    package My::TelemetryCollector;

    sub new { bless { modules => [] }, shift }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{modules}}, {
            module_name => $context->result->{module_info}{module_name},
            source_kind => $context->source_info->{kind},
        };
    }

    sub modules { return shift->{modules} }
}

my $collector = My::TelemetryCollector->new;
my $pipeline = FSM::Pipeline::HDLGenerator->new(
    extensions => [ $collector ],
);

$pipeline->generate_hdl_from_file('fsm/trial_0.fsm');
$pipeline->generate_hdl_from_file('fsm/lte_dif_pmaster.fsm');
```

This is useful when:
- you embed FSMGen inside a larger build/reporting flow,
- and you want explicit post-generation data without reviving the old plugin model.

Practical rule:
- if you need explicit post-generation behavior, a typed extension is the current supported seam,
- if you need explicit parsed-source inspection, use `after_parse_source($context)`,
- if you need explicit CLI loading, use repeated `--extension-module Module::Name` with modules already on `@INC`,
- if you want to keep module lists out of the command line, use repeated `--extension-config <file>` with lines of the form `module Module::Name`,
- if typed extension loading fails, the current pipeline/CLI now keeps `Extension config file:` or `Extension module:` labels around that failure, and CLI constructor failures stay cleaned instead of dumping the `bin/fsmgen` script line,
- if a typed extension hook fails, the current pipeline/CLI now keeps `Source file:`, `Extension module:`, and `Extension stage:` labels around that failure so the failing hook stays source-local and actionable,
- if you need `.plg` discovery, auto-discovery, richer extension parameters, or broad mid-pipeline mutation hooks, that is not part of the shipped boundary.

See [docs/EXTENSION_MODEL.md](docs/EXTENSION_MODEL.md) for the architecture note and exact current contract.

## 8) External compatibility flow (legacy environment)
If working in the external flow that uses `generate_fsm_hdl.pl`, the equivalent command pattern is:
```bash
perl generate_fsm_hdl.pl --debug /path/to/input.fsm -o output.sv
```
Use this only in environments where that script is part of the active toolchain.

## 9) Troubleshooting
### Parser rejects combinational self-dependency
If you see `Illegal combinational self-dependency`, rewrite the logic so combinational `=` assignments do not create feedback loops.

### Parser rejects D-input self-dependency
If you see `Illegal D-input self-dependency`, the RHS or guard of a `<=` / `<=+` assignment is reading the same D-input-named LHS. Use `<-` for normal Q/output feedback such as `A <- (+ A 1)`, or use the `<=+` auxiliary Q mirror (`A_r`) when the source must intentionally see the registered value separately from the same-cycle D-input name.

### Verilog/VHDL behavior
- Verilog: supported through conversion path
- VHDL: explicit not-implemented backend error is expected currently

### Regression check
Before committing parser/generator changes:
```bash
prove -v t/01-regression.t
```

## 10) Practical authoring guidelines
- Use `=` only for true combinational outputs.
- Use `<-` for ordinary flopped state and register loopback, especially for Q-named signals such as `addr_q`.
- Use `<=` only when you intentionally want the authored LHS to mean the D-input/next-value side, and do not read that same LHS name on the RHS or guard.
- Prefer simple, explicit conditions; when conditions grow, expect intermediate signals in output RTL.
- Run with `--debug=3` when bringing up new FSM files.
