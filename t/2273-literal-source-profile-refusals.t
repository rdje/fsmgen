use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;

sub parsed {
    my $source = q{(?fsm:literal_profile (+params (W 8))
      (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1))
      (idle (<(& A B 3) (= (DATA 1)) (= (OTHER 1))) (-> idle)))};
    my $raw = scalar Lispish::multi(\$source);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my @helpers = grep {exists $_->{_source_literal_width_allocation}} values %{$module->signals};
    die 'fixture requires one literal source helper' unless @helpers == 1;
    return ($module, $helpers[0], $raw);
}

sub generate {
    my ($ctx, $module) = @_;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my ($hdl, $error);
    {
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {$hdl = $ctx->generate_systemverilog($module); 1} or $error = $@;
    }
    return ($hdl, $error, $capture);
}

subtest 'actual constrained Core sources cannot borrow an earlier literal width policy' => sub {
    # These are private Core-profile interventions, not new source syntax.
    my @cases = (
        ['signed operand', sub {$_[0]->signals->{A}{signed} = 1}],
        ['named operand', sub {$_[0]->signals->{A}{declared_type_name} = 'foreign'}],
        ['typed operand', sub {$_[0]->signals->{A}{declared_type_spec} = {kind => 'foreign'}}],
        ['state operand', sub {$_[0]->signals->{A}{state_model} = {kind => 'foreign'}}],
        ['opaque operand', sub {push @{$_[0]->signals->{A}{constraints}}, {kind => 'independent'}}],
        ['signed result', sub {$_[1]{signed} = 1}],
        ['declared result', sub {$_[1]->set_attribute('width_declared', 1)}],
        ['opaque result', sub {push @{$_[1]{constraints}}, {kind => 'independent'}}],
    );
    for my $case (@cases) {
        my ($module, $helper, $raw) = parsed();
        my $before = $json->encode($raw);
        $case->[1]->($module, $helper);
        my $ctx = FSM::HDL::FlattenedDT->new;
        my ($hdl, $error, $capture) = generate($ctx, $module);
        ok(defined($error) && length($error), "$case->[0] refuses actual generation") or diag($hdl // 'no HDL');
        like($error // '', qr/(?:literal|current.*source intent)/i,
            'refusal identifies the literal source-proof boundary');
        ok(!defined($hdl), 'no HDL escapes the unsupported independent profile');
        ok(!eval {$capture->snapshot; 1}, 'failure leaves no valid completed capture');
        is($json->encode($raw), $before, 'caller source kinds preserve during refusal');
        ok(!exists($ctx->{direct_declared_width_emitted_literal_ranges})
            && !exists($ctx->{direct_declared_width_emitted_literal_assignments}),
            'failed generation leaves no literal emission ledger');
        my ($fresh, undef, $fresh_raw) = parsed();
        my $fresh_before = $json->encode($fresh_raw);
        my ($good_hdl, $good_error, $good_capture) = generate($ctx, $fresh);
        is($good_error, undef, 'fresh same-backend source recovers') or diag($good_error);
        ok(defined($good_hdl) && eval {$good_capture->snapshot; 1}, 'fresh source returns HDL and completed capture');
        like($good_hdl // '', qr/\bA & B & 3;/, 'fresh source retains the original expression');
        is($json->encode($fresh_raw), $fresh_before, 'fresh caller source kinds preserve');
    }
};

done_testing();
