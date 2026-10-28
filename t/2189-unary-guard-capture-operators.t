use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Synthesis::EnableGraph::CaptureSupport;

my $json = JSON::PP->new->canonical;
my $capture = FSM::Synthesis::EnableGraph::CaptureSupport->new(flattened_dt => {});
sub signal { FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'INPUT', width => $_[0])) }
sub unary { FSM::CoreAST::UnaryOp->new(operator => $_[0], operand => $_[1]) }
sub evaluate {
    my ($ast, $value, $width) = @_;
    return $value if $ast->isa('FSM::AST::SignalRef');
    die 'unexpected captured AST' unless $ast->isa('FSM::AST::UnaryOp');
    my $operand = evaluate($ast->operand, $value, $width);
    my $op = $ast->operator;
    return $operand ? 0 : 1 if $op eq '!';
    return ((1 << $width) - 1) ^ $operand if $op eq '~';
    return -$operand if $op eq '-';
    return $operand if $op eq '+';
    my @bits = map {($operand >> $_) & 1} 0 .. $width - 1;
    return ($operand != 0 ? 1 : 0) if $op eq '|';
    return ($operand == (1 << $width) - 1 ? 1 : 0) if $op eq '&';
    my $parity = 0; $parity ^= $_ for @bits;
    return $parity if $op eq '^';
    die "unexpected captured operator $op";
}
sub source {
    my ($width, $op, $negative) = @_;
    my $guard = $negative ? '<!' : '<';
    return "(?fsm:guard_ops (+params (W $width)) (+interface (output DATA) (output OTHER))"
        .' (+size (DATA 1) (OTHER 1) (INPUT (param W)))'
        ." (idle ($guard($op INPUT) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
}
sub parse {my ($text) = @_; FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text))}
sub condition {$_[0]->states->[0]->decision_trees->[0]->elements->[0]->branches->[0]{condition}}

subtest 'capture preserves actual unary opcodes and distinct fixed truth controls' => sub {
    my %expected = (
        1 => {'^' => [0,1], '&' => [0,1], '|' => [0,1], '!' => [1,0], '~' => [1,0],
            neg => [0,-1], pos => [0,1], not => [1,0]},
        8 => {'^' => [0,1,0,0], '&' => [0,0,0,1], '|' => [0,1,1,1], '!' => [1,0,0,0], '~' => [255,254,252,0],
            neg => [0,-1,-3,-255], pos => [0,1,3,255], not => [1,0,0,0]},
    );
    my %aliases = (neg => '-', pos => '+', not => '!');
    for my $width (1, 8) {
        my @values = $width == 1 ? (0,1) : (0,1,3,255);
        for my $op ('^','&','|','!','~','neg','pos','not') {
            my $core = unary($op, signal($width));
            is($core->type, 'unary_op', 'generic node type does not identify its operation');
            my $runtime = $capture->convert_condition_to_ast($core);
            is($runtime->operator, $aliases{$op} // $op, "$op actual operation survives capture at width $width");
            is_deeply([map {evaluate($runtime, $_, $width)} @values], $expected{$width}{$op},
                'independent literal truth values distinguish reductions/complement from logical NOT');
            is($core->operator, $op, 'capture leaves original operation unchanged');
        }
    }
};

subtest 'actual parsed positive and negative reduction guards retain recursive operations in native capture' => sub {
    for my $width (1, 8) {
        for my $op ('^','&','|','!') {
            for my $negative (0,1) {
                my $module = parse(source($width, $op, $negative));
                my $core = condition($module);
                is($core->operator, $negative ? '!' : $op, 'actual parser retains the authored outer guard operation');
                is($core->operand->operator, $op, 'negative guard retains inner operation') if $negative;
                my $before = $json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]);
                my $converted = $capture->convert_condition_to_ast($core);
                is($converted->operator, $negative ? '!' : $op, 'actual native condition keeps outer operation');
                is($converted->operand->operator, $op, 'negative native guard keeps inner operation') if $negative;
                my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
                my $hdl = $dt->generate_systemverilog($module);
                if (!$negative && $op ne '!') {
                    like($hdl, qr/^  assign \w+ = \(\Q$op\E\(INPUT\)\); \/\/ Source: ast_factorization$/m,
                        'whole actual factored native guard reduces the complete input');
                    my ($predicate) = $hdl =~ /^  assign (\w+) = \(\Q$op\E\(INPUT\)\); \/\/ Source: ast_factorization$/m;
                    if (defined $predicate) {
                        for my $target ('data', 'other') {
                            like($hdl, qr/^  assign idle_\Q$target\E_1_en = idle_en & \Q$predicate\E; /m,
                                'actual output selector uses the positive reduction predicate with state gating');
                        }
                    }
                }
                is($json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]), $before,
                    'complete source parameter maps and JSON kinds conserve');
            }
        }
    }
};

subtest 'malformed or unsupported unary operation cannot borrow a logical NOT default' => sub {
    for my $bad (undef, '', {}, 'UNKNOWN') {
        my $core = unary('!', signal(8)); $core->{operator} = $bad;
        ok(!eval {$capture->convert_condition_to_ast($core); 1}, 'malformed unary opcode refuses');
        like($@, qr/unary.*operator/i, 'operation contract is named');
    }
};
done_testing();
