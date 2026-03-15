# FSMGen User Guide

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
  - one explicit `?ports` block,
  - one or more embedded `?fsmc` children in the same file,
  - `C1` single-child passthrough via deterministic same-name wiring,
  - `C2` multi-child FSM composition via explicit `?toplink` wiring with `instance.port` child endpoints.
  - `C3` mixed FSM plus external RTL composition via explicit `?toplink` wiring and sidecar `<module>.rtlif` interface metadata.
  - `C4` declared top-port connect-by-name via `=name` declarations inside `?ports`.
- See [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md) for the scoped `R6` plan and [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md) for historical context.

## 2) Core concepts
### FSM input file
A `.fsm` file defines states, decision trees, conditions, assignments, and transitions.

### Terms and concepts
- **State**: named execution context in the FSM.
- **Decision tree (DT)**: conditional/action structure evaluated within a state.
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

### Assignment operators
- `A <- expr` : synchronous/flopped assignment
- `A <= expr` : synchronous/flopped assignment variant
- `A = expr`  : combinational assignment

### Combinational safety rule
For `=` assignments, RHS must not depend on the same LHS through any combinational path.
Examples rejected by parser:
- direct: `A = A`
- indirect: `A = B` and `B = A`

Synchronous loopback remains valid:
- `A <- A`

## 2.1) Currently supported `.fsm` constructs (live reference)
This section is the current live support boundary.

Standard used here:
- "fully supported" means the construct is in the active parser, goes through the active SystemVerilog/Verilog generation path, and is locked by current regressions.
- "implemented but not fully regression-backed" means the parser/runtime has support for it, but the current test depth is not strong enough to present it as equally solid.

### Fully supported single-FSM constructs
- Root form `(?fsm:name ...)`
- Flattened legacy root form `(+fsm name)` with sibling `(+system ...)`, state blocks, and `(+size ...)`
- Conventional `(+system ...)` section declaring the shared system pair:
  - `(+system (clock clk) (sreset rstn))`
  - `(+system (clock clk) (asreset rstn))`
- Regular state blocks like `(s0 ...)`, `(idle ...)`
- Special reset states `(-syncrst ...)` and `(-asyncrst ...)`
- Standalone decision-tree blocks like `(-alpha_dt ...)`, `(-misc ...)`, or `(-mycombit ...)`
- Symbol-definition sections:
  - `(+constants ...)`
  - `(+enums ...)`
  - `(+define ...)`
  - `(+params ...)`

Standalone DT note:
- User-facingly, hyphen-prefixed top-level blocks are supported as standalone DT blocks.
- When an FSM contains only those blocks, the active runtime treats it as DT-only generation and does not synthesize a `current_state` / `next_state` state-register plan.
- Regular named states still use the same underlying decision-tree machinery, but they additionally participate in state encoding and transition planning.

