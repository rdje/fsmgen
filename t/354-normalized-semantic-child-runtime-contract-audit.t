#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_child_parameter_override_entry_keys
    normalized_semantic_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_presence_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_assertion_keys
    normalized_semantic_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
);
use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_composition_child_entry_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_keys
);
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_structural_rtl_ir_presence_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_presence_keys
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_presence_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'symbol-rich direct semantic payload keeps bounded child-owner contracts at runtime' => sub {
    my $decoded = run_semantic_json('t/corpus/direct_size_expression_widths.fsm');
    my $semantic = $decoded->{semantic};

    assert_keys_present(
        $semantic->{module},
        normalized_semantic_module_presence_keys(),
        'symbol-rich direct semantic.module keeps bounded core keys',
    );
    assert_keys_absent(
        $semantic->{module},
        [grep { /^composition_/ } @{normalized_semantic_module_optional_metric_keys() || []}],
        'symbol-rich direct semantic.module omits composition-specific metric keys',
    );
    assert_keys_present(
        $semantic->{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'symbol-rich direct semantic.system_contract keeps bounded keys',
    );

    ok(
        ref($semantic->{explicit_system_contract}) eq 'HASH',
        'symbol-rich direct semantic.explicit_system_contract is present as a hash',
    );
    assert_keys_present(
        $semantic->{explicit_system_contract},
        normalized_semantic_explicit_system_contract_presence_keys(),
        'symbol-rich direct semantic.explicit_system_contract keeps bounded keys',
    );

    assert_signal_analysis_contract(
        $semantic->{signal_analysis},
        'symbol-rich direct semantic.signal_analysis keeps bounded buckets and entry keys',
    );

    assert_keys_present(
        $semantic->{forward_ir},
        normalized_semantic_forward_ir_presence_keys(),
        'symbol-rich direct semantic.forward_ir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_presence_keys(),
        'symbol-rich direct semantic.forward_ir.intent_hir keeps bounded keys',
    );
    assert_keys_absent(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_optional_composition_keys(),
        'symbol-rich direct semantic.forward_ir.intent_hir omits composition-only keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'symbol-rich direct semantic.forward_ir.lowered_rtl_ir keeps bounded keys',
    );
    assert_keys_absent(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'symbol-rich direct semantic.forward_ir.lowered_rtl_ir omits composition-only keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{structural_rtl_ir},
        normalized_semantic_structural_rtl_ir_presence_keys(),
        'symbol-rich direct semantic.forward_ir.structural_rtl_ir keeps bounded keys',
    );

    ok(
        ref($semantic->{symbol_contract}) eq 'HASH',
        'symbol-rich direct semantic.symbol_contract is present as a hash',
    );
    assert_keys_present(
        $semantic->{symbol_contract},
        normalized_semantic_symbol_contract_presence_keys(),
        'symbol-rich direct semantic.symbol_contract keeps bounded keys',
    );
    ok(
        !exists $semantic->{composition},
        'symbol-rich direct semantic payload omits the optional composition branch',
    );
};

subtest 'standalone dt semantic payload keeps bounded multi-drive entry schemas at runtime' => sub {
    my $dt_path = write_fsm('standalone_dt_semantic_multi_drive_schema.fsm', <<'DT');
(?dt:standalone_dt_semantic_multi_drive_schema
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (= (OUT A))
    )
  )
  (-from_b
    (<SEL==1'b1
      (= (OUT B))
    )
  )
)
DT

    my $decoded = run_semantic_json($dt_path);
    my $lowered_rtl_ir = $decoded->{semantic}{forward_ir}{lowered_rtl_ir};

    assert_keys_present(
        $lowered_rtl_ir,
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'standalone dt semantic.forward_ir.lowered_rtl_ir keeps bounded shell keys',
    );
    assert_keys_absent(
        $lowered_rtl_ir,
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'standalone dt semantic.forward_ir.lowered_rtl_ir omits composition-only keys',
    );
    is(
        $lowered_rtl_ir->{standalone_dt_multi_drive_target_count},
        1,
        'standalone dt semantic.forward_ir.lowered_rtl_ir reports one multi-drive target',
    );
    ok(
        ref($lowered_rtl_ir->{standalone_dt_multi_drive_targets}) eq 'ARRAY',
        'standalone dt semantic.forward_ir.lowered_rtl_ir emits a multi-drive target array',
    );

    my $target = $lowered_rtl_ir->{standalone_dt_multi_drive_targets}[0];
    assert_exact_keys(
        $target,
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'standalone dt multi-drive target entry keeps the bounded key schema',
    );
    assert_exact_keys(
        $target->{multi_drive_assertion},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'standalone dt multi-drive assertion keeps the bounded key schema',
    );
};

