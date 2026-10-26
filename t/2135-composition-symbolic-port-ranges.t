use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::StructuralRTLIR;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::SourcePathResolver;
use FSM::Support::CompositionParameterContract qw(build_composition_parameter_contract);
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-symbolic-port-ranges.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my $plan = FSM::Composition::Plan->new(top_name => $spec->top->name, raw_spec => $spec,
    ports => $spec->top->ports_blocks->[0]->ports);
my $ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan)->as_hashref;
sub emit { FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module($_[0]) }
sub port { my ($input, $name) = @_; return (grep {$_->{name} eq $name} @{$input->{ports}})[0] }
sub refuses {
    my ($label, $change, $pattern) = @_;
    my $input = copy($ir); $change->($input);
    my $before = $json->encode($input);
    my $ok = eval {emit($input);1}; my $error = $@;
    ok(!$ok, "$label refuses"); like($error, $pattern, "$label identifies the boundary");
    is($json->encode($input), $before, "$label leaves caller unchanged");
}
my $expected = <<'HDL';
module range_top #(
    parameter W = 1,
    parameter ALIAS = W
) (
    input clk,
    input signed [6:0] typed,
    input [2:0] fixed,
    input [(ALIAS - 1):0] data,
    output [(((W * 6) / 2) - 1):0] result,
    input [(4 - 1):0] literal
);
endmodule
HDL
chomp $expected;
subtest 'actual source Plan and IR emit symbolic ranges, independent of width caches' => sub {
    my $before = $json->encode($ir);
    for my $language (qw(systemverilog sv verilog v)) {
        my $input = copy($ir); $input->{target_language} = $language;
        my $text = eval {emit($input)};
        is($@, '', "$language accepts prepared canonical widths");
        is($text, $expected, "$language complete declarations preserve literal and alias meaning");
        is(eval {emit(FSM::IR::StructuralRTLIR->new(%$input))}, $expected, 'object entrypoint preserves complete output');
    }
    my $input = copy($ir);
    port($input, $_)->{width} = 999 for qw(data result literal);
    is(eval {emit($input)}, $expected, 'numeric port caches never provide symbolic ranges');
    port($input, 'data')->{signed} = 1;
    port($input, 'data')->{state_model} = 'two_state';
    my $typed = eval {emit($input)};
    like($typed // '', qr/input bit signed \[\(ALIAS - 1\):0\] data/, 'signed and two-state scalar meaning survives symbolic range');
    is($json->encode($ir), $before, 'source and nested captured IR remain unchanged');
};
subtest 'hostile contracts cannot fall back to numeric widths' => sub {
    refuses('foreign scope', sub {port($_[0], 'data')->{width_contract}{scope}{owner} = 'other'}, qr/width.*scope/i);
    refuses('missing lookup', sub {port($_[0], 'data')->{width_contract}{references} = []}, qr/width.*lookup/i);
    refuses('wrong identity', sub {port($_[0], 'data')->{width_contract}{references}[0]{token} = 'W'}, qr/width.*lookup/i);
    refuses('extra lookup', sub {push @{port($_[0], 'data')->{width_contract}{references}}, {kind=>'parameter', token=>'W'}}, qr/width.*lookup/i);
    refuses('unknown param', sub {port($_[0], 'data')->{width_contract}{expression} = ['param','MISSING']; port($_[0], 'data')->{width_contract}{references}[0]{token} = 'MISSING'}, qr/width.*parameter/i);
    refuses('missing contract', sub {port($_[0], 'data')->{width_contract} = {}}, qr/width.*contract/i);
    refuses('raw expression', sub {port($_[0], 'data')->{width_contract}{expression} = 'W + 1'}, qr/width.*lookup/i);
    refuses('aggregate static', sub {port($_[0], 'result')->{width_contract}{references}[1]{value_payload} = {kind=>'list',items=>[]}}, qr/aggregate payload/);
    refuses('typed width conflict', sub {port($_[0], 'data')->{declared_type_spec} = {kind=>'bits',width=>1}}, qr/width.*declared type/i);
    refuses('zero width', sub {port($_[0], 'data')->{width_contract}{expression} = ['-', 1, 1]; port($_[0], 'data')->{width_contract}{references} = []}, qr/positive integer width/);
    refuses('zero divisor', sub {port($_[0], 'data')->{width_contract}{expression} = ['/',1,0]; port($_[0], 'data')->{width_contract}{references} = []}, qr/divides by zero/);
    refuses('unsupported op', sub {port($_[0], 'data')->{width_contract}{expression} = ['<<',1,1]}, qr/unsupported width/);
    refuses('missing environment', sub {delete $_[0]{parameter_environment}}, qr/port width contract emission is blocked/);
    my $input = copy($ir); $input->{target_language} = 'vhdl';
    my $ok = eval {FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module($input);1};
    ok(!$ok, 'VHDL symbolic ranges stay refused'); like($@, qr/port width contract emission is blocked/, 'VHDL width guard remains exact');
};
subtest 'discovery exposes only prepared range support' => sub {
    my $contract = build_composition_parameter_contract();
    ok($contract->{prepared_scalar_emission}{symbolic_port_widths}, 'prepared direct range support advertised');
    ok(!$contract->{public_source_planning_supported} && !$contract->{hdl_emission_supported}, 'complete source/HDL flags remain false');
};
done_testing;
