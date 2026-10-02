use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::SameSourceLibraryOriginParser;

{
    package FSM::Test::MissingExportAssociation;
    use parent 'FSM::Test::SameSourceLibraryOriginParser';
    sub _parse_library_form {
        my ($self, @args) = @_;
        my $actual = $self->SUPER::_parse_library_form(@args);
        delete $self->{exports}{$actual->{name}};
        return $actual;
    }
}
my $json = JSON::PP->new->canonical;
my @paths = sort glob '.artifacts/conditional-origin-library/current/*.json';
die 'wrong complete source membership' unless @paths == 24;
for my $path (@paths) {
    open my $file, '<:raw', $path or die $!;
    my $input = $json->decode(do {local $/; <$file>});
    my $actor = eval {FSM::Test::MissingExportAssociation->new->parse_source($input->{source}, $input->{label})};
    my $error = $@;
    ok(defined($actor), 'canonical export association must survive actual cloning: ' . $input->{case}{name});
    diag($error) unless defined $actor;
    if (my $dir = $ENV{FSMGEN_LIBRARY_ORIGIN_RED_CAPTURE}) {
        my ($name) = $path =~ m{/([^/]+)$};
        open my $out, '>:raw', "$dir/$name" or die $!;
        print {$out} $json->encode({source => $input->{source}, label => $input->{label},
            ordinary => $input->{ordinary}, actor => $actor, diagnostic => $error}) . "\n";
        close $out or die $!;
    }
}
done_testing;
