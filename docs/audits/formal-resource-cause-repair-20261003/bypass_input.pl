use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Scheduler::ISF;
my $base='docs/audits/formal-resource-cause-repair-20261003';my $json=JSON::PP->new->canonical;
open my $fh,'<:raw',"$base/current-causes.json" or die $!;
my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
my $row=(grep {$_->{consumer} eq 'helper' && $_->{id} eq 'raw formal alias' && $_->{band} eq 'current_fixture'} @$rows)[0];die 'whole raw alias input missing' unless $row;
my $actor=$row->{actor};my $before=$json->encode($actor);my $module;
{
    no warnings 'redefine';
    *FSM::Scheduler::ISF::LoweringIR::_validate_round_robin_rule_user_resource=sub {
        my ($ir,$name,$users)=@_;
        return FSM::Scheduler::ISF::LoweringIR::_round_robin_pointer_declaration($name,$users);
    };
}
my $ok=eval {$module=FSM::Scheduler::ISF->new->{ir}->build_module($actor);1};my $error=$@;
open my $out,'>:raw',"$base/bypass-input.json" or die $!;
print {$out} $json->encode({source=>$row->{source},actor=>$actor,module=>$module,accepted=>$ok?1:0,error=>$error,unchanged=>$before eq $json->encode($actor)?1:0}),"\n";close $out or die $!;
print "Captured genuine resource-validation bypass input/output.\n";
