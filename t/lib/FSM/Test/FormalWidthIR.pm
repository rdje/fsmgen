package FSM::Test::FormalWidthIR;

use strict;
use warnings;
use JSON::PP;
use Exporter 'import';
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

our @EXPORT_OK = qw(formal_width_actor formal_width_products);
my $json = JSON::PP->new->canonical;

sub formal_width_actor {
    my ($case) = @_;
    die "unknown formal width case\n" unless $case eq 'scopes' || $case eq 'literals' || $case eq 'mixed';
    return FSM::Adapter::ISF->new->parse_file("t/data/isf-formal-width-ir/$case.isf");
}

sub formal_width_products {
    my %products;
    for my $case (qw(scopes literals mixed)) {
        my $actor = formal_width_actor($case);
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
        die "expected actual direct-formal preparation\n" unless $context;
        my $physical_before = $json->encode($context->{actor});
        my $ir = $scheduler->{ir}->build_module($context->{actor});
        FSM::Scheduler::ISF::FormalLowering->verify($context, {$ir->{actor_name} => $ir});
        my $physical_after = $json->encode($context->{actor});
        my $files = $scheduler->lower($actor)->{files};
        my $report = $scheduler->report($actor);
        $products{$case} = {
            actor => $json->decode($before), context => $context, ir => $ir,
            physical_before => $json->decode($physical_before),
            files => $files, report => $report,
            caller_unchanged => $json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false,
            physical_unchanged => $physical_before eq $physical_after ? JSON::PP::true : JSON::PP::false,
        };
    }
    return \%products;
}

1;
