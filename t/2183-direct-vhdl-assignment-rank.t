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
sub expression {
    my ($text, $decls, $target) = @_;
    return FSM::HDL::FlattenedDT::Backend::VHDL::_sv_expr_to_vhdl($text,
        {decls_by_name => $decls, target_lhs => $target});
}
subtest 'actual unsigned sources extend or truncate to actual target rank and length' => sub {
    for my $width (1, 8) {
        my $decls = fixture($width);
        my $before = $json->encode($decls);
        for my $row (
            ['INPUT_PORT', 'DATA', "std_logic_vector(resize(unsigned(INPUT_PORT), DATA'length))"],
            ['((INPUT_PORT))', 'DATA', "std_logic_vector(resize(unsigned(INPUT_PORT), DATA'length))"],
            ['DATA', 'SPARE', "std_logic_vector(resize(unsigned(DATA), SPARE'length))"],
            ['FIXED', 'DATA', "std_logic_vector(resize(unsigned'(0 => FIXED), DATA'length))"],
            ['DATA', 'TYPED', 'signed(resize(unsigned(DATA), 4))'],
            ['DATA', 'FIXED_VALUE', 'DATA(0)'],
            ['(|DATA)', 'FIXED_VALUE', '(fsmgen_direct_vhdl_reduce_or(DATA))'],
            ['((|DATA))', 'DATA', "std_logic_vector(resize(unsigned'(0 => (fsmgen_direct_vhdl_reduce_or(DATA))), DATA'length))"],
            ['(&(DATA))', 'DATA', "std_logic_vector(resize(unsigned'(0 => (fsmgen_direct_vhdl_reduce_and(DATA))), DATA'length))"],
            ['(~^DATA)', 'DATA', "std_logic_vector(resize(unsigned'(0 => (not fsmgen_direct_vhdl_reduce_xor(DATA))), DATA'length))"],
        ) {
            is(expression($row->[0], $decls, $row->[1]), $row->[2], "$row->[0] to $row->[1] at default $width");
        }
        is(FSM::HDL::FlattenedDT::Backend::VHDL::_convert_sequential_assignment(
            $decls, 'next_DATA <= INPUT_PORT;'),
            "next_DATA <= std_logic_vector(resize(unsigned(INPUT_PORT), next_DATA'length));",
            'actual generated register consumer uses the same assignment conversion');
        is($json->encode($decls), $before, 'complete actual caller records and JSON kinds conserve');
    }
};
subtest 'computed expressions and selections cannot borrow selected-default shapes' => sub {
    for my $width (1, 8) {
        my $decls = fixture($width);
        for my $row (
            ['INPUT_PORT + DATA', 'DATA'], ['INPUT_PORT ^ DATA', 'DATA'],
            ['DATA * FIXED', 'TYPED'], ['DATA & INPUT_PORT', 'DATA'],
            ['DATA | INPUT_PORT', 'DATA'], ['{DATA, FIXED}', 'DATA'],
            ['!DATA', 'DATA'], ['DATA[0]', 'FIXED_VALUE'],
            ['(|DATA[0])', 'FIXED_VALUE'], ['INPUT_PORT', 'DATA[0]'],
            ['INPUT_PORT == 0', 'DATA[0]'], ['0', 'DATA[0]'],
            ['TYPED', 'DATA'], ['UNKNOWN', 'DATA'], ['^DATA', 'DATA'],
        ) {
            ok(!eval {expression($row->[0], $decls, $row->[1]); 1},
                "$row->[0] to $row->[1] refuses at default $width");
            like($@, qr/symbolic.*(?:assignment|select|shape)|(?:assignment|select|shape).*symbolic/,
                'refusal identifies the symbolic assignment boundary');
        }
    }
};
subtest 'whole static assignment products and reduction targets preserve' => sub {
    my $decls = {A => {name => 'A', scalar => 0, signed => 0, msb => 7, lsb => 0},
        B => {name => 'B', scalar => 0, signed => 0, msb => 7, lsb => 0},
        FLAG => {name => 'FLAG', scalar => 1}};
    is(expression('A', $decls, 'B'), 'A', 'static identity assignment');
    is(expression('A + B', $decls, 'B'), 'std_logic_vector(unsigned(A) + unsigned(B))', 'static arithmetic');
    is(expression('(|A)', $decls, 'FLAG'), '(fsmgen_direct_vhdl_reduce_or(A))', 'static reduction scalar');
    is(expression('A[0]', $decls, 'FLAG'), 'A(0)', 'static selection');
    is(expression('7', $decls, 'B'), 'std_logic_vector(to_unsigned(7, 8))', 'static literal');
};
done_testing();
