use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw','t/1947-isf-formal-reusable-products.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub source_value_copy {');my $end=index($test,'sub parse {',$start);
die 'exact copier missing' unless $start>=0 && $end>$start;
eval substr($test,$start,$end-$start);die $@ if $@;
open $fh,'<:raw','docs/audits/reusable-projection-kind-repair-20261003/products.json' or die $!;
my $fixtures=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
my $l=FSM::Scheduler::ISF->new->{ir};my @rows;
for my $row (@$fixtures) {
 my $actor=FSM::Adapter::ISF->new->parse_source($row->{source},
  $row->{id}=~/^(mixed|raw_width|external)$/?'reusable_products.isf':"isf/$row->{id}.isf");
 if ($row->{id}!~/^(mixed|raw_width|external)$/) {
  push @{$actor->{transactions}},FSM::Adapter::ISF->new->parse_source('(actor scratch (transaction local_main (ports (input local_delay (width 4))) (wait local_delay)))','reusable_products.isf')->{transactions}[0];
 }
 my $p=$l->prepare_formal_source($actor);my $before=$json->encode($p->{actor});
 my $current=source_value_copy($p->{actor});my $prior=dclone($p->{actor});
 push @rows,{id=>$row->{id},source=>$row->{source},original=>$json->decode($before),
  current=>$current,prior=>$prior,after=>$p->{actor}};
}
open my $out,'>:raw','docs/audits/reusable-projection-kind-repair-20261003/clone-inputs.json' or die $!;
print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
print "Captured actual prepared actor current/pure and prior/Storable clone inputs.\n";
