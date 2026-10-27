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
sub condition {
    my ($text, $decls) = @_;
    return FSM::HDL::FlattenedDT::Backend::VHDL::_sv_condition_to_vhdl($text,
        {decls_by_name => $decls});
}
subtest 'symbolic sized comparisons keep numeric meaning without selected-default sizing' => sub {
    for my $width (1, 8) {
        my $decls = fixture($width);
        my $before = $json->encode($decls);
        for my $op (qw(== != < <= > >=)) {
            my $vop = $op eq '==' ? '=' : $op eq '!=' ? '/=' : $op;
            for my $literal (["1'b1", '"1"'], ["4'hF", '"1111"']) {
                my ($sv, $bits) = @$literal;
                for my $name (qw(DATA INPUT_PORT)) {
                    is(condition("$name $op $sv", $decls), "unsigned($name) $vop unsigned'($bits)",
                        "$name $op $sv at default $width uses numeric vector overloads");
                    is(condition("$sv $op $name", $decls), "unsigned'($bits) $vop unsigned($name)",
                        "reversed $sv $op $name preserves orientation");
                }
            }
        }
        is($json->encode($decls), $before, 'complete actual declarations and JSON kinds conserve');
    }
};
subtest 'decimal equality and boolean result literals use elaborated operand and target ranks' => sub {
    for my $width (1, 8) {
        my $decls = fixture($width);
        my $before = $json->encode($decls);
        for my $op (qw(== !=)) {
            my $vop = $op eq '==' ? '=' : '/=';
            for my $value (0, 1, 7) {
                is(condition("DATA $op $value", $decls), "unsigned(DATA) $vop $value", 'natural overload avoids truncating a too-wide decimal');
                is(condition("$value $op DATA", $decls), "$value $vop unsigned(DATA)", 'reversed natural overload');
            }
        }
        is(expression('INPUT_PORT == 0', $decls, 'DATA'),
            "std_logic_vector(to_unsigned(1, DATA'length)) when unsigned(INPUT_PORT) = 0 else std_logic_vector(to_unsigned(0, DATA'length))",
            'boolean result uses actual symbolic target length');
        is($json->encode($decls), $before, 'decimal consumers preserve caller data');
    }
};
subtest 'signed symbolic decimal contract and unsupported signed sized comparisons stay explicit' => sub {
    my $decls = {TARGET => {name => 'TARGET', scalar => 0, signed => 1, msb => 0, lsb => 0,
        vhdl_type => 'signed((W - 1) downto 0)', vhdl_range => '((W - 1) downto 0)'}};
    my $before = $json->encode($decls);
    is(condition('TARGET == 7', $decls), 'TARGET = 7', 'signed numeric scalar equality');
    is(condition('7 != TARGET', $decls), '7 /= TARGET', 'reversed signed numeric scalar inequality');
    is(expression('TARGET == 0', $decls, 'TARGET'),
        "to_signed(1, TARGET'length) when TARGET = 0 else to_signed(0, TARGET'length)", 'signed boolean result retains vector rank');
    ok(!eval {condition('TARGET == -1', $decls); 1}, 'negative comparison keeps existing arithmetic refusal');
    like($@, qr/arithmetic expression/, 'negative comparison has no new admission');
    for my $text ("TARGET == 4'hF", "4'hF != TARGET") {
        ok(!eval {condition($text, $decls); 1}, 'signed symbolic sized comparison is withheld');
        like($@, qr/signed symbolic.*comparison/, 'refusal identifies unsupported signed comparison');
    }
    is($json->encode($decls), $before, 'explicit downstream signed records conserve');
};
subtest 'static products and invalid literals retain their bounded contracts' => sub {
    my $decls = {FIXED => {name => 'FIXED', scalar => 1},
        FIXED8 => {name => 'FIXED8', scalar => 0, signed => 0, msb => 7, lsb => 0}};
    is(condition('FIXED == 1', $decls), "FIXED = '1'", 'static scalar equality');
    is(condition("FIXED8 < 1'b1", $decls), 'FIXED8 < "00000001"', 'static unsigned sized comparison');
    is(condition('FIXED8 == 7', $decls), 'FIXED8 = "00000111"', 'static vector decimal equality');
    is(expression('FIXED == 0', $decls, 'FIXED8'), '"00000001" when FIXED = \'0\' else "00000000"', 'static vector boolean result');
    my $symbolic = fixture(1);
    for my $case (['DATA == -1', qr/arithmetic expression|negative equality/], ["DATA == 2'b101", qr/literal|fit/],
        ["DATA == 3'bx01", qr/x\/z/]) {
        ok(!eval {condition($case->[0], $symbolic); 1}, "invalid $case->[0] refuses");
        like($@, $case->[1], 'existing literal restriction remains visible');
    }
};
done_testing();
