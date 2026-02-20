# Context and Design Decisions: FSMGen Parser Modernization

**The Designer View:**
The `FSMGenFull.pm` adapter, written around earlier iterations of Lispish AST traversal, had evolved into a "God object" accumulating over 2,000 lines. The sheer complexity of evaluating syntactic tokens concurrently with abstract semantic routing meant any bugs across specific architectures (like MIPICSI or LTE cores) were impossible to trace without enormous cognitive load. By factoring this monolithic logic out using Solid design paradigms into discrete domains (`SignalManager`, `ExpressionBuilder`, `Parser`, `SignalAnalyzer`), the system is fundamentally cleaner to read and debug for subsequent FSM developers. 

**The Picky View & Execution Context:**
- We discovered recursive edge cases deep in the Lispish parser logic (like `mipicsi2_txdcore_hs.fsm` leveraging complex `?(| a b c)` expressions). Because boolean AST nodes were intrinsically nested as arrays with leading operands rather than binary trees, the original parsing routinely passed implicit `undef` signal tags downward, terminating FSM instantiation silently and destroying the FSM output state block.
- A profound Perl compiler behavioral quirk was also identified. Syntaxes using `bless { var => $val // die "msg", next_var => "test" }` behave erroneously; the unparenthesized `die` falls into list-context logic and assumes trailing keys/values as function parameters! By meticulously enforcing `Carp::confess` execution with strict parenthesis, this unhinged bug is permanently neutralized.
- Moving forward, all FSM compiler faults trigger strict `Carp::confess` bindings, surfacing precise stack traces. This directly prevents topological macro implementations matching silently and crashing.

**Architectural Choices:**
We chose a `Test::More` based IPC regression script over in-memory mocking for `t/01-regression.t` to ensure the compilation environment exactly perfectly mimics the target `SV` deployment. By aggressively ignoring the user-facing output directory `Entities/*` alongside a `File::Temp` interceptor, the automated suite leaves zero environment footprint. We chose not to test `generic_fifo.fsm` during regression as it employs topological module instantiation headers rather than parseable raw sequential states.
