package FSM::Test::GeneratedWidthIR;

use strict;
use warnings;
use JSON::PP;
use Exporter 'import';
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

our @EXPORT_OK = qw(generated_width_actor generated_width_products);
my $json = JSON::PP->new->canonical;

sub generated_width_actor {
    my ($case) = @_;
    die "unknown generated width case\n" unless $case eq 'generated' || $case eq 'plain';
    return FSM::Adapter::ISF->new->parse_file("t/data/isf-generated-width-ir/$case.isf");
}

sub generated_width_products {
    my %products;
    for my $case (qw(generated plain)) {
        my $actor = generated_width_actor($case);
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $ir = $scheduler->{ir}->build_module($actor);
        my $files = $scheduler->lower($actor)->{files};
        my $report = $scheduler->report($actor);
        $products{$case} = {actor => $json->decode($before), ir => $ir,
            files => $files, report => $report,
            caller_unchanged => $json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false};
    }
    return \%products;
}

1;
