# Context and Design Decisions: FSMGen Parser Modernization

**The Designer View:**
The `FSMGenFull.pm` adapter, written around earlier iterations of Lispish AST traversal, had evolved into a "God object" accumulating over 2,000 lines. The sheer complexity of evaluating syntactic tokens concurrently with abstract semantic routing meant any bugs across specific architectures (like MIPICSI or LTE cores) were impossible to trace without enormous cognitive load. By factoring this monolithic logic out using Solid design paradigms into discrete domains (`SignalManager`, `ExpressionBuilder`, `Parser`, `SignalAnalyzer`), the system is fundamentally cleaner to read and debug for subsequent FSM developers. 

**The Picky View & Execution Context:**
- We discovered recursive edge cases deep in the Lispish parser logic (like `mipicsi2_txdcore_hs.fsm` leveraging complex `?(| a b c)` expressions). Because boolean AST nodes were intrinsically nested as arrays with leading operands rather than binary trees, the original parsing routinely passed implicit `undef` signal tags downward, terminating FSM instantiation silently and destroying the FSM output state block.
- A profound Perl compiler behavioral quirk was also identified. Syntaxes using `bless { var => $val // die "msg", next_var => "test" }` behave erroneously; the unparenthesized `die` falls into list-context logic and assumes trailing keys/values as function parameters! By meticulously enforcing `Carp::confess` execution with strict parenthesis, this unhinged bug is permanently neutralized.
- Moving forward, all FSM compiler faults trigger strict `Carp::confess` bindings, surfacing precise stack traces. This directly prevents topological macro implementations matching silently and crashing.

**Architectural Choices:**
We chose a `Test::More` based IPC regression script over in-memory mocking for `t/01-regression.t` to ensure the compilation environment exactly perfectly mimics the target `SV` deployment. By aggressively ignoring the user-facing output directory `Entities/*` alongside a `File::Temp` interceptor, the automated suite leaves zero environment footprint. We chose not to test `generic_fifo.fsm` during regression as it employs topological module instantiation headers rather than parseable raw sequential states.

# Context and Design Decisions: FSMGen Environment decoupling and CI Setup

**The Designer View:**
The FSMGen compiler originally hardcoded rigid absolute paths to a separate `pgen` package assuming it would permanently exist at `../pgen/fx`. Rather than contorting the tool into requiring an environment `$PGEN_HOME` configuration which bloats execution, we verified the repository can self-resolve these dependencies via `PathSearch.pm` assuming the `specs/` and `plugin/` folders exist locally in the `cwd`. Integrating these directly into the file system yields a self-contained, frictionless Perl FSM toolkit immediately accessible out of the box.

**Architectural Choices:**
We introduced a GitHub Actions `.yml` workflow binding `prove t/01-regression.t` strictly to PR events. This natively integrates the isolated `Test::More` IPC wrapper suite into the repo's lifecycle, ensuring all future core Perl `.pm` parser development maintains topological API compilation compatibility across Linux runners mechanically.
