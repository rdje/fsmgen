use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::Composition::PlanBuilder;
use FSM::Composition::RTLInterfaceLoader;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::StructuralRTLIR;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::Pipeline::HDLGenerator;
use FSM::SourcePathResolver;

my $json = JSON::PP->new->canonical;
sub copy { return $json->decode($json->encode($_[0])) }
my %capture;
sub parsed {
    my ($path) = @_;
    my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
    FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
        fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
    return $spec;
}
sub refusal {
    my ($label, $code, $pattern) = @_;
    my $ok = eval {$code->();1};my $error = $@;
    ok(!$ok, "$label refuses");like($error, $pattern, "$label identifies its boundary");
    $capture{refusals}{$label} = {accepted => $ok ? 1 : 0, error => $error};
}

subtest 'actual child plan propagates detached values, source and bindings' => sub {
    my $path = 't/data/composition-top-child-bindings.fsm';
    my $spec = parsed($path);
    my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet => 1);
    my $resolver = FSM::SourcePathResolver->new;
    my $instances = FSM::Composition::PlanBuilder->realize_instances(pipeline => $pipeline,
        composition_spec => $spec, instances => $spec->top->instances, fsm_file => $path,
        source_path_resolver => $resolver,
        rtl_interface_loader => FSM::Composition::RTLInterfaceLoader->new(path_resolver => $resolver));
    my $plan = FSM::Composition::Plan->new(lane => 'C3', top_name => $spec->top->name,
        instances => $instances, raw_spec => $spec);
    my $environment = $spec->top->parameter_environment;
    my $structural;
    my $ok = eval {$structural = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan);1};
    ok($ok, 'structural builder preserves a real source environment') or do {diag($@);return};
    my $intent = FSM::IR::IntentHIRBuilder->build_from_composition_plan(composition_plan => $plan);
    my $structural_view = $structural->as_hashref;
    my $intent_view = $intent->as_hashref;
    is_deeply($structural_view->{parameter_environment}, $environment, 'complete structural environment matches its actual producer');
    is_deeply($intent_view->{parameter_environment}, $environment, 'complete intent environment matches its actual producer');
    is_deeply($intent_view->{parameter_names}, [qw(W SAME LANES)], 'top parameter names retain authored order');
    is($intent_view->{parameter_count}, 3, 'intent count follows the actual declarations');
    is($intent_view->{parameter_environment}{parameters}{W}{value_text}, '16', 'actual canonical default is preserved');
    is_deeply($intent_view->{parameter_environment}{scope}, {kind => 'composition_top', owner => 'child_bindings'}, 'real source scope stays explicit');
    for my $index (0..$#$instances) {
        is_deeply($structural_view->{instances}[$index]{parameter_overrides}, $instances->[$index]->parameter_overrides,
            'structural instances retain complete validated scoped overrides');
        is_deeply($intent_view->{composition_children}[$index]{parameter_overrides}, $instances->[$index]->parameter_overrides,
            'intent children retain complete validated scoped overrides');
    }
    $capture{structural} = copy($structural_view);
    # Raw child module_info contains typed compiler objects; retain only the
    # declared JSON-safe environment and override families under qualification.
    $capture{intent} = {parameter_environment => copy($intent_view->{parameter_environment}),
        parameter_names => copy($intent_view->{parameter_names}), symbol_contract => copy($intent_view->{symbol_contract}),
        children => [map {{instance_name => $_->{instance_name}, parameter_overrides => copy($_->{parameter_overrides})}}
            @{$intent_view->{composition_children}}]};
    for my $object ($structural, $intent) {
        my $view = $object->parameter_environment;
        $view->{parameters}{W}{value_text} = 'WRONG';
        $view->{default_bindings}{W}{kind} = 'WRONG';
        is_deeply($object->parameter_environment, $environment, 'IR getter owns nested source/value/binding data');
        my $hash = $object->as_hashref;
        $hash->{parameter_environment}{declaration_order}[0] = 'WRONG';
        is_deeply($object->as_hashref->{parameter_environment}, $environment, 'IR exported hash cannot mutate its owner');
    }
    my $coerced = FSM::IR::StructuralRTLIRBuilder->coerce($structural_view);
    $structural_view->{parameter_environment}{scope}{owner} = 'WRONG';
    is_deeply($coerced->parameter_environment, $environment, 'hash coercion preserves and detaches the complete environment');
    my $given = FSM::IR::IntentHIRBuilder->build_from_composition_plan(composition_plan => $plan,
        structural_rtl_ir => $structural);
    is_deeply($given->parameter_environment, $environment, 'prebuilt actual structural IR preserves the plan environment');
    for my $case (qw(missing wrong_owner wrong_value)) {
        my $bad = copy($capture{structural});
        if ($case eq 'missing') {delete $bad->{parameter_environment}}
        elsif ($case eq 'wrong_owner') {$bad->{parameter_environment}{scope}{owner} = 'WRONG'}
        else {$bad->{parameter_environment}{parameters}{W}{value_text} = '32'}
        my $before = $json->encode($bad);
        refusal("supplied structural $case", sub {FSM::IR::IntentHIRBuilder->build_from_composition_plan(
            composition_plan => $plan, structural_rtl_ir => $bad)}, qr/parameter environment.*(match|agree)/s);
        is($json->encode($bad), $before, 'mismatched supplied structure remains unchanged');
    }
    is_deeply($plan->parameter_environment, $environment, 'all consumers preserve the original plan snapshot');
};

