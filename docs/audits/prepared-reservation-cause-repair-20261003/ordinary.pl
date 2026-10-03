use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Scalar::Util qw(refaddr blessed);
use FSM::Scheduler::ISF::PreparedFormalReservations;
my $json=JSON::PP->new->canonical;
my $base='docs/audits/prepared-reservation-cause-repair-20261003';
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
my @rows=map {my %row=%$_;delete $row{native};\%row} @api;
open my $out,'>:raw',"$base/current-api.json" or die $!;
print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
