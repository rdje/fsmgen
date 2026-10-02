use strict;
use warnings;
use lib 'perl','t/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
my $base='docs/audits/conditional-macro-intent-20261002';
for my $name (qw(first_when_bit_sample first_unless_bit_sample first_when_field_sample first_unless_field_sample first_cond_sample first_bit_sample_zero domain_first_sample)) {
 subtest "desired ordinary macro branch: $name" => sub {
  my $actor=FSM::Adapter::ISF->new->parse_file("$base/sources/$name.isf");
  my $before=JSON::PP->new->canonical->encode($actor);
  my $builder=FSM::Scheduler::ISF->new->{ir};
  my $ir=$builder->build_module($actor);
  if ($name eq 'domain_first_sample') {
   my ($domain)=grep {$_->{name}eq'io'} @{$ir->{domain_partition}{domains}};
   $actor=_domain_actor_for_scheduled_artifact($actor,$domain,'idle');
   $ir=$builder->build_module($actor);
  }
  is($ir->{states}[0]{kind},'branch','conditional macro starts with a decision, not an activation gate');
  is(scalar(grep {$_->{kind}eq'branch'} @{$ir->{states}}),$name eq 'first_cond_sample'?2:1,'complete source conditional branch membership');
 };
}
done_testing;
