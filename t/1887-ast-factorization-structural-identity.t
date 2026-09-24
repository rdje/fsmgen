#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::AST::Node;
use FSM::CoreAST;
use FSM::HDL::ASTFactorization;

sub signal_ref { FSM::AST::SignalRef->new($_[0]) }
sub concat { FSM::CoreAST::Concatenation->new(map { signal_ref($_) } @_) }
sub factor {
    my @expressions = @_;
    my $f = FSM::HDL::ASTFactorization->new;
    $f->add_ast_expression($expressions[$_], "use_$_") for 0 .. $#expressions;
    return ($f, $f->analyze_and_factorize);
}
sub driver_map {
    my ($reverse) = @_;
    my @asts = (concat('A', 'A'), concat('B', 'B'), concat('A', 'B'));
    @asts = reverse @asts if $reverse;
    my (undef, $result) = factor(@asts, @asts);
    return {map { $_ => $result->{intermediate_signals}{$_}{ast}->to_systemverilog }
        keys %{$result->{intermediate_signals}}};
}

if (@ARGV && $ARGV[0] eq '--drivers') {
    print JSON::PP->new->canonical->encode(driver_map($ARGV[1]));
    exit 0;
}

subtest 'concatenation sharing preserves ordered operands and their multiplicity' => sub {
    my ($f, $result) = factor(concat('A', 'A'), concat('B', 'B'), concat('A', 'A'), concat('B', 'B'));
    my $signals = $result->{intermediate_signals};
    is_deeply([sort map { $_->{ast}->to_systemverilog } values %$signals],
        ['{A, A}', '{B, B}'], 'independent drivers survive and equal expressions share');
    is_deeply([sort map { $_->{usage_count} } values %$signals], [2, 2], 'counts belong to each expression');
    my %replacement = map { $signals->{$_}{structural_id} => $_ } keys %$signals;
    for my $name (qw(A B)) {
        my $sub = $f->substitute_ast_recursively(concat($name, $name), \%replacement);
        is($signals->{$sub->name}{ast}->to_systemverilog, "{$name, $name}", 'substitution keeps its own driver');
    }
    isnt($f->get_ast_structural_id(concat('A', 'B')), $f->get_ast_structural_id(concat('B', 'A')),
        'operand order matters');
    isnt($f->get_ast_structural_id(concat('A')), $f->get_ast_structural_id(concat('A', 'A')),
        'operand count matters');
    my $nested_a = FSM::CoreAST::Concatenation->new(concat('A', 'B'), signal_ref('C'));
    my $nested_b = FSM::CoreAST::Concatenation->new(concat('B', 'A'), signal_ref('C'));
    isnt($f->get_ast_structural_id($nested_a), $f->get_ast_structural_id($nested_b), 'nested operands matter');
};

subtest 'literal representation and signal selections cannot alias' => sub {
    my $f = FSM::HDL::ASTFactorization->new;
    my @pairs = (
        [FSM::CoreAST::Literal->new(1, width => 2), FSM::CoreAST::Literal->new(1, width => 8), 'literal width'],
        [FSM::CoreAST::Literal->new(10, width => 8, radix => 'hex'),
         FSM::CoreAST::Literal->new(10, width => 8, radix => 'decimal'), 'literal radix'],
        [FSM::AST::Literal->new(0), FSM::AST::Literal->new('unknown_value'), 'zero is a value'],
        [FSM::AST::Literal->new(1), FSM::CoreAST::Literal->new(1), 'sized legacy and unsized core literal'],
        [FSM::CoreAST::SignalRef->new(signal_ref('BUS'), slice => [3, 0]),
         FSM::CoreAST::SignalRef->new(signal_ref('BUS'), slice => [7, 4]), 'signal slice'],
        [FSM::CoreAST::SignalRef->new(signal_ref('BUS')),
         FSM::CoreAST::SignalRef->new(signal_ref('BUS'), slice => [3, 0]), 'full signal versus slice'],
        [FSM::CoreAST::AggregateRef->new(signal_ref('BUS'), [{kind => 'member', name => 'a'}]),
         FSM::CoreAST::AggregateRef->new(signal_ref('BUS'), [{kind => 'member', name => 'b'}]), 'aggregate path'],
    );
    for my $pair (@pairs) {
        my ($a, $b, $label) = @$pair;
        isnt($f->get_ast_structural_id($a), $f->get_ast_structural_id($b), $label);
        my (undef, $r) = factor(
            FSM::CoreAST::Concatenation->new($a, signal_ref('C')),
            FSM::CoreAST::Concatenation->new($b, signal_ref('C')));
        is(scalar keys %{$r->{intermediate_signals}}, 0, "$label does not create false sharing");
    }
};

