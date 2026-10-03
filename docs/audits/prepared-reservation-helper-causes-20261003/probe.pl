use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF::PreparedFormalReservations;
my $json=JSON::PP->new->canonical;
my $base='docs/audits/prepared-reservation-helper-causes-20261003';
sub graph {
 my ($value,$active,$path)=@_;$active||={};$path//='';
 return $value unless ref($value);
 my $address=refaddr($value);
 return {'$cycle'=>$active->{$address}} if exists $active->{$address};
 local $active->{$address}=$path;
 return {'$blessed'=>blessed($value),'$value'=>{}} if blessed($value);
 if (ref($value) eq 'HASH') {return {map {$_=>graph($value->{$_},$active,"$path/$_")} keys %$value}}
 if (ref($value) eq 'ARRAY') {return [map {graph($value->[$_],$active,"$path/$_")} 0..$#$value]}
 die 'undeclared native reference';
}
my @api;my @genuine;my $original=FSM::Scheduler::ISF::PreparedFormalReservations->can('collect');
my $real_like=Test::More->can('like');
{
 no warnings 'redefine';
 local *FSM::Scheduler::ISF::PreparedFormalReservations::collect=sub {
  my ($class,$input)=@_;my $before=graph($input);my ($result,$error);
  my $ok=eval {$result=$original->($class,$input);1};$error=$@;
  push @api,{before=>$before,after=>graph($input),accepted=>$ok?1:0,error=>$error,result=>$ok?graph($result):undef,native=>$input};
  die $error unless $ok;return $result;
 };
 local *Test::More::like=sub {
  my ($error,$pattern,$label)=@_;my $row=$api[-1];die 'missing real refusal' unless $row && !$row->{accepted};
  push @genuine,{%$row,label=>$label,pattern=>$pattern,error=>$error};
  return $real_like->(@_);
 };
 my $ok=do './t/1959-isf-prepared-formal-reservations.t';die $@ if $@;die $! unless defined $ok;
}
# Complete expected causes are declared from input schema/ownership contracts.
sub expected_cause {
 my ($label)=@_;$label=~s/ has a focused diagnostic$//;
 my %top=map {$_=>1} qw(actor actor_context deferred_formal_collisions domain_source_products generated_child_products generated_children parent_activation_products parent_completion_products parent_named_completion_products parent_point_products parent_payload_snapshot_products parent_storage_read_products parent_storage_write_products parent_wiring_products pruned_transactions reusable_child_products transaction_products transactions resource_signal_products domain_partition transaction_binding_report_products);
 return "Prepared formal reservations have incomplete preparation (missing: $1; unexpected: )" if $label=~/^missing ([a-z_]+)$/ && $top{$1};
 return "Prepared formal reservations have malformed preparation field '$1'" if $label=~/^malformed ([a-z_]+)$/ && $top{$1};
 my %known=(
  'unknown producer must be classified'=>'Prepared formal reservations have incomplete preparation (missing: ; unexpected: new_producer_products)',
  'missing live transaction producer'=>'Prepared formal reservations have incomplete transaction products (missing: main; unexpected: )',
  'unknown context'=>'Prepared formal reservations have incomplete transaction contexts (missing: ; unexpected: ghost)',
  'unknown generated child'=>'Prepared formal reservations have unknown generated_children membership',
  'unknown partition'=>'Prepared formal reservations have an unknown domain partition kind',
  'unclassified reusable product'=>'Prepared formal reservations have incomplete reusable children (missing: ; unexpected: unclassified)',
  'missing domain'=>'Prepared formal reservations have incomplete domain products (missing: aux; unexpected: )',
  'wrong domain owner'=>'Prepared formal reservations have mismatched domain identity',
  'missing nested actor'=>'Prepared formal reservations have incomplete preparation (missing: actor; unexpected: )',
  'missing child module'=>'Prepared formal reservations have incomplete generated children (missing: worker; unexpected: )',
  'missing nested producer'=>'Prepared formal reservations have incomplete preparation (missing: parent_completion_products; unexpected: )',
  'erased domain in both product maps'=>'Prepared formal reservations have incomplete source domain membership (missing: aux; unexpected: )',
  'wrong partition realization'=>'Prepared formal reservations have mismatched domain partition kind',
  'erased child IR'=>"Prepared formal reservations have malformed child scope 'worker'",
  'erased partition'=>'Prepared formal reservations are missing the source domain partition',
  'cycle diagnostic retained'=>"Formal reservation inventory has a cycle at '/actor_context/cycle'",
 );
 die "undeclared caller $label" unless exists $known{$label};return $known{$label};
}
{
 package PreparedReservationCauseSubject;
 use Storable qw(dclone);
 our (@bits,@errors);
 sub collect {FSM::Scheduler::ISF::PreparedFormalReservations->collect($_[0])}
 sub ok {push @bits,$_[0]?1:0;return $_[0]}
 sub like {push @errors,$_[0];my $matched=$_[0]=~$_[1]?1:0;push @bits,$matched;return $matched}
 # The cause observer measures only ok/like bits; before/after graphs
 # independently qualify input preservation.
 sub is_deeply {return 1}
}
open my $fh,'<:raw','t/1959-isf-prepared-formal-reservations.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub rejected {');my $end=index($test,'my $simple =',$start);
die 'exact helper missing' unless $start>=0 && $end>$start;
eval 'package PreparedReservationCauseSubject;'.substr($test,$start,$end-$start);die $@ if $@;
my @rows;
for my $fixture (@genuine) {
 my $cause=expected_cause($fixture->{label});my $direct=$fixture->{label} eq 'cycle diagnostic retained';
 die "genuine cause differs: $fixture->{label}; expected $cause; actual $fixture->{error}" unless (split /\n/,$fixture->{error})[0] eq $cause;
 for my $band (qw(current_fixture earlier_reference primary_cause_echo)) {
  my $input=dclone($fixture->{native});
  if ($band ne 'current_fixture') {
   my $key=$band eq 'primary_cause_echo'?$cause:'_early_reference';
   $input->{$key}=bless {},'PreparedCauseSentinel';
  }
  my $before=graph($input);@PreparedReservationCauseSubject::bits=();@PreparedReservationCauseSubject::errors=();
  if ($direct) {
   my $ok=eval {PreparedReservationCauseSubject::collect($input);1};my $error=$@;
   PreparedReservationCauseSubject::ok(!$ok);PreparedReservationCauseSubject::like($error,$fixture->{pattern},'direct cycle');
  } else {
   PreparedReservationCauseSubject::rejected($input,$fixture->{pattern},$fixture->{label});
  }
  my $error=$PreparedReservationCauseSubject::errors[0];
  push @rows,{label=>$fixture->{label},direct=>$direct?1:0,band=>$band,expected_cause=>$cause,
   pattern=>"$fixture->{pattern}",before=>$before,after=>graph($input),error=>$error,
   assertions=>[@PreparedReservationCauseSubject::bits],primary_matched=>((split /\n/,$error)[0]=~$fixture->{pattern}?1:0)};
 }
}
open my $out,'>:raw',"$base/causes.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
my @plain_api=map {my %r=%$_;delete $r{native};\%r} @api;
open $out,'>:raw',"$base/default-api.json" or die $!;print {$out} $json->encode({rows=>\@plain_api}),"\n" or die $!;close $out or die $!;
print STDERR 'Captured ',scalar(@genuine),' original refusal consumers / ',scalar(@rows)," actual cause bands.\n";
