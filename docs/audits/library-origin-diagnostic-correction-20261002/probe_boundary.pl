use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use FSM::Test::LibraryDocumentOriginAuthority;

my $error = wrong_boundary(qr/library origin selected source bytes differ from authority/);
print JSON::PP->new->canonical->encode({error => $error,
    expected => 'library origin selected source bytes differ from authority'}) . "\n";
sub wrong_boundary {
    my ($expected) = @_;
    eval {FSM::Test::LibraryDocumentOriginAuthority->from_documents('missing.isf', {}, [])};
    return $@;
}
