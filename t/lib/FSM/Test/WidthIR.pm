package FSM::Test::WidthIR;

use strict;
use warnings;
use JSON::PP;
use Exporter 'import';
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

our @EXPORT_OK = qw(width_ir_actor width_ir_products);
my $json = JSON::PP->new->canonical;

sub width_ir_actor {
    my ($case) = @_;
    die "unknown width IR case\n" unless $case eq 'actor' || $case eq 'plain';
    return FSM::Adapter::ISF->new->parse_file("t/data/isf-width-ir/$case.isf");
}

sub width_ir_products {
    my %products;
    for my $case (qw(actor plain)) {
        my $actor = width_ir_actor($case);
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $prepared = $scheduler->{ir}->prepare_formal_source($actor);
        my $ir = $scheduler->{ir}->build_module($actor);
        my $files = $scheduler->lower($actor)->{files};
        my $report = $scheduler->report($actor);
        $products{$case} = {
            actor => $json->decode($before), prepared => $prepared, ir => $ir,
            files => $files, report => $report,
            caller_unchanged => $json->encode($actor) eq $before
                ? JSON::PP::true : JSON::PP::false,
        };
    }
    return \%products;
}

1;
