use strict;
use warnings;
use lib 'perl';
use Scalar::Util qw(blessed refaddr);
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;
# Deliberately reproduce the old requirement selector. Keep source preparation,
# inference, rendering, declaration/assignment ledgers and every final guard live.
sub overscoped_literal {
    my ($node, $active, $remaining, $depth, $rows) = @_;
    return 0 unless blessed($node);
    die "Direct literal emission selector exceeds its bounded tree\n"
        if $depth > FSM::CoreExpressionWidthSupport::MAX_DEPTH() || --$$remaining < 0;
    my $identity = refaddr($node);
    die "Direct literal emission selector contains a cycle\n" if $active->{$identity};
    local $active->{$identity} = 1;
    return 1 if $node->isa('FSM::CoreAST::Literal');
    if ($node->isa('FSM::CoreAST::SignalRef')) {
        my $signal = $node->{signal};
        return blessed($signal) && ($signal->{attributes}{is_intermediate}
            || (ref($rows) eq 'HASH' && ref($rows->{$signal->{name}}) eq 'HASH'
                && ($rows->{$signal->{name}}{source} // '') eq 'fsmgen_parsing'))
            ? overscoped_literal($signal->{driving_ast}, $active, $remaining, $depth + 1, $rows) : 0;
    }
    for my $operand (@{ref($node->{operands}) eq 'ARRAY' ? $node->{operands} : []}) {
        return 1 if overscoped_literal($operand, $active, $remaining, $depth + 1, $rows);
    }
    return 0;
}
{
    no warnings 'redefine';
    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::_contains_literal
        = \&overscoped_literal;
    my $result = do './t/2297-scalar-literal-guard-emission.t';
    die $@ if $@;
    die $! unless defined $result;
}
