use strict;
use warnings;
use JSON::PP;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

my $base = 'docs/audits/raw-semantic-links-20261011';
die "one complete semantic wire-kind candidate" unless @ARGV == 1;
my $path = $ARGV[0];
die "own relative typed semantic candidate" unless index($path, "$base/") == 0 && $path !~ m{^/|(?:^|/)\.\.(?:/|$)|(?:^|/)\.git(?:/|$)};
my @root = stat '.';
my $current = '';
for my $part (split m{/}, $path) {
    $current .= ($current eq '' ? '' : '/') . $part;
    my @st = stat $current;
    die "ordinary same-volume typed semantic candidate boundary" if !@st || $st[0] != $root[0] || -l $current || -e "$current/.git";
}
die "whole ordinary typed semantic candidate" unless -f $path;
open my $fh, '<:raw', $path or die "open complete typed semantic candidate: $!";
my $raw = do { local $/; <$fh> };
close $fh or die "close complete typed semantic candidate: $!";
my $decoded;
gunzip \$raw => \$decoded or die "whole typed semantic candidate decompression: $GunzipError";
my $json = JSON::PP->new->utf8->canonical;
my $candidate = $json->decode($decoded);
die "complete typed semantic records" unless ref($candidate->{semantic_links}{records}) eq 'ARRAY';
sub integer {
    my ($value) = @_;
    return !ref($value) && $json->encode($value) =~ /\A(?:0|[1-9][0-9]*)\z/;
}
for my $record (@{$candidate->{semantic_links}{records}}) {
    die "semantic record coordinate requires a JSON integer" unless ref($record->{record}) eq 'ARRAY' && @{$record->{record}} == 3 && integer($record->{record}[2]);
    die "complete typed semantic phase allocation" unless ref($record->{phases}) eq 'ARRAY';
    for my $index (0 .. $#{$record->{phases}}) {
        my $domain = $record->{phases}[$index]{domain};
        die "semantic phase coordinate requires a JSON integer" unless ref($domain) eq 'ARRAY' && @$domain == 4 && integer($domain->[2]) && integer($domain->[3]);
        die "semantic typed phase must belong to its exact record and ordinal" unless $json->encode([@$domain[0..2]]) eq $json->encode($record->{record}) && $domain->[3] == $index;
    }
}
print "PASS independent semantic JSON integer record and phase coordinates.\n";
