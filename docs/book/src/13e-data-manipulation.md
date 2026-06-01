# Data Manipulation

ISF provides abstract data manipulation constructs that the scheduler
lowers to appropriate `.fsm` expressions.

## `(update var expr)` — Variable Modification

```lisp
(update counter (- counter 1))
(update status BUSY)
(update rdata (| (<< rdata 1) bit_in))
```

General-purpose variable assignment. The expression is any `.fsm`-compatible
expression, supplied as one scalar or list expression payload. The form is
exact: `(update var expr)`, with scalar `var`. Missing expressions, nested
targets, and extra operands are rejected before scheduled `.fsm` emission.

Division and modulo RHS expressions also fail closed when a divisor operand is
a numeric/exact-width literal zero, an actor-level constant that resolves to
zero, or an actor-local scalar parameter default that resolves to zero,
including nested expressions such as
`(update out (+ mask (% numerator 8'd0)))`, `(set out (/ numerator ZERO))`,
or `(set out (/ numerator ZERO_PARAM))`.

Nonzero literal divisors, nonzero actor-constant divisors, nonzero
actor-parameter divisors, and dynamic scalar divisors are preserved in the
scheduled `.fsm`; FSMGen does not yet prove arbitrary dynamic divisors
nonzero.

**Lowering**: `(<- (var expr))` — sequential Q-named assignment.

## `(incr NAME [by N])` / `(decr NAME [by N])` — Compound Increment / Decrement

```lisp
(incr count)          ;; count += 1
(incr total by din)   ;; total += din
(decr remaining)      ;; remaining -= 1
(decr level by 2)     ;; level -= 2
```

`(incr …)` and `(decr …)` are the compound-assignment sugar a high-level
language has (`x += N`, `x++`). They capture the common counter / accumulator
intent more directly than spelling out `(set NAME (+ NAME N))`. The amount is an
optional `by N` (the `by` keyword followed by the amount); `N` defaults to `1`
and may be a literal, a signal, or an expression.

