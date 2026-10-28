use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::HDL::FlattenedDT;

my $json = JSON::PP->new->canonical;
sub source {
    my ($width, $expression, $symbolic) = @_;
    my $header = $symbolic ? "(+params (W $width))" : '';
    my $slot = $symbolic ? '(param W)' : $width;
    return "(?fsm:bitwise_guard $header (+size (A $slot) (B $slot) (C $slot) (DATA 1) (OTHER 1))"
        ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
}
sub parse {my ($s) = @_; FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$s))}
sub intermediates {
    my ($m) = @_;
    return grep {$_->get_attribute('is_intermediate') && $_->driving_ast} values %{$m->signals};
}
sub source_snapshot {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {my $s = $m->signals->{$_}; $_ => [$s->width, $s->declared_width_source,
            $s->declared_width_binding, $s->declared_width_requirements]} keys %{$m->signals}}]);
}

subtest 'actual parser-created bitwise helpers retain declared vector widths before native generation' => sub {
    my %ops = ('&' => '&', '|' => '|', '^' => '^', and => '&', or => '|', xor => '^');
    for my $width (1, 8) {
        for my $symbolic (0, 1) {
            for my $op ('&', '|', '^', 'and', 'or', 'xor') {
                my $m = parse(source($width, "($op A B)", $symbolic));
                my @helpers = intermediates($m);
                is(scalar(@helpers), 1, 'actual source creates one owned helper');
                my $helper = $helpers[0]; my $name = $helper->name;
                is($helper->width, $width, 'Core width agrees with independent declared operand widths before backend inference');
                is($helper->driving_ast->operator, $ops{$op}, 'actual helper retains the authored bitwise operation');
                my $before = source_snapshot($m);
                my $hdl = eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m)};
                ok(defined($hdl), "fixed/captured source generates at operand width $width") or diag $@;
                next unless defined($hdl);
                my $range = $width == 1 ? '' : '[7:0] ';
                like($hdl, qr/^  wire \Q$range$name\E;$/m, 'complete emitted helper declaration agrees with Core');
                like($hdl, qr/^  assign \Q$name\E = A \Q$ops{$op}\E B; \/\/ Source: fsmgen_parsing$/m,
                    'actual data expression preserves bitwise values');
                my $gate = $width == 1 ? '&' : '&&';
                for my $output ('data', 'other') {
                    like($hdl, qr/^  assign idle_\Q$output\E_1_en = idle_en \Q$gate\E \Q$name\E; /m,
                        'complete state selector uses logical whole-vector truth for wide helpers');
                }
                is(source_snapshot($m), $before, 'complete source captures, selected widths and JSON kinds conserve');
            }
        }
    }
};

subtest 'literal high-bit controls distinguish logical state gating from low-bit truncation' => sub {
    my $m = parse(source(8, '(& A B)', 0)); my ($helper) = intermediates($m);
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m);
    my $name = $helper->name;
    my ($gate) = $hdl =~ /^  assign idle_data_1_en = idle_en (&&|&) \Q$name\E; /m;
    ok(defined($gate), 'actual native selector exposes its gate operation');
    my @words = (0, 2, 128, 255);
    # For A=B these are the literal results of bitwise AND. This oracle reads
    # the emitted gate, independently of the parser's width inference kernel.
    my @actual = map {$gate eq '&&' ? ($_ != 0 ? 1 : 0) : ((1 & $_) & 1)} @words;
    is_deeply(\@actual, [0,1,1,1], 'both distinct high-bit-only values enable the active state');
    is_deeply([map {$gate eq '&&' ? (0 && $_) : ((0 & $_) & 1)} @words], [0,0,0,0], 'inactive state disables every word');
};

subtest 'nested n-ary comparison and scalar-reduction contexts keep their distinct widths' => sub {
    for my $case (
        ['(& A B C)', 8, 1, [qw(A B C)]], ['(| A (& B C))', 8, 2, [qw(A B C)]],
        ["(== (| A B) 8'd3)", 8, 1, [qw(A B)]], ['(| (^ A) (& B))', 1, 1, [qw(A B)]],
    ) {
        my ($expression, $expected, $count, $inputs) = @$case;
        my $m = parse(source(8, $expression, 1)); my @helpers = intermediates($m);
        is(scalar(@helpers), $count, 'actual nested helper count is independent of allocation names');
        is_deeply([sort map {$_->width} @helpers], [($expected) x $count], 'every actual helper preserves its own expression width');
        is_deeply([map {$m->signals->{$_}->width} @$inputs], [(8) x @$inputs], 'helper sizing cannot resize its source operands');
        ok(eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m); 1}, 'actual nested source generates without declaration/source mismatch') or diag $@;
    }
};

subtest 'direct builder preserves literal width constraints without resizing signal operands' => sub {
    my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $manager);
    my $signal = $manager->register_signal('BIT', width => 1);
    my $literal = FSM::CoreAST::Literal->new('10000000', width => 8, radix => 'binary');
    my $reference = $builder->finalize_nary_expression('|', [FSM::CoreAST::SignalRef->new($signal), $literal]);
    is($reference->signal->width, 8, 'literal width is an independent max constraint on the computed result');
    is($signal->width, 1, 'actual source signal remains one bit');
    is($literal->width, 8, 'literal retains its independent width');
    ok(!defined($reference->signal->declared_width_binding), 'numeric sizing does not invent mutable source provenance');
    my $unknown = FSM::CoreAST::Expression->new(type => 'future_width_shape');
    my $unknown_result = $builder->finalize_nary_expression('&', [FSM::CoreAST::SignalRef->new($signal), $unknown]);
    ok(!defined($builder->infer_exact_expression_width($unknown_result->signal->driving_ast)), 'unproved expression width stays unknown');
    is($unknown_result->signal->width, 1, 'unknown-width private construction retains its existing placeholder');
    is($signal->width, 1, 'unknown result cannot resize the actual input');

};
done_testing();
