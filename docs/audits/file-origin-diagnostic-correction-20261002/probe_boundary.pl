use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use FSM::Test::FileDocumentOriginAuthority;

my $expected = 'file origin selected source bytes differ from authority';
my $error = wrong_boundary(qr/file origin selected source bytes differ from authority/);
print JSON::PP->new->canonical->encode({error => $error, expected => $expected}) . "\n";

sub wrong_boundary {
    my ($pattern) = @_;
    eval {FSM::Test::FileDocumentOriginAuthority->from_files('missing.isf', {}, [])};
    return $@;
}