This is a pure ISF parser desugar into the existing
[`(update …)` / `(set …)`](#update-var-expr--variable-modification) data op — no
new lowering machinery:

| Form | Desugars to |
| --- | --- |
| `(incr x)` | `(set x (+ x 1))` |
| `(incr x by N)` | `(set x (+ x N))` |
| `(decr x)` | `(set x (- x 1))` |
| `(decr x by N)` | `(set x (- x N))` |

They are valid anywhere a `(set …)` is — at the transaction top level and inside
control-flow bodies (`when`, `switch`, `while`, `until`, `repeat`, and so the
`for` / `cond` forms that lower to them). The canonical use is a loop
accumulator:

```lisp
(actor scoreboard
  (interface
    (input start)
    (output done)
    (output rounds (width 8))
    (output bonus (width 8)))
  (transaction run
    (on start)
    (incr bonus by 10)        ;; bonus += 10 once  -> 10
    (for (i 3)
      (incr rounds))          ;; rounds += 1 per iteration -> 3
    (complete done)))
```

After `start`, `bonus` reaches `10` (one `+= 10`) and `rounds` reaches `3` (one
`+= 1` executed each of the three loop iterations), then `done` asserts.

A malformed form fails closed before `.fsm` emission: `(incr)` with no register
name, or trailing tokens that are not a `by N` pair (e.g. `(incr x foo 2)`), is
rejected with a diagnostic.

> **Sequential writes accumulate.** Because `(incr …)` / `(decr …)` lower to an
> expression `(set …)`, two in a row (`(incr x)` then `(incr x)`) run as two
> sequential states — each with its own write-enable — so `x` ends up bumped
> twice. (You can also combine them into one `(incr x by N)`.)

**Lowering**: `(<- (NAME (+ NAME N)))` / `(<- (NAME (- NAME N)))` — the same
sequential Q-named assignment `(set …)` produces.

## `(set-bit NAME N)` / `(clear-bit NAME N)` / `(toggle-bit NAME N)` — Single-Bit Manipulation

```lisp
(set-bit    ctrl 0)   ;; ctrl[0] <- 1   (e.g. an enable bit)
(clear-bit  irq  3)   ;; irq[3]  <- 0   (e.g. acknowledge / clear a flag)
(toggle-bit mode 7)   ;; mode[7] <- ~mode[7]
```

The bread-and-butter of control / status / configuration registers — set an
enable bit, clear an interrupt flag, flip a mode bit — expressed by intent rather
than by hand-written masks. `N` is a literal bit index counting from `0`, and
must be in range for the register (`0 <= N < width`).

This is a pure ISF parser desugar into a single-level masked
[`(set …)`](#update-var-expr--variable-modification), using only the supported
`.fsm` bitwise operators:

| Form | Desugars to | Mask |
| --- | --- | --- |
| `(set-bit x N)` | `(set x (\| x M))` | `M = 2^N` |
| `(toggle-bit x N)` | `(set x (^ x M))` | `M = 2^N` |
| `(clear-bit x N)` | `(set x (& x INV))` | `INV = (2^width - 1) ^ 2^N` |

The masks are emitted as plain literals (the backend widths them to the register)
and the expression is single-level — a deliberate choice, because a nested or
shift-based mask (`(<< 1 N)`, or `(^ x (& x M))`) produces an unsized 32-bit
intermediate that fails the width-clean lint, and bitwise-NOT (`~`) is not a
supported `.fsm` operator. `set-bit` / `toggle-bit` masks are width-independent;
`clear-bit`'s inverse mask needs the register's **width**, which is resolved from
its declaration — a transaction `(local …)`, an interface port, or a
`(storage (var …))`.

A complete runnable register-control example (each output reset to a known value,
one bit op each):

```lisp
(actor csr_ctl
  (interface (input start) (output done)
             (output en (width 8)) (output irq (width 8)) (output mode (width 8)))
  (transaction main
    (on start)
    (local e (width 8) (reset 0))
    (local i (width 8) (reset 255))
    (local m (width 8) (reset 0))
    (set-bit e 0)        ;; e:    0   -> 1     (0x01)
    (clear-bit i 3)      ;; i:    255 -> 247   (0xF7)
    (toggle-bit m 4)     ;; m:    0   -> 16    (0x10)
    (update en e)
    (update irq i)
    (update mode m)
    (complete done)))
```

After `start`, `en == 1`, `irq == 247`, and `mode == 16`. (The reset-value locals
rely on a register holding its value between writes — see
[Local Variables](./13m-local-variables.md).)

A malformed form fails closed before `.fsm` emission: a missing register name, a
missing / non-integer / multiple bit index, a bit index `>=` the register width,
or — for `clear-bit` — a register whose width is not a statically known literal
(e.g. a parameterized `(width W)`), since the inverse mask cannot then be formed.

> **Sequential bit ops compose.** Two bit ops on the same register
> (`(set-bit ctrl 0)` then `(set-bit ctrl 1)`) run as two sequential states, each
> with its own write-enable, so both bits end up set. (You can also write the
> combined mask directly with `(set ctrl (| ctrl 3))`.)

**Lowering**: `(<- (NAME (| NAME M)))` / `(<- (NAME (^ NAME M)))` /
`(<- (NAME (& NAME INV)))` — the sequential Q-named assignment `(set …)` produces.

## `(when-bit NAME N body…)` / `(unless-bit NAME N body…)` — Branch On A Bit

```lisp
(when-bit   ctrl 0  (start-engine))   ;; run body when ctrl[0] == 1
(unless-bit irq  3  (idle))           ;; run body when irq[3]  == 0
```

The read side of single-bit register intent — poll a status bit, branch on a
config / flag bit. `(when-bit …)` runs its body when bit `N` is **set**;
`(unless-bit …)` runs it when bit `N` is **clear**. `N` is a literal bit index,
`0 <= N < width`.

These are a pure ISF parser desugar into a `(when …)`
([Control Flow](./13d-control-flow.md)) with a **width-qualified** masked
comparison:

| Form | Desugars to |
| --- | --- |
| `(when-bit x N body…)` | `(when (!= (& x W'dMASK) W'd0) body…)` |
| `(unless-bit x N body…)` | `(when (== (& x W'dMASK) W'd0) body…)` |

where `MASK = 2^N` and `W` is the register's declared width. The sized literals
(`W'd…`) and the explicit `!=` / `==` are deliberate: an unsized literal mask
(`(& x 8)`) creates a 32-bit intermediate that fails the width-clean lint and a
multi-bit-truthiness mis-evaluation, while the sized masked comparison is
verilator-lint + yosys clean and correct. Because the mask is sized, `W` must be
a statically known literal (resolved from a `(local …)`, an interface port, or a
`(storage (var …))`) — a symbolic `(width W)` fails closed.

The body is a normal clause list, so it nests and composes with every other
construct (including a nested `(when-bit …)` and the bit ops above):

```lisp
(actor flag_poll
  (interface (input start) (input cfg (width 8)) (output done)
             (output engine (width 8)) (output sleep (width 8)))
  (transaction main
    (on start)
    (when-bit cfg 0          ;; bit 0 set => enabled
      (set-bit engine 0))
    (unless-bit cfg 0        ;; bit 0 clear => idle
      (set-bit sleep 0))
    (complete done)))
```

When `cfg[0]` is 1 the engine bit is set; when it is 0 the sleep bit is set.

A malformed form fails closed before `.fsm` emission: a missing name; a missing /
non-integer bit index; an index `>=` the register width; an empty body; or a
non-literal / symbolic width.

**Lowering**: `(?(!= (& NAME W'dMASK) W'd0) …)` /
`(?(== (& NAME W'dMASK) W'd0) …)` — the decision state a `(when …)` produces.

## `(set-field NAME (bits HI LO) VALUE)` — Multi-Bit Field Write

```lisp
(set-field ctrl (bits 5 3) 5)    ;; ctrl[5:3] <- 3'b101, other bits preserved
(set-field div  (bits 7 0) 24)   ;; div[7:0]  <- 24
```

The multi-bit generalisation of [`set-bit`](#set-bit-name-n--clear-bit-name-n--toggle-bit-name-n--single-bit-manipulation)
— write a named register field (a mode, a divider ratio, a priority level) to a
value, leaving the surrounding bits untouched. `HI` and `LO` are the literal
inclusive bit bounds (`HI >= LO`), and `VALUE` is a literal that must fit in the
`HI - LO + 1`-bit field.

This is a pure ISF parser desugar into a width-clean masked read-modify-write
`(set …)` built from sized literals:

```lisp
(set-field x (bits HI LO) V) -> (set x (| (& x W'dCLEARMASK) W'dSHIFTED))
  CLEARMASK = (2^width - 1) ^ (((2^(HI-LO+1)) - 1) << LO)   ;; field bits zeroed
  SHIFTED   = V << LO                                        ;; V placed in the field
```

The sized literals (`W'd…`) keep the nested `(| (& …) …)` verilator-lint + yosys
clean — an unsized mask would create a 32-bit intermediate that fails the
width-clean lint — so the register's **width** must be a statically known literal
(resolved from a `(local …)`, an interface port, or a `(storage (var …))`).

A complete runnable example (a control register whose `[5:3]` mode field is set
while the rest of the register is preserved):

```lisp
(actor mode_set
  (interface (input start) (output done) (output ctrl (width 8)))
  (transaction main
    (on start)
    (local r (width 8) (reset 255))   ;; 0xFF
    (set-field r (bits 5 3) 5)        ;; r[5:3] <- 101  =>  0xEF
    (update ctrl r)
    (complete done)))
```

After `start`, `ctrl == 239` (`0xEF`): bits `[5:3]` hold `101` and every other bit
keeps its `0xFF` value.

A malformed form fails closed before `.fsm` emission: a missing name; a malformed
`(bits HI LO)` selector; non-literal `HI` / `LO` / `VALUE`; `HI < LO`; `HI >=` the
register width; a `VALUE` that overflows the field; or a non-literal / symbolic
width. Two `(set-field …)` writes to the same register run as two sequential
read-modify-write states (each with its own write-enable), so writing two
disjoint fields back to back leaves both set.

**Lowering**: `(<- (NAME (| (& NAME W'dCLEARMASK) W'dSHIFTED)))` — the sequential
Q-named assignment `(set …)` produces.

## `(when-field NAME (bits HI LO) VALUE body…)` / `(unless-field …)` — Branch On A Field

```lisp
(when-field   mode (bits 2 0) 3  (enter-turbo))    ;; run body when mode[2:0] == 3
(unless-field mode (bits 2 0) 3  (enter-normal))   ;; run body when mode[2:0] != 3
```

The read/compare companion to
[`set-field`](#set-field-name-bits-hi-lo-value--multi-bit-field-write), and the
multi-bit generalisation of
[`when-bit`](#when-bit-name-n-body--unless-bit-name-n-body--branch-on-a-bit):
dispatch on a register's mode / level / selector field. `(when-field …)` runs its
body when the field equals `VALUE`; `(unless-field …)` runs it when it does not.

A pure ISF parser desugar into a `(when …)` with a width-qualified masked field
comparison (only the field's bits participate — the surrounding bits are masked
off):

| Form | Desugars to |
| --- | --- |
| `(when-field x (bits HI LO) V body…)` | `(when (== (& x W'dFIELDMASK) W'dSHIFTED) body…)` |
| `(unless-field x (bits HI LO) V body…)` | `(when (!= (& x W'dFIELDMASK) W'dSHIFTED) body…)` |

where `FIELDMASK = ((2^(HI-LO+1)) - 1) << LO` and `SHIFTED = V << LO`. As with the
other field / bit constructs, the sized literals require the register's width to
be a statically known literal (resolved from a `(local …)`, an interface port, or
a `(storage (var …))`).

```lisp
(actor mode_dispatch
  (interface (input start) (input mode (width 8)) (output done)
             (output turbo (width 8)) (output normal (width 8)))
  (transaction main
    (on start)
    (when-field   mode (bits 2 0) 3  (set-bit turbo 0))    ;; mode[2:0] == 3 -> turbo
    (unless-field mode (bits 2 0) 3  (set-bit normal 0))   ;; otherwise      -> normal
    (complete done)))
```

The comparison looks only at `mode[2:0]`, so `mode = 0xF3` (upper nibble set,
`mode[2:0] == 3`) still takes the `turbo` path.

A malformed form fails closed before `.fsm` emission: a missing name; a malformed
`(bits HI LO)` selector; non-literal `HI` / `LO` / `VALUE`; `HI < LO`; `HI >=` the
register width; a `VALUE` overflowing the field; an empty body; or a non-literal /
symbolic width.

**Lowering**: `(?(== (& NAME W'dFIELDMASK) W'dSHIFTED) …)` /
`(?(!= (& NAME W'dFIELDMASK) W'dSHIFTED) …)` — the decision state a `(when …)`
produces.

## `(shift_left reg bit [(width N)])` — Shift Register (Left)

```lisp
(shift_left rdata sda_in)
(shift_left rdata sda_in (width 8))
```

Shifts `reg` left by 1 and ORs in `bit` at LSB.

The form is exact: `(shift_left reg bit)` or
`(shift_left reg bit (width N))`, with scalar `reg`, scalar `bit`, and a
positive integer width when the option is present.

**Lowering**: `(<- (reg (| (<< reg 1) bit)))`, or `reg>` when `reg` is a
declared output port.

```lisp
(state
  (<- (rdata> (| (<< rdata 1) sda_in)))
  (-> next_state))
```

The emitted `.fsm` uses the normal expression surface: `<<` and `>>` are
supported binary operators through SystemVerilog generation, with `shl` and
`shr` as word aliases. When the shifted value is later used to drive a 1-bit
serial output, select the intended bit explicitly, for example
`(drive mosi tx_byte[7])`; FSMGen does not silently truncate an 8-bit word into
a 1-bit line.

An explicit `(width N)` is transaction-local width evidence for `reg`, not a
cast or resize. It may fill a missing width fact for later operations such as
`shift_right` and for schedule-report storage metadata, but it must match any
already-known width for the shifted register. Plain `(shift_left reg bit)`
remains accepted without width evidence because the left-shift expression does
not need a computed MSB insertion position.

**Use case**: I2C/SIPO — capturing serial bits into a parallel register.

## `(shift_right reg bit [(width N)])` — Shift Register (Right)

```lisp
(shift_right tx_reg msb_data)
(shift_right tx_reg msb_data (width 8))
```

Shifts `reg` right by 1 and ORs in `bit` at MSB.

The form is exact: `(shift_right reg bit)` or
`(shift_right reg bit (width N))`, with scalar `reg`, scalar `bit`, and
positive integer width when the option is present.

**Lowering**: `(<- (reg (| (>> reg 1) (<< bit width-1))))`

```lisp
(state
  (<- (tx_reg (| (>> tx_reg 1) (<< msb_data 7))))
  (-> next_state))
```

Known interface, sampled-source, assemble-inferred, and explicit
`(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)` widths use a concrete insert
position. If the shifted value has no known width and no explicit width
option, lowering fails before scheduled `.fsm` emission instead of emitting a
placeholder `WIDTH` expression. An explicit
`(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)` is an assertion: it may fill
missing width evidence, but it must match any already-known width for the
shifted register. `TX_PARAM` names a same-transaction scalar parameter default
on a generated child or direct/non-generated transaction and must resolve to a
positive integer. `PARAM` names an actor-local scalar parameter default that
resolves to a positive integer, and `CONST` names a declared actor constant
that resolves to a positive integer. Unrelated or cross-transaction
transaction parameters remain fail-closed for data-operation width evidence.

## `(assemble field1 field2 ... as var [(widths N...)])` — Concatenation

```lisp
(assemble header payload crc as packet)
(assemble header payload crc as packet (widths 4 8 4))
```

Concatenates fields into a single variable.

The form is exact:
`(assemble part... as var [(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)])`, with one or more
scalar parts and scalar target `var`.

When present, the optional trailing `(widths ...)` list must contain one
positive width per part, in the same order as the parts. Entries may be
positive integer literals, actor-local scalar parameter defaults, or declared
actor constants that resolve to positive integers.

**Lowering**: `(<- (var (concat field1 field2 ...)))`

```lisp
(state
  (<- (packet (concat header payload crc)))
  (-> next_state))
```

**Example — building a SPI frame**:
```lisp
(assemble cmd addr data as spi_frame)
```

When every part width is known, or the `(widths ...)` option supplies every
part width, `assemble` derives the target width from the part-width sum. If
exactly one part width is missing and the target width plus all sibling part
widths are known, FSMGen infers the missing part width as the positive
remainder. Explicit or inferred part widths remain available as
transaction-local evidence for later data operations, such as a following
`shift_right` on the assembled target or part. If the target already has a
known width, the final part-width sum must match it. A zero or negative
inferred remainder fails closed. Two or more unknown part widths may still
lower to the reviewable concat expression, but they are not used as width
evidence unless the `(widths ...)` option makes them known.

## `(extract word as field1 field2 ... [(widths N...)])` — Field Extraction

```lisp
(extract packet as header payload crc)
(extract packet as header payload crc (widths 4 8 4))
```

Deconstructs `word` into named fields. The form is exact:
`(extract word as field... [(widths N...)])`, with one scalar source word and
one or more scalar destination fields. The optional `(widths N...)` payload
must contain one positive integer width per field.

**Current lowering**: one extraction state is emitted.

When the source word and destination fields have known widths, or when the
extract clause supplies an ordered `(widths N...)` list matching the field
count, each field is assigned from an exact descending slice.

If exactly one destination field width is missing and the source word plus
every sibling field has known positive width, FSMGen infers the missing field
width as the positive remainder.

That inferred width remains available as transaction-local evidence for later
data operations, such as a following `shift_right` on the extracted field.

Two or more unknown field widths remain ambiguous and fail closed instead of
placeholder slice bounds.

Explicit widths must be positive integers and must not conflict with already
known field widths.

When the source word width is known, the sum of field widths must match it; a
zero or negative inferred remainder fails closed.

```lisp
(state
  (<= (header> (slice packet 15 12)))
  (<= (payload> (slice packet 11 4)))
  (<= (crc> (slice packet 3 0)))
  (-> next_state))
```

### Current Width Evidence Boundary

Before lowering a transaction, ISF builds one private width map from the whole
actor and transaction shape. Interface declarations and actor-owned
`(storage ...)` declarations seed that map, samples inherit known source
widths, explicit `shift_left`, `shift_right`, `assemble`, and `extract` width
options add local evidence, and `assemble` can infer its target width when all
parts are known or infer one missing part width from a known target and known
siblings.

This is
type/shape evidence, not cycle-value evidence, so it is not
source-order-sensitive inside the transaction.

Today this evidence is used to avoid `WIDTH`, `HIGH`, and `LOW` placeholders
for accepted migrated data operations. Schedule reports expose positive
integer `width` metadata for inferred scheduler counters and for register
storage whose ISF width evidence is known. They also expose optional `role`
metadata when the lowerer has stable evidence for the storage purpose,
including declared actor-owned storage, sampled aliases, extracted fields,
ordinary data registers, completion pulses, watchdog/latency/repeat counters,
and named-drive request/payload storage.

The planned precedence for this tree is declaration first: interface and
actor-owned storage declarations are hard width facts. Then come explicit
operation-local width options, sampled-alias propagation, structural
derivation from `assemble`/`extract`, and finally existing generated scheduler
storage for counter families. Explicit width options are assertions, not
silent casts: they may fill an unknown width, but they must agree with any
existing width fact for the same name.

Accepted migrated operation families do not emit `WIDTH`, `HIGH`, or `LOW`
placeholders. `extract` fails when field positions cannot be proven after the
single-missing-field inference rule.

`shift_right` fails when the shifted register width is missing or
contradictory. `shift_left` accepts optional width evidence and rejects
contradictory explicit widths while still accepting widthless shifts.

`assemble` accepts optional ordered part-width evidence, rejects known
target-width mismatches, rejects contradictory explicit part widths, and
rejects non-positive single-part inferred remainders.

## I2C Shift Register — Complete Example

```lisp
(transaction i2c_transfer
  (on start ...)
  ;; Capture 8 bits via shift register
  (repeat 8
    (drive scl 1)
    (shift_left rdata sda_in)
    (drive scl 0))
  (complete done))
```

Each cycle: SCL high → sample `sda_in` into `rdata` LSB → SCL low.

After 8 cycles: `rdata` contains the full byte.

## Complete Accept-Path Examples

### Bank Storage Access

```lisp
(actor bank_demo
  (storage
    (bank ram (width 8) (depth 4)))
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input wr_addr (width 2))
    (input wr_data (width 8))
    (output rd_data (width 8))
    (output done))
  (transaction tx
    (on start)
    (store ram wr_addr wr_data)
    (load ram wr_addr as rd_data)
    (complete done)))
```

**Walkthrough.** `(storage (bank ram (width 8) (depth 4)))`
declares one actor-owned 4-deep, 8-bit bank `ram`. The transaction
writes one cell with `(store ram wr_addr wr_data)` and reads it
back into the output `rd_data` with `(load ram wr_addr as rd_data)`.
The lowered schedule emits one cycle for the store, one for the
load, and one for the completion drive. `bank_accesses[]` in the
schedule report records both accesses and the scheduled `.fsm`
carries a scalarized `+size` family for the four cells.

### Data Assembly And Extraction

```lisp
(actor dataop_demo
  (storage
    (var packed (width 8))
    (var lo (width 4))
    (var hi (width 4)))
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction tx
    (on start)
    (assemble lo hi as packed (widths 4 4))
    (complete done)))
```

**Walkthrough.** Three storage variables: `lo` (4-bit), `hi`
(4-bit), and `packed` (8-bit). `(assemble lo hi as packed (widths 4
4))` concatenates `lo` (LSBs) and `hi` (MSBs) into `packed`. The
`(widths ...)` option asserts the per-field widths so the lowerer
can place each field at a concrete bit position. The transaction
runs the assembly once and completes. The reverse direction uses
`(extract packed (widths 4 4) (as lo hi))` — not shown here.
