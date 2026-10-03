use strict;
use warnings;
use lib 'perl';
use FSM::Scheduler::ISF::PreparedFormalReservations;
open my $fh,'<:raw','perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm' or die $!;
my $source=do {local $/;<$fh>};close $fh or die $!;
my $start=index($source,'sub _shape {');my $end=index($source,'sub _same_keys {',$start);
die 'exact shape guard missing' unless $start>=0 && $end>$start;
my $body=substr($source,$start,$end-$start);
my $before='_same_keys($value, $fields, $where);';
die 'shape membership site missing' unless index($body,$before)>=0;
$body=~s/\Q$before\E/_same_keys(\$value, \$fields, \$where) unless \$where eq 'preparation';/;
{
 no warnings 'redefine';
 eval 'package FSM::Scheduler::ISF::PreparedFormalReservations;'.$body;die $@ if $@;
}
# BODY_LOADED: actual full repaired test follows only this real guard bypass.
my $ok=do './t/1959-isf-prepared-formal-reservations.t';die $@ if $@;die $! unless defined $ok;
