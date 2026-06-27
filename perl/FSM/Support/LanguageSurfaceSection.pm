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
            shipped_suffixes => [qw(.fsm .isf .ppif .axi .apb)],
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
                    current_boundary => join(' ',
                        'bounded public .ppif is the generic Protocol/Platform Intent Format IAL2 container; AXI is the first shipped IAL2 profile/example, not the definition of IAL2; .axi is now the first profile-alias file surface over the same IAL2 model, .apb is now the bounded APB requester-transfer/completer/fixed-composition plus busy-capable and status-capable requester/composition profile-alias file surface, and additional protocol-specific suffixes such as .chi, .ace, .ahb, .atb, .smbus, or .i2s remain future profile aliases rather than separate layers; common IAL2 constructs stay small until compatible reuse is proven across multiple profiles; every .ppif path lowers through generated .isf before generated .fsm.',
                        'Current bounded .ppif coverage includes one-channel Valid-Ready sources including the AXI AW first-profile sample and the protocol-neutral valid-ready handshake sample, the AXI AW/W multi-channel Valid-Ready bundle, the protocol-neutral dual-channel Valid-Ready bundle, the APB requester-transfer source, the APB busy-capable requester-transfer source, the APB status-capable requester-transfer source, the APB completer source, the one-requester/one-completer APB composition source, the busy-capable one-requester/one-completer APB composition source, the status-capable one-requester/one-completer APB composition source, and one-object AXI manager capacity/status sources.',
                        'Current bounded .apb coverage mirrors the APB requester-transfer, APB busy-capable requester-transfer, APB status-capable requester-transfer, APB completer, one-requester/one-completer APB composition, busy-capable one-requester/one-completer APB composition, and status-capable one-requester/one-completer APB composition .ppif sources through support-accounted profile-alias fixtures.',
                        'Support-accounted AXI manager coverage includes capacity/status, ID-family metadata, transaction envelopes and fan-in, concrete-ID assertions, bounded auto-ID lifecycle, same-ID reject and issue-order-queue policy, generated auto-ID write/read response-demux, generated single/last/multi-beat read-data capture, burst-length/runtime validation, scalar RRESP aggregation, one-or-more read burst-last queue-head groups, one-or-more write queue-head groups, read single-beat and read burst-last queue-head response-demux including multiple/mixed depth-3 scalar, raw-ARLEN, runtime-validation, and multi-beat output-bank read-data groups, same-family mixed auto-ID plus concrete queue-head response-demux with scalar, raw-ARLEN, runtime-validation, and multi-beat output-bank read-data over the selected read burst-last shape, generated single-active and multiple all-dynamic write/read response-demux, generated all-dynamic same-ID issue-order queues for selected write BID, read single-beat RID, and read burst-last RID/RLAST depth-2/depth-3 shapes, selected read-data, raw-ARLEN, runtime-validation, and multi-beat output-bank behavior over generated all-dynamic read burst-last issue-order queues, generated mixed dynamic/static response-demux families, generated one-dynamic plus one-concrete-static mixed dynamic/static same-ID issue-order queue behavior for write BID, read single-beat RID, and read burst-last RID/RLAST, generated one-dynamic plus two-concrete-static mixed dynamic/static write BID same-ID issue-order queue behavior, paired scalar read-data over the generated mixed read single-beat and burst-last queue completions, report-only raw-ARLEN burst-length capture, runtime beat-count/RLAST validation, and runtime-validation multi-beat output banks over the generated mixed read burst-last queue completion.',
                        'Broader mixed issue-order queue cardinality beyond that selected write BID multi-static shape, multi-peripheral APB interconnect/decode, APB sidebands, scoreboards, group-local simultaneous enqueue widening, packed burst-vector outputs, alternate full burst payload assembly, aliases beyond .axi and .apb, platform clauses, full AXI manager behavior, direct backend lowering, verification-output generation, backend-language variants, and VHDL remain deferred',
                    ),
                },
                {
                    suffix => '.axi',
                    intent_layer => 'IAL2',
                    status => 'shipped_bounded_profile_alias',
                    role => 'AXI profile-alias source over the same IAL2 Protocol/Platform Intent model',
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
                    sample_path => 'ppif/axi_aw_valid_ready.axi',
                    current_boundary => 'bounded public .axi is the first IAL2 profile-alias suffix and is intentionally only an AXI example over IAL2, not the definition of IAL2. .axi sources use the same protocol-platform-intent form as .ppif, must declare an explicit AXI-family profile axi, axi3, axi4, or axi5, and lower through generated .isf before generated .fsm. The first support-accounted alias fixture mirrors ppif/axi_aw_valid_ready.ppif at ppif/axi_aw_valid_ready.axi and generates axi_aw_valid_ready_monitor. Non-AXI profiles such as valid-ready are rejected as suffix/profile mismatches for .axi. .chi, .ace, .ahb, .atb, .smbus, .i2s, .pif, and .ppi remain unsupported. Direct IAL2-to-IAL0 lowering remains forbidden.',
                },
                {
                    suffix => '.apb',
                    intent_layer => 'IAL2',
                    status => 'shipped_bounded_profile_alias',
                    role => 'APB profile-alias source over the same IAL2 Protocol/Platform Intent model',
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
                    sample_path => 'ppif/apb_requester_transfer.apb',
                    current_boundary => join(' ',
                        'bounded public .apb is the APB requester-transfer, busy-capable APB requester-transfer, status-capable APB requester-transfer, APB completer, fixed one-requester/one-completer APB composition, busy-capable fixed APB composition, and status-capable fixed APB composition IAL2 profile-alias suffix.',
                        '.apb sources use the same protocol-platform-intent form as .ppif, must declare explicit (profile apb), support exactly one (apb-requester apb_requester ...) with optional response (busy NAME) and selected busy-gated (status NAME width 2), exactly one (apb-completer apb_completer ...), or the explicit one-requester/one-completer/(apb-composition apb_tb ...) shape in this slice, and lower through generated .isf before generated .fsm.',
                        'The support-accounted alias fixtures mirror ppif/apb_requester_transfer.ppif, ppif/apb_requester_transfer_busy.ppif, ppif/apb_requester_transfer_status.ppif, ppif/apb_completer.ppif, ppif/apb_composition.ppif, ppif/apb_composition_busy.ppif, and ppif/apb_composition_status.ppif at ppif/apb_requester_transfer.apb, ppif/apb_requester_transfer_busy.apb, ppif/apb_requester_transfer_status.apb, ppif/apb_completer.apb, ppif/apb_composition.apb, ppif/apb_composition_busy.apb, and ppif/apb_composition_status.apb.',
                        'They generate HDL modules apb_requester, apb_completer, and composition top apb_tb respectively; busy-capable requester and composition aliases add the requester busy output, and status-capable requester and composition aliases add busy plus a 2-bit requester status output.',
                        'Non-APB profiles are rejected as suffix/profile mismatches for .apb. Multi-peripheral APB interconnect/decode, sidebands, alternate widths, back-to-back policy, direct IAL2-to-IAL0 lowering, direct backend lowering, verification-output generation, backend-language variants, and VHDL remain deferred.',
                    ),
                },
            ],
            unsupported_first_slice_aliases => [qw(.pif .ppi .chi .ace .ahb .atb .smbus .i2s)],
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
