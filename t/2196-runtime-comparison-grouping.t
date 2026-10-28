use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::AST::Node;
use FSM::CoreAST;
use FSM::Synthesis::EnableGraph::CaptureSupport;

my $json = JSON::PP->new->canonical;
sub signal {FSM::AST::SignalRef->new($_[0])}
sub binary {FSM::AST::BinaryOp->new(@_)}
sub shape {
    my ($ast) = @_;
    return ['signal',$ast->name] if $ast->isa('FSM::AST::SignalRef');
    return ['literal',$ast->value] if $ast->isa('FSM::AST::Literal');
    return [$ast->operator,shape($ast->left),shape($ast->right)];
}
sub evaluate_rendered {
    my ($text,$values) = @_;
    $text =~ s/\b([ABC])\b/$values->{$1}/ge;
    # A closed test-only integer grammar. Perl gives comparisons higher
    # precedence than bitwise &/|, independently of the production printer.
    die 'non-closed test expression' unless $text =~ /\A[0-9\s()&|=!<>]+\z/;
    my $result = eval $text;
    die $@ if $@;
    return 0 + $result;
}

subtest 'every comparison retains actual bitwise child grouping in either orientation' => sub {
    for my $compare ('==','!=','<','>','<=','>=') {
        for my $bitwise ('&','|') {
            for my $right (0,1) {
                my $bits = binary($bitwise,signal('A'),signal('B'));
                my $ast = $right ? binary($compare,signal('C'),$bits) : binary($compare,$bits,signal('C'));
                my $before = $json->encode(shape($ast));
                my $expected = $right ? "C $compare (A $bitwise B)" : "(A $bitwise B) $compare C";
                is($ast->to_systemverilog, $expected, 'complete expression preserves the actual comparison operand tree');
                is($json->encode(shape($ast)), $before, 'rendering keeps the complete caller expression and JSON kinds');
            }
        }
    }
};

subtest 'actual rendered text preserves independent distinguishing literal outcomes' => sub {
    for my $case (
        ['&',0,{A=>2,B=>2,C=>2},1], ['|',0,{A=>2,B=>0,C=>3},0],
        ['&',1,{A=>2,B=>2,C=>2},1], ['|',1,{A=>1,B=>2,C=>2},0],
    ) {
        my ($op,$right,$values,$expected) = @$case;
        my $bits = binary($op,signal('A'),signal('B'));
        my $ast = $right ? binary('==',signal('C'),$bits) : binary('==',$bits,signal('C'));
        is(evaluate_rendered($ast->to_systemverilog,$values),$expected,
            'emitted syntax yields the independently expected comparison value');
    }
};

subtest 'actual Core capture text now agrees with the canonical grouped comparison' => sub {
    my $left = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>'A',width=>8));
    my $right = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>'B',width=>8));
    my $core = FSM::CoreAST::BinaryOp->new('==',FSM::CoreAST::BinaryOp->new('|',$left,$right),
        FSM::CoreAST::Literal->new('00000011',width=>8,radix=>'binary'));
    my $capture = FSM::Synthesis::EnableGraph::CaptureSupport->new(flattened_dt=>{});
    is($core->to_systemverilog,"(A | B) == 8'b11",'independent actual Core producer retains grouping');
    is($capture->convert_condition_to_ast($core)->to_systemverilog,"(A | B) == 8'b11",
        'runtime capture preserves complete typed comparison text');
};

subtest 'ordinary scalar, logical, bitwise and already-grouped operator products preserve' => sub {
    for my $case (
        [binary('==',signal('A'),signal('B')),'A == B'],
        [binary('&',signal('A'),signal('B')),'A & B'],
        [binary('|',signal('A'),signal('B')),'A | B'],
        [binary('^',signal('A'),signal('B')),'(A ^ B)'],
        [binary('&&',signal('A'),signal('B')),'(A && B)'],
        [binary('|',binary('==',signal('A'),signal('B')),signal('C')),'(A == B) | C'],
        [binary('==',binary('+',signal('A'),signal('B')),signal('C')),'(A + B) == C'],
        [binary('==',binary('^',signal('A'),signal('B')),signal('C')),'(A ^ B) == C'],
    ) {is($case->[0]->to_systemverilog,$case->[1],'complete existing unrelated expression spelling preserves')}
};
done_testing();
