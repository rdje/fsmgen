package FSM::Test::NoFileFormCarry;
use strict;
use warnings;
use FSM::Test::FileDocumentOriginAuthority;
my $producer = FSM::Test::FileDocumentOriginAuthority::Parser->can('_build_actor');
{
    no warnings 'redefine';
    *FSM::Test::FileDocumentOriginAuthority::Parser::_build_actor = sub {
        my ($self, @args) = @_;
        local $self->{file_actor_forms} = {};
        return $producer->($self, @args);
    };
}
1;
