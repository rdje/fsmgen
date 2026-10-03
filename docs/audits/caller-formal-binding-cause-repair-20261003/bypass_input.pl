use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
my $json=JSON::PP->new->canonical;
my $base='docs/audits/caller-formal-binding-cause-repair-20261003';
open my $fh,'<:raw',"$base/current-causes.json" or die $!;
my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
my $row=$rows->[0];my $actor=$row->{actor};my $before=$json->encode($actor);
{
    no warnings 'redefine';
    *FSM::Scheduler::ISF::LoweringIR::_validate_transaction_port_bindings=sub {return 1};
}
my $ok=eval {FSM::Scheduler::ISF::LoweringIR->new->_validate_transaction_port_bindings($actor);1};my $error=$@;
open my $out,'>:raw',"$base/bypass-input.json" or die $!;
print {$out} $json->encode({source=>$row->{source},actor=>$actor,error=>$error,accepted=>$ok?1:0,unchanged=>$before eq $json->encode($actor)?1:0}),"\n";
close $out or die $!;
print "PASS real binding-validation bypass capture.\n";
