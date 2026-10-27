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
sub condition {
    my ($text, $decls) = @_;
    return FSM::HDL::FlattenedDT::Backend::VHDL::_sv_condition_to_vhdl($text,
        {decls_by_name => $decls});
}
subtest 'actual symbolic vectors retain whole-vector truth at either selected default' => sub {
    for my $width (1, 8) {
        my $decls = fixture($width);
        my $before = $json->encode($decls);
        my $one = "fsmgen_direct_vhdl_reduce_or(DATA) = '1'";
        my $zero = "fsmgen_direct_vhdl_reduce_or(DATA) = '0'";
        for my $row (['DATA', $one], ['!DATA', $zero], ['((DATA))', $one],
            ['!((DATA))', $zero], ['!!DATA', $one],
            ['DATA && FIXED', "($one) and (FIXED = '1')"],
            ['DATA || FIXED && !DATA', "($one) or ((FIXED = '1') and ($zero))"],
            ['!(DATA && FIXED)', "($zero) or (FIXED = '0')"],
            ['!(DATA || FIXED)', "($zero) and (FIXED = '0')"],
            ["DATA && INPUT_PORT == 1'b1", "($one) and (unsigned(INPUT_PORT) = unsigned'(\"1\"))"],
            ['DATA && (|INPUT_PORT)', "($one) and ((fsmgen_direct_vhdl_reduce_or(INPUT_PORT) = '1'))"],
            ['!(^DATA)', "(fsmgen_direct_vhdl_reduce_xor(DATA) = '0')"]) {
            is(condition($row->[0], $decls), $row->[1], "$row->[0] at default $width preserves Boolean structure");
        }
        is($json->encode($decls), $before, 'complete actual caller records and JSON kinds conserve');
    }
};
subtest 'implicit whole-vector truth helper is allocated and collision-checked before rendering' => sub {
    my $decls = fixture(1);
    my %required = FSM::HDL::FlattenedDT::Backend::VHDL::_required_vector_reduction_helpers('', $decls);
    is_deeply(\%required, {'|' => 1}, 'symbolic profile reserves existing OR helper even without an explicit reduction');
    my %joined = FSM::HDL::FlattenedDT::Backend::VHDL::_required_vector_reduction_helpers('assign VALUE = (^DATA);', $decls);
    is_deeply(\%joined, {'|' => 1, '^' => 1}, 'implicit truth joins explicit operator helpers');
    ok(!eval {FSM::HDL::FlattenedDT::Backend::VHDL::_validate_vector_reduction_helper_names(
        \%required, 'fixture', [{name => 'fsmgen_direct_vhdl_reduce_or'}]); 1}, 'implicit helper collision refuses');
    like($@, qr/helper name.*collides/, 'same helper collision authority applies');
};
subtest 'unqualified symbolic condition leaves and malformed Boolean trees refuse' => sub {
    my $decls = fixture(8);
    for my $text ('DATA & INPUT_PORT', 'DATA[0]', '(|DATA[0])', '() && DATA', 'DATA == INPUT_PORT', 'DATA < 7',
        '!(DATA == 0)', '!DATA == 0', 'DATA &&', '(DATA || FIXED', 'DATA) || FIXED') {
        ok(!eval {condition($text, $decls); 1}, "$text is withheld before source activation");
        like($@, qr/condition|parenthes|symbolic/, 'refusal names its symbolic Boolean boundary');
    }
};
subtest 'static condition products and helper inventory preserve' => sub {
    my $decls = {FLAG => {name => 'FLAG', scalar => 1},
        FIXED8 => {name => 'FIXED8', scalar => 0, signed => 0, msb => 7, lsb => 0}};
    is(condition('FLAG', $decls), "FLAG = '1'", 'static bare scalar');
    is(condition('!FLAG', $decls), "FLAG = '0'", 'static negated scalar');
    is(condition('FLAG && !FLAG', $decls), "(FLAG = '1') and (FLAG = '0')", 'existing static compound condition');
    my %required = FSM::HDL::FlattenedDT::Backend::VHDL::_required_vector_reduction_helpers('', $decls);
    is_deeply(\%required, {}, 'static profile adds no implicit helper');
};
done_testing();
