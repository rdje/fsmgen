use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF::PreparedFormalReservations;
use FSM::Test::DiagnosticCause;
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw','docs/audits/prepared-reservation-helper-causes-20261003/causes.json' or die $!;
my $fixtures=$json->decode(do {local $/;<$fh>});close $fh or die $!;
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
sub restore {
 my ($value,$nodes,$path)=@_;$nodes||={};$path//='';
 return $value unless ref($value);
 if (ref($value) eq 'HASH' && exists $value->{'$cycle'}) {return $nodes->{$value->{'$cycle'}} // die 'missing cycle root'}
 if (ref($value) eq 'HASH' && exists $value->{'$blessed'}) {
  die 'unknown native marker' unless $value->{'$blessed'} eq 'PreparedCauseSentinel' && !keys %{$value->{'$value'}};
  return bless {},'PreparedCauseSentinel';
 }
 if (ref($value) eq 'HASH') {my $out={};$nodes->{$path}=$out;for my $key (keys %$value) {$out->{$key}=restore($value->{$key},$nodes,"$path/$key")} return $out}
 if (ref($value) eq 'ARRAY') {my $out=[];$nodes->{$path}=$out;push @$out,restore($value->[$_],$nodes,"$path/$_") for 0..$#$value;return $out}
 die 'undeclared descriptor';
}
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

open $fh,'<:raw','t/1959-isf-prepared-formal-reservations.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub rejected {');my $end=index($test,'my $simple =',$start);
die 'exact helper missing' unless $start>=0 && $end>$start;
my $helper=substr($test,$start,$end-$start);
$start=index($test,'my $ok = eval {collect($bad); 1};');
$end=index($test,"\n};",$start);die 'exact direct cycle assertion missing' unless $start>=0 && $end>$start;
my $direct=substr($test,$start,$end-$start);
{
 package CurrentReservationCauseSubject;
 use Storable qw(dclone);
 our ($bad,@bits,@errors);
 sub collect {FSM::Scheduler::ISF::PreparedFormalReservations->collect($_[0])}
 sub ok {push @bits,$_[0]?1:0;return $_[0]}
 sub is_deeply {return 1}
 sub diag {}
 sub diagnostic_cause_matches {
  push @errors,$_[0];return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
 }
}
# Compile before native API calls; no active source eval can echo a reason.
eval 'package CurrentReservationCauseSubject; our $bad;'.$helper.'sub direct_consumer {'.$direct."\n}";die $@ if $@;
my @captures;
for my $row (@{$fixtures->{rows}}) {
 my $input=restore($row->{before});my $before=graph($input);
 my $expected=expected_cause($row->{label});
 @CurrentReservationCauseSubject::bits=();@CurrentReservationCauseSubject::errors=();
 if ($row->{direct}) {$CurrentReservationCauseSubject::bad=$input;CurrentReservationCauseSubject::direct_consumer()}
 else {CurrentReservationCauseSubject::rejected($input,$expected,"$row->{label} / $row->{band}")}
 is_deeply(\@CurrentReservationCauseSubject::bits,[1,$row->{band} eq 'current_fixture'?1:0],"$row->{label} / $row->{band}: complete cause only");
 is((split /\n/,$CurrentReservationCauseSubject::errors[0])[0],(split /\n/,$row->{error})[0],"$row->{label} / $row->{band}: actual primary conserved");
 is($json->encode(graph($input)),$json->encode($before),"$row->{label} / $row->{band}: complete caller graph and kinds unchanged");
 push @captures,{label=>$row->{label},direct=>$row->{direct},band=>$row->{band},expected_cause=>$expected,
  before=>$before,after=>graph($input),error=>$CurrentReservationCauseSubject::errors[0],assertions=>[@CurrentReservationCauseSubject::bits]};
}
if (defined $ENV{FSMGEN_PREPARED_CAUSE_CAPTURE}) {
 open my $out,'>:raw',$ENV{FSMGEN_PREPARED_CAUSE_CAPTURE} or die $!;
 print {$out} $json->encode({rows=>\@captures}),"\n" or die $!;close $out or die $!;
}
done_testing;
