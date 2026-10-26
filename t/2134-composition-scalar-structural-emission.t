use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Composition::RTLChildRealizer;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::StructuralRTLIR;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::Support::CompositionParameterContract qw(build_composition_parameter_contract);
use FSM::SourcePathResolver;

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-scalar-emission.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
my $resolver = FSM::SourcePathResolver->new;
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => $resolver);
my $child = FSM::Composition::RTLChildRealizer->realize_rtl_child_instance(
    instance => $spec->top->instances->[0], composition_spec => $spec, fsm_file => $path,
    rtl_interface_loader => FSM::Composition::RTLInterfaceLoader->new(path_resolver => $resolver));
my $plan = FSM::Composition::Plan->new(top_name => $spec->top->name, raw_spec => $spec,
    ports => $spec->top->ports_blocks->[0]->ports, instances => [$child]);
my $ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan)->as_hashref;
sub emit { FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module($_[0]) }
sub refuses {
    my ($label, $change, $pattern) = @_;
    my $input = copy($ir); $change->($input);
    my $before = $json->encode($input);
    my $ok = eval {emit($input);1}; my $error = $@;
    ok(!$ok, "$label refuses"); like($error, $pattern, "$label explains its boundary");
    is($json->encode($input), $before, "$label preserves caller data");
}
my $expected = <<'HDL';
module scalar_emission #(
    parameter WIDTH = 16,
    parameter ALIAS = WIDTH,
    parameter SAME = 16,
    parameter SUM = (ALIAS + 2)
) (
    input clk
);

    scalar_leaf #(
        .WIDTH(SUM),
        .EQUAL(SAME),
        .STATIC(2)
    ) child (

    );

endmodule
HDL
chomp $expected;
subtest 'actual source, real child declarations and captured IR emit symbolic scalar parameters' => sub {
    my $before = $json->encode($ir);
    for my $language (qw(systemverilog sv verilog v)) {
        my $input = copy($ir); $input->{target_language} = $language;
        my $text = eval {emit($input)};
        is($@, '', "$language emitter admits the prepared scalar profile");
        is($text, $expected, "$language complete HDL preserves exact top/default/child identities");
        is(emit(FSM::IR::StructuralRTLIR->new(%$input)), $expected, 'object entrypoint emits the same complete source');
    }
    my $changed = copy($ir);
    $changed->{parameter_environment}{parameters}{WIDTH}{value_text} = '999';
    $changed->{parameter_environment}{parameters}{WIDTH}{value_payload}{payload} = '999';
    $_->{value_text} = '999' for grep {exists $_->{binding_expression}} @{$changed->{instances}[0]{parameter_overrides}};
    is(emit($changed), $expected, 'unrelated validation cache changes never freeze top defaults or child actuals');
    is($json->encode($ir), $before, 'all nested source/IR inputs remain unchanged');
};
subtest 'unqualified widths, namespaces, types and scopes stay closed' => sub {
    refuses('pending width', sub {$_[0]{ports}[0]{width_contract} = {}}, qr/requires a complete width contract/);
    refuses('port name collision', sub {$_[0]{ports}[0]{name} = 'WIDTH'}, qr/WIDTH.*port/);
    refuses('foreign child binding', sub {$_[0]{instances}[0]{parameter_overrides}[0]{binding_expression}{scope}{owner} = 'other'}, qr/scope/);
    refuses('aggregate child declaration', sub {$_[0]{instances}[0]{parameter_overrides}[0]{declaration_default_value_kind} = 'list'}, qr/scalar.*override/);
    refuses('reserved child parameter', sub {$_[0]{instances}[0]{parameter_overrides}[0]{name} = 'wire'}, qr/override.*identifier/);
    refuses('missing captured environment', sub {delete $_[0]{parameter_environment}}, qr/symbolic parameter binding.*blocked/s);
    refuses('unsupported top aggregate', sub {$_[0]{parameter_environment}{parameters}{WIDTH}{value_kind} = 'list'}, qr/scalar parameter/);
    my $vhdl = copy($ir); $vhdl->{target_language} = 'vhdl';
    my $ok = eval {FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module($vhdl);1};
    ok(!$ok, 'Verilog ALIAS fixture remains outside the VHDL profile'); like($@, qr/reserved/, 'VHDL rejects the reserved ALIAS declaration');
};
subtest 'ordinary static source shape and public applicability remain explicit' => sub {
    my $static = {module_name => 'static_top', ports => [{name => 'clk', direction => 'input', width => 1}],
        nets => [], instances => [{module_name => 'leaf', instance_name => 'u_leaf',
            parameter_overrides => [{name => 'W', value_text => '16'}], port_bindings => []}]};
    is(emit($static), "module static_top (\n    input clk\n);\n\n    leaf #(\n        .W(16)\n    ) u_leaf (\n\n    );\n\nendmodule",
        'complete pre-existing static formatting stays exact');
    my $contract = build_composition_parameter_contract();
    ok($contract->{public_source_planning_supported} && $contract->{hdl_emission_supported}, 'bounded fixed-interface RTL source support is advertised; broader profiles remain guarded');
    is_deeply($contract->{prepared_scalar_emission}, {targets => [qw(systemverilog sv verilog v)],
        top_defaults => JSON::PP::true, child_actuals => JSON::PP::true,
        symbolic_port_widths => JSON::PP::true, typed_top_parameters => JSON::PP::false,
        source_admission => JSON::PP::false}, 'discovery names only the prepared direct-emitter subset');
};
done_testing;