subtest 'static contract and defaults retain one actual resolution boundary' => sub {
    my $spec = parsed('t/data/composition-top-instance-bindings.fsm');
    my $top = $spec->top;
    my $plan = FSM::Composition::Plan->new(top_name => $top->name, raw_spec => $spec);
    my $before = FSM::IR::IntentHIRBuilder->build_composition_top_symbol_contract($plan);
    is_deeply($before->{constant_scalar_leaves}, {C => '16'}, 'authored C is the complete local scalar constant set');
    is($before->{constant_count}, 1, 'parameter declarations do not enter the static constant count');
    is_deeply($before->{package_imports}, ['shared'], 'authored package import remains a separate namespace');

    $top->top_symbols->store_constant('C', {kind => 'scalar', payload => '32'});
    $top->resolve_parameter_defaults;
    my $after = FSM::IR::IntentHIRBuilder->build_composition_top_symbol_contract($plan);
    is_deeply($after, $before, 'old plan cannot mix original defaults with retried live static symbols');
    is($plan->parameter_environment->{parameters}{W}{value_text}, '16', 'old actual parameter default stays original');
    my $new_plan = FSM::Composition::Plan->new(top_name => $top->name, raw_spec => $spec);
    isnt($json->encode(FSM::IR::IntentHIRBuilder->build_composition_top_symbol_contract($new_plan)), $json->encode($before),
        'new plan selects the real retried static context');
    is($new_plan->parameter_environment->{parameters}{W}{value_text}, '32', 'new actual default and static context change together');
    ok($new_plan->can('parameter_symbol_contract'), 'plan owns the static context of its environment') or return;
    $top->top_symbols->store_constant('C', {kind => 'scalar', payload => '64'});
    my $captured = $new_plan->parameter_symbol_contract;
    is($captured->{constant_scalar_leaves}{C}, '32', 'captured static C stays paired with the actual retried W32');
    is_deeply(FSM::IR::IntentHIRBuilder->build_composition_top_symbol_contract($new_plan), $captured,
        'live cache edits without re-resolution cannot alter the captured contract');
    $captured->{package_imports}[0] = 'WRONG';
    isnt($new_plan->parameter_symbol_contract->{package_imports}[0], 'WRONG', 'static contract getter detaches import metadata');
    $capture{static_context} = {original => $before, retried => $new_plan->parameter_symbol_contract};
};

subtest 'environment-only structural objects and hashes cannot emit cached parameterless HDL' => sub {
    my $spec = parsed('t/data/composition-top-child-bindings.fsm');
    my $environment = $spec->top->parameter_environment;
    for my $language (qw(systemverilog verilog vhdl)) {
        my $emitter = $language eq 'vhdl' ? 'FSM::Backend::VHDL::StructuralRTLIREmitter'
            : 'FSM::Backend::VerilogFamily::StructuralRTLIREmitter';
        my $base = {module_name => 'child_bindings', source_root_kind => 'top', target_language => $language,
            ports => [], nets => [], instances => [], auxiliary_assignments => []};
        my $static = $emitter->emit_module(copy($base));
        like($static, $language eq 'vhdl' ? qr/entity child_bindings/ : qr/module child_bindings/, 'ordinary no-environment target still emits');
        $capture{static_hdl}{$language} = $static;
        for my $kind (qw(hash object)) {
            my $data = copy($base);$data->{parameter_environment} = copy($environment);
            my $input = $kind eq 'hash' ? $data : FSM::IR::StructuralRTLIR->new(%$data);
            my $before = $json->encode($kind eq 'hash' ? $input : $input->as_hashref);
            refusal("$language environment-only $kind", sub {$emitter->emit_module($input)}, qr/parameter environment.*blocked.*lowering/s);
            is($json->encode($kind eq 'hash' ? $input : $input->as_hashref), $before, 'emission refusal preserves the complete caller');
        }
    }
};
if (my $out_path = $ENV{FSMGEN_IR_ENVIRONMENT_CAPTURE}) {
    open my $out, '>', $out_path or die $!;print {$out} $json->encode(\%capture), "\n" or die $!;close $out or die $!;
}
done_testing();