subtest 'unrecognized expression kinds stay inline, including their containing expression' => sub {
    my @expressions = (
        FSM::CoreAST::IndexedRef->new(signal_ref('BUS'), 0),
        FSM::CoreAST::IndexedRef->new(signal_ref('BUS'), 1),
        FSM::CoreAST::ConditionalExpression->new(signal_ref('C'), signal_ref('A'), signal_ref('B')),
        FSM::CoreAST::ConditionalExpression->new(signal_ref('C'), signal_ref('B'), signal_ref('A')),
        FSM::CoreAST::FunctionCall->new('f', signal_ref('A')),
        FSM::CoreAST::FunctionCall->new('g', signal_ref('B')),
        FSM::CoreAST::ParameterRef->new('P'), FSM::CoreAST::ParameterRef->new('Q'),
        FSM::AST::LogicalConstant->new(0), FSM::AST::LogicalConstant->new(1),
        FSM::HDL::SubstitutedBinaryOp->new(operator => '|', left => signal_ref('A'), right => signal_ref('B')),
        FSM::HDL::SubstitutedUnaryOp->new(operator => '!', operand => signal_ref('A')),
    );
    for my $ast (@expressions) {
        my $container = FSM::AST::BinaryOp->new('|', $ast, signal_ref('C'));
        my ($f, $r) = factor($ast, $ast, $container, $container);
        is(scalar keys %{$r->{intermediate_signals}}, 0, ref($ast).' is not class-only sharing');
        is($f->substitute_ast_recursively($container, {}), $container, 'inline object preserved');
    }
};

subtest 'candidate driver names are independent of input order and hash seed' => sub {
    my $expected = JSON::PP->new->canonical->encode(driver_map(0));
    for my $seed (0, 1, 7) {
        for my $reverse (0, 1) {
            local $ENV{PERL_HASH_SEED} = $seed;
            local $ENV{PERL_PERTURB_KEYS} = 0;
            open my $fh, '-|', $^X, $0, '--drivers', $reverse or die "driver worker: $!";
            local $/;
            my $actual = <$fh>;
            close $fh;
            is($?, 0, "driver worker seed $seed order $reverse succeeds");
            is($actual, $expected, 'same named drivers');
        }
    }
};

subtest 'independent HDL simulation checks substituted concatenations with different inputs' => sub {
    my ($iverilog) = grep { -x $_ } map { File::Spec->catfile($_, 'iverilog') } File::Spec->path;
    my ($vvp) = grep { -x $_ } map { File::Spec->catfile($_, 'vvp') } File::Spec->path;
    plan skip_all => 'Icarus Verilog is required for the independent behavioral oracle'
        unless $iverilog && $vvp;
    my $work = tempdir(CLEANUP => 1);
    my ($f, $r) = factor(concat('A', 'A'), concat('B', 'B'), concat('A', 'A'), concat('B', 'B'));
    my $signals = $r->{intermediate_signals};
    my %replacement = map { $signals->{$_}{structural_id} => $_ } keys %$signals;
    # The wrapper supplies the known two-bit context; the production factorizer
    # supplies both drivers and substituted output expressions. Expected values
    # below are independently authored, not calculated from those ASTs.
    my $sv = "module tb; reg A, B; wire [1:0] OA, OB;\n";
    for my $name (sort keys %$signals) {
        $sv .= "wire [1:0] $name; assign $name = ".$signals->{$name}{ast}->to_systemverilog.";\n";
    }
    for my $name (qw(A B)) {
        $sv .= "assign O$name = ".$f->substitute_ast_recursively(concat($name, $name), \%replacement)->to_systemverilog.";\n";
    }
    $sv .= <<'SV';
initial begin
  A=0; B=0; #1; if (OA !== 0 || OB !== 0) $fatal(1, "both zero");
  A=1; B=0; #1; if (OA !== 3 || OB !== 0) $fatal(1, "A distinct from B");
  A=0; B=1; #1; if (OA !== 0 || OB !== 3) $fatal(1, "B distinct from A");
  A=1; B=1; #1; if (OA !== 3 || OB !== 3) $fatal(1, "both one");
  $display("PASS distinct concatenation substitution"); $finish;
end
endmodule
SV
    my $source = File::Spec->catfile($work, 'tb.sv');
    my $image = File::Spec->catfile($work, 'simulation.vvp');
    open my $fh, '>', $source or die "$source: $!";
    print {$fh} $sv; close $fh or die "$source: $!";
    is(system($iverilog, '-g2012', '-s', 'tb', '-o', $image, $source), 0, 'generated expressions compile');
    is(system($vvp, $image), 0, 'all independently specified values match');
};

done_testing();
