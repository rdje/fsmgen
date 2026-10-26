use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::SourcePathResolver;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializableCompositionPlanSnapshot qw(build_serializable_composition_plan_snapshot);
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report);
use FSM::Support::NormalizedSemanticReportContract qw(build_normalized_semantic_report_contract);

my $json = JSON::PP->new->canonical;
my $path = 't/data/composition-top-port-width-expressions.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my $plan = FSM::Composition::Plan->new(top_name => $spec->top->name, raw_spec => $spec,
    ports => $spec->top->ports_blocks->[0]->ports);
my $structural = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan);
my $intent = FSM::IR::IntentHIRBuilder->build_from_composition_plan(composition_plan => $plan);
my $snapshot = build_serializable_composition_plan_snapshot(composition_plan => $plan);
my $report = build_normalized_semantic_success_report(input => $path, source_file => $path,
    result => {composition_plan => $plan, intent_hir => $intent->as_hashref, structural_rtl_ir => $structural->as_hashref});
sub named { my ($rows, $name) = @_; return (grep {$_->{name} eq $name} @$rows)[0] }
sub cloned { $json->decode($json->encode($_[0])) }
my $expected = {
    scope => {kind => 'composition_top', owner => 'port_widths'},
    expression => ['+', [['param', ['ALIAS']], 'widths.EXTRA']],
    references => [{kind => 'parameter', token => 'ALIAS'},
        {kind => 'static_symbol', token => 'widths.EXTRA', value_payload => {kind => 'scalar', payload => '2'}}],
};
subtest 'actual products allocate source and scoped dependencies to matching ports' => sub {
    for my $rows (
        $structural->ports, $intent->signal_analysis->{inputs}, $intent->signal_analysis->{multi_bit},
        $snapshot->{top_ports}, $report->{semantic}{forward_ir}{structural_rtl_ir}{ports},
        $report->{semantic}{forward_ir}{intent_hir}{signal_analysis}{inputs},
        $report->{semantic}{signal_analysis}{inputs}, $report->{semantic}{composition}{plan_snapshot}{top_ports},
    ) {
        my $data = named($rows, 'data');
        is($data->{width}, 18, 'cached default remains independent expected 16 plus static two');
        is_deeply($data->{width_contract}, $expected, 'matching actual declaration preserves alias, static cache, AST kinds and scope');
        my $static = named($rows, 'typed');
        ok(!exists $static->{width_contract}, 'ordinary named type omits optional width contract');
    }
    my $result = named($structural->ports, 'result');
    is($result->{width}, 24, 'independent multiply/divide default width');
    is_deeply($result->{width_contract}{references}, [{kind => 'parameter', token => 'W'}],
        'another port retains W rather than equal-valued ALIAS');
    is($json->encode(cloned($report)), $json->encode($report), 'complete normalized report round trips without JSON kind changes');
};
subtest 'public schemas describe exact optional paths and key families' => sub {
    my $contract = build_normalized_semantic_report_contract()->{composition_parameter_contract};
    is_deeply($contract->{width_contract_keys}, [qw(scope expression references)], 'exact contract keys');
    is_deeply($contract->{width_reference_keys}, {parameter => [qw(kind token)], static_symbol => [qw(kind token value_payload)]},
        'kind-specific lookup schemas');
    is_deeply($contract->{width_analysis_buckets}, [qw(inputs multi_bit outputs single_bit)], 'wildcard expansion is bounded to actual buckets');
    is_deeply($contract->{width_contract_paths}, [
        'semantic.forward_ir.structural_rtl_ir.ports[].width_contract',
        'semantic.forward_ir.intent_hir.signal_analysis.*[].width_contract',
        'semantic.signal_analysis.*[].width_contract',
        'semantic.composition.plan_snapshot.top_ports[].width_contract'], 'only actual produced paths');
    my $manifest = build_capability_manifest();
    is_deeply($manifest->{semantic_exports}{normalized_semantic_json}{composition_parameter_contract}, $contract,
        'native/API discovery shares the same optional schema');
    ok(JSON::PP::is_bool($contract->{public_source_planning_supported}) && $contract->{public_source_planning_supported},
        'bounded fixed-interface RTL source support is advertised; broader profiles remain guarded');
    ok(JSON::PP::is_bool($contract->{hdl_emission_supported}) && $contract->{hdl_emission_supported}, 'bounded fixed-interface RTL source support is advertised; broader profiles remain guarded');
    $contract->{width_reference_keys}{parameter}[0] = 'WRONG';
    is_deeply(build_normalized_semantic_report_contract()->{composition_parameter_contract}{width_reference_keys}{parameter},
        [qw(kind token)], 'nested schema getter remains detached');
};
subtest 'source and producer owners survive public and hash snapshot mutation' => sub {
    my $original_structural = $json->encode($structural->as_hashref);
    my $original_intent = $json->encode($intent->as_hashref);
    for my $rows ($report->{semantic}{forward_ir}{structural_rtl_ir}{ports},
        $report->{semantic}{forward_ir}{intent_hir}{signal_analysis}{inputs},
        $report->{semantic}{signal_analysis}{inputs}, $snapshot->{top_ports}) {
        my $contract = named($rows, 'data')->{width_contract};
        next unless $contract;
        $contract->{scope}{owner} = 'WRONG';
        $contract->{references}[1]{value_payload}{payload} = '99';
    }
    is($json->encode($structural->as_hashref), $original_structural, 'public mutation cannot reach structural owner');
    is($json->encode($intent->as_hashref), $original_intent, 'public mutation cannot reach intent owner');
    my $hash_input = {ports => [{name => 'data', width => 18, width_token => cloned($expected->{expression}), width_contract => cloned($expected)}]};
    my $before = $json->encode($hash_input);
    my $hash_snapshot = build_serializable_composition_plan_snapshot(composition_plan => $hash_input);
    if (my $contract = $hash_snapshot->{top_ports}[0]{width_contract}) {
        $contract->{scope}{owner} = 'WRONG';
    }
    $hash_snapshot->{top_ports}[0]{width_token}[0] = 'WRONG';
    is($json->encode($hash_input), $before, 'hash-backed width AST/contract copies are detached too');
    $hash_input->{ports}[0]{width_contract}{invalid} = sub {};
    my $ok = eval {build_serializable_composition_plan_snapshot(composition_plan => $hash_input);1};
    ok(!$ok, 'unsupported width-contract references refuse instead of degrading to class names');
};
subtest 'supplied structural IR cannot drop or change captured width meaning' => sub {
    for my $change (
        sub { delete $_[0]->{width_contract} },
        sub { $_[0]->{width} = 22 },
        sub { $_[0]->{width_contract}{references}[0]{token} = 'W' },
        sub { $_[0]->{width_contract}{scope}{owner} = 'other_top' },
    ) {
        my $input = $structural->as_hashref;
        $change->(named($input->{ports}, 'data'));
        my $ok = eval {FSM::IR::IntentHIRBuilder->build_from_composition_plan(composition_plan => $plan, structural_rtl_ir => $input);1};
        ok(!$ok, 'missing or changed captured width meaning refuses');
        like($@, qr/structural port width contracts must match/, 'meaningful producer mismatch boundary');
    }
    my $input = $structural->as_hashref;
    delete $input->{parameter_environment};
    my $ok = eval {FSM::IR::StructuralRTLIR->assert_no_pending_parameter_bindings($input);1};
    ok(!$ok, 'removing environment cannot turn a prepared width contract into HDL permission');
    like($@, qr/port width contract emission is blocked.*port 'data'/s, 'exact target refusal retains port context');
    for my $target (qw(systemverilog verilog vhdl)) {
        $input->{target_language} = $target;
        my $emitter = $target eq 'vhdl' ? 'FSM::Backend::VHDL::StructuralRTLIREmitter'
            : 'FSM::Backend::VerilogFamily::StructuralRTLIREmitter';
        $ok = eval {$emitter->emit_module($input);1};
        ok(!$ok, "$target public emitter entrypoint refuses pending width lowering");
        like($@, qr/port width contract emission is blocked.*port 'data'/s, 'same contextual width boundary');
    }
};
done_testing;
