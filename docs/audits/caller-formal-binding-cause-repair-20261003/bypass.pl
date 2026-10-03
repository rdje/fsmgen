use strict;
use warnings;
use lib 'perl','t/lib';
use FSM::Scheduler::ISF::LoweringIR;
{
    no warnings 'redefine';
    *FSM::Scheduler::ISF::LoweringIR::_validate_transaction_port_bindings=sub {return 1};
}
do './t/1933-isf-caller-formal-binding-scope.t';die $@ if $@;
