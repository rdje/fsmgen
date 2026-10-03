use strict;
use warnings;
use lib 't/lib';
use JSON::PP;
use FSM::Test::DiagnosticCause;
my $base='docs/audits/local-formal-helper-cause-repair-20261003';
my $json=JSON::PP->new->canonical;
sub read_json {open my $fh,'<:raw',$_[0] or die $!;my $raw=do {local $/;<$fh>};close $fh or die $!;return $json->decode($raw)}
my $current=read_json("$base/bindings.json")->{sources}{'t/2052-isf-local-formal-origin-authority.t'};
my $helper=substr($current,index($current,'sub first_line {'),index($current,'sub unrelated_refusal {')-index($current,'sub first_line {'));
eval "package ReplayCurrent; use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches); $helper";die $@ if $@;
my $old=read_json('docs/audits/local-formal-helper-causes-20261003/bindings.json');
eval 'package ReplayPrior;'.$old->{helper};die $@ if $@;
my $cases=read_json('docs/audits/local-formal-helper-causes-20261003/causes.json');
my %patterns=map {$_->{id} => $_->{pattern}} @{$cases->{rows}};
delete $ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK};
my @rows;
for my $r (@{read_json("$base/current-causes.json")->{rows}}) {
    my $pattern=eval 'qr/'.$patterns{$r->{id}}.'/';die $@ if $@;
    push @rows,{id=>$r->{id},band=>$r->{band},current=>ReplayCurrent::diagnostic_matches($r->{error},$r->{expected_cause})?1:0,prior=>ReplayPrior::diagnostic_matches($r->{error},$pattern)?1:0};
}
print $json->encode(\@rows),"\n";
