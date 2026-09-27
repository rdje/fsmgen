package FSM::Scheduler::ISF::ChildActivation;

use v5.20;
use strict;
use warnings;
use Exporter qw(import);
use FSM::Support::HDLInstanceIdentifierPolicy;

our @EXPORT_OK = qw(guard_child_activation);

# Generated do holds start until completion; spawn pulses it. Both represent
# one request per assertion, even if delayed done outlives the terminal state.
sub guard_child_activation {
    my ($ir, $entry) = @_;
    my %reserved = map { $_ => 1 } grep { defined $_ } (
        keys %{$ir->{signal_widths} || {}}, keys %{$ir->{counters} || {}},
        (map { $_->{name} } @{$ir->{ports} || []}, @{$ir->{constants} || []},
            @{$ir->{params} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    );
    my $seen = FSM::Support::HDLInstanceIdentifierPolicy->allocate_generated_instance_identifier(
        desired => 'isf_child_start_seen', role => 'activation', reserved => \%reserved);
    $ir->{counters}{$seen} = $ir->{signal_widths}{$seen} = 1;
    $ir->{reset_values}{$seen} = 0;
    $ir->{storage_roles}{$seen} = 'child_start_history';
    push @{$ir->{explicit_internal_signals}}, $seen;
    push @{$ir->{dt_blocks}}, {
        name => $seen, kind => 'child_activation', assignments => [
            {lhs => $seen, rhs => 'start', op => '<-', source_kind => 'child_start_history'},
        ],
    };
    my $guard = {expr => "(& start (! $seen))", expr_ast => ['&', 'start', ['!', $seen]]};
    $entry->{guard} = $guard;
    $_->{condition} = $guard for @{$entry->{transitions} || []};
}

1;
