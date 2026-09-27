package FSM::Scheduler::ISF::DriveInvocationSources;

use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;
use FSM::Package::AggregatePathSupport;

# Validate the producer association, not execution exclusion. Actual emitted
# guards and their qualification remain a separate writer-activation contract.
sub resolve {
    my ($class, $dt, $index) = @_;
    confess "Drive invocation requires a named-drive assignment index\n"
        unless ref($dt) eq 'HASH' && ($dt->{kind} // '') eq 'drive'
            && ref($dt->{assignments}) eq 'ARRAY'
            && defined($index) && !ref($index) && $index =~ /\A(?:0|[1-9][0-9]*)\z/
            && $index < @{$dt->{assignments}};
    my $assignment = $dt->{assignments}[$index];
    my $owner = $dt->{source_owner};
    confess "Drive invocation requires an explicit drive source owner\n"
        unless ref($owner) eq 'HASH' && ($owner->{kind} // '') eq 'drive' && _name($owner->{name});
    my $invocation = ref($assignment) eq 'HASH' ? $assignment->{drive_invocation} : undef;
    confess "Drive invocation requires an explicit per-assignment source\n"
        unless ref($invocation) eq 'HASH' && keys(%$invocation) == 4
            && _name($invocation->{drive}) && $invocation->{drive} eq $owner->{name}
            && _name($invocation->{request_signal}) && _name($invocation->{kind});
    if ($invocation->{kind} eq 'local') {
        confess "Drive invocation has inconsistent local callers\n"
            unless _names($invocation->{local_transactions}) && _names($dt->{local_transaction_callers})
                && _same($invocation->{local_transactions}, $dt->{local_transaction_callers})
                && $invocation->{request_signal} eq "$invocation->{drive}_start"
                && ($assignment->{source_kind} // '') eq 'drive_body';
    } elsif ($invocation->{kind} eq 'generated') {
        my $source = $invocation->{generated_source};
        my @keys = qw(activation_kind child_transaction instance owner owner_kind prefix source_kind);
        confess "Drive invocation has malformed generated source identity\n"
            unless ref($source) eq 'HASH' && keys(%$source) == @keys
                && !grep {!_name($source->{$_})} @keys;
        my $sources = $dt->{generated_call_sources};
        confess "Drive invocation has no matching generated producer source\n"
            unless ref($sources) eq 'ARRAY'
                && (grep {ref($_) eq 'HASH' && _same($_, $source)} @$sources) == 1
                && $invocation->{request_signal} eq "$source->{prefix}_start"
                && ($assignment->{source_kind} // '') eq $source->{source_kind};
    } else {
        confess "Drive invocation has an unknown source kind\n";
    }
    return FSM::Package::AggregatePathSupport->clone_structured_value($invocation);
}
sub _name {defined($_[0]) && !ref($_[0]) && length($_[0])}
sub _names {
    my ($names) = @_;
    return 0 unless ref($names) eq 'ARRAY' && !grep {!_name($_)} @$names;
    my %seen;
    return !grep {$seen{$_}++} @$names;
}
sub _same {JSON::PP->new->canonical->encode($_[0]) eq JSON::PP->new->canonical->encode($_[1])}

1;
