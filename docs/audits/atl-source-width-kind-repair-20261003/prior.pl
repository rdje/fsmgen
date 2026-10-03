use strict;
use warnings;
use lib 'perl', 't/lib';
use FSM::Scheduler::ISF;
open my $fh, '-|', 'git', 'show',
    'b30ed324e63549180f50c3d624d386258fba7405:perl/FSM/Scheduler/ISF/LoweringIR.pm' or die $!;
my $source = do {local $/; <$fh>};
close $fh or die $!;
my $start = index($source, 'sub _ensure_atl_child_data_source_ports {');
my $end = index($source, 'sub _atl_generated_top_data_links', $start);
die 'exact prior guard missing' unless $start >= 0 && $end > $start;
{
    no warnings 'redefine';
    eval 'package FSM::Scheduler::ISF::LoweringIR;' . substr($source, $start, $end - $start);
    die $@ if $@;
}
my $result = do './t/2059-isf-atl-source-width-kind-preservation.t';
die $@ if $@;
die $! unless defined $result;
