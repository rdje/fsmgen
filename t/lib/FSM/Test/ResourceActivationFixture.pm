package FSM::Test::ResourceActivationFixture;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(resource_activation_source resource_activation_cases);

sub resource_activation_cases { return qw(priority round_robin literals_priority literals_round_robin mixed reverse unbound) }

sub resource_activation_source {
    my ($case) = @_;
    die "Unknown resource activation fixture '$case'\n"
        unless grep { $_ eq $case } resource_activation_cases();
    my $arbiter = $case =~ /round_robin/ || $case eq 'mixed' || $case eq 'reverse'
        ? 'round_robin' : 'priority';
    my @resources = ("(resource shared (kind rule_slot) (arbiter $arbiter) (users low middle high))");
    push @resources, '(resource extra (kind rule_slot) (arbiter priority) (users high low))'
        if $case eq 'mixed' || $case eq 'reverse';
    @resources = reverse @resources if $case eq 'reverse';
    @resources = ('(resource parking (kind named_drive) (arbiter priority))') if $case eq 'unbound';
    my @requests = $case =~ /^literals/ ? ('0', '1', '(& a b)') : ('a', 'b', '(& a c)');
    return "(actor activation_$case (clock clk) (reset rst_n)\n"
        . '(interface (input start) (input a) (input b) (input c) (output done)'
        . ' (output low_value (width 8)) (output middle_value (width 8)) (output high_value (width 8)))'
        . ' (transaction main (on start) (complete done))'
        . ' (priority high over middle) (priority middle over low)'
        . ' (resources ' . join(' ', @resources) . ')'
        . " (rule low (when $requests[0]) (set low_value 3))"
        . " (rule middle (when $requests[1]) (set middle_value 5))"
        . " (rule high (when $requests[2]) (set high_value 7)))\n";
}

1;
