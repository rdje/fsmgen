use strict;
use warnings;
use lib 'perl','t/lib';
use JSON::PP;
use Cwd qw(abs_path);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
my $j=JSON::PP->new->canonical;
my $base='docs/audits/conditional-macro-intent-20261002';
open my $cf,'<',"$base/cases.json" or die $!; local $/; my $cases=$j->decode(<$cf>);
my %all;
for my $case (@$cases) {
 my $path="$base/sources/$case->{name}.isf";
 my ($actor,$parse_error,$ir,$private_error,$lowered,$lower_error);
 eval {$actor=FSM::Adapter::ISF->new->parse_file($path);1} or $parse_error=$@;
 if($actor) {
  eval {$lowered=FSM::Scheduler::ISF->new->lower($actor);1} or $lower_error=$@;
  eval {
   my $a=$j->decode($j->encode($actor));
   my $builder=FSM::Scheduler::ISF->new->{ir};
   my $formal=FSM::Scheduler::ISF::FormalLowering->prepare($builder,$a);
   $a=$formal->{actor} if $formal;
   $ir=$builder->build_module($a);
   if (($case->{context}//'')eq'domain') {
    my ($domain)=grep {$_->{name}eq'io'} @{$ir->{domain_partition}{domains}};
    $a=_domain_actor_for_scheduled_artifact($a,$domain,'idle');
    $ir=$builder->build_module($a);
   }
   1;
  } or $private_error=$@;
 }
 $all{$case->{name}}={case=>$case,actor=>$actor,parse_error=>$parse_error,private_ir=>$ir,private_error=>$private_error,lowered=>$lowered,lower_error=>$lower_error};
}
print $j->encode(normalize_repository_paths(\%all,abs_path('.'))),"\n";