- `(+size ...)` signal-width declarations
- Unconditional state transitions `(-> next_state)`
- Test-node branching `(?SIG (=0 ...) (=1 ...))`
- Register assignment `(A <- B)`
- D-input style sequential assignment `(A <= B)`
- Combinational assignment `(A = B)`
- Explicit output exposure on the LHS, for example `(G> = H)` and `(output_data> <= 8'1)`
- Dual-output register form `(I <-= J)` producing `next_I`
- Dual-output D-input form `(K <=+ L)` producing `K_r`
- Delayed pulse form `(P <N 0)` and `(P <N 1)`, including `N=0`
- Literal forms `1`, `8'3`, `8'b1010`, `8'hFF`, and `const_8b0`
- Signal-reference forms `SIG`, `SIG[3]`, `SIG[7:0]`, `SIG'8`, `SIG.member`, and `SIG>`
- Condition forms that are in the active supported path: `<sig`, `<!sig`, `<sig=value`, and test-node equality branches like `=0` / `=1`
- Nested guarded blocks using standalone `< ...` / `<! ...` action forms
- Condition suffixes attached directly to assignments or transitions, for example `(A <= B <start)` and `(-> busy <!full)`
- Compound-update shorthand forms `(++ sig)`, `(-- sig)`, `(+=N sig)`, and `(-=N sig)`
- Inline compound modifiers on assignments, for example `(A <- B (+= 2))` and `(C = D (-= 1))`
- RHS operator expressions for the currently regression-backed active families:
  - unary `!`
  - binary equality `==`
  - n-ary `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`
  - word aliases `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, `xor`
- Enforced diagnostics for illegal combinational self-dependency with `=`
- Enforced diagnostics for mixing `=` with sequential operators on the same LHS
- Enforced diagnostics for mixing pulse-delayed and non-pulse sequential operators on the same LHS
- Enforced diagnostics for multiple different `<N` delays on the same LHS
- Enforced diagnostics for `<N` with RHS other than literal `0` or `1`

### Fully supported composition `.fsm` constructs
- Root form `(?top:name ...)`
- Explicit `(?ports:block ...)` blocks with flat port tokens
- Port tokens like `clk`, `rstn`, `data_in<8`, `txd>`, and `=final_data>8`
- `(?fsmc:instance child_source)` with exactly one embedded FSM source name
- `(?rtl:module)` for external RTL children
- External RTL interface loading via sidecar `<module>.rtlif`
- Explicit `(?toplink:name ...)` blocks with flat `/source/target/` tokens
- Dotted child endpoints in links, for example `/producer.output_data/consumer.input_data/`
- `C1` lane: one `?top`, one `?fsmc`, explicit `?ports`, deterministic same-name top wiring
- `C2` lane: multiple `?fsmc` children plus explicit `?toplink` wiring and deterministic internal nets
- `C3` lane: mixed `?fsmc` plus `?rtl`, with `.rtlif`-based interface validation
- `C4` lane: declared connect-by-name through `=name` in `?ports`
- `C5` diagnostics: duplicate-driver rejection, explicit-link width mismatch rejection, connect-by-name ambiguity rejection, connect-by-name unknown-endpoint rejection, and width mismatch rejection
- `C6` scoped rejection of legacy out-of-scope composition constructs

### Implemented, but not strong enough yet to call fully supported
- No additional construct family is currently parked in this middle bucket.

### Explicitly out of active support
- VHDL generation
- Non-conventional `(+system ...)` forms, including:
  - alternative clock names,
  - alternative reset names,
  - additional system directives,
  - and partial `+system` declarations that do not match the conventional shared pair
- Unsupported top-level directive sections outside the current supported family, for example:
  - `(+clock clk)`
  - `(+asreset rstn)`
  - `(+bogus ...)`
- Bare condition suffixes without an explicit guard marker, for example:
  - `(A <= B start)`
  - `(-> busy full)`
- Legacy composition forms such as `?&...`, nested `?top`, `?ports` mapping directives, nested `?toplink`, and multi-source `?fsmc`

### Draft normative contract for guards, suffixes, updates, and operator expressions
This is the current `R8` draft normative contract for the active language slice that is now regression-backed explicitly.

Guarded blocks:
- `(<cond ...actions...)` executes its actions when `cond` is true in the active condition model.
- `(<!cond ...actions...)` executes its actions when `cond` is false in the active condition model.
- Nested guarded blocks are allowed, and nested guards compose by logical `AND`.
- Current active examples include:
  - `(<req (A <= B))`
  - `(<!full (-> busy))`
  - `(<(& req start !full) (D = C))`
  - `(<count=8'3 (FLAG = 1))`

Condition suffixes:
- A suffix guard is the single-action form of a guarded block.
- Suffix guards must use the explicit guarded forms `<...` or `<!...`; bare suffixes like `(A <= B start)` are not part of the active contract.
- Examples:
  - `(A <= B <start)` is the single-action guarded form of `(<start (A <= B))`
  - `(-> busy <!full)` is the single-action guarded form of `(<!full (-> busy))`

Update shorthand:
- `(++ counter)` means increment `counter` by `1`
- `(-- retry_count)` means decrement `retry_count` by `1`
- `(+=4 byte_count)` means increment `byte_count` by `4`
- `(-=1 remaining)` means decrement `remaining` by `1`
- Inline forms keep the surrounding assignment family:
  - `(ACC <- SRC (+= 2))`
  - `(COMB = SRC (-= 1))`

Operator expressions:
- The RHS expression grammar is shared across combinational and sequential assignments.
- The assignment operator decides timing/storage semantics; the RHS decides only the expression tree.
- Current regression-backed operator surface:
  - unary: `!`
  - binary equality: `==`
  - n-ary arithmetic/logic: `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`
  - aliases: `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, `xor`
- Current lowering model:
  - `+`, `*`, `&`, `|`, `^` are treated as n-ary expression families
  - `-`, `/`, `%` are treated as left-associative n-ary expression families
- Examples:
  - `(sum = (+ a b c d))`
  - `(diff = (- a b c d))`
  - `(prod = (* a b c d))`
  - `(quo = (/ a b c d))`
  - `(mask = (^ x y z))`
  - `(alias_sum = (add a b c d))`
  - `(alias_xor = (xor x y z))`

Boundary note:
- Some future normalization ideas discussed in engineering notes are not part of the active contract yet.
- In particular, the more systematic sugar direction such as `<foo==3` as canonical shorthand over a fully explicit guard expression remains saved in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), but it is not yet the active supported language contract.

### Draft normative contract for symbol-definition sections
This is the current `R8` draft normative contract for the symbol-definition families that are now regression-backed explicitly.

`(+constants ...)`:
- Defines named literal constants.
- Current active use:
  - `(+constants (C0 8'3) (ZERO const_8b0))`
- References to those names resolve as literals in assignment RHS expressions and guard equality conditions.

`(+define ...)`:
- Defines one named literal-like value per directive block.
- Current active use:
  - `(+define (D0 8'4))`
- References to that name resolve as literals in assignment RHS expressions and guard equality conditions.

`(+params ...)`:
- Defines named scalar parameter values.
- Current active use:
  - `(+params (P0 8))`
- References to those names resolve as literals in assignment RHS expressions and guard equality conditions.

`(+enums ...)`:
- Defines named enumerations with member/value pairs.
- Current active use:
  - `(+enums (mode (IDLE 0) (BUSY 1)))`
- Enum members are referenced as `enum_name.member_name`, for example `mode.BUSY`.
- Those references resolve as literals in assignment RHS expressions and guard equality conditions.

Regression-backed examples:
```lisp
(+constants
  (C0 8'3)
  (ZERO const_8b0)
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
- This slice locks symbol resolution in assignment RHS expressions and guard equality conditions.
- Broader semantics for these families should be documented explicitly if and when the contract is widened beyond that current active use.

### Draft normative contract for the conventional `+system` section
This is the current `R8` draft normative contract for the active `+system` boundary.

Accepted form:
```lisp
(+system
  (clock clk)
  (sreset rstn)
)
```

Also accepted:
```lisp
(+system
  (clock clk)
  (asreset rstn)
)
```

Current meaning:
- If `+system` is present, the active contract currently treats it as a declarative confirmation of the conventional shared system-input pair:
  - `clk`
  - `rstn`
- The parser now validates that exact boundary explicitly instead of silently ignoring richer legacy `+system` content.
- The parser records:
  - default clock domain `clk`,
  - default reset domain `rstn`,
  - and typed system signals for `clk` and `rstn`.

Current boundary:
- Supported:
  - exactly `(clock clk)`
  - exactly one reset declaration naming `rstn` via:
    - `(sreset rstn)`
    - or `(asreset rstn)`
- Rejected explicitly:
  - alternative clock names such as `(clock core_clk)`
  - alternative reset names such as `(sreset reset_n)`
  - unsupported directives such as `(areset rstn)` or other legacy `+system` entries
  - incomplete `+system` sections

Regression-backed example:
```lisp
(?fsm:system_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A = B)
  )
)
```

Boundary note:
- This slice makes the conventional shared-system declaration explicit and regression-backed.
- It accepts the two legacy reset spellings already present in the active tree, but it does not yet widen the contract into arbitrary system metadata, custom clock/reset names, or richer reset-mode differentiation.

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
```

Current narrow composition example:
```lisp
(?top:single_child_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child_ctrl child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset rstn)
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
- the child FSM is embedded in the same file,
- the child exposes `output_data` explicitly as an output,
- the top `?ports` block matches the realized child interface exactly.

Current narrow multi-child example:
```lisp
(?top:two_child_top
  (?ports:public_io
    clk
    rstn
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
- every child is an embedded `?fsmc`,
- `clk` and `rstn` use the shared system-input contract,
- non-system connections are expressed explicitly through `?toplink`,
- explicit link widths and endpoint roles must match exactly.

Current narrow declared connect-by-name example:
```lisp
(?top:connect_by_name_top
  (?ports:public_io
    clk
    rstn
    =final_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
  )
)
```

This currently works because:
- `=final_data>8` declares that the top output `final_data` must be resolved by same-name matching rather than by an explicit top-output `?toplink`,
- exactly one compatible child endpoint named `final_data` exists,
- compatibility means same name, same direction, and same width,
- ambiguous or missing matches fail explicitly.

Realistic `=name` patterns:

1. Expose one child FSM output directly at the top level without a second `?toplink`
```lisp
(?top:packet_formatter_top
  (?ports:public_io
    clk
    rstn
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
    rstn
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
    rstn
    =txd>
  )
  (?rtl:uart_tx)
)
```

With sidecar interface metadata:
```lisp
(?rtlif:uart_tx
  clk
  rstn
  data_in<8
  txd>
)
```

This is useful when:
- the external RTL module already uses the public top-level signal name you want,
- so the composition can expose `txd` without an extra explicit `/uart_tx.txd/txd/` link.

Practical rules for `=name`:
- use it only when the top-level name should intentionally stay the same as the child endpoint name,
- use normal explicit `?toplink` when you need renaming, remapping, or multiple non-system connections,
- do not use `=clk` or `=rstn`; those already use the dedicated shared system-input contract,
- a match is valid only when exactly one child endpoint has the same name, same direction, and same width.
- if widths do not match, generation fails before emission and the diagnostic names both endpoints and their widths.

Current narrow mixed FSM + external RTL example:
```lisp
(?top:fsm_plus_rtl_top
  (?ports:public_io
    clk
    rstn
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
  rstn
  data_in<8
  txd>
)
```

This currently works because:
- the FSM child is still compiled through the active FSM pipeline,
- the external RTL child is instantiated but not regenerated,
- composition loads the RTL interface from `uart_tx.rtlif` beside the source file or through the existing `FSMLIB` search roots,
- non-system mixed-child connections remain explicit through `?toplink`.

## 4) Useful options
- `-o, --output <file>` : output file path
- `-l, --language <systemverilog|sv|verilog|v|vhdl>` : target language
- `-d, --debug[=N]` : numeric trace compatibility level (`0..4`; bare `--debug` implies `4`)
- `--trace-verbosity <none|low|medium|high|debug>` : named trace verbosity selector
- `--trace-log[=FILE]` : route trace output to FILE (default: `trace.log`)
- `--trace-emojis` / `--notrace-emojis` : enable/disable emoji markers in trace formatting
- `--extension-module <Module::Name>` : load an explicit typed extension module from `@INC` (may be repeated)
- `--extension-config <file>` : load typed extension modules from an explicit config file (may be repeated)
- `-q, --quiet` : suppress informational messages
- `-h, --help` : full CLI help

## 5) Input resolution and FSMLIB
`fsmgen` resolves `<fsm_file>` as:
1. bare name (`foo`) or `foo.fsm`: searched in `FSMLIB` paths, then current directory
2. relative path (`../fsm/foo.fsm`): used directly
3. absolute path: used directly

Example:
```bash
export FSMLIB="/project/fsm:/shared/fsm"
./bin/fsmgen lte_dif_pmaster
```

## 6) Debug workflow
Recommended debug run:
```bash
./bin/fsmgen --trace-verbosity=debug --trace-log=trace.log --output /tmp/example.sv fsm/trial_1.fsm
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
- the active pipeline validates that extension entries are objects before using them.

What it is not:
- not `.plg` file scanning,
- not `AUTOLOAD` lookup,
- not implicit hook discovery by string name,
- not implicit CLI plugin discovery in the current shipped slice.

The current boundary is explicit.
You can use it either:
- programmatically when embedding [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) from Perl,
- or from the CLI with repeated `--extension-module Module::Name` flags.

For CLI loading, the module must already be available in Perl's `@INC`, for example through `PERL5LIB`.
Config-file loading is also explicit: the config file lists module names, and those modules must also already be available in `@INC`.

Current shipped hook:
- `after_parse_source($context)`
- `after_generate_result($context)`

What they do:
- `after_parse_source($context)` runs after parsing/classification and lets an extension inspect the source frontier before semantic lowering.
- `after_generate_result($context)` runs after generation has produced the normal result hash and before that result is returned to the caller.

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
- if you need `.plg` discovery, auto-discovery, richer extension parameters, or broad mid-pipeline mutation hooks, that is not part of the shipped boundary.

See [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) for the architecture note and exact current contract.

## 8) External compatibility flow (legacy environment)
If working in the external flow that uses `generate_fsm_hdl.pl`, the equivalent command pattern is:
```bash
perl generate_fsm_hdl.pl --debug /path/to/input.fsm -o output.sv
```
Use this only in environments where that script is part of the active toolchain.

## 9) Troubleshooting
### Parser rejects combinational self-dependency
If you see `Illegal combinational self-dependency`, rewrite the logic so combinational `=` assignments do not create feedback loops.

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
- Use `<-`/`<=` for flopped behavior and register loopback.
- Prefer simple, explicit conditions; when conditions grow, expect intermediate signals in output RTL.
- Run with `--debug=3` when bringing up new FSM files.
