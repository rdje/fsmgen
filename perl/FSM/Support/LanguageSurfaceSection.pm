package FSM::Support::LanguageSurfaceSection;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::LanguageSurfaceContract qw(
    build_language_surface_contract
    language_surface_file_surface_entry_keys
);

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
        file_surfaces => {
            shipped_suffixes => [qw(.fsm .isf .ppif)],
            layer_order => [qw(IAL2 IAL1 IAL0)],
            direct_ial2_to_ial0_allowed => JSON::PP::false,
            entry_presence_keys => language_surface_file_surface_entry_keys(),
            entries => [
                {
                    suffix => '.fsm',
                    intent_layer => 'IAL0',
                    status => 'shipped',
                    role => 'explicit cycle-authored review artifact and direct HDL input',
                    lowers_to => [],
                    generated_review_artifacts => [],
                    supported_cli_modes => [
                        'default HDL generation',
                        '--check --json / --check-json',
                        '--emit-semantic-json',
                        '--verify-hdl',
                    ],
                    sample_path => 'fsm/trial_0.fsm',
                    current_boundary => 'direct authored .fsm input remains the IAL0 review artifact and HDL source path',
                },
                {
                    suffix => '.isf',
                    intent_layer => 'IAL1',
                    status => 'shipped',
                    role => 'Intent Scheduling Format source that lowers to reviewable .fsm before HDL',
                    lowers_to => ['.fsm'],
                    generated_review_artifacts => ['.fsm'],
                    supported_cli_modes => [
                        'default HDL generation',
                        '--outdir',
                        '--emit-verification-output uvm-passive-monitor --verification-outdir',
                        '--emit-verification-output vhdl-observation-package --verification-outdir',
                        '--emit-schedule-json',
                        '--check --json / --check-json',
                        '--emit-semantic-json',
                        '--verify-hdl',
                    ],
                    sample_path => 'isf/apb_requester.isf',
                    current_boundary => 'shipped ISF parser/scheduler subsets lower through generated .fsm review artifacts',
                },
                {
                    suffix => '.ppif',
                    intent_layer => 'IAL2',
                    status => 'shipped_bounded_public',
                    role => 'Protocol/Platform Intent Format source that lowers to generated .isf before generated .fsm',
                    lowers_to => ['.isf', '.fsm'],
                    generated_review_artifacts => ['.isf', '.fsm'],
                    supported_cli_modes => [
                        'default HDL generation',
                        '--outdir',
                        '--emit-schedule-json',
                        '--check --json / --check-json',
                        '--emit-semantic-json',
                        '--verify-hdl',
                    ],
                    sample_path => 'ppif/axi_aw_valid_ready.ppif',
                    current_boundary => 'bounded public .ppif is the generic Protocol/Platform Intent Format IAL2 container; AXI is the first shipped IAL2 profile/example, not the definition of IAL2; future protocol-specific suffixes such as .axi, .chi, .ace, .ahb, .apb, .atb, .smbus, or .i2s are profile aliases over IAL2 rather than separate layers; common IAL2 constructs stay small until compatible reuse is proven across multiple profiles; every .ppif path lowers through generated .isf before generated .fsm. Current bounded .ppif coverage includes one-channel Valid-Ready sources including the AXI AW first-profile sample and the protocol-neutral valid-ready handshake sample, multi-channel Valid-Ready bundles, and one-object AXI manager capacity/status sources. Support-accounted AXI manager coverage includes capacity/status, ID-family metadata, transaction envelopes and fan-in, concrete-ID assertions, bounded auto-ID lifecycle, same-ID reject and issue-order-queue policy, generated auto-ID write/read response-demux, generated single/last/multi-beat read-data capture, burst-length/runtime validation, scalar RRESP aggregation, one-or-more read burst-last queue-head groups, one-or-more write queue-head groups, read single-beat and read burst-last queue-head response-demux including multiple/mixed depth-3 scalar, raw-ARLEN, runtime-validation, and multi-beat output-bank read-data groups, same-family mixed auto-ID plus concrete queue-head response-demux with scalar, raw-ARLEN, runtime-validation, and multi-beat output-bank read-data over the selected read burst-last shape, generated single-active and multiple all-dynamic write/read response-demux, generated all-dynamic same-ID issue-order queues for selected write BID, read single-beat RID, and read burst-last RID/RLAST depth-2/depth-3 shapes, selected read-data, raw-ARLEN, runtime-validation, and multi-beat output-bank behavior over generated all-dynamic read burst-last issue-order queues, generated mixed dynamic/static response-demux families, generated one-dynamic plus one-concrete-static mixed dynamic/static same-ID issue-order queue behavior for write BID, read single-beat RID, and read burst-last RID/RLAST, generated one-dynamic plus two-concrete-static mixed dynamic/static write BID same-ID issue-order queue behavior, paired scalar read-data over the generated mixed read single-beat and burst-last queue completions, report-only raw-ARLEN burst-length capture, runtime beat-count/RLAST validation, and runtime-validation multi-beat output banks over the generated mixed read burst-last queue completion. Broader mixed issue-order queue cardinality beyond that selected write BID multi-static shape, scoreboards, group-local simultaneous enqueue widening, packed burst-vector outputs, alternate full burst payload assembly, aliases, platform clauses, full AXI manager behavior, direct backend lowering, verification-output generation, backend-language variants, and VHDL remain deferred',
                },
            ],
            unsupported_first_slice_aliases => [qw(.pif .ppi .axi .chi .ace .ahb .apb .atb)],
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
                'legacy <=+ assignment operator alias for <=-',
                'composition ?wiring /source/target/ slash-link tokens',
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
            canonical_clock => '(clock NAME), where NAME is an HDL identifier; examples use clk',
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
                'state DT DTE headers such as (idle <entry_event ...) and non-state DT DTE headers such as (-route <req ...)',
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
            width_declarations => [
                '+size with positive integer literal or constant expression terms',
                '+types (bits WIDTH_SYMBOL) with positive integer scalar constants or enum members',
            ],
            package_roots => ['?pkg reusable scalar/aggregate/type/enum declarations'],
        },
        composition => {
            top_root => '?top',
            generated_children => [qw(?fsmc ?dtc)],
            external_rtl_children => ['?rtl with ?rtlif sidecar or embedded metadata'],
            wiring => ['?ports', '?wiring', '=port connect-by-name'],
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
