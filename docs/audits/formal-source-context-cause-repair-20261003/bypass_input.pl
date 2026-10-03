use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
my $base='docs/audits/formal-source-context-cause-repair-20261003';
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw','docs/audits/formal-source-context-helper-causes-20261003/corrected-live.json' or die $!;
my $input=$json->decode(do {local $/;<$fh>});close $fh or die $!;
{
 no warnings 'redefine';
 *FSM::Scheduler::ISF::LoweringIR::_validate_transaction_port_bindings=sub {return 1};
}
my $actor=FSM::Adapter::ISF->new->parse_source($input->{source},'source_context.isf');
my $before=$json->encode($actor);
my $accepted=eval {FSM::Scheduler::ISF::LoweringIR->new->prepare_formal_source($actor);1};
my $error=$@;
open my $out,'>:raw',"$base/bypass-input.json" or die $!;
print {$out} $json->encode({source=>$input->{source},actor=>$actor,error=>$error,accepted=>$accepted?1:0,unchanged=>$before eq $json->encode($actor)?1:0}),"\n";close $out or die $!;
print $error;
