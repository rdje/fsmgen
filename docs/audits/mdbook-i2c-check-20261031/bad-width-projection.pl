use strict;
use warnings;
use lib 'perl';
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;
my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $original = $class->can('_contributions');
{
    no strict 'refs'; no warnings 'redefine';
    local *{"${class}::_contributions"} = sub {
        my ($capture, $observation) = @_;
        # Deliberately incorrect: let every amount operand contribute to the
        # data maximum. Keep original capture, inference and all guards live.
        local $capture->{walk}{width_stamps} = $capture->{walk}{stamps};
        return $original->(@_);
    };
    my $result = do './t/2296-inline-shift-literal-emission.t';
    die $@ if $@;
    die $! unless defined $result;
}
