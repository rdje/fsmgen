use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;

my $class = 'FSM::HDL::FlattenedDT::Backend::VHDL';
my $json = JSON::PP->new->canonical;
sub raw_module {
    my ($expression, $flag) = @_; $flag //= 'FLAG';
    return "module fixed_logic (\n  input wire $flag,\n  input wire [7:0] WORD,\n"
        ."  input logic signed [7:0] SIGNED_WORD,\n  input wire [0:0] ONEBIT_VECTOR,\n"
        ."  output wire [7:0] VECTOR_RESULT,\n  output wire RESULT\n);\n  assign RESULT = $expression;\nendmodule\n";
}
my $module = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_module(raw_module('FLAG && WORD'));
my @ports = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_ports($module->{ports}, {});
my $decls = {map {$_->{name} => $_} @ports};
sub expression {
    FSM::HDL::FlattenedDT::Backend::VHDL::_sv_expr_to_vhdl($_[0], {decls_by_name => $decls, target_lhs => $_[1] // 'RESULT'})
}
sub convert {$class->new(flattened_dt => {})->convert_systemverilog_to_vhdl($_[0])}
sub parse {my ($s) = @_; FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$s))}

subtest 'actual fixed declarations lower whole vector logical values into scalar operators' => sub {
    my $before = $json->encode($decls);
    my $word = 'fsmgen_direct_vhdl_reduce_or(WORD)';
    for my $case (
        ['FLAG && WORD', "(FLAG) and ($word)"],
        ['WORD || FLAG', "($word) or (FLAG)"],
        ['FLAG && !WORD', "(FLAG) and (not ($word))"],
        ['!(WORD && FLAG)', "(not ($word)) or (not (FLAG))"],
        ['!WORD', "not ($word)"],
        ['FLAG && ONEBIT_VECTOR', '(FLAG) and (fsmgen_direct_vhdl_reduce_or(ONEBIT_VECTOR))'],
        ['SIGNED_WORD && FLAG', '(fsmgen_direct_vhdl_reduce_or(std_logic_vector(SIGNED_WORD))) and (FLAG)'],
    ) {
        is(expression($case->[0]), $case->[1], 'complete logical expression returns scalar std_logic values');
    }
    is($json->encode($decls), $before, 'complete actual declaration records and JSON kinds conserve');
};

subtest 'helper dependency reservation follows consumed whole-vector truth and VHDL case folding' => sub {
    my %required = FSM::HDL::FlattenedDT::Backend::VHDL::_required_vector_reduction_helpers('assign RESULT = FLAG && WORD;', $decls);
    is_deeply(\%required, {'|' => 1}, 'actual fixed logical vector assignment reserves the OR fold');
    my %scalar = FSM::HDL::FlattenedDT::Backend::VHDL::_required_vector_reduction_helpers('assign RESULT = FLAG && FLAG;', $decls);
    is_deeply(\%scalar, {}, 'unrelated vector declarations create no unused implicit helper');
    my %explicit = FSM::HDL::FlattenedDT::Backend::VHDL::_required_vector_reduction_helpers('assign RESULT = FLAG && (^WORD);', $decls);
    is_deeply(\%explicit, {'^' => 1}, 'an explicit reduction is already scalar and needs no implicit OR');
    for my $name ('fsmgen_direct_vhdl_reduce_or', 'FSMGEN_DIRECT_VHDL_REDUCE_OR') {
        ok(!eval {FSM::HDL::FlattenedDT::Backend::VHDL::_validate_vector_reduction_helper_names(
            {'|' => 1}, 'fixed_logic', [{name => $name}]); 1}, 'actual VHDL function namespace rejects either declaration spelling');
        like($@, qr/helper name.*collides/, 'same helper collision authority names refusal');
        ok(!eval {convert(raw_module("$name && WORD", $name)); 1}, 'public raw conversion refuses consumed-helper collision before an artifact');
    }
};

subtest 'actual source-aware and raw conversion agree on typed fixed vector guards' => sub {
    open my $input, '<', 't/data/ial0-bitwise-vector-guards.fsm' or die $!;
    my $source = do {local $/; <$input>}; close $input or die $!;
    my $m = parse($source); my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $before = $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {$_ => $m->signals->{$_}->width} keys %{$m->signals}}]);
    my $sv = $dt->generate_systemverilog($m); my $hdl = $dt->generate_vhdl($m);
    like($hdl, qr/^  function fsmgen_direct_vhdl_reduce_or\(value : std_logic_vector\) return std_logic is$/m,
        'actual helper is declared before typed assignments');
    like($hdl, qr/for index in value'range loop/, 'whole vector fold uses the declared range');
    for my $output ('data', 'other') {
        like($hdl, qr/^  idle_\Q$output\E_1_en <= \(idle_en\) and \(fsmgen_direct_vhdl_reduce_or\(intermediate_and_A_B_1\)\);$/m,
            'complete native selector combines scalar state and scalar whole-vector truth');
    }
    is($hdl, convert($sv), 'whole source-aware/current raw artifact agrees');
    is($dt->generate_vhdl($m), $hdl, 'reused backend preserves the complete product and helper set');
    is($json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {$_ => $m->signals->{$_}->width} keys %{$m->signals}}]), $before, 'complete caller widths and captured maps conserve');
};

subtest 'ordinary scalar, vector-data, selected-bit and comparison products retain existing paths' => sub {
    is(expression('FLAG && FLAG'), 'FLAG and FLAG', 'scalar-only logical product remains unchanged');
    is(expression('FLAG && WORD[0]'), 'FLAG and WORD(0)', 'existing fixed bit-selection product stays exact');
    is(expression('WORD', 'VECTOR_RESULT'), 'WORD', 'compatible vector data assignment is not reinterpreted as a Boolean predicate');
    is(expression("WORD == 8'd2"), "'1' when WORD = \"00000010\" else '0'", 'existing fixed comparison uses its previous typed path');
};
done_testing();
