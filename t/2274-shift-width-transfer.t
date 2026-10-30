use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::CoreAST;
use FSM::AST::Node;
use FSM::CoreExpressionWidthSupport;
use FSM::ExpressionNamer;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::ASTFactorization;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport;

my $json = JSON::PP->new->canonical;
sub reference {
    return FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_[0], width => $_[1]));
}

subtest 'Core and named results follow the left operand independently of amount width' => sub {
    for my $operator (qw(<< >> <<< >>> shl shr sal sar)) {
        for my $bits (1, 8) {
            my $left = reference('A', $bits);
            for my $amount (reference('AMOUNT', 64), FSM::CoreAST::Literal->new('1')) {
                my $expression = FSM::CoreAST::BinaryOp->new($operator, $left, $amount);
                my $namer = FSM::ExpressionNamer->new;
                is(FSM::CoreExpressionWidthSupport->infer_width($expression), $bits,
                    "$operator exact result ignores amount width");
                is($namer->infer_ast_width($expression), $bits, "$operator Core naming width agrees");
                my $name = $namer->name_ast_expression($expression);
                is($namer->get_signal_definitions->{$name}{width}, $bits,
                    "$operator stored named definition agrees");
                my $concat = FSM::CoreAST::Concatenation->new($expression, reference('B', 3));
                is(FSM::CoreExpressionWidthSupport->infer_width($concat), $bits + 3,
                    'concatenation sums shifted data and independent part widths');
                is($left->signal->width, $bits, 'left source width is unchanged');
            }
        }
    }
    my $calls = 0;
    my $shift = FSM::CoreAST::BinaryOp->new('<<', reference('A', 8), FSM::CoreAST::Literal->new('1'));
    is(FSM::CoreExpressionWidthSupport->infer_width($shift,
        unsized_literal_width => sub {++$calls; 32}), 8, 'target amount floor cannot widen shifted data');
    is($calls, 0, 'width-only inference need not resolve the amount');
    my $unknown_left = FSM::CoreAST::BinaryOp->new('<<', FSM::CoreAST::Literal->new('3'), reference('AMOUNT', 64));
    ok(!defined FSM::CoreExpressionWidthSupport->infer_width($unknown_left),
        'known amount cannot make an unknown left width exact');
    is(FSM::CoreExpressionWidthSupport->infer_width($unknown_left, unsized_literal_width => sub {32}),
        32, 'an explicit caller policy may still resolve the left literal');
    is(FSM::CoreExpressionWidthSupport->infer_width(FSM::CoreAST::BinaryOp->new('+', reference('A', 8), reference('B', 64))),
        64, 'ordinary binary maximum preserves both independent operands');
};

subtest 'runtime and substituted width consumers retain their own left-width evidence' => sub {
    my $source = '(?fsm:shift_width (+size (A 8) (AMOUNT 64) (DATA 1) (OTHER 1))'
        .' (idle (<(<< A AMOUNT) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $namer = FSM::ExpressionNamer->new;
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->new(
        flattened_dt => {fsm_module => $module, expr_namer => $namer});
    for my $operator (qw(<< >> <<< >>>)) {
        my $left = FSM::AST::SignalRef->new('A');
        my $right = FSM::AST::Literal->new("64'd1");
        my $runtime = FSM::AST::BinaryOp->new($operator, $left, $right);
        my $substituted = FSM::HDL::SubstitutedBinaryOp->new(operator => $operator, left => $left, right => $right);
        is($namer->infer_ast_width($runtime), 1,
            "$operator runtime namer preserves its context-free reference width");
        is($support->infer_width_from_intermediate_ast($runtime), 8,
            "$operator runtime backend uses actual left source width");
        is($support->infer_width_from_intermediate_ast($substituted), 8,
            "$operator substituted backend uses actual left source width");
    }
};

subtest 'actual fixed native declarations agree without changing the amount or caller' => sub {
    for my $operator (qw(<< >> <<< >>>)) {for my $bits (1, 8) {for my $amount ('AMOUNT', '1') {
        my $source = "(?fsm:shift_native (+size (A $bits) (AMOUNT 64) (DATA 1) (OTHER 1))"
            ." (idle (<($operator A $amount) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $raw = scalar Lispish::multi(\$source);
        my $before = $json->encode($raw);
        my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
        my $core_before = $json->encode({map {$_ => $module->signals->{$_}->width} keys %{$module->signals}});
        for my $language (qw(systemverilog verilog)) {
            my $backend = FSM::HDL::FlattenedDT->new;
            my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my ($hdl, $error);
            {
                local $backend->{declared_width_declaration_capture} = $capture;
                eval {$hdl = $language eq 'verilog' ? $backend->generate_verilog($module)
                    : $backend->generate_systemverilog($module); 1} or $error = $@;
            }
            is($error, undef, "$language $operator fixed $bits generation completes") or diag $error;
            next if $error;
            my %assignments = $hdl =~ /^  assign (\w+) = ([^;]+);/mg;
            my @names = grep {$assignments{$_} eq "A $operator $amount"} keys %assignments;
            is(scalar(@names), 1, 'complete actual shift expression preserves both operands');
            next unless @names == 1;
            my $name = $names[0];
            my $snapshot = $capture->snapshot;
            is($snapshot->{target_declarations}{$name}{width}, $bits,
                'actual helper width follows shifted data, independently of amount');
            my $range = $bits == 1 ? '' : '[7:0] ';
            like($hdl, qr/^  wire \Q$range$name\E;$/m, 'actual declaration agrees with the captured width');
            is($snapshot->{target_declarations}{AMOUNT}{width}, 64, 'independent amount declaration stays wide')
                if $amount eq 'AMOUNT';
            is($module->signals->{A}->width, $bits, 'Core left declaration preserves');
            is($json->encode({map {$_ => $module->signals->{$_}->width} keys %{$module->signals}}),
                $core_before, 'complete actual Core declaration membership and widths preserve');
            is($json->encode($raw), $before, 'complete caller source and JSON kinds preserve');
        }
    }}}
};
done_testing();
