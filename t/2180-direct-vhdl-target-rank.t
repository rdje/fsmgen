use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::Backend::VHDL::DirectDeclarationPlan;
my $json = JSON::PP->new->canonical;
open my $fh, '<', 't/data/ial0-direct-symbolic-storage.fsm' or die $!;
my $source = do {local $/; <$fh>}; close $fh or die $!;
sub fixture {
    my ($width) = @_;
    my $text = $source =~ s/\(W 1\)/(W $width)/r;
    my $m = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $sv;
    {local $dt->{declared_width_declaration_capture} = $capture; $sv = $dt->generate_systemverilog($m)}
    my $ids = FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv);
    my $plan = FSM::Backend::VHDL::DirectDeclarationPlan->prepare(fsm_module => $m,
        assignment_analysis => $dt->{assignment_analysis}, declaration_capture => $capture->snapshot,
        identifier_map => $ids->{identifier_map});
    my $parsed = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_direct_declarations($ids->{text}, $plan);
    return {map {$_->{name} => $_} @{$parsed->{ports}}, @{$parsed->{signals}}};
}
sub type {return FSM::HDL::FlattenedDT::Backend::VHDL::_vhdl_type_for_decl($_[0])}
sub expression {
    my ($text, $decls, $target) = @_;
    return FSM::HDL::FlattenedDT::Backend::VHDL::_sv_expr_to_vhdl($text,
        {decls_by_name => $decls, target_lhs => $target});
}
subtest 'actual paired declarations use canonical target type and target length for literals' => sub {
    for my $width (1, 8) {
        my $decls = fixture($width);
        my $before = $json->encode($decls);
        is(type($decls->{DATA}), 'std_logic_vector((COPY - 1) downto 0)', 'actual storage canonical target type');
        is(type($decls->{INPUT_PORT}), 'std_logic_vector((W - 1) downto 0)', 'actual port canonical target type');
        for my $row (
            ['0', "std_logic_vector(to_unsigned(0, DATA'length))"],
            ['7', "std_logic_vector(to_unsigned(7, DATA'length))"],
            ['-1', "std_logic_vector(to_signed(-1, DATA'length))"],
            ["1'b0", "std_logic_vector(resize(unsigned'(\"0\"), DATA'length))"],
            ["4'hF", "std_logic_vector(resize(unsigned'(\"1111\"), DATA'length))"],
        ) {
            is(expression($row->[0], $decls, 'DATA'), $row->[1], "whole-target $row->[0] preserves vector rank at default $width");
        }
        is($json->encode($decls), $before, 'actual parsed fields and scalar kinds are read-only');
    }
};
subtest 'signed target contract zero-extends unsigned sized literals before conversion' => sub {
    # Explicit downstream type contract; this does not admit a new signed source profile.
    my $decls = {TARGET => {name => 'TARGET', scalar => 0, signed => 1, msb => 7, lsb => 0,
        vhdl_type => 'signed((W - 1) downto 0)', vhdl_range => '((W - 1) downto 0)'}};
    is(type($decls->{TARGET}), 'signed((W - 1) downto 0)', 'signed symbolic declaration');
    is(expression("4'hF", $decls, 'TARGET'), "signed(resize(unsigned'(\"1111\"), TARGET'length))", 'unsigned source literal keeps zero extension');
    is(expression('-1', $decls, 'TARGET'), "to_signed(-1, TARGET'length)", 'negative decimal retains signed conversion');
};
subtest 'static scalar and vector whole-target products preserve' => sub {
    my $scalar = {name => 'FIXED', scalar => 1};
    my $vector = {name => 'FIXED8', scalar => 0, signed => 0, msb => 7, lsb => 0};
    is(type($scalar), 'std_logic', 'fixed scalar type');
    is(type($vector), 'std_logic_vector(7 downto 0)', 'fixed vector type');
    is(expression("1'b0", {FIXED => $scalar}, 'FIXED'), "'0'", 'fixed scalar sized literal');
    is(expression('7', {FIXED8 => $vector}, 'FIXED8'), 'std_logic_vector(to_unsigned(7, 8))', 'fixed numeric whole vector literal');
    is(expression("4'hF", {FIXED8 => $vector}, 'FIXED8'), '"1111"', 'old static sized literal product stays unchanged');
};
subtest 'selected symbolic lvalues and malformed literals cannot borrow whole-target rank' => sub {
    my $decls = fixture(8);
    for my $target ('DATA[0]', 'DATA[3:0]') {
        ok(!eval {expression("1'b0", $decls, $target); 1}, "$target is withheld pending selected-lvalue integration");
        like($@, qr/symbolic.*selected|selected.*symbolic/, 'contextual refusal explains the bound');
    }
    ok(!eval {expression("3'bx01", $decls, 'DATA'); 1}, 'unknown-state literals retain the bounded refusal');
    like($@, qr/x\/z/, 'no new unknown-state source profile');
    ok(!eval {expression("2'b101", $decls, 'DATA'); 1}, 'oversized authored literal still refuses');
    like($@, qr/literal|fit/, 'literal validation remains authoritative');
};
done_testing();
