use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Test::More;
use FSM::Scheduler::ISF::PreparedFormalReservations;
open my $fh,'<:raw','docs/audits/prepared-reservation-helper-causes-20261003/causes.json' or die $!;
my $data=JSON::PP->new->decode(do {local $/;<$fh>});close $fh or die $!;
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
{
 package RealReservationConsumer;
 use Test::More;
 use Storable qw(dclone);
 our $band;
 sub collect {FSM::Scheduler::ISF::PreparedFormalReservations->collect($_[0])}
 no warnings 'redefine';
 sub like {
  my ($error,$pattern,$label)=@_;
  is($error=~$pattern?1:0,$band eq 'current_fixture'?1:0,"$label: matches only intended cause");
 }
}
open $fh,'<:raw','t/1959-isf-prepared-formal-reservations.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub rejected {');my $end=index($test,'my $simple =',$start);
die 'exact helper missing' unless $start>=0 && $end>$start;
eval 'package RealReservationConsumer;'.substr($test,$start,$end-$start);die $@ if $@;
for my $row (@{$data->{rows}}) {
 my ($body)=$row->{pattern}=~/\A\(\?\^:(.*)\)\z/s;die 'undeclared pattern flags' unless defined $body;
 my $pattern=qr/$body/;die 'pattern spelling drift' unless "$pattern" eq $row->{pattern};
 my $input=restore($row->{before});$RealReservationConsumer::band=$row->{band};
 if ($row->{direct}) {
  my $ok=eval {RealReservationConsumer::collect($input);1};my $error=$@;
  ok(!$ok,'actual direct cycle/control refused');
  RealReservationConsumer::like($error,$pattern,"$row->{label} / $row->{band}");
 } else {RealReservationConsumer::rejected($input,$pattern,"$row->{label} / $row->{band}")}
}
done_testing;
