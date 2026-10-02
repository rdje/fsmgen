package FSM::Test::NoFileFormAssociation;
use strict;
use warnings;
use FSM::Test::FileDocumentOriginAuthority;
my $producer = FSM::Test::FileDocumentOriginAuthority::Parser->can('_parse_library_form');
{
    no warnings 'redefine';
    *FSM::Test::FileDocumentOriginAuthority::Parser::_parse_library_form = sub {
        my ($self, @args) = @_;
        local $self->{file_forms} = {};
        return $producer->($self, @args);
    };
}
1;
