use strict;
use warnings;
use JSON::PP qw(decode_json);

my $path = 'docs/audits/record-value-own-boundary-publication-20261005/initial-publication.json';
open my $file, '<:raw', $path or die "read initial publication: $!";
my $raw = do { local $/; <$file> };
close $file or die "close initial publication: $!";
my $publication = decode_json($raw);
my $literal = './t/1986-isf-record-port-value-gates.t';
die 'original test filename was split inside the source-qualified literal'
    if index($publication->{own_block}, $literal) < 0;
print "PASS original source filename literal conserved\n";
