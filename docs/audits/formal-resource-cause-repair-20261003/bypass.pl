use strict;
use warnings;
use lib 'perl','t/lib';
use FSM::Scheduler::ISF::LoweringIR;
{
    no warnings 'redefine';
    *FSM::Scheduler::ISF::LoweringIR::_validate_round_robin_rule_user_resource=sub {
        my ($ir,$name,$users)=@_;
        return FSM::Scheduler::ISF::LoweringIR::_round_robin_pointer_declaration($name,$users);
    };
}
do './t/1944-isf-formal-resource-products.t';die $@ if $@;
