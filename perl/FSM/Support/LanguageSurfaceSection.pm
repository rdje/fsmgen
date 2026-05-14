package FSM::Support::LanguageSurfaceSection;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::LanguageSurfaceContract qw(build_language_surface_contract);

our @EXPORT_OK = qw(
    build_language_surface_section
);

sub build_language_surface_section {
    return {
        strict_mode => {
            intended_for_generated_fsm => JSON::PP::true,
            compatibility_syntax_is_canonical => JSON::PP::false,
            canonical_direct_roots => [qw(?fsm ?dt ?mod)],
            canonical_composition_roots => [qw(?top ?rtlif ?pkg)],
            canonical_child_roots => [qw(?fsmc ?dtc ?rtl)],
        },
        default_mode_compatibility => {
            accepted_but_not_canonical_for_generated_output => [
                '+fsm root family',
                '?module direct root alias',
                'empty (+size) section',
                '(asreset rstn) reset spelling',
                '(sreset rstn) reset spelling',
                'compact (:= signal=value) init/default directive',
                'infix assignment forms such as (OUT = SRC)',
                'legacy child roots under ?fsmc / ?dtc',
            ],
        },
        assignments => {
            canonical_pair_forms => [qw(= <- <= <-= <=- <N)],
            canonical_lhs_pack_forms => [qw(concat cat)],
            canonical_rhs_pack_forms => [qw(concat cat)],
            compatibility_forms => [
                'infix assignment forms',
                'legacy <=+ assignment operator alias for <=-',
            ],
        },
        system_contracts => {
            canonical_clock => '(clock clk)',
            canonical_synchronous_reset => '(sreset reset)',
            canonical_asynchronous_reset => '(areset rst_n)',
            legacy_or_misleading_reset_forms_rejected_in_strict => [
                '(asreset rstn)',
                '(sreset rstn)',
            ],
        },
        expressions => {
            guard_forms => [
                'guarded blocks such as (<req ...) and (<!hold ...)',
                'condition suffixes such as (-> busy <start) and (= (OUT IN) <(& valid ready))',
                'non-state DT DTE headers such as (-route <req ...) and (-mode_hit <mode=3 ...)',
                'compact comparison guards use the existing name<op>value grammar',
            ],
            scalar_constant_expression_operators => [qw(+ - * / % & | ^ add sub mul div mod and or xor)],
            runtime_expression_operators => [qw(+ - * / % & | ^ && || == != < <= > >= !)],
            test_node_selectors => [
                'explicit operator-prefixed selectors such as =0, !=8\'0, <8\'4, <=8\'3, >8\'3, and >=8\'1',
                'single fallback selector spelled default or _',
                'fallback selector condition is logical NOT of the OR of all explicit sibling selector predicates',
            ],
            literal_families => [
                'decimal',
                '0d decimal',
                '0b binary',
                '0o octal',
                '0x hex',
                'SystemVerilog based literals',
                q{FSMGen intent-sized literals like 5'23, 8'-10, 8'-0xA, 8'-0b1010, and 20'x1},
            ],
        },
        declarations => {
            scalar_and_aggregate_names => [qw(+constants +enums +params +types +define +import)],
            width_declarations => ['+size with positive integer literal or constant expression terms'],
            package_roots => ['?pkg reusable scalar/aggregate/type/enum declarations'],
        },
        composition => {
            top_root => '?top',
            generated_children => [qw(?fsmc ?dtc)],
            external_rtl_children => ['?rtl with ?rtlif sidecar or embedded metadata'],
            wiring => ['?ports', '?toplink', '=port connect-by-name'],
            lanes => [qw(C1 C2 C3 C4)],
        },
        intentionally_blocked_or_not_yet_public => [
            'VHDL backend generation',
            'unchecked annotations treated as enforced metadata',
            'full normalized semantic JSON export beyond the bounded public semantic JSON slice',
            'full check-only JSON diagnostic schema stabilization',
            'unbounded aggregate expression domains',
            'SPECFORGE PDF/prose IntentIR extraction',
        ],
        surface_contract => build_language_surface_contract(),
    };
}

1;
