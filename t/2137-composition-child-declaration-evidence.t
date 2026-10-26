use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::GeneratedChildRealizer;
use FSM::Composition::RTLChildRealizer;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Composition::Plan;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;
use FSM::Composition::Instance;
use FSM::SourcePathResolver;
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report);
use FSM::Support::CompositionParameterContract qw(build_composition_parameter_contract);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys);

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-child-declaration-evidence.fsm';
my $raw = Lispish::multi($path);
my $original = $json->encode($raw);
my $spec = FSM::Composition::Parser->new->parse_source($raw);
my $resolver = FSM::SourcePathResolver->new;
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => $resolver);
my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'systemverilog');
my $loader = FSM::Composition::RTLInterfaceLoader->new(path_resolver => $resolver);
my @children;
my %expected = (INTEGER => '1', BIT => "1'b1", VECTOR => "8'h01", ALIAS => "8'h01");

for my $instance (@{$spec->top->instances}) {
    my $kind = $instance->kind;
    subtest "$kind declaration evidence stays distinct from equal actual values" => sub {
        my $child;
        if ($kind eq 'rtl') {
            $child = FSM::Composition::RTLChildRealizer->realize_rtl_child_instance(
                instance => $instance, rtl_interface_loader => $loader,
                composition_spec => $spec, fsm_file => $path);
        } else {
            my $method = $kind eq 'fsmc' ? 'realize_fsmc_child_instance' : 'realize_dtc_child_instance';
            $child = FSM::Composition::GeneratedChildRealizer->$method(instance => $instance,
                pipeline => $pipeline, composition_spec => $spec, fsm_file => $path,
                header => '?top:declaration_evidence', source_path_resolver => $resolver);
        }
        push @children, $child;
        my $records = $child->parameter_overrides;
        for my $record (@$records) {
            my $name = $record->{name};
            is($record->{value_text}, '1', "$name actual cache is deliberately equal");
            is($record->{binding_expression}{parameter}, 'W', "$name retains the top reference");
            # Package payloads normalize hex digits; direct defaults retain their token.
            my $value = $kind eq 'rtl' && $name eq 'ALIAS' ? "8'h1" : $expected{$name};
            is($record->{declaration_default_value_text}, $value, "$name retains canonical declaration type evidence");
            is_deeply($record->{declaration_default_value_payload}, {kind=>'scalar',payload=>$value},
                "$name declaration payload is independent of actual cache");
            ok(ref($record->{declaration_default_value_type_spec}) eq 'HASH', "$name retains the declared default type record");
            my $source = $name eq 'ALIAS' ? ($kind eq 'rtl' ? 'declaration_defaults.VECTOR' : 'VECTOR') : $expected{$name};
            is_deeply($record->{declaration_default_source_expression}, $kind eq 'rtl' ? $source : [$source],
                "$name retains the authored frontend tree, including aliases");
        }
        my $baseline = $json->encode($child->parameter_overrides);
        $records->[0]{declaration_default_value_payload}{payload} = '999';
        $records->[0]{declaration_default_value_type_spec}{kind} = 'wrong';
        is($json->encode($child->parameter_overrides), $baseline, 'getter mutations cannot rewrite declaration evidence');
    };
}

subtest 'captured IR and public optional schemas preserve complete declaration records' => sub {
    my $plan = FSM::Composition::Plan->new(top_name => $spec->top->name, raw_spec => $spec,
        instances => \@children);
    my $structural = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan)->as_hashref;
    my $intent = FSM::IR::IntentHIRBuilder->build_from_composition_plan(composition_plan => $plan)->as_hashref;
    my $report = build_normalized_semantic_success_report(input => $path, source_file => $path,
        result => {composition_plan=>$plan, structural_rtl_ir=>$structural, intent_hir=>$intent});
    for my $i (0..$#children) {
        is_deeply($structural->{instances}[$i]{parameter_overrides}, $children[$i]->parameter_overrides,
            'complete actual declaration record reaches structural IR');
        is_deeply($report->{semantic}{forward_ir}{structural_rtl_ir}{instances}[$i]{parameter_overrides},
            $children[$i]->parameter_overrides, 'complete public structural record preserves evidence');
    }
    my $keys = normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys();
    for my $key (qw(declaration_default_value_text declaration_default_value_payload declaration_default_value_type_spec declaration_default_source_expression)) {
        ok(grep($_ eq $key, @$keys), "$key is an optional override schema member");
    }
    my $contract = build_composition_parameter_contract();
    is_deeply($contract->{declaration_default_value_keys}, [qw(declaration_default_value_kind declaration_default_value_payload declaration_default_value_text)],
        'discovery names the exact declaration default value family');
    ok(!$contract->{public_source_planning_supported} && !$contract->{hdl_emission_supported},
        'preparation does not enable source queries or full HDL support');
    is($json->encode(copy($report)), $json->encode($report), 'complete report round trips without changing JSON kinds');
};
subtest 'missing declaration evidence cannot borrow actual caches or stale annotations' => sub {
    for my $instance (@{$spec->top->instances}) {
        my ($owner, %args, $declarations, $reset);
        if ($instance->kind eq 'rtl') {
            $owner = 'FSM::Composition::RTLChildRealizer';
            my $loaded = $loader->load_interface(module_name=>$instance->module_name, source_file=>$path,
                embedded_raw_ast=>$spec->raw_ast, top_symbols=>$spec->top->top_symbols);
            %args = (loaded_metadata=>$loaded);
            $declarations = {map {$_->{name} => $_} @{$loaded->{parameter_declarations}}};
            $reset = sub {delete $declarations->{INTEGER}{raw_default_value}};
        } else {
            $owner = 'FSM::Composition::GeneratedChildRealizer';
            my $sources = $instance->kind eq 'fsmc' ? $spec->embedded_fsm_sources : $spec->embedded_dt_sources;
            my $module = FSM::Pipeline::SourceFrontend->create_fsm_module(raw_ast=>$sources->{$instance->source_name},
                source_label=>$instance->source_name, fsm_file=>$path, source_path_resolver=>$resolver);
            %args = (child_module=>$module);
            $declarations = $module->parameters;
            $reset = sub {$module->set_parameter('INTEGER', $declarations->{INTEGER})};
        }
        my $overrides = $instance->parameter_overrides;
        $overrides->[0]{declaration_default_source_expression} = 'FORGED';
        my $annotated = FSM::Composition::Instance->new(kind=>$instance->kind, name=>$instance->name,
            module_name=>$instance->module_name, source_name=>$instance->source_name, parameter_overrides=>$overrides);
        $reset->();
        my $records = $owner->validate_parameter_overrides(instance=>$annotated, %args);
        ok(!exists $records->[0]{declaration_default_source_expression}, $instance->kind.' source-less declaration acquires no forged provenance');
        my $payload_key = $instance->kind eq 'rtl' ? 'default_value_payload' : 'value_payload';
        delete $declarations->{INTEGER}{$payload_key};
        $reset->();
        my $ok = eval {$owner->validate_parameter_overrides(instance=>$annotated, %args);1};
        ok(!$ok, $instance->kind.' incomplete declaration refuses despite a valid actual cache');
        like($@, qr/requires complete declaration default evidence/, 'refusal names the missing declaration boundary');
    }
};
is($json->encode($raw), $original, 'whole authored input remains unchanged');
done_testing;
