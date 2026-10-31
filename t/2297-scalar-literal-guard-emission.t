use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $json = JSON::PP->new->canonical;
sub fixture {
    my ($expression, %args) = @_;
    my $params = $args{mutable} ? '(+params (W 8))' : '';
    my $a = $args{mutable} ? '(param W)' : 8;
    my $text = "(?fsm:scalar_literals $params (+size (A $a) (B 128) (G 2) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $original = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    is($json->encode($raw), $original, 'caller source and literal kinds preserve');
    my @helpers = map {$module->signals->{$_}} grep {
        $module->signals->{$_}{attributes}{is_intermediate}
    } sort keys %{$module->signals};
    return ($module, \@helpers);
}
sub generate {
    my ($module, %args) = @_;
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my ($hdl, $error);
    {
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {
            $hdl = $args{verilog} ? $ctx->generate_verilog($module)
                : $ctx->generate_systemverilog($module);
            1;
        } or $error = $@;
    }
    return ($hdl, $error, $capture);
}
sub refused {
    my ($module) = @_;
    my ($hdl, $error, $capture) = generate($module);
    like($error // '', qr/Direct literal emission requires current completed source intent/,
        'unproved source still refuses at the original intent guard');
    ok(!defined($hdl), 'no HDL escapes a refused source');
    ok(!eval {$capture->snapshot; 1}, 'failed generation exposes no partial declaration proof');
}

subtest 'comparison inputs and literal sizes do not widen scalar result guards' => sub {
    for my $operator (qw(== != < <= > >=)) {
        for my $verilog (0, 1) {
            my ($module, $helpers) = fixture("(| ($operator A 128'd1) ($operator B 0))");
            is(scalar(@$helpers), 1, 'guard has one actual physical helper');
            my $helper = $helpers->[0];
            ok(!$helper->source_literal_width_allocation, 'scalar-only literals gain no data-maximum policy');
            ok(!$class->requires_emission($helper), 'typed scalar result stops data-literal selection');
            my ($hdl, $error, $capture) = generate($module, verilog => $verilog);
            is($error, undef, 'actual target generation succeeds') or diag($error);
            next if $error;
            is($capture->snapshot->{target_declarations}{$helper->name}{width}, 1,
                'physical target really is scalar');
            like($hdl, qr/^  wire \Q@{[$helper->name]}\E;$/m, 'actual HDL has a scalar wire');
        }
    }
};

subtest 'logical negation and nested generated children retain their own scalar widths' => sub {
    for my $expression (
        '(& (! B) (== A 0))',
        '(& (! (| (== A 128\'d1) (== B 0))) G)',
        '(^ (| (== A 0) (== B 0)) (| (== A 0) (== B 0)))',
    ) {
        my ($module, $helpers) = fixture($expression);
        my ($hdl, $error, $capture) = generate($module);
        is($error, undef, 'nested native generation succeeds') or diag($error);
        next if $error;
        for my $helper (@$helpers) {
            my $expected = $helper->{driving_ast}{operator} eq '&' && $expression =~ / G\)/ ? 2 : 1;
            is($capture->snapshot->{target_declarations}{$helper->name}{width}, $expected,
                'every physical nested helper agrees with independent scalar/data arithmetic');
        }
    }
};

subtest 'actual data literals and physical children still require original proof' => sub {
    for my $change (
        sub {delete $_[0]{_source_literal_width_allocation}},
        sub {$_[0]{driving_ast}{operands}[1]{value} = '1'},
    ) {
        my ($module, $helpers) = fixture("(| A 1'b0)");
        ok($helpers->[0]->source_literal_width_allocation, 'true data literal has original intent');
        $change->($helpers->[0]);
        refused($module);
    }
    my ($module, $helpers) = fixture("(& (! (| A 1'b1)) (== B 0))");
    my @literal_children = grep {$_->source_literal_width_allocation} @$helpers;
    is(scalar(@literal_children), 1, 'logical parent retains an actual data-literal child');
    my ($hdl, $error, $capture) = generate($module);
    is($error, undef, 'logical parent and data child generate with their separate contracts') or diag($error);
    if (!$error) {
        is($capture->snapshot->{target_declarations}{$literal_children[0]->name}{width}, 8,
            'physical child preserves the data width under scalar negation');
    }
    delete $literal_children[0]{_source_literal_width_allocation};
    refused($module);
};

subtest 'scalar-only mutable and standalone behavior retains its existing family' => sub {
    my ($mutable, $helpers) = fixture('(| (== A 0) (== B 0))', mutable => 1);
    ok(!$_->source_literal_width_allocation, 'mutable scalar operands gain no data-literal policy') for @$helpers;
    my ($hdl, $error) = generate($mutable);
    is($error, undef, 'existing scalar comparison behavior remains accepted') or diag($error);
    my ($standalone, $standalone_helpers) = fixture('(== A 0)');
    is(scalar(@$standalone_helpers), 0, 'standalone comparison remains inline without a literal helper');
};

done_testing();
