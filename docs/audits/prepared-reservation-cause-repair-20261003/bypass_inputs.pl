use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Scheduler::ISF::PreparedFormalReservations;
open my $fh,'<:raw','docs/audits/prepared-reservation-cause-repair-20261003/bypass.pl' or die $!;
my $source=do {local $/;<$fh>};close $fh or die $!;
my $at=index($source,'# BODY_LOADED:');die 'body boundary missing' unless $at>=0;
eval substr($source,0,$at);die $@ if $@;
my $json=JSON::PP->new->canonical;
open $fh,'<:raw','docs/audits/prepared-reservation-helper-causes-20261003/default-api.json' or die $!;
my $original=$json->decode(do {local $/;<$fh>})->{rows}[0]{before};close $fh or die $!;
my @rows;
for my $kind (qw(missing_optional_category unknown_producer)) {
 my $input=$json->decode($json->encode($original));
 if ($kind eq 'missing_optional_category') {delete $input->{domain_partition}}
 else {$input->{new_producer_products}={}}
 my $before=$json->encode($input);my $result;
 my $ok=eval {$result=FSM::Scheduler::ISF::PreparedFormalReservations->collect($input);1};my $error=$@;
 push @rows,{kind=>$kind,original=>$original,before=>$json->decode($before),after=>$input,
  accepted=>$ok?1:0,error=>$error,result=>$ok?$result:undef};
}
open my $out,'>:raw','docs/audits/prepared-reservation-cause-repair-20261003/bypass-inputs.json' or die $!;
print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
