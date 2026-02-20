# FSMGen parser refactoring and error handling modernization

*   **FSMGenFull Monolith Decomposition:**
    *   Removed `perl/FSM/Adapter/FSMGenFull.pm` 2.1k line execution and rewrote it as a facade orchestrating 4 distinct parsing sub-modules.
    *   Created `FSM::Adapter::FSMGenFull::SignalManager`: responsible for traversing the topology and registering input/output signals dynamically, factoring away symbol registry properties.
    *   Created `FSM::Adapter::FSMGenFull::ExpressionBuilder`: extracts complex nested expressions and factors them iteratively into isolated combinational intermediates to ensure correct multi-width matching and syntax.
    *   Created `FSM::Adapter::FSMGenFull::Parser`: Dispatches states and action elements across decision-trees cleanly using topological semantics.
    *   Created `FSM::Adapter::FSMGenFull::SignalAnalyzer`: Passes over the completely unified FSMModule AST after instantiation to correctly verify all assignments and dependencies.

*   **Lispish Nested Expression AST Parsing:**
    *   Mitigated a subtle implicit array traversal failure in the Lispish string representation parsing logic.
    *   `?(| is_fe2fs is_le2ls is_pf2ph)` in `mipicsi` was throwing AST errors because group conditions returned layered Arrays. Handled via the AST Extractor to route recursive boolean logic cleanly.

*   **CoreAST Perl Hash Execution Fix:**
    *   Replaced subtle but lethal `$hash->{target} = $source // die "err",` constructor logic over 20+ files. The un-parenthesized `die` syntax was covertly swallowing successive hash keys due to list-context parsing, destroying AST object properties.

*   **Regression Infrastructure:**
    *   Removed untested unused classes (`ASTv1.pm` -> `ASTv5.pm`).
    *   Built `t/01-regression.t` running `Test::More` IPC wrapper verifying end-to-end `fsmgen` translation across `fsm/*.fsm` directory instances, safely ignoring templates (`generic_fifo.fsm`).

*   **Tracing Standardisation:**
    *   Replaced scattered string `die` statements across `FSM/` module structure with rigorously scoped stack-tracing via `Carp::confess` tracing libraries.

# FSMGen Environment decoupling and GitHub CI Setup

*   **PGen Decoupling:**
    *   FSMGen dependencies (`specs/` and `plugin/`) have been adopted natively into the file system out of the `pgen/fx` external dependency path.
    *   Removed `PPlugin.pm` `$top, '..', 'pgen', 'fx', 'plugin'` hotfix.
    *   Removed `PathSearch.pm` hardcoded `../pgen` `@INC` addition.
    *   Removed `FindBin` relative path from `bin/fsmgen`. 
    *   All parsing is fully independent and dynamically resolved from the `cwd` or execution context!

*   **Repository Onboarding:**
    *   Drafted `README.md` at project root covering execution semantics, options, CI/CD testing guarantees and syntax pointing toward `WARP.md`.

*   **Continuous Automation:**
    *   Adopted `ubuntu-latest` GitHub Runner deploying Perl `5.32`.
    *   Configured `.github/workflows/regression.yml` to trigger on PRs enforcing 100% green compliance of the IPC `01-regression.t` parsing suite against `fsm/`.
