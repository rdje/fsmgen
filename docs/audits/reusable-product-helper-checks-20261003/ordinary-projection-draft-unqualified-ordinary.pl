use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;
my $base='docs/audits/reusable-product-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
our $s=FSM::Scheduler::ISF->new;our $l=$s->{ir};our $work='';
open my $fh,'<:raw','t/1947-isf-formal-reusable-products.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub parse {');my $end=index($test,'sub qualify {',$start);
die 'exact ordinary helpers missing' unless $start>=0 && $end>$start;
eval substr($test,$start,$end-$start);die $@ if $@;
my ($mixed)=$test=~/my \$mixed = <<'ISF';
(.*?)
ISF/s;die 'mixed source missing' unless defined $mixed;$mixed.="\n";
my @rows;
for my $id (qw(fifo_library_use atl_resolved_child_pipeline
 atl_resolved_child_pin_ingress_vector_multi_pipeline
 atl_resolved_child_pin_egress_vector_multi_pipeline
 atl_two_child_vector_data_pipeline atl_two_child_trigger_batch_pipeline mixed external raw_width)) {
 my ($source,$actor);
 if ($id=~/^(mixed|raw_width)$/) {
  $source=$mixed;
  $source=~s/\(transaction worker/(storage (var payload (width 8))) (transaction worker/ if $id eq 'raw_width';
  $actor=parse($source);
 } elsif ($id eq 'external') {
  $source='(actor external (instance reader of packet_reader) (transaction main (wait 1)))';$actor=parse($source);
 } else {
  open $fh,'<:raw',"isf/$id.isf" or die $!;$source=do {local $/;<$fh>};close $fh or die $!;
  $actor=file_actor("isf/$id.isf");
  push @{$actor->{transactions}},parse('(actor scratch (transaction local_main (ports (input local_delay (width 4))) (wait local_delay)))')->{transactions}[0];
 }
 my $before_text=$json->encode($actor);my $p=$l->prepare_formal_source($actor);my $physical=project($p);
 my $module=$id eq 'raw_width'?undef:$l->build_module($actor);
 my $physical_module=$l->build_module($physical);my $reprepared=$l->prepare_formal_source($physical);
 die 'input mutation' unless $json->encode($actor) eq $before_text && $json->encode($p->{actor}) eq $before_text;
 die 'reusable before drift' if defined($module) && $json->encode(actual_products($module,$p->{generated_children})) ne $json->encode($p->{reusable_child_products});
 die 'reusable projection drift' unless $json->encode(actual_products($physical_module,$p->{generated_children})) eq $json->encode($p->{reusable_child_products}) && $json->encode($reprepared->{reusable_child_products}) eq $json->encode($p->{reusable_child_products});
 push @rows,{id=>$id,source=>$source,actor=>$actor,original=>$json->decode($before_text),prepared=>$p,physical=>$physical,module=>$module,physical_module=>$physical_module,reprepared=>$reprepared};
}
open my $out,'>:raw',"$base/products.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
print 'PASS nine complete reusable source/preparation/physical/module observations and exact reusable equality.',"\n";
