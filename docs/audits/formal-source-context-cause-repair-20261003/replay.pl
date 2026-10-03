use strict;
use warnings;
use lib 't/lib';
use JSON::PP;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
my $base='docs/audits/formal-source-context-cause-repair-20261003';
open my $fh,'<:raw',"$base/current-causes.json" or die $!;
my $json=JSON::PP->new->canonical;my $data=$json->decode(do {local $/;<$fh>});close $fh or die $!;
my @rows;
for my $r (@{$data->{rows}}) {
 push @rows,{id=>$r->{id},band=>$r->{band},matched=>diagnostic_cause_matches($r->{error},$r->{expected_cause})?1:0};
}
print $json->encode(\@rows),"\n";
