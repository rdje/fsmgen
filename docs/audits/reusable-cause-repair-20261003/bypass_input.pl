use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Scheduler::ISF;
my $base = 'docs/audits/reusable-cause-repair-20261003';
my $json = JSON::PP->new->canonical;
open my $fh, '<:raw', "$base/bypass.pl" or die $!;
my $script = do {local $/; <$fh>};
close $fh or die $!;
my $end = index($script, "my \$result = do './t/1947");
die 'exact bypass setup missing' unless $end > 0;
eval substr($script, 0, $end);
die $@ if $@;
open $fh, '<:raw', "$base/prior-causes.json" or die $!;
my $prior = $json->decode(do {local $/; <$fh>});
close $fh or die $!;
my ($fixture) = grep {
    $_->{id} eq 'library versus generated module collision'
        && $_->{band} eq 'current_fixture'
        && $_->{method} eq 'prepare_formal_source'
} @{$prior->{rows}};
die 'exact collision actor missing' unless $fixture;
my @rows;
for my $method (qw(prepare_formal_source build_module)) {
    my $actor = $json->decode($json->encode($fixture->{actor_before}));
    my $before = $json->encode($actor);
    my $lowerer = FSM::Scheduler::ISF->new->{ir};
    my $result;
    my $accepted = eval {$result = $lowerer->$method($actor); 1};
    my $error = $@;
    push @rows, {method => $method, source => $fixture->{source},
        original => $json->decode($before), actor => $json->decode($json->encode($actor)),
        accepted => $accepted ? 1 : 0, error => $error, result => $result};
}
open my $out, '>:raw', "$base/bypass-inputs.json" or die $!;
print {$out} $json->encode({rows => \@rows}), "\n" or die $!;
close $out or die $!;
print "Captured complete actual collision-bypass inputs and results.\n";