subtest 'composition semantic payload keeps bounded shared-datapath candidate schemas at runtime' => sub {
    my $composition_path = write_fsm('shared_datapath_semantic_schema.fsm', <<'FSM');
(?top:shared_datapath_semantic_schema
  (?ports:public_io
    clk
    reset
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?wiring:wiring
    (left.status_bus left_status)
    (right.status_bus right_status)
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (<= (status_bus> 8'1))
  )
  (+size
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (<= (status_bus> 8'2))
  )
  (+size
    (status_bus 8)
  )
)
FSM

    my $decoded = run_semantic_json($composition_path);
    my $composition = $decoded->{semantic}{composition};
    my $lowered_rtl_ir = $decoded->{semantic}{forward_ir}{lowered_rtl_ir};

    assert_keys_present(
        $lowered_rtl_ir,
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'composition semantic.forward_ir.lowered_rtl_ir keeps bounded shell keys',
    );
    assert_keys_present(
        $lowered_rtl_ir,
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'composition semantic.forward_ir.lowered_rtl_ir keeps composition-only keys',
    );
    is(
        $lowered_rtl_ir->{composition_shared_datapath_candidate_count},
        1,
        'composition semantic.forward_ir.lowered_rtl_ir reports one shared-datapath candidate',
    );
    ok(
        ref($lowered_rtl_ir->{composition_shared_datapath_candidates}) eq 'ARRAY',
        'composition semantic.forward_ir.lowered_rtl_ir emits a shared-datapath candidate array',
    );

    my $candidate = $lowered_rtl_ir->{composition_shared_datapath_candidates}[0];
    is_deeply(
        $composition->{shared_datapath_candidates},
        $lowered_rtl_ir->{composition_shared_datapath_candidates},
        'composition semantic.composition.shared_datapath_candidates aliases the lowered-RTL candidate surface',
    );
    assert_exact_keys(
        $composition->{shared_datapath_candidates}[0],
        normalized_semantic_composition_shared_datapath_candidate_entry_keys(),
        'composition shared-datapath candidate alias keeps the bounded entry key schema',
    );
    assert_exact_keys(
        $composition->{shared_datapath_candidates}[0]{multi_value_assertion},
        normalized_semantic_composition_shared_datapath_assertion_keys(),
        'composition shared-datapath candidate alias multi-value assertion keeps the bounded key schema',
    );
    assert_exact_keys(
        $composition->{shared_datapath_candidates}[0]{contributors}[0],
        normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys(),
        'composition shared-datapath candidate alias contributor keeps the bounded contributor key schema',
    );
    assert_exact_keys(
        $composition->{shared_datapath_candidates}[0]{contributors}[0]{bound_connection_expr},
        normalized_semantic_composition_shared_datapath_bound_connection_expr_keys(),
        'composition shared-datapath candidate alias contributor bound_connection_expr keeps the bounded schema',
    );
    assert_exact_keys(
        $composition->{shared_datapath_candidates}[0]{contributors}[0]{drive_intent},
        normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        'composition shared-datapath candidate alias contributor drive_intent keeps the bounded schema',
    );
    if (@{$composition->{shared_datapath_candidates}[0]{contributors}[0]{drive_intent}{rhs_enable_families} || []}) {
        assert_exact_keys(
            $composition->{shared_datapath_candidates}[0]{contributors}[0]{drive_intent}{rhs_enable_families}[0],
            normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            'composition shared-datapath candidate alias contributor drive_intent rhs_enable_families keep the bounded schema',
        );
    }
    if (@{$composition->{shared_datapath_candidates}[0]{aggregate_enable_families} || []}) {
        assert_exact_keys(
            $composition->{shared_datapath_candidates}[0]{aggregate_enable_families}[0],
            normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            'composition shared-datapath candidate alias aggregate_enable_families keep the bounded schema',
        );
    }
    assert_exact_keys(
        $candidate,
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        'shared-datapath candidate keeps the bounded entry key schema',
    );
    assert_exact_keys(
        $candidate->{multi_value_assertion},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        'shared-datapath candidate multi-value assertion keeps the bounded key schema',
    );

    ok(ref($candidate->{contributors}) eq 'ARRAY', 'shared-datapath candidate emits contributor entries');
    is($candidate->{contributor_count}, 2, 'shared-datapath candidate reports two contributors');
    for my $index (0 .. $#{$candidate->{contributors} || []}) {
        my $contributor = $candidate->{contributors}[$index];
        my $label = "shared-datapath contributor $index";

        assert_exact_keys(
            $contributor,
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            "$label keeps the bounded contributor key schema",
        );
        assert_exact_keys(
            $contributor->{bound_connection_expr},
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            "$label bound_connection_expr keeps the bounded key schema",
        );
        assert_exact_keys(
            $contributor->{output_drive_family},
            normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
            "$label output_drive_family keeps the existing bounded output-drive schema",
        );
        if (@{$contributor->{output_drive_family}{rhs_enable_families} || []}) {
            assert_exact_keys(
                $contributor->{output_drive_family}{rhs_enable_families}[0],
                normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
                "$label output_drive_family rhs_enable_families keep the existing bounded schema",
            );
        }
        assert_exact_keys(
            $contributor->{drive_intent},
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            "$label drive_intent keeps the bounded drive-intent schema",
        );
        if (@{$contributor->{drive_intent}{rhs_enable_families} || []}) {
            assert_exact_keys(
                $contributor->{drive_intent}{rhs_enable_families}[0],
                normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
                "$label drive_intent rhs_enable_families keep the bounded schema",
            );
        }
        assert_keys_present(
            $contributor->{intent_hir},
            normalized_semantic_intent_hir_presence_keys(),
            "$label delegates nested intent_hir to the existing bounded owner",
        );
        assert_keys_present(
            $contributor->{lowered_rtl_ir},
            normalized_semantic_lowered_rtl_ir_presence_keys(),
            "$label delegates nested lowered_rtl_ir to the existing bounded owner",
        );
        assert_keys_present(
            $contributor->{structural_rtl_ir},
            normalized_semantic_structural_rtl_ir_presence_keys(),
            "$label delegates nested structural_rtl_ir to the existing bounded owner",
        );
    }

    ok(ref($candidate->{aggregate_enable_families}) eq 'ARRAY', 'shared-datapath candidate emits aggregate enable families');
    is(
        $candidate->{aggregate_enable_family_count},
        scalar(@{$candidate->{aggregate_enable_families} || []}),
        'shared-datapath candidate aggregate family count matches the emitted array',
    );
    for my $index (0 .. $#{$candidate->{aggregate_enable_families} || []}) {
        my $family = $candidate->{aggregate_enable_families}[$index];
        my $label = "shared-datapath aggregate family $index";

        assert_exact_keys(
            $family,
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            "$label keeps the bounded family key schema",
        );
        assert_exact_keys(
            $family->{same_value_assertion},
            normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            "$label same-value assertion keeps the bounded key schema",
        );
        ok(ref($family->{contributors}) eq 'ARRAY', "$label emits aggregate contributor entries");
        is(
            $family->{contributor_count},
            scalar(@{$family->{contributors} || []}),
            "$label contributor count matches the emitted array",
        );
        for my $contributor (@{$family->{contributors} || []}) {
            assert_exact_keys(
                $contributor,
                normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
                "$label aggregate contributor keeps the bounded key schema",
            );
        }
    }
};

subtest 'composition semantic payload keeps bounded child-owner contracts at runtime' => sub {
    my $decoded = run_semantic_json('fsm/apb_tb.fsm');
    my $semantic = $decoded->{semantic};

    assert_keys_present(
        $semantic->{module},
        normalized_semantic_module_presence_keys(),
        'composition semantic.module keeps bounded core keys',
    );
    assert_keys_present(
        $semantic->{module},
        normalized_semantic_module_optional_metric_keys(),
        'composition semantic.module keeps composition-only metric keys',
    );
    assert_keys_present(
        $semantic->{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'composition semantic.system_contract keeps bounded keys',
    );
    ok(
        exists $semantic->{explicit_system_contract}
            && !defined $semantic->{explicit_system_contract},
        'composition semantic.explicit_system_contract stays null when the top did not author +system',
    );

    assert_signal_analysis_contract(
        $semantic->{signal_analysis},
        'composition semantic.signal_analysis keeps bounded buckets and entry keys',
    );

    assert_keys_present(
        $semantic->{forward_ir},
        normalized_semantic_forward_ir_presence_keys(),
        'composition semantic.forward_ir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_presence_keys(),
        'composition semantic.forward_ir.intent_hir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{intent_hir},
        normalized_semantic_intent_hir_optional_composition_keys(),
        'composition semantic.forward_ir.intent_hir keeps composition-only keys',
    );
    is_deeply(
        $semantic->{forward_ir}{intent_hir}{composition_children},
        $semantic->{composition}{children},
        'composition semantic.forward_ir.intent_hir.composition_children aliases semantic.composition.children',
    );
    assert_exact_keys(
        $semantic->{forward_ir}{intent_hir}{composition_children}[0],
        normalized_semantic_intent_hir_composition_child_entry_keys(),
        'composition semantic.forward_ir.intent_hir.composition_children[] entry keeps exact bounded keys',
    );
    is_deeply(
        $semantic->{forward_ir}{intent_hir}{composition_generated_children},
        $semantic->{composition}{generated_children},
        'composition semantic.forward_ir.intent_hir.composition_generated_children aliases semantic.composition.generated_children',
    );
    assert_exact_keys(
        $semantic->{forward_ir}{intent_hir}{composition_generated_children}[0],
        normalized_semantic_intent_hir_composition_generated_child_entry_keys(),
        'composition semantic.forward_ir.intent_hir.composition_generated_children[] entry keeps exact bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'composition semantic.forward_ir.lowered_rtl_ir keeps bounded keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{lowered_rtl_ir},
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'composition semantic.forward_ir.lowered_rtl_ir keeps composition-only keys',
    );
    assert_keys_present(
        $semantic->{forward_ir}{structural_rtl_ir},
        normalized_semantic_structural_rtl_ir_presence_keys(),
        'composition semantic.forward_ir.structural_rtl_ir keeps bounded keys',
    );

    ok(
        !exists $semantic->{symbol_contract},
        'composition semantic payload omits the optional symbol_contract branch for symbol-free tops',
    );
    ok(
        ref($semantic->{composition}) eq 'HASH',
        'composition semantic.composition is present as a hash',
    );
    assert_keys_present(
        $semantic->{composition},
        normalized_semantic_composition_presence_keys(),
        'composition semantic.composition keeps bounded keys',
    );
    assert_exact_keys(
        $semantic->{composition}{children}[0],
        normalized_semantic_composition_child_entry_keys(),
        'composition semantic.composition.children[] entry keeps exact bounded keys',
    );
    assert_exact_keys(
        $semantic->{composition}{generated_children}[0],
        normalized_semantic_composition_generated_child_entry_keys(),
        'composition semantic.composition.generated_children[] entry keeps exact bounded keys',
    );
    assert_keys_present(
        $semantic->{composition}{provenance_report},
        composition_report_public_top_level_keys(),
        'composition semantic.composition.provenance_report keeps bounded public keys',
    );
};

subtest 'parameterized composition child semantic payload keeps bounded parameter-override aliases at runtime' => sub {
    my $composition_path = write_fsm('parameterized_regular_child_semantic_schema.fsm', <<'FSM');
(?top:parameterized_regular_child_top
  (+constants
    (OVERRIDE_WIDTH 16)
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
      (RESET_VALUE 8'hA5)
    )
  )
  (?wiring:wiring
    (payload_in u_uart.data_in)
    (u_uart.txd serial_out)
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH 8)
    (RESET_VALUE 8'h00)
  )
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
  txd>:data
)
FSM

    my $decoded = run_semantic_json($composition_path);
    my $semantic = $decoded->{semantic};

    my $structural_instance = $semantic->{forward_ir}{structural_rtl_ir}{instances}[0] || {};
    is(
        scalar(@{$structural_instance->{parameter_overrides} || []}),
        2,
        'parameterized regular child structural instance exposes two parameter overrides',
    );
    my %structural_override_by_name =
        map { $_->{name} => $_ } @{$structural_instance->{parameter_overrides} || []};
    $structural_override_by_name{WIDTH} ||= {};
    assert_keys_present(
        $structural_override_by_name{WIDTH},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'structural instance WIDTH parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $structural_override_by_name{WIDTH},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'structural instance WIDTH parameter override keeps bounded raw-value extension keys',
    );
    assert_keys_present(
        $structural_override_by_name{WIDTH},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'structural instance WIDTH parameter override keeps bounded value-metadata extension keys',
    );

    my %composition_child_by_instance =
        map { $_->{instance_name} => $_ } @{$semantic->{composition}{children} || []};
    my $composition_child = $composition_child_by_instance{u_uart} || {};
    ok($composition_child_by_instance{u_uart}, 'composition child list includes the parameterized RTL child');
    is_deeply(
        $composition_child->{parameter_overrides},
        $structural_instance->{parameter_overrides},
        'composition child parameter_overrides aliases structural instance parameter_overrides',
    );
    my %composition_override_by_name =
        map { $_->{name} => $_ } @{$composition_child->{parameter_overrides} || []};
    $composition_override_by_name{WIDTH} ||= {};
    assert_keys_present(
        $composition_override_by_name{WIDTH},
        normalized_semantic_composition_child_parameter_override_entry_keys(),
        'composition child WIDTH parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $composition_override_by_name{WIDTH},
        normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
        'composition child WIDTH parameter override keeps bounded raw-value extension keys',
    );
    assert_keys_present(
        $composition_override_by_name{WIDTH},
        normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
        'composition child WIDTH parameter override keeps bounded value-metadata extension keys',
    );

    my %intent_child_by_instance =
        map { $_->{instance_name} => $_ } @{$semantic->{forward_ir}{intent_hir}{composition_children} || []};
    my $intent_child = $intent_child_by_instance{u_uart} || {};
    ok($intent_child_by_instance{u_uart}, 'intent-HIR child list includes the parameterized RTL child');
    is_deeply(
        $intent_child->{parameter_overrides},
        $composition_child->{parameter_overrides},
        'intent-HIR composition child parameter_overrides aliases composition child parameter_overrides',
    );
    my %intent_override_by_name =
        map { $_->{name} => $_ } @{$intent_child->{parameter_overrides} || []};
    $intent_override_by_name{WIDTH} ||= {};
    assert_keys_present(
        $intent_override_by_name{WIDTH},
        normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys(),
        'intent-HIR child WIDTH parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $intent_override_by_name{WIDTH},
        normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        'intent-HIR child WIDTH parameter override keeps bounded raw-value extension keys',
    );
    assert_keys_present(
        $intent_override_by_name{WIDTH},
        normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        'intent-HIR child WIDTH parameter override keeps bounded value-metadata extension keys',
    );
};

subtest 'composition semantic payload keeps bounded standalone-DT child schemas at runtime' => sub {
    my $composition_path = write_fsm('composition_standalone_dt_semantic_schema.fsm', <<'FSM');
(?top:composition_standalone_dt_semantic_schema
  (?ports:public_io
    sel
    data_a<8
    data_b<8
    final_out>8
  )
  (?dtc:router_a route_a)
  (?dtc:router_b route_b)
  (?wiring:wiring
    (sel router_a.sel)
    (data_a router_a.a)
    (data_b router_a.b)
    (router_a.out router_b.in)
    (router_b.final_out final_out)
  )
)

(?dt:route_a
  (+size
    (sel 1)
    (a 8)
    (b 8)
    (out 8)
  )
  (-from_a
    (<sel==1'b0
      (= (out> a))
    )
  )
  (-from_b
    (<sel==1'b1
      (= (out> b))
    )
  )
)

(?dt:route_b
  (+size
    (in 8)
    (final_out 8)
  )
  (-route
    (= (final_out> in))
  )
)
FSM

    my $decoded = run_semantic_json($composition_path);
    my $composition = $decoded->{semantic}{composition};
    my $intent_hir = $decoded->{semantic}{forward_ir}{intent_hir};

    assert_keys_present(
        $composition,
        normalized_semantic_composition_presence_keys(),
        'standalone-DT composition semantic.composition keeps bounded keys',
    );
    is(
        $composition->{standalone_dt_child_count},
        2,
        'standalone-DT composition reports two reusable DT children',
    );
    ok(
        ref($composition->{standalone_dt_children}) eq 'ARRAY',
        'standalone-DT composition emits standalone_dt_children[]',
    );
    is(
        scalar(@{$composition->{standalone_dt_children} || []}),
        $composition->{standalone_dt_child_count},
        'standalone-DT child count matches the emitted array',
    );

    my $first_child = $composition->{standalone_dt_children}[0];
    is_deeply(
        $intent_hir->{composition_standalone_dt_children},
        $composition->{standalone_dt_children},
        'intent-HIR composition_standalone_dt_children aliases semantic.composition.standalone_dt_children',
    );
    my $intent_hir_first_child = $intent_hir->{composition_standalone_dt_children}[0];
    assert_exact_keys(
        $intent_hir_first_child,
        normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys(),
        'intent-HIR composition_standalone_dt_children[] entry keeps exact bounded keys',
    );
    assert_exact_keys(
        $first_child,
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        'composition semantic.composition.standalone_dt_children[] entry keeps exact bounded keys',
    );
    is(
        $first_child->{standalone_dt_count},
        scalar(@{$first_child->{standalone_dt_names} || []}),
        'standalone-DT child standalone_dt_count matches standalone_dt_names[]',
    );
    ok(
        ref($first_child->{standalone_dt_enable_families}) eq 'ARRAY',
        'standalone-DT child emits standalone_dt_enable_families[]',
    );
    for my $family (@{$first_child->{standalone_dt_enable_families} || []}) {
        assert_exact_keys(
            $family,
            normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
            'composition standalone-DT enable-family entry keeps exact bounded keys',
        );
    }
    for my $family (@{$intent_hir_first_child->{standalone_dt_enable_families} || []}) {
        assert_exact_keys(
            $family,
            normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
            'intent-HIR standalone-DT enable-family entry keeps exact bounded keys',
        );
    }
    assert_exact_keys(
        $first_child->{standalone_dt_module_enable_family},
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        'composition standalone-DT module-enable-family keeps exact bounded keys',
    );
    assert_exact_keys(
        $intent_hir_first_child->{standalone_dt_module_enable_family},
        normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys(),
        'intent-HIR standalone-DT module-enable-family keeps exact bounded keys',
    );
    is(
        $first_child->{standalone_dt_multi_drive_target_count},
        scalar(@{$first_child->{standalone_dt_multi_drive_targets} || []}),
        'standalone-DT child multi-drive target count matches standalone_dt_multi_drive_targets[]',
    );
    ok(
        ref($first_child->{standalone_dt_multi_drive_targets}) eq 'ARRAY',
        'standalone-DT child emits standalone_dt_multi_drive_targets[]',
    );
    my $target = $first_child->{standalone_dt_multi_drive_targets}[0];
    assert_exact_keys(
        $target,
        normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        'composition standalone-DT multi-drive target entry keeps exact bounded keys',
    );
    assert_exact_keys(
        $target->{multi_drive_assertion},
        normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        'composition standalone-DT multi-drive assertion delegates to exact bounded keys',
    );
    my $intent_hir_target = $intent_hir_first_child->{standalone_dt_multi_drive_targets}[0];
    assert_exact_keys(
        $intent_hir_target,
        normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
        'intent-HIR standalone-DT multi-drive target entry keeps exact bounded keys',
    );
    assert_exact_keys(
        $intent_hir_target->{multi_drive_assertion},
        normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
        'intent-HIR standalone-DT multi-drive assertion delegates to exact bounded keys',
    );
    for my $branch (qw(intent_hir lowered_rtl_ir structural_rtl_ir)) {
        ok(
            ref($first_child->{$branch}) eq 'HASH',
            "composition standalone-DT child delegates nested $branch as a bounded object",
        );
    }
};

done_testing();

sub run_semantic_json {
    my ($relpath) = @_;
    my $path = File::Spec->file_name_is_absolute($relpath) ? $relpath : repo_file($relpath);
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );

    ok($success, "semantic JSON export succeeds for $relpath");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON export keeps stderr clean for $relpath");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub assert_signal_analysis_contract {
    my ($signal_analysis, $label) = @_;

    assert_keys_present(
        $signal_analysis,
        normalized_semantic_signal_analysis_presence_keys(),
        "$label: signal-analysis buckets stay bounded",
    );

    for my $bucket (qw(inputs outputs multi_bit single_bit)) {
        next unless @{$signal_analysis->{$bucket} || []};
        assert_keys_present(
            $signal_analysis->{$bucket}[0],
            normalized_semantic_signal_analysis_entry_presence_keys(),
            "$label: bucket $bucket entries stay bounded",
        );
    }
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub assert_exact_keys {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    is_deeply(
        [sort keys %{$payload}],
        [sort @{$keys || []}],
        "$label: exact keys match",
    );
}

sub assert_keys_absent {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(!exists $payload->{$key}, "$label: omits key $key");
    }
}
