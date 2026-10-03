use strict;
use warnings;
use lib 't/lib';
use JSON::PP;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
open my $fh,'<:raw','docs/audits/formal-resource-cause-repair-20261003/current-causes.json' or die $!;
my $json=JSON::PP->new->canonical;my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
print $json->encode([map {diagnostic_cause_matches($_->{error},$_->{expected_cause})} @$rows]),"\n";
