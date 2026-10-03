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
my $helpers=substr($test,$start,$end-$start);
my $old='my $a = dclone($p->{actor});';
my $new='my $a = copy_value($p->{actor});';
die 'exact project clone site missing' unless index($helpers,$old)>=0;
$helpers=~s/\Q$old\E/$new/;
sub copy_value {
 my ($value)=@_;
 return [map {copy_value($_)} @$value] if ref($value) eq 'ARRAY';
 return {map {$_=>copy_value($value->{$_})} keys %$value} if ref($value) eq 'HASH';
 return $value;
}
eval $helpers;die $@ if $@;
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
 my $input_equal=$json->encode($actor) eq $before_text?1:0;
 my $prepared_actor_equal=$json->encode($p->{actor}) eq $before_text?1:0;
 die 'reusable before drift' if defined($module) && $json->encode(actual_products($module,$p->{generated_children})) ne $json->encode($p->{reusable_child_products});
 my $physical_equal=$json->encode(actual_products($physical_module,$p->{generated_children})) eq $json->encode($p->{reusable_child_products})?1:0;
 my $reprepared_equal=$json->encode($reprepared->{reusable_child_products}) eq $json->encode($p->{reusable_child_products})?1:0;
 push @rows,{id=>$id,source=>$source,actor=>$actor,original=>$json->decode($before_text),input_equal=>$input_equal,prepared_actor_equal=>$prepared_actor_equal,prepared=>$p,physical=>$physical,module=>$module,physical_module=>$physical_module,reprepared=>$reprepared,physical_equal=>$physical_equal,reprepared_equal=>$reprepared_equal};
}
open my $out,'>:raw',"$base/pure-products.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
print 'PASS nine complete reusable source/preparation/physical/module observations with pure-copy FIFO equality and recorded remaining caller-width kind gaps.',"\n";
