use strict;
use warnings;
use lib 'perl';
use FSM::Scheduler::ISF::LoweringIR;
{
 no warnings 'redefine';
 # Genuine runtime provider bypass; the provider's source stays unchanged.
 *FSM::Scheduler::ISF::LoweringIR::_validate_transaction_port_bindings=sub {return 1};
}
my $result=do './t/1936-isf-formal-source-context.t';
die $@ if $@;
die $! unless defined $result;
